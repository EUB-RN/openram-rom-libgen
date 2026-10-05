# Using It on Your Own ROM (Step-by-Step Usage Guide)

One command takes an OpenRAM ROM macro to a `.lib` and a `.sv`. **Every command is executed at the root of this repository** -- the directory holding `flow.py` -- and your macro goes under `user/` inside it. Nothing is ever run from inside the macro's own directory.

[<- back to the README](../README.md)

---

## Quick Example: The 7-Line Summary

For a ROM named `rom_1024x32`, the entire flow:

```bash
cd /path/to/openram-rom-libgen        # the repo root: flow.py is here
mkdir -p user/rom_1024x32
cp /wherever/rom_1024x32.sp  user/rom_1024x32/
cp /wherever/rom_1024x32.lef user/rom_1024x32/
cp /wherever/rom_1024x32.gds user/rom_1024x32/      # optional (for parasitic C extraction)
nix develop                                          # or: nix-shell (provides tools + env)
python3 scripts/rom_char/rom_paths.py --check rom_1024x32
./flow.py rom_1024x32
ls output/lib output/verilog
```

---

## Detailed Step-by-Step Guide

### 1. Put the macro under `user/`, at the repo root

`user/` is the macro directory `shell.nix` and `flake.nix` point `ROM_MACROS_DIR` at, so a macro placed there is discovered with zero extra configuration. You create it; the repository ships the directory empty. One sub-directory per ROM, named after the macro, with the files inside named after it too:

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

* **Macro Name:** The macro name is whatever the sub-directory is called, and `<macro>.sp` and `<macro>.lef` must match it -- that name is what you pass to `flow.py`, and what the output files are named after.
* **`examples/`:** `examples/` is study/reference material, not the place to put your own macro. To characterise those instead, point `ROM_MACROS_DIR` at that tree manually.

### 2. Enter the environment, from the repo root

```bash
nix develop        # flakes -- pins nixpkgs itself, needs no channel
# or:
nix-shell          # classic
```

Either shell brings `ngspice`, `magic`, `iverilog`, `opensta` and `python3`, detects a Sky130 PDK in standard locations, and exports:
* `ROM_MACROS_DIR=$(pwd)/user`
* `ROM_OUT_DIR=$(pwd)/output`
* `NGSPICE_BIN` and `STA_BIN`

> [!IMPORTANT]
> If the shell prints `no sky130 PDK found`, export `PDK_ROOT` yourself before proceeding -- without the device models, no simulation deck will run.
> Without Nix, install those five tools manually and export the same variables. See [Toolchain Requirements & Environment Setup](requirements.md) for full instructions.

When `<macro>_cap_only.spice` is absent, the flow runs Magic parasitic extraction and also requires `OPENRAM_TECH=/path/to/OpenRAM/technology` to locate technology rules.

### 3. Check the macro before spending hours on it

Always validate the macro structure and sub-circuits before launching SPICE sweeps:

```bash
python3 scripts/rom_char/rom_paths.py --check <macro>
```

This verifies every expected file and sub-circuit in `<macro>.sp`, printing `ok` or reporting missing elements.

The sub-circuit names it looks for are the standard names emitted by OpenRAM's `rom_compiler`:

```text
<macro>_rom_base_array        <macro>_rom_control_logic
<macro>_rom_base_one_cell     <macro>_rom_row_decode
<macro>_rom_base_zero_cell    <macro>_rom_bitline_inverter
<macro>_precharge_cell        <macro>_rom_column_mux_array
                              <macro>_rom_output_buffer
```

If your macro directory does not supply local `.mag` files for `rom_base_one_cell`, `rom_base_zero_cell`, `precharge_cell`, or `sky130_fd_bd_sram__openram_sp_nand2_dec`, the flow automatically resolves them from the shared repository `mags/` directory (or falls back to calibrated Sky130 generic baselines).

### 4. Run characterization

```bash
./flow.py <macro>
```

`<macro>` is the directory name from step 1, not a path -- `flow.py` looks it up under `user/` automatically. It runs pre-flight, the SPICE sweep, both generators, and the test suite.

#### Useful Flags

* `./flow.py`: With no macro name, processes **every** macro under the macro tree.
* `--from-logs`: Rebuilds `.lib` and `.sv` from existing logs on disk without re-simulating.
* `--check-only`: Stops immediately after pre-flight checks.
* `--jobs <N>`: Sets concurrent ngspice worker processes (default: 4).
* `--from-step <stage>`: Resumes execution at a failed or specified stage without repeating earlier simulations. Available stages include `extract`, `column-worst`, `periphery-active`, `backend-delay`, `coldec-delay`, `periphery-power`, `pin-cap`, etc. (run `./flow.py --list-steps`).

---

## The Two Modes, and Why the Second One Exists

The flow provides two characterization modes:

```bash
./flow.py <macro>          # Standard mode (tens of minutes)
./flow.py <macro> --full   # Full mode (roughly an afternoon)
```

| | `./flow.py <macro>` (Standard) | `./flow.py <macro> --full` (Full) |
|---|---|---|
| **Every `.lib` term except the two below** | Measured | Measured |
| **Address hold (`hold_rising`)** | `hold = access` (safe fallback) | **Measured** via bisection and converted to `clk0` pin frame |
| **Input clock slew (`index_1` axis)** | Flat axis (safe fallback) | **Measured** across 3 points (0.05, 0.2, 0.5 ns) |
| **Extra stages** | -- | `run_wl_slew.sh`, `run_hold_bisect.sh`, `run_addr2wl.sh`, `run_slew_sweep.sh` |
| **Runtime cost** | Tens of minutes | Roughly an afternoon |

### Why the slew axis is not in standard mode: it moves nothing

`index_1` is the input-slew axis of every delay table. `run_slew_sweep.sh` measures it by sweeping the front end at 0.05, 0.2, and 0.5 ns clock edges.

In this architecture, `access` is dominated by the dynamic bitline discharge:
$$\text{access} = \underbrace{t_{clk2pre}}_{\text{sees } clk0} + \underbrace{\max(t_{dis\_50}, t_{coldec})}_{\text{triggers off precharge}} + \underbrace{t_{bl2dout}}_{\text{triggers off bitline}}$$

Over a **10x** change in clock transition time, $t_{clk2pre}$ stretches by ~5.7% (0.7227 to 0.7642 ns at TT), moving total `access` by **only 0.24%** (17.2260 to 17.2675 ns), because >88% of access is the internal bitline discharge that has no path back to `clk0`. The standard mode ships a flat axis (three identical rows), which matches physical silicon within a fraction of a percent without wasting hours of simulation time.

### Why hold bisection is not in standard mode: the fallback is already safe

Standard mode ships `hold = access`, declaring that the address must remain stable for the full read window.

This is fundamentally safe: the row decoder is clocked, so an address moving during evaluate drops a second wordline, permanently discharging unintended bitlines. Holding the address for the entire read window is sufficient by construction. In timing analysis, a hold constraint that is too long loses timing margin, but can never produce an unsafe chip.

`--full` measures the true physical cut time: `run_hold_bisect.sh` bisects the exact moment the address can change without corrupting the read in flight. Once the bitline has crossed the bitline inverter trip point, the downstream buffer delay no longer constrains the address:
$$\text{hold}_{addr} = t_{cut} + t_{clk2pre} - t_{addr2wl}$$
Across example macros, the measured hold is 88–95% of access (a 5–12% tighter constraint).

### What is in both modes (and is never skipped)

`run_early_path.sh` runs in **both modes**. It measures the *best* column (fastest discharge path) to produce `retain_rise` and `retain_fall` (`dout hold`). Without this arc, static timing analysis tools would assume output data is retained indefinitely, masking hold races in external capture flip-flops. Because a missing constraint is dangerous, early-path characterization is mandatory in all modes.

---

## 5. What Comes Out

Generated outputs are placed in `output/` at the repository root:

```text
output/lib/<macro>_TT_1p8V_25C.lib      Typical corner
output/lib/<macro>_SS_1p6V_100C.lib     Slow corner
output/lib/<macro>_FF_1p95V_n40C.lib    Fast corner
output/verilog/<macro>.sv                Behavioural model with measured delays
```

Every generated `.lib` and `.sv` model is automatically validated against syntax checkers, OpenSTA, and the behavioural test suite.

---

## 6. Power and Ground in the `.lib`

The generated Liberty file declares its power/ground rails and explicitly links each signal pin to them:

```text
voltage_map ( VCCD1, 1.80 )      rail name -> voltage
  pg_pin(vccd1) voltage_name : VCCD1;       pin -> rail
    related_power_pin : vccd1;              signal pin -> pg_pin
    related_pg_pin    : vccd1;              internal_power / leakage -> pg_pin
```

All four links must exist for multi-voltage power analysis tools to trace from a signal pin to its supply rail:
* The pin names are extracted dynamically from the macro's LEF (`USE POWER` / `USE GROUND`) rather than hardcoded to `vccd1`/`vssd1`.
* The first power/ground pins in the LEF become the primary supply rails; any additional power/ground pins are written as backup rails.
* `tests/lib_tests/check_lib.py` verifies that every power/ground reference resolves correctly, and `tests/lib_tests/test_rom_lib.py` ensures no signal pin is left without a power rail.

---

## 7. Validating the Output

To ensure produced timing and behavioural models are immediately usable by downstream tools without unexpected syntax or semantic issues, run the verification suite:

```bash
tests/run_tests.sh
```

Three test suites run eleven checks:
1. **Scripts & SPICE helpers:** SPICE utilities, flow resume, dynamic periphery settling, and paired leakage analysis.
2. **Liberty validation:** Structural syntax, 15 deliberate fault injection fixtures (`check_lib.py`), ROM timing semantics, and industry-standard parser compliance via **OpenSTA** (`sta`).
3. **Verilog validation:** Syntax elaboration and dynamic behavioural simulation via **Icarus Verilog** (`iverilog` / `vvp`), asserting precharge, access delay, falling-edge invalidation, `cs0` gating, and address hold behavior.

> [!NOTE]
> Passing characterization tests validates the Liberty and SystemVerilog models; it does **not** substitute for physical DRC (Magic) or LVS (Netgen) on the layout. Physical sign-off remains a separate step.

---

## 8. Reference Macros in `examples/`

The repository includes four fully characterized Sky130 ROM macros under `examples/` (`wrom0` through `wrom3`, each 1064 words x 32 bits, 134 rows x 256 columns) with their complete characterization logs.

You can inspect these examples to study the flow or test changes end-to-end without running ngspice from scratch by regenerating and comparing outputs:

```bash
./scripts/rom_char/regen_rom_libs.sh && git diff --stat output/
```

