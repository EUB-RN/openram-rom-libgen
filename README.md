# openram-rom-libgen

**Timing and power characterization for OpenRAM ROM macros, and the Liberty
(`.lib`) + behavioural Verilog generated from it.**

OpenRAM's characterizer writes a `.lib` for SRAM only; its ROM compiler emits
just `.sp` / `.v` / `.lef` / `.gds`. This repository builds SPICE decks from
the macro's own netlist, measures them with ngspice at three corners, and
writes the files synthesis, STA and simulation need.

Measured timing and power values are read back from simulation logs. When a
measurement is unavailable, the generators either refuse to publish the
output or mark the conservative/analytic fallback explicitly in the generated
file; a file carrying such warnings is not a validated deliverable until
`tests/run_tests.sh` passes. Waveform figures are screenshots of ngspice's own
plot window rather than plots regenerated from the measurement logs.

| deliverable | path | written by |
|---|---|---|
| Liberty, three corners per macro | `output/lib/<macro>_<CORNER>.lib` | `regen_rom_libs.sh` -> `gen_rom_lib.py` |
| behavioural model with measured timing | `output/verilog/<macro>.sv` | `gen_macro_behavioral_v.py` |

Deeper reading: [the macro](docs/macro.md) · [measurement names](docs/naming.md)
· [what is measured](docs/measurements.md) · [flow and files](docs/flow.md)
· [your own ROM](docs/your-rom.md) · [limitations](docs/limitations.md)

> **Current checkout status:** all fifteen Liberty files (`wrom0`-`wrom3` and
> `random_2k`, three corners each) and all five matching `.sv` models pass the
> strict repository test suite, including OpenSTA parsing and behavioural
> simulation. This is a snapshot, not a permanent guarantee; rerun
> `tests/run_tests.sh` after changing or regenerating any output. See
> [`docs/STATUS.md`](docs/STATUS.md) for the resolution and verification details.
>
> This repository validates characterization models; it does not make the
> layout physically clean. The checked-in macro logs currently report DRC
> violations and LVS pin-matching failures. Resolve or formally waive those
> results separately before physical sign-off.

---

## Contents

**Start here:** [How to use](#how-to-use) ·
[Using it on your own ROM](#using-it-on-your-own-rom) ·
[The two modes](#the-two-modes-and-why-the-second-one-exists) ·
[Running the measurements one by one](docs/flow.md)

How it works:

1. [The ROM macro](#1-the-rom-macro)
2. [How each block is modelled](#2-how-each-block-is-modelled)
   - [Parasitics](#parasitic-extraction--resistance-modelling)
   - [The column](#the-column-bitline-discharge-and-precharge)
   - [Front end](#the-periphery-front-end-clk0---internal-clock---wordline---precharge)
   - [Back end](#the-back-end-bitline---dout0-at-one-of-the-three-lib-loads)
   - [Column decoder](#the-column-decoder-against-the-discharge-it-races)
   - [Leakage](#leakage-and-energy-current-not-voltage)
   - [Read energy](#dynamic-read-energy-the-average-of-10-random-reads-not-the-worst-case)
3. [Pin capacitance, and slew](#3-pin-capacitance-and-slew)
   - [Input pin C](#input-pin-capacitance----the-capacitance-attribute-of-every-input-pin)
   - [Wordline slew](#wordline-slew----how-fast-a-wordline-really-falls)
   - [Output slew](#output-slew-and-the-two-lib-table-axes)
   - [Address setup](#address-setup)
4. [The `.lib`](#4-the-lib-how-it-is-built-and-how-it-is-checked)
   - [Built](#built)
   - [Checked](#checked)
5. [The behavioural Verilog](#5-the-behavioural-verilog-why-and-how)
   - [Why](#why-it-is-generated)
   - [How](#how-it-is-generated)
   - [Syntax check](#syntax-check)

---

## How to use

### What you need

**Every command on this page is run from the root of this repository** -- the
directory that holds `flow.py`. Never from inside a macro's own directory, and
never from `scripts/`.

There are **no Python packages to install**: every script uses the standard
library only, so there is no `requirements.txt` and nothing for `pip`. What
the flow and complete validation suite need is five external tools and a PDK:

| | why | without it |
|---|---|---|
| `python3` | every generator | nothing runs |
| `ngspice` **with KLU** | every measurement; all decks select KLU | KLU-less or legacy-SPARSE results are rejected, so no `.lib` |
| `magic` 8.3+ | parasitic extraction, flow step 1 | no `<macro>_cap_only.spice`, so no column deck |
| `iverilog` | simulates the generated `.sv` in the testsuite | that test layer SKIPs |
| `OpenSTA` (`sta`) | reads every generated Liberty with a consumer parser | that test layer SKIPs unless Nix or `STA_BIN` supplies it |
| a **sky130 PDK** | the transistor models ngspice reads | not one deck will run |

### Getting that environment

**If you already have those five on your `$PATH` and a sky130 PDK on disk,
you need nothing else.** Add the OpenRAM technology tree when Magic must create
`<macro>_cap_only.spice`:

The ngspice build must report `Compiled with KLU Direct Linear Solver` from
`ngspice --version`. Every generated deck contains `.options klu`, and the
runner refuses a log unless ngspice confirms `Using KLU as Direct Linear
Solver`; it never accepts a silent fallback to legacy SPARSE. The Nix shell
runs the same solver probe while building its verified ngspice wrapper.

```bash
export PDK_ROOT=$HOME/OpenLane/pdks      # the directory CONTAINING sky130A/
export OPENRAM_TECH=$HOME/OpenRAM/technology  # required only for extraction
export ROM_MACROS_DIR=$(pwd)/user
export ROM_OUT_DIR=$(pwd)/output
```

**Check it took, before spending hours on it:**

```bash
./flow.py <macro> --check-only
```

That answers both halves of "can this run here" in one table -- the macro
(does it have the files and sub-circuits the decks expect) and the machine:

```text
  tool       status   what it is for
  ✓ python3    the generators
  ✗ ngspice    MISSING -- every measurement
  ✓ sky130     the transistor models
  ⚠ magic      not found -- parasitic extraction (--with-extract) (that part is skipped)
  ✓ iverilog   simulates the generated .sv in the testsuite
```

Anything marked `✗` stops the flow and the command exits non-zero, naming what
to install or which variable to export -- for a missing PDK it prints the exact
path it looked for. A `⚠` only narrows the run: that part is skipped and the
rest still produces a library. `--check-only` does not probe OpenSTA;
`tests/run_tests.sh` reports an OpenSTA skip, and `ROM_TESTS_STRICT=1` turns
that skip into a failure.

Pre-flight checks required files, pins, geometry and expected sub-circuits. It
does **not** run or certify DRC/LVS, and a pre-flight pass must not be read as a
physical-verification pass. It also does not validate the machine-specific
`OPENRAM_TECH` path; `run_cap_extract.sh` checks that when extraction is
actually needed.

`SKY130_LIB`, `NGSPICE_BIN`, `MAGIC_BIN`, `IVERILOG_BIN`, `VVP_BIN` and
`STA_BIN` are optional overrides -- each is derived from `PDK_ROOT` or from
`$PATH` when unset, so set them only if the binary you want is not the first
one on the path.

**Or let Nix supply the tools**, if you would rather not install them:

```bash
nix develop        # flakes -- pins nixpkgs itself, needs no channel
nix-shell          # classic
```

Either drops you into a shell with all five tools, looks for a sky130 PDK in
the usual places, and exports `ROM_MACROS_DIR`, `ROM_OUT_DIR` and
`NGSPICE_BIN` and `STA_BIN` for you. If the banner says `no sky130 PDK found`,
export `PDK_ROOT` yourself before going on -- Nix does not ship the PDK.
Nix also does not know where your OpenRAM checkout lives: export
`OPENRAM_TECH` before a run that must extract a missing
`<macro>_cap_only.spice`.

> [!NOTE]
> **First-run cost & caching:**
> * **Initial setup & compilation:** Most toolchain dependencies (`python3`, `ngspice`, `magic`, `iverilog`) and their runtime libraries are fetched prebuilt from `cache.nixos.org`. However, OpenSTA is not available in the binary cache for this pinned revision and is compiled locally from source during the first run. Depending on your system and network, this initial setup takes several minutes and requires storage in `/nix/store`.
> * **Subsequent launches:** All dependencies and build artifacts remain globally cached in `/nix/store`. Re-entering the environment (`nix develop` or `nix-shell`) takes only 2–3 seconds.
> * **Flakes vs. Classic Nix:** If running `nix-shell` on a flakes-first install without channels, any warning about `file 'nixpkgs' was not found` for interactive bash is harmless (it simply uses your host shell). Use `nix develop` to bypass channel lookups entirely.


### Cleaning up the Nix environment and storage

Nix stores cached packages and build closures under `/nix/store` and `~/.cache/nix`. To free disk space, remove stale build environments, and collect garbage:

```bash
# 1. Delete all old shell generations and garbage-collect unreferenced packages:
nix-collect-garbage -d

# 2. Hard-link identical store files to optimize disk usage:
nix-store --optimise

# 3. Clear local evaluation cache (optional):
rm -rf ~/.cache/nix

# 4. Remove stale direnv environments (if direnv was used):
rm -rf .direnv
```

> [!NOTE]
> `nix-collect-garbage -d` deletes old generations and unreferenced derivations without touching active system profiles. Re-entering `nix-shell` or `nix develop` will automatically download or build required tools cleanly.

### Running it

Put your macro in `user/<macro>/` (at least `<macro>.sp` and `<macro>.lef`,
named after the directory), then run **one command**:

```bash
python3 scripts/rom_char/rom_paths.py --check <macro>     # can it go through the flow?
./flow.py <macro>                                        # <- the whole thing
```

That runs pre-flight, every SPICE measurement, the `.lib` and `.sv`
generators and the full testsuite, in that order, and writes:

```text
output/lib/<macro>_TT_1p8V_25C.lib      typical
output/lib/<macro>_SS_1p6V_100C.lib     slow    <- sign-off corner
output/lib/<macro>_FF_1p95V_n40C.lib    fast
output/verilog/<macro>.sv                behavioural model, measured delays
```

**There are two modes.** Same command, one flag:

| | command | cost | what it measures |
|---|---|---|---|
| standard | `./flow.py <macro>` | tens of minutes | everything except the address hold and the clock-slew axis, which ship as safe, declared fallbacks |
| full | `./flow.py <macro> --full` | ~an afternoon | the same plus measured address hold and clock-slew axes |

For the characterization model, both modes are intended to be conservative
where they approximate, but only an output with a clean full test run is a
candidate for timing sign-off. Neither mode replaces DRC/LVS. **[Why the split exists, with the
numbers](#the-two-modes-and-why-the-second-one-exists)** -- the address hold
comes out 3-12% shorter under `--full`, and the slew axis moves `access` by
0.24%.

Useful flags: `--from-logs` rebuilds the `.lib` and `.sv` from logs already on
disk without re-simulating, `--check-only` stops after pre-flight, `--all`
(or no macro name) processes every macro in the tree, and `--jobs <n>` changes
the flow's default of four concurrent ngspice jobs.

Step-by-step version with the directory layout, the environment and what to
do when pre-flight complains:
**[Using it on your own ROM](#using-it-on-your-own-rom)**.

### Continuing after a failed step

Use `--from-step` to rerun the failed step and everything after it with your
updated parameters. Earlier stages are skipped and their files are reused:

```bash
./flow.py --list-steps
./flow.py <macro> --from-step 2 --jobs 2
./flow.py <macro> --from-step pin-cap --jobs 2
./flow.py <macro> --full --from-step hold-bisect
```

The numeric steps match the CLI phases: **1** pre-flight, **2** simulations,
**3** Liberty generation, **4** SystemVerilog generation, **5** tests.
They are not the measurement numbers in the step-by-step documentation.
Use a name such as `backend-delay`, `periphery-power`, or `pin-cap` to start
inside phase 2. The CLI prints these names during the run and a restart
command when a stage fails. Edit that command's parameter values as needed.

`--from-step 2` skips pre-flight and starts the simulation phase, including
extraction only for macros missing its output (or with `--with-extract`).
A named simulation start does not rerun extraction unless the name is
`extract`; missing extraction inputs are an error. Retain `--full` when
continuing a full run; its four additional stage names require that flag.
`--from-step 3`, `4`, and `5` do not require a simulator or PDK.

This is an explicit restart point, not an automatic checkpoint: the selected
stage reruns for all selected macros and its configured corners. Keep the same
macro/output directories and required environment variables. If a parameter
change also affects an earlier stage, start at the earliest affected stage.
Existing `.prov` checks still run during Liberty generation; this option does
not waive them or automatically infer parameter dependencies. It cannot be
combined with `--from-logs` or `--check-only`.

---

## 1. The ROM macro

> **The layout screenshots in this section are representative, not the example
> macros.** They are taken from a ROM built by the same OpenRAM `rom_compiler`
> and show the same architecture, but it is a *different macro* from the
> `wrom0`..`wrom3` under `examples/` -- the block labels in the picture carry
> that macro's own prefix. Read them as "this is what the structure looks
> like", never as a measurement. **Every number on this page comes from a
> netlist or a measurement log of the example macros, never from a picture**
> -- the waveform figures further down are the ones generated from the
> examples' own simulations.

![Macro floorplan](docs/img/01-macro-floorplan.png)

Seven top-level blocks: `rom_control_logic`, `rom_row_decode`,
`rom_column_decode`, `rom_base_array`, `rom_bitline_inverter`,
`rom_column_mux_array`, `rom_output_buffer`.

![Cell array](docs/img/02-array-overview.png)

What makes it unlike an SRAM, and what every model below has to respect:

* **A bitline is the entire column in series** -- ~80 NMOS in the discharge
  path, so the delay grows roughly *quadratically* with chain length. (That
  count is `wrom0`'s worst column, scanned out of its netlist by
  `find_worst_column.py`; it is not read off the array picture above, which is
  a different macro. Your own ROM's chain length is whatever
  `rom_paths.py --check` reports for it.)
* **The stored bit is a metal strap.** Every cell position holds a real
  transistor; a `zero_cell` shorts its source to its drain, a `one_cell` does
  not.

| `rom_base_one_cell` | `rom_base_zero_cell` |
|---|---|
| ![one cell](docs/img/03a-one-cell.png) | ![zero cell](docs/img/03b-zero-cell.png) |
| wordline falls -> chain breaks -> bitline stays high -> reads **1** | strap does not care -> chain conducts -> bitline discharges -> reads **0** |

* **All wordlines stay HIGH except the selected one**, which is driven LOW.
* **There is no latch anywhere** -- no dff, no sense amp, no replica column in
  the extracted cell inventory. `dout0` is valid only while `clk0` is high.
* **The bitline is a dynamic node.** Nothing drives it high during evaluate,
  so the ROM has a *minimum* clock frequency as well as a maximum, and the
  discharge is **irreversible**: an address change mid-evaluate ANDs the rows.

`access` is therefore a sum of three separately measured terms:

| # | term | deck | measurement |
|---|---|---|---|
| 1 | `clk0` -> `precharge` | periphery | `t_clk2pre` |
| 2 | precharge -> bitline 50% | column | `t_dis_50` -- **dominates** |
| 3 | bitline -> `dout0` | back end | `t_bl2dout` |

Names like `t_clk2pre` read *time, from `clk0`, to the precharge net*: see
[Reading a measurement name](docs/naming.md).

---

## 2. How each block is modelled

The 34 000-transistor macro is never simulated whole -- it does not converge.
Each block gets its own reduced deck, and the terms are added back in the
`.lib`.

| block | deck | what is kept, what is replaced |
|---|---|---|
| `rom_base_array` | **column** `col<N>_worst_case_parasitic*.sp` | one real column -- the one with the most `one_cell`s, chosen by a netlist scan. Every wordline held at DC VDD. Result x column count for energy and leakage. |
| `rom_control_logic`, `rom_row_decode` | **periphery** `periph_active_<corner>.sp` | the real logic; the array is **deleted and put back as a lump** -- cell gate count x measured gate C + parasitic wire C |
| `rom_bitline_inverter`, `rom_column_mux_array`, `rom_output_buffer` | **back end** `backend_<corner>_<load>.sp` | the real read path, driven by the column deck's OWN discharge waveform replayed sample for sample; run once per `.lib` output load |
| `rom_column_decode` | **coldec** `coldec_a<addr>_<corner>.sp` | hangs off the same precharge net as the bitline, so the middle term is `max(bitline, column decode)`, not their sum |
| every repeated block, leakage | **block slices** `periph_leak_paired_<corner>.sp` | one instance of each block on its own supply source; one parsed deck changes `gmin` and `cs0` in place and runs every `.op`, then each branch current is multiplied by the netlist-derived count |
| one cell's gate | `cellgate_<corner>.sp` | the lump the periphery deck loads itself with -- `c_one_ff`, `c_zero_ff` |

Every deck uses **real Magic parasitic capacitance** and runs each corner
against its own sky130 models. No fixed derating factor.

### Parasitic extraction & resistance modelling

Full-macro RC extraction cannot be run directly in Magic because its resistance network solver segfaults on large ROM arrays and shorted zero-cells. To avoid this crash and still capture parasitics accurately, the flow pairs macro-level capacitance extraction (`extresist off`) with an analytical per-cell resistance model:

1. **Magic crashes on full-macro resistance extraction:** Magic (specifically versions 8.3.628 / 8.3.629) segfaults when attempting whole-macro resistance extraction (`extresist all` / `ext2spice extresist on`) on arrays containing tens of thousands of devices. Furthermore, ROM programming creates degenerate cell topologies: `rom_base_zero_cell` shorts its source and drain together with a metal1 strap (representing logic 0), which causes Magic's resistance network solver to crash immediately.
2. **Reproducing the Magic segfault:** Anyone can reproduce this crash on an example macro (e.g. `wrom0`) to verify why whole-macro resistance extraction cannot be used:

   ```bash
   # Proof: attempting full-macro resistance extraction in Magic triggers a segfault
   cd examples/wrom0
   magic -dnull -noconsole << 'EOF'
   load wrom0
   extract style ngspice(si)
   extract all
   extresist tolerance 1
   extresist all
   ext2spice hierarchy on
   ext2spice format ngspice
   ext2spice cthresh 0
   ext2spice rthresh 0
   ext2spice extresist on
   ext2spice -o wrom0_rc.spice
   quit -noprompt
   EOF
   # Result: Segmentation fault (core dumped)
   ```

3. **How the flow solves this:**
   * **Capacitance (`run_cap_extract.sh`):** Magic extracts real distributed parasitic capacitance with resistance extraction disabled (`ext2spice rthresh infinite`, `ext2spice extresist off`).
   * **Series Resistance (`gen_resistance_model.py`):** Resistance is extracted on single isolated cells (where Magic runs without crashing) and computed analytically from `.mag` geometries + PDK sheet resistances for strapped degenerate cells.
   * **Critical path injection:** The resulting resistances (~505 $\Omega$ per `one_cell`, ~41.5 $\text{k}\Omega$ over the worst column) are injected into the column deck (`--with-resistance`), moving access delay by **+15% at TT, +6.6% at SS, and +28% at FF**.
   * **Array-level parasitics:** While inter-column coupling and top metal bitline capacitance (~+3 fF) are not bundled in a monolithic extraction due to these tool limits, access timing is bounded cleanly without simulation convergence failures or tool crashes (see [docs/limitations.md](docs/limitations.md)).

### The column: bitline discharge and precharge

Simulates the worst-case series chain column under extracted capacitance and injected wire resistance. Measures `t_dis_50` (the dominant middle term of `access`, ~88% of total delay) and `t_pre_99` (bitline recharge time, which defines `min_pulse_width(fall)` and the maximum operating frequency).

> 📖 **Detailed SPICE deck, measurement table, and waveforms:** See [docs/measurements.md#the-column-bitline-discharge-and-precharge](docs/measurements.md#the-column-bitline-discharge-and-precharge).

### The periphery front end: clk0 -> internal clock -> wordline -> precharge

Simulates the control logic and address decode path with the bitline array replaced by equivalent lumped RC loads. Measures `t_clk2pre` (first term of `access`), derives internal clock delays, and proves by measurement that selected wordlines fall (active-low evaluate).

> 📖 **Detailed SPICE deck, measurement table, and waveforms:** See [docs/measurements.md#the-periphery-front-end-clk0---internal-clock---wordline---precharge](docs/measurements.md#the-periphery-front-end-clk0---internal-clock---wordline---precharge).

### The back end: bitline -> dout0, at one of the three `.lib` loads

Simulates the read path (bitline inverter, 256:32 column multiplexer, and output buffer) across three Liberty load capacitance points (`index_2`). Driven directly by replaying the column deck's actual discharge curve via a PWL source to measure `t_bl2dout` (third term of `access`) and output transition slew.

> 📖 **Detailed SPICE deck, measurement table, and waveforms:** See [docs/measurements.md#the-back-end-bitline---dout0-at-one-of-the-three-lib-loads](docs/measurements.md#the-back-end-bitline---dout0-at-one-of-the-three-lib-loads).

### The column decoder, against the discharge it races

Verifies that the column select signal `t_pre2sel` arrives well before the bitline discharges through 50% (`t_dis_50`). In all example macros, the select margin is 23-35x faster, ensuring the discharge remains the middle term of `access`.

> 📖 **Detailed SPICE deck, measurement table, and waveforms:** See [docs/measurements.md#the-column-decoder-against-the-discharge-it-races](docs/measurements.md#the-column-decoder-against-the-discharge-it-races).

### Leakage and energy: current, not voltage

Measures DC leakage via schematic block slicing and an adaptive `gmin` sweep (preventing artificial conductance errors), and evaluates dynamic switching charge `q_c3` using the `gear` numerical integrator (preventing trapezoidal body-node ringing).

> 📖 **Detailed SPICE deck, measurement table, and waveforms:** See [docs/measurements.md#leakage-and-energy-current-not-voltage](docs/measurements.md#leakage-and-energy-current-not-voltage).

### Dynamic read energy: the average of 10 random reads, not the worst case

Calculates realistic read energy by sampling 10 random addresses rather than assuming worst-case discharge across all columns. In a masked ROM, only logic-0 cells discharge their bitlines; accounting for actual row data patterns avoids a 1.8-2.0x overestimation in internal power.

> 📖 **Detailed calculation, random sampling, and logs:** See [docs/measurements.md#dynamic-read-energy-the-average-of-10-random-reads-not-the-worst-case](docs/measurements.md#dynamic-read-energy-the-average-of-10-random-reads-not-the-worst-case).

---

## 3. Pin capacitance, and slew

### Input pin capacitance -- the `capacitance` attribute of every input pin

Pin capacitance is measured by integrating charging current ($C = Q/V_{DD}$) over independent rise and fall ramps with adaptive settling. For multi-bit buses like `addr0`, the worst-case pin capacitance is assigned to the bus in the `.lib`.

> 📖 **Detailed SPICE deck, measurement table, and waveforms:** See [docs/measurements.md#input-pin-capacitance----the-capacitance-attribute-of-every-input-pin](docs/measurements.md#input-pin-capacitance----the-capacitance-attribute-of-every-input-pin).

### Wordline slew -- how fast a wordline really falls

Measures realistic 80-20% and 90-10% fall times of the wordlines driving the array. The extracted ramp (`t_wl1090 / 0.8`) directly feeds the hold time bisection deck (`run_hold_bisect.sh`), replacing synthetic ideal step assumptions with real silicon transitions.

> 📖 **Detailed SPICE deck, measurement table, and waveforms:** See [docs/measurements.md#wordline-slew----how-fast-a-wordline-really-falls](docs/measurements.md#wordline-slew----how-fast-a-wordline-really-falls).

### Output slew, and the two `.lib` table axes

Builds the Liberty timing 2D lookup tables: `index_1` (input transition time) is populated by sweeping `clk0` slew, while `index_2` (output load capacitance) is populated by the three back-end load simulations.

> 📖 **Detailed SPICE deck, measurement table, and waveforms:** See [docs/measurements.md#output-slew-and-the-two-lib-table-axes](docs/measurements.md#output-slew-and-the-two-lib-table-axes).

### Address setup

Measures address buffer delay to the decoder NAND gates (`t_addr2dec`). While the internal clock delay (`t_clk2int`) physically creates a negative setup margin at the pins, the `.lib` conservatively declares the positive buffer delay (+0.03 ns at TT) to protect timing margin against PVT variations. `cs0` inherits this setup bound, while its hold is conservatively mapped to the full access window.

> 📖 **Detailed analysis, margin race discussion, and waveforms:** See [docs/measurements.md#address-setup](docs/measurements.md#address-setup).

---

## 4. The `.lib`: how it is built, and how it is checked

### Built

`regen_rom_libs.sh` reads every term out of a log and passes it to
`gen_rom_lib.py --measured`. Under `--measured` the analytic BASE table and
the corner derating factors are **not** applied -- the value already belongs
to that corner, so multiplying would double count.

| `.lib` content | source |
|---|---|
| `cell_rise`/`cell_fall` on `dout0`, rising_edge arc | `t_clk2pre` + `max(t_dis_50, t_pre2sel)` + `t_bl2dout` |
| the **falling_edge arc** -- clk0 falls, data gone | `t_clk2pre + t_pre_50 +` smallest-load `t_bl2dout` |
| output slew tables | `t_dout_slew` |
| `min_pulse_width` rise / fall, `minimum_period` | evaluate window; `t_pre_99` |
| `setup_rising` | worst `t_addr2dec*` |
| `hold_rising` | bisected chain cut (`run_hold_bisect.sh` with `tf` from `run_wl_slew.sh`) |
| `capacitance` per input pin | `c_cyc<i>_ff` |
| leakage | column `.op` x columns + periphery block slices, same clk0 state so they add |
| energy, active and idle | active: mean of 10 random reads, `<zeros in the selected row>` x `e_col_pj` + `e_periph_pj`; idle from the `!cs0` deck |
| pins, bus widths, area | the macro's LEF |

The falling-edge arc is not optional: without it STA reads an unlatched ROM as
if it held its output, and reports a false pass.

`t_pre` uses `t_pre_99`, not `t_pre_90` -- 90% recharge comes out ~0.5 ns and
would write a `min_pulse_width(fall)` 20x too small.

### Visualizing the timing: Liberty arcs on the simulation waveform

Every timing constraint and delay arc in the `.lib` corresponds directly to an event in a real read cycle (here shown on `wrom0` at the SS corner, via `tb_wrom0_wave.v`):

![OpenRAM ROM Waveform & Liberty (.lib) Timing Mappings](docs/img/19-waveform-timing.png)

* **`setup_rising (addr0)`**: Address must arrive and settle before `clk0` rises (~50 ps).
* **`hold_rising (addr0)`**: Address must remain stable after `clk0` rises (35.97 ns at SS). Once this window closes, the address is free to move (here stepping to row `278`) without corrupting the read in flight.
* **`access time` (`cell_fall / cell_rise`)**: From `clk0` rise until `dout0` transitions from precharge `FFFFFFFF` to valid data (`0c1af939`, 41.06 ns at SS).
* **`dout hold` (`retain_rise/fall`)**: Minimum duration previous data is guaranteed held at output after clock rise (~2.2 ns).
* **`falling_edge arc`**: When `clk0` falls, the precharge PMOS pulls bitlines high, returning `dout0` to `FFFFFFFF` within 3.49 ns (unlatched ROM output invalidation).
* **`min_pulse_width` (rise & fall)**: Required evaluate (high phase, 41.98 ns) and precharge recharge (low phase, 14.88 ns) durations.
* **`cs0 clock_gating_hold_falling`**: `cs0` must remain high for the entire evaluate high phase; releasing it early would re-open precharge and destroy the read in flight.

### Checked

```bash
./tests/run_tests.sh                 # output/lib/*.lib
./tests/run_tests.sh path/to/x.lib
```

The runner has three suites and eleven checks; it exits with status 1 if any
executed check fails:

| suite | checks | what they prove |
|---|---|---|
| `tests/scripts_tests/` | SPICE utilities, error/provenance handling, flow resume, periphery settling, paired periphery leakage | parsers and generators work, failed or stale measurements stay loud, `--from-step` restarts at the requested boundary, dynamic periphery retries keep their final provenance verdict consistent, and single-parse paired-op sweeps vary cs0 and gmin correctly |
| `tests/lib_tests/` | checker fixtures, generic Liberty, ROM semantics, OpenSTA | the checker catches all 15 planted defects in `fixtures/`, generated files are structurally valid and describe the ROM, and a consumer parser accepts them |
| `tests/verilog_tests/` | iverilog elaboration and behavioural simulation | generated `.sv` models compile and reproduce precharge, access, invalidation, hold and chip-select behaviour |

OpenSTA and Verilog checks report a skip when their tools are absent. Use
`ROM_TESTS_STRICT=1` when a skip must fail the run.

---

## 5. The behavioural Verilog: why, and how

### Why it is generated

The `<macro>.v` OpenRAM ships comes from the **SRAM** template and models the
timing wrongly:

```verilog
always @(posedge clk0) begin cs0_reg = cs0; addr0_reg = addr0; ... end
always @(negedge clk0) if (cs0_reg) dout0 <= #(DELAY) mem[addr0_reg];
// "All inputs are registers"  +  "FIXME: This delay is arbitrary"
```

Both assumptions are false here. The extracted cell inventory contains **no
dff, latch, sense_amp, replica_column or delay_chain** -- the read element is
a plain inverter. The inputs are not registered and the output is not
registered. Anything simulated against that model, gate level included, never
sees the ROM's dynamic behaviour: neither an address changing mid-evaluate,
nor the data disappearing when `clk0` falls.

### How it is generated

```bash
python3 scripts/rom_char/gen_macro_behavioral_v.py            # every macro
python3 scripts/rom_char/gen_macro_behavioral_v.py wrom0
python3 scripts/rom_char/gen_macro_behavioral_v.py --corner TT_1p8V_25C
```

Nothing is typed by hand -- the three timing parameters are read back out of
the macro's own `.lib`, defaulting to **SS**, the worst corner, so the model
stays pessimistic:

| parameter | read from the `.lib` |
|---|---|
| `ACCESS_NS` | `TOTAL (worst load)` in the header |
| `T_PRE_NS` | `min_pulse_width` fall_constraint |
| `SETUP_NS` | the first `setup_rising` value |

Geometry (`DEPTH`, `WIDTH`, address bits, rows x columns) comes from
`rom_paths.py` -- netlist, LEF and config, one source. So after regenerating
the `.lib`s, rerunning this script is all it takes.

The model reproduces what the silicon does, and reports it with `$display`
when `REPORT=1`: data valid only while `clk0` is high, a setup violation on
an address that moved too late, a short precharge phase, and the
**irreversible discharge** -- an address changing during evaluate yields the
bitwise AND of every row selected in that phase. Ones do not come back.

### Syntax check

The generator itself refuses to write a file it cannot fill: a missing `.lib`
value or unreadable geometry is a warning and a skipped macro, with a non-zero
exit status, never a file with a placeholder in it.

The Verilog is **simulation only** -- not synthesizable; the ASIC flow reads
`<macro>_bbox.v`. Check it with any simulator, e.g.:

```bash
iverilog -g2012 -o /tmp/rom.vvp output/verilog/wrom0.sv && echo "syntax OK"
# or run the full testsuite (tests all .lib files, OpenSTA, and all .sv models):
./tests/run_tests.sh
```

Validation is local and reproducible through Nix. Before committing generated
outputs, run the strict suite so a missing tool cannot silently skip a layer:

```bash
nix develop --command env ROM_TESTS_STRICT=1 ./tests/run_tests.sh
```

---

## Using it on your own ROM

One command takes an OpenRAM ROM macro to a `.lib` and a `.sv`. **Every command
on this page is typed at the root of this repository** -- the directory holding
`flow.py` -- and your macro goes under `user/` inside it. Nothing is ever run
from inside the macro's own directory.

For a ROM named `rom_1024x32`, the whole of it:

```bash
cd /path/to/openram-rom-libgen        # the repo root: flow.py is here
mkdir -p user/rom_1024x32
cp /wherever/rom_1024x32.sp  user/rom_1024x32/
cp /wherever/rom_1024x32.lef user/rom_1024x32/
cp /wherever/rom_1024x32.gds user/rom_1024x32/      # optional
nix-shell                                            # tools + env, still at the repo root
python3 scripts/rom_char/rom_paths.py --check rom_1024x32
./flow.py rom_1024x32
ls output/lib output/verilog
```

The rest of this section is those seven lines explained. The
[next section](#running-the-measurements-one-by-one) is the same flow taken
apart, for when you want a single measurement.

### 1. Put the macro under `user/`, at the repo root

`user/` is the macro tree `shell.nix` points `ROM_MACROS_DIR` at, so a macro
placed there is found with no further configuration. You create it; the repo
ships the directory empty. One sub-directory per ROM, named after the macro,
and the files inside named after it too:

```text
user/
└── <macro>/
    ├── <macro>.sp           REQUIRED  netlist -- geometry and the critical path
    ├── <macro>.lef          REQUIRED  pin list, directions, area
    ├── <macro>.gds          OPTIONAL  only for real parasitic extraction
    ├── mags/                OPTIONAL  cell layouts; falls back to repo `mags/`
    ├── config/<macro>.py    OPTIONAL  word_size / words_per_row cross-check
    │   or <macro>.py        OPTIONAL  same config at the macro root
    └── rom_configs/<macro>.bin  OPTIONAL  contents; word count for the model
```

The macro name is whatever the sub-directory is called, and `<macro>.sp` and
`<macro>.lef` must match it -- that name is what you pass to every command
below, and what the output files are named after.

`examples/` is study material, not the place to put your own macro. To
characterise those instead, point `ROM_MACROS_DIR` at that tree by hand.

### 2. Enter the environment, from the repo root

```bash
nix develop        # flakes -- pins nixpkgs itself, needs no channel
nix-shell          # classic
```

Either brings ngspice, Magic, iverilog, OpenSTA and python3, finds a sky130 PDK in the
usual places, and exports `ROM_MACROS_DIR=$(pwd)/user`,
`ROM_OUT_DIR=$(pwd)/output`, `NGSPICE_BIN` and `STA_BIN`. If it prints
`no sky130 PDK found`, export `PDK_ROOT` yourself before going on -- without
the device models not one deck will run. Without Nix, install those five and
set the same variables by hand; there are no Python packages to install, so
there is nothing for `pip`. Full list and the `nixpkgs`-not-found case:
[What you need](#what-you-need).

When `<macro>_cap_only.spice` is absent, the flow runs Magic extraction and
also needs `OPENRAM_TECH=/path/to/OpenRAM/technology`; the Nix shell cannot
derive this machine-specific path for you.

### 3. Check the macro before spending hours on it

Still at the repo root -- the path below is relative to it:

```bash
python3 scripts/rom_char/rom_paths.py --check <macro>
```

It names every file it wants and every sub-circuit the decks expect, one line
each, and says whether the macro can go through the flow at all. A missing
sub-circuit here is an architecture mismatch, not a typo -- see
[docs/your-rom.md](docs/your-rom.md).

### 4. Run it

```bash
./flow.py <macro>
```

`<macro>` is the directory name from step 1, not a path -- `flow.py` looks it
up under `user/` itself. It runs pre-flight, the SPICE sweep, both generators
and the full testsuite, in that order, and takes hours: the simulations are
the flow. `./flow.py` with no macro name processes **every** macro under the
tree.
`--from-logs` rebuilds the `.lib` and `.sv` from logs already on disk without
re-simulating; `--check-only` stops after pre-flight. For a failed stage, use
`--from-step`; the [restart section](#continuing-after-a-failed-step) lists the
stable phase and stage names.

There is a second mode, and it is the same command with one flag:

```bash
./flow.py <macro> --full
```

Both modes measure everything the `.lib` declares. `--full` additionally
measures the two terms the standard mode leaves on a safe approximation --
the address hold and the `index_1` clock-slew axis -- and costs about an
afternoon per macro instead of tens of minutes. **Why that split exists is
[its own section](#the-two-modes-and-why-the-second-one-exists)**, because
the reasoning is the point rather than the flag.

### 5. What comes out

Written under `output/` at the repo root, named after the macro:

```text
output/lib/<macro>_TT_1p8V_25C.lib      typical
output/lib/<macro>_SS_1p6V_100C.lib     slow
output/lib/<macro>_FF_1p95V_n40C.lib    fast
output/verilog/<macro>.sv                behavioural model, measured delays
```

### The two modes, and why the second one exists

**No script in this repository is meant to be run by hand.** Every number that
reaches a `.lib` comes out of a log `flow.py` produced, checked against the
netlist it was measured on, by content hash -- an unstamped or stale log is
refused rather than read. The `run_*.sh` files are stages of the flow, not a
toolbox; the
[section below](#running-the-measurements-one-by-one) takes them apart so you
can watch one of them work, not so you can assemble a library out of them.

What the two modes differ in is how many of those stages run:

| | `./flow.py <macro>` | `./flow.py <macro> --full` |
|---|---|---|
| every `.lib` term except the two below | measured | measured |
| the address hold | `hold = access`, pessimistic | **measured** and converted to the `clk0` pin's frame |
| the `index_1` (clk0 slew) axis | one flat axis | **measured**, three points |
| extra stages | -- | `run_wl_slew.sh`, `run_hold_bisect.sh`, `run_addr2wl.sh`, `run_slew_sweep.sh` |
| cost per macro | tens of minutes | roughly an afternoon |

Both modes target a conservative timing model. `--full` removes the two
optional timing fallbacks in this table; other explicitly reported fallbacks
or a failing test still make the result incomplete. This statement covers the
Liberty/behavioural model only, not physical DRC/LVS sign-off.

#### Why the slew axis is not in the standard mode: it moves nothing

`index_1` is the input-slew axis of every delay table, and `run_slew_sweep.sh`
measures it by running the front end at 0.05, 0.2 and 0.5 ns of `clk0` edge.
The reason it can be left out is that **this macro barely responds to it**.
`access` is a sum of three terms and only the first can see `clk0` at all:

```text
access = t_clk2pre + max(t_dis_50, t_coldec) + t_bl2dout
         ^^^^^^^^^   ^^^^^^^^^^^^^^^^^^^^^^   ^^^^^^^^^^
         sees clk0    triggers off the         triggers off
                      precharge net            the bitline
```

Over a **10x** change in the clock edge, `t_clk2pre` stretches by 5.7% --
0.7227 to 0.7642 ns at TT -- and `access` moves from 17.2260 to 17.2675 ns.
That is **0.24%**, well under one percent, because 15.34 ns of that sum is a
bitline discharge with no path back to `clk0`. The output-transition table is
flat along the axis for the same reason.

So the standard mode ships a flat axis: three identical rows, which is what
the measurement produces anyway to within a quarter of a percent. The cost of
proving that on *your* macro is `<corners> x <slew points>` full periphery
runs, and `--full` is where you pay it -- worth doing if your ROM's array is
small enough that the front-end term stops being a rounding error in the sum.

#### Why the hold is not in the standard mode: the fallback is already safe

This is the address hold -- how long `addr0` must stay put after the clock
edge -- and the standard mode ships `hold = access`, the full read window.

That is not a guess with a hopeful number attached. It is the honest statement
of what the circuit does before anyone measures it: the row decoder is
clocked, so an address that moves during evaluate drops a second wordline,
that wordline cannot come back inside the cycle, and the cut chain leaves the
bitline wherever it happened to be. Holding the address for the whole read is
sufficient, by construction.

**It is also the direction it is safe to be wrong in.** A hold constraint that
is too long makes a timing tool reject a design that would in fact have
worked; it can never accept one that would have failed. You lose margin, not
correctness -- which is exactly why this measurement could be moved out of the
default flow and into a mode you opt into. Nothing about the standard library
is unsound without it.

What `--full` buys is the real number. `run_hold_bisect.sh` cuts the series
chain at the cell nearest the bitline -- the worst place to cut -- and bisects
the cut time until the read still lands within 10% of the rail; the smallest
passing cut *is* the requirement. It turns out the read is decided once the
bitline is through the bitline inverter's trip point, so the tail of `access`
does not constrain the address at all:

| wrom0, TT | ns |
|---|---|
| cut time, in the column deck's own frame | 16.1742 |
| + `t_clk2pre` (`clk0` -> the internal evaluate edge) | 0.7642 |
| - `t_addr2wl` (`addr0` -> the wordline it drops) | 1.1875 |
| **= `hold_rising` at the `clk0` pin** | **15.7509** |
| against `access` | 17.2675 |

Three of the mode's four stages are that one number: `run_wl_slew.sh` measures
the wordline edge the bisect deck cuts with (without it the deck uses an ideal
step, and the answer comes back pessimistic again), `run_hold_bisect.sh` finds
the cut time, and `run_addr2wl.sh` supplies the term that carries it out of
the deck's frame and into Liberty's, which is referenced to the `clk0` pin.
Across the four example macros it lands at 88-95% of `access`: the fallback
was pessimistic by 5-12%.

**Two things `--full` does not relax.** `cs0` keeps the full access window in
both modes -- it is not on the decode path at all, it gates the precharge, so
losing it during evaluate pulls the bitline back to VDD and kills the read at
*any* point in the cycle, including the late part the address is excused from.
And `cs0` keeps its `hold_falling = 0` arc, which says it must survive to the
capture edge. Those are different constraints that happen to be written in the
same field, and the measurement above touches neither.

#### What is in both modes, and is not a choice

`run_early_path.sh` runs in **both**. It measures the *best* column -- the
shortest chain -- to give `retain_rise`/`retain_fall`, the earliest dout0 can
leave its previous value.

It is not a mode because it has no pessimistic reading. The hold and the slew
axis both fall back to a number that is merely too conservative; this one
falls back to **no arcs at all**, and a timing tool with no `retain_*` believes
the previous cycle's data is held right up to the access time. A race that
eats the old value before it is captured then passes silently. A missing
constraint is not a conservative constraint, so there is no version of the
flow that omits it.

`regen_rom_libs.sh` names every term it had to fall back on, in the `.lib`
header and on stderr, in either mode -- so a library never quietly passes off
a fallback as a measurement.

Longer version, with the directory layout explained and the two ways in
compared: [`user/README.md`](user/README.md) and
[docs/your-rom.md](docs/your-rom.md).

---

## Running the measurements one by one

This characterization flow is designed to be executed via `./flow.py <macro>`, which automatically orchestrates stage dependencies, parallel execution, provenance tracking, and library validation.

If you need to inspect individual SPICE decks, debug specific stages, or run the low-level characterization scripts one by one, refer to **[Requirements, the flow, and the files](docs/flow.md)**.

---

## License

[BSD 3-Clause](LICENSE) -- the same licence OpenRAM itself uses, so the
generator and the compiler it characterises carry no compatibility question
between them.

What is under `examples/` is not this project's own work: the four `wrom*`
macros, their netlists and their layout come out of OpenRAM's `rom_compiler`
on the SkyWater sky130 PDK, and the `sky130_fd_bd_sram__*.mag` cells are the
PDK's. They are committed so that every number in `output/` can be traced back
to the log and the netlist it was measured from. Their own licences apply to
them.
