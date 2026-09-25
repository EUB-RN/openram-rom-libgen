# openram-rom-libgen

**Timing and power characterization for OpenRAM ROM macros, and the Liberty
(`.lib`) + behavioural Verilog generated from it.**

OpenRAM's characterizer writes a `.lib` for SRAM only; its ROM compiler emits
just `.sp` / `.v` / `.lef` / `.gds`. This repository builds SPICE decks from
the macro's own netlist, measures them with ngspice at three corners, and
writes the files synthesis, STA and simulation need.

**No number in the output is typed by hand** -- every one is read back out of
a measurement log. **No figure is drawn by a plotting tool** -- every waveform
is ngspice's own plot of its own simulation.

| deliverable | path | written by |
|---|---|---|
| Liberty, three corners per macro | `output/lib/<macro>_<CORNER>.lib` | `regen_rom_libs.sh` -> `gen_rom_lib.py` |
| behavioural model with measured timing | `output/verilog/<macro>.v` | `gen_macro_behavioral_v.py` |

Deeper reading: [the macro](docs/macro.md) · [measurement names](docs/naming.md)
· [what is measured](docs/measurements.md) · [flow and files](docs/flow.md)
· [your own ROM](docs/your-rom.md) · [limitations](docs/limitations.md)

---

## Contents

1. [The ROM macro](#1-the-rom-macro)
2. [How each block is modelled](#2-how-each-block-is-modelled)
   - [Parasitics](#parasitic-extraction--resistance-modelling-an-intentional-design-choice)
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

[Quick start](#quick-start)

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
| every repeated block, leakage | **block slices** `periph_leak_cs<n>_<corner>_g<gmin>.sp` | one instance of each block on its own supply source, so a single `.op` reports every block's current on a separate branch; x a count from the netlist |
| one cell's gate | `cellgate_<corner>.sp` | the lump the periphery deck loads itself with -- `c_one_ff`, `c_zero_ff` |

Every deck uses **real Magic parasitic capacitance** and runs each corner
against its own sky130 models. No fixed derating factor.

### Parasitic extraction & resistance modelling: an intentional design choice

A common question is why full-macro RC extraction (extracting wire resistance and array-level parasitics together in a single pass) is not run directly in Magic. **Using capacitance-only extraction (`extresist off`) at the macro level combined with a per-cell series resistance model is an intentional architectural and design choice:**

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

```bash
./scripts/rom_char/run_col_timing.sh wrom0
ngspice examples/wrom0/char/col236_worst_case_parasitic.sp
```
```
ngspice 1 -> run
ngspice 2 -> plot v(precharge) v(bl_0_236)
```

**What comes out of this deck** (`col<N>_worst_case_parasitic*.log`). The blue
trace is the whole of `access`'s dominant term; the red one is the precharge
phase that has to finish before the next read can start:

| measurement | what it is | where it lands |
|---|---|---|
| `t_dis_50` | precharge -> bitline 50% | **term 2 of `access`**, the largest one (wrom0 TT: 15.3355 of 17.2675 ns) |
| `t_dis_10` | the 10% point of the same fall | no `.lib` number of its own -- it is the cross-check that the back-end deck is replaying THIS curve: both decks print `t_dis_50`/`t_dis_10` and they must agree |
| `t_dis_50_prev` | the same discharge one cycle earlier | no `.lib` number -- it is the settling proof. Over 1% apart and the run is a start-up transient, not a steady state, and the deck says so |
| `t_pre_50` | recharge to 50% | the **falling_edge arc**: `t_clk2pre + t_pre_50 +` smallest-load `t_bl2dout` |
| `t_pre_99` | recharge to 99% | `min_pulse_width(fall)` and `minimum_period` -- the ROM's *minimum* clock frequency |
| `t_pre_90` | recharge to 90% | measured, deliberately NOT used: 90% lands ~0.5 ns and would write a `min_pulse_width` 20x too small |

![Column deck: precharge net and bitline](docs/img/10-col-deck.png)

*`col236_worst_case_parasitic.sp`, ngspice's own plot window. Red is
`v(precharge)`, blue the bitline `v(bl_0_236)` of wrom0's worst column. The
bitline sits at VDD while precharge is low, overshoots a little as precharge
releases at 1.00 us, then falls -- through 50% at ~14.8 ns, which is term 2 of
`access` and ~85% of it. The long flat tail is the dynamic node holding at 0:
nothing drives it back up until the next precharge.*

### The periphery front end: clk0 -> internal clock -> wordline -> precharge

```bash
./scripts/rom_char/run_periphery_power.sh wrom0
ngspice examples/wrom0/char/periph_active_tt.sp
```
```
ngspice 1 -> run
ngspice 2 -> plot v(clk0) v(wrom0_rom_row_decode_0/clk) v(wrom0_rom_row_decode_0/wl_0) v(wrom0_rom_column_decode_0/clk)
```

**What comes out of this deck** (`periph_active_<corner>.log`). It is the only
deck with the real decoder in it, so both the front-end delay and the
periphery's share of the energy come from here:

| measurement | what it is | where it lands |
|---|---|---|
| `t_clk2pre` | clk0 -> the internal precharge net | **term 1 of `access`**. Also the term the `index_1` slew axis moves, and the `+t_clk2pre` that carries the hold into the clk0 pin's frame |
| `t_clk2int` | clk0 -> the internal clock | not a `.lib` value: it is the other half of the SETUP race. The address requirement at the pin is `t_addr2dec - t_clk2int` = -0.2948 ns, quoted in the header |
| `t_wlfall0` | clk0 -> the selected wordline's fall | **not in `access`** -- see below. Feeds the hold work |
| `t_wlslew0`, `t_wl1090_0` | 80-20 and 90-10 fall times | `t_wl1090_0 / 0.8` is the real wordline ramp `run_hold_bisect.sh` drives its cut with |
| `v_wl0_eval` .. `v_wl7_eval` | wordline VOLTAGE at a fixed instant inside evaluate | no number -- the polarity EVIDENCE: the selected row reads 6.17e-08 V, the other seven read a flat 1.800000 V |
| `q_c2`, `q_c3` | charge drawn from VDD over two consecutive cycles | their gap is the settling check; `q_c3` is the one used |
| `e_periph_pj` | `q_c3 x VDD` | the periphery term of BOTH `internal_power` states -- added to the column term when `cs0`, and the whole of it when `!cs0` |

**The wordline is measured here but is deliberately not in `access`.** It
arrives at 1.5692 ns against the precharge net's 0.7642 ns, so adding it would
lengthen the sum by 0.8 ns. It is not in series: the read that sets `access`
is a read of **0**, and there the selected cell is a `zero_cell` -- a metal
strap that conducts whatever its gate does -- while every other wordline stays
HIGH and does not move at all. The chain is closed the moment precharge
releases. (The case where the wordline edge does matter is a read of **1**,
which the column deck does not simulate; see
[limitations.md](docs/limitations.md).)

The selected wordline **falls** -- the decoder polarity is settled by this
measurement, not assumed.

![Periphery deck: clock, wordline, precharge](docs/img/11-periph-frontend.png)

*`periph_active_tt.sp`. Red `v(clk0)` rises with the real input slew; blue is
the row decoder's internal clock, green the column decoder's, orange the
selected wordline `wl_0`. Two things are measurements rather than assumptions
here: the internal clock arrives ~0.55 ns after `clk0` crosses, and `wl_0` is
HIGH for the whole of that edge and only **falls** ~2.5 ns later. That
polarity -- selected wordline low, all others high -- is why the column deck
holds every other wordline at VDD.*

### The back end: bitline -> dout0, at one of the three `.lib` loads

```bash
./scripts/rom_char/run_backend_delay.sh wrom0
ngspice examples/wrom0/char/backend_tt_2756.sp
```
```
ngspice 1 -> run
ngspice 2 -> plot v(wrom0_rom_base_array_0/bl_0_236) v("dout0[2]")
```

**What comes out of this deck** (`backend_<corner>_<load>.log`). It is run
once per `.lib` output load, which is what makes `index_2` three measurements
rather than one number copied three times:

| measurement | what it is | where it lands |
|---|---|---|
| `t_bl2dout` | bitline -> `dout0`, through the bitline inverter, the 256:32 mux and the output buffer | **term 3 of `access`** (wrom0 TT: 0.9532 .. 1.1678 ns across the three loads). The SMALLEST-load value is also the third term of the falling_edge arc |
| `t_dout_slew` | the output's own transition time | the `output_transition` tables, and `retaining_rise`/`retaining_fall` take the smallest-load one |

The bitline here is not a stimulus shaped to look like a discharge, it is the
discharge: `run_backend_delay.sh` re-runs this corner's column deck with the
waveform kept and the samples are replayed through a PWL source. The deck
header prints the `t_dis_50`/`t_dis_10` of the curve it replayed, and they
match the column log to four decimals -- that is the proof it is the same
curve, at all three corners.

Until 2026-09-24 this was a straight ramp through the measured 50% and 10%
points instead. It reproduced those two instants and nothing else: a discharge
decelerates, so the secant between them runs 2.3-3.1x flatter than the curve
does where the bitline inverter actually trips (wrom0 TT: -0.0382 V/ns against
-0.1185 V/ns at the VDD/2 the deck trips on). The error it left behind was **not** one-sided --

| corner | `t_bl2dout` on the ramp | on the real edge | |
|---|---|---|---|
| TT | 1.7321 ns | 1.1678 ns | 48% pessimistic |
| FF | 1.4854 ns | 0.8093 ns | 84% pessimistic |
| SS | 1.9117 ns | 2.4829 ns | **23% optimistic** |

(largest load, the widest of the three). A too-flat edge leaves the inverter
in its transition region for nanoseconds, so what the `trig`->`targ` interval
measures is partly how far the output has already moved by the time the
bitline passes 50%. At SS the back end is slow enough (2-2.8 ns of output
slew) for that head start to outweigh everything else, and the `.lib` was
optimistic at the one corner signoff actually uses.

![Back-end deck: bitline to dout0](docs/img/12-backend-dout.png)

*`backend_tt_2756.sp`. Red is the bitline `v(bl_0_236)` -- the column deck's
own discharge, replayed; blue is `v(dout0[2])`. The red curve is the whole
argument of this section in one picture: it is not a line. It leaves VDD at
15.5 ns almost flat, is steepest around the 0.9 V the inverter trips at
(20.3 ns, `t_dis_50` + the deck's 5 ns start), and then trails off towards
zero for tens of nanoseconds. A straight ramp fitted to the 50% and 10%
points is the chord across that trail, three times flatter than the curve is
where it matters. dout0 falls 1.17 ns after the bitline crosses 50% --
`t_bl2dout` at this load -- and it falls in ~0.6 ns, an edge no part of the
bitline's own shape resembles.*

### The column decoder, against the discharge it races

```bash
./scripts/rom_char/run_coldec_delay.sh wrom0
ngspice examples/wrom0/char/coldec_a0_tt.sp
```
```
ngspice 1 -> run
ngspice 2 -> plot v(wrom0_rom_column_decode_0/clk) v(wrom0_rom_column_decode_0/wl_0)
```

**What comes out of this deck** (`coldec_a<addr>_<corner>.log`):

| measurement | what it is | where it lands |
|---|---|---|
| `t_pre2sel<k>_rise` | precharge -> column select k rises | the RACE against `t_dis_50`. `access`'s middle term is `max(t_dis_50, t_pre2sel)`, and the `.lib` header records the margin (23-35x everywhere, so the bitline wins and `access` is unchanged) |
| `t_pre2sel<k>_fall` | the same select falling | reported as "failed" on the seven unselected ones, and that failure is the polarity evidence: all eight selects are LOW during precharge, only the addressed one rises |
| `t_clk2pre` | re-measured with the decoder present | a cross-check, not a shipped number: 0.7630 ns here against 0.7642 ns in the periphery log, 0.2% apart -- proof the added block did not disturb the path it hangs off |

Nothing from this deck becomes a delay in the `.lib` while the decoder keeps
losing the race. `gen_rom_lib.py --t-coldec` will switch the middle term over
if a future macro ever flips it, and `run_coldec_delay.sh` exits non-zero and
says so.

`t_pre2sel` must land before `t_dis_50`, otherwise the middle term of `access`
is the decoder and the script says so.

![Column decode vs bitline discharge](docs/img/13-coldec.png)

*The column decoder's internal clock (red) against the addressed select
`wl_0` (blue): the select needs ~1.5 ns to reach VDD after the clock edge.
Set that against `t_dis_50` in the figure two sections up and the race is not
close -- the bitline is at 50% long after the select has settled, so `access`
keeps the discharge as its middle term. Captured from `periph_active_tt.sp`,
which carries the same `rom_column_decode` instance, so the window title
names that deck rather than `coldec_a0_tt.sp`; the vectors are the ones the
`plot` line above asks for.*

### Leakage and energy: current, not voltage

```bash
./scripts/rom_char/run_col_energy.sh wrom0
ngspice examples/wrom0/char/col236_energy_tt.sp
```
```
ngspice 1 -> run
ngspice 2 -> plot i(Vvdd) xlimit 800n 1000n ylimit -130u 20u
```

Both limits are needed and the `ylimit` is the important half: `xlimit` only
crops the x window, while the y axis keeps autoscaling over the WHOLE vector.
That vector is dominated by a 16.1 mA spike 5 ps into the run, so on a plain
`plot i(Vvdd)` the axis comes out in milliamps and every real current is a
flat line on zero. Pinning the y range puts the axis in microamps, which is
where the settled cycle lives -- `+17.3 uA` at 800.01 ns and `-122.7 uA` at
800.31 ns on the discharge edge, `-57.7 uA` at 911.6 ns on the recharge.

**That opening spike is an artefact of the simulation, not of the ROM.** `uic`
starts every node at 0 V, so on the very first timestep every parasitic C on
the supply charges at once; it is picoseconds wide and its height is set by
the solver's first step, not by the circuit. A real macro comes up on a supply
ramp and never draws it. It is also the reason the measured window sits on a
late cycle: the inrush at 5 ps and the slow chain fill-up behind it are five
orders of magnitude away from the 600 ns where `q_c2` starts, so neither of
them reaches the `.lib`.

**What comes out of these two decks.** They are the only ones that report a
CURRENT rather than a voltage, and between them they fill both power sections
of the `.lib`:

| measurement | deck / log | where it lands |
|---|---|---|
| `q_c3` | `col<N>_energy_<corner>.log` | the charge over the settled second-to-last cycle -- the early cycles are never used |
| `e_col_pj` | same | `q_c3 x VDD`: the energy ONE discharging column costs. Multiplied by the zeros in the selected row, it becomes `internal_power` `when "cs0"` |
| `q_c2` | same | the cycle before it, purely as the settling check |
| `vvdd#branch` | `col<N>_leak_<corner>.log` (`.op`, no waveform) | the array half of `cell_leakage_power`, times the column count |
| per-block branch currents | `periph_leak_cs<n>_<corner>.total` | the periphery half, one slice per block times a count from the netlist. Both halves are taken in the SAME idle state (clk0 low) so that they can be added |

Energy is `q_c3 x VDD` -- the charge integrated over the **second-to-last**
cycle, so the deck has settled. With `uic` every node starts at 0 and the
chain fills slowly, so the early cycles are a start-up transient and are never
used. The window moves with `--cycles` (6 on the column deck, 8 on the
periphery one) rather than sitting on a fixed cycle number: when the column
deck gained the array-level parasitics the extra charge made wrom2 at SS miss
the 1% settling limit at 4 cycles. The names `q_c2`/`q_c3` are historical --
they are the last two cycles, whichever those are.

![Column supply current over one cycle](docs/img/17-col-energy.png)

*`col236_energy_tt.sp`: `i(Vvdd)`, the current the column draws from the
supply, over one cycle. Flat and nearly zero between events -- that floor is
the leakage the `.op` deck measures separately -- with a single ~58 uA spike
when precharge pulls the bitline back to VDD. The area under that spike is
`q_c3`; `q_c3 x VDD` is `e_col_pj`, what one discharging column costs. Energy
is taken here, not from a voltage, because charge is what the `.lib` wants.*

### Dynamic read energy: the average of 10 random reads, not the worst case

`run_col_energy.sh` measures what **one** discharging column costs. What the
`.lib` needs is what a **read** costs, and that depends on how many columns
discharge at all.

Not all of them do. A read precharges every bitline to VDD while `clk0` is
low, then drops the selected row's wordline:

* the cell is a `zero_cell` -- a metal strap. It conducts whatever its
  wordline does, the series chain stays closed, **that bitline discharges**
  and the next precharge has to recharge it;
* the cell is a `one_cell` -- an NMOS whose gate has just gone low. It
  **opens** the chain, that bitline stays at VDD, and the next precharge draws
  nothing for it.

So the energy of one read is set by the number of zeros in the **selected
row** -- about half the array on the example macros (wrom0: 126.9 of 256).
Scoring every column as discharging, which is what this flow used to do, is
1.8-2.0x over the truth.

```bash
python3 scripts/rom_char/gen_random_read_energy.py wrom0 --corner tt
```
```
wrom0 tt: dynamic read energy, average of 10 random reads
  array        : 134 rows x 256 columns, 1064 words x 8 per row
  E_column     : 0.4966 pJ per discharged column  (col236_energy_tt.log)
  E_periphery  : 6.2581 pJ per cycle              (periph_active_tt.log)
  seed         : 4192668302

  read     address      row   discharged       E (pJ)
  1             45        5          118      64.8608
  2            860      107          133      72.3103
  3            542       67          122      66.8474
  4            297       37          127      69.3305
  5            351       43          111      61.3844
  6            877      109          109      60.3911
  7            388       48          129      70.3238
  8            202       25          124      67.8406
  9            487       60          134      72.8070
  10           752       94          132      71.8137

  average      : 67.7910 pJ   (min 60.3911, max 72.8070, sd 4.4201)
  worst case   : 133.3962 pJ   (all 256 columns discharging -- 1.97x)
  whole array  : 69.2564 pJ   (exact mean over all 134 rows, 126.9 of 256
                 columns discharging; per-row spread 0..158). The
                 sample is -2.12% against it.
```

Nothing here simulates. Both energy terms are still the measured ones
(`e_col_pj`, `e_periph_pj`); what is new is the **activity**, counted from the
netlist's own cell types. `regen_rom_libs.sh` calls this per macro per corner
and writes the per-read table to `char/random_energy_<corner>.log`, which the
`.lib` header cites.

**The seed is per macro, not per corner** -- on purpose. How many columns
discharge is a property of the ROM *contents*: the same address selects the
same row holding the same zeros at tt, ss and ff. Seeding per corner drew a
different sample at each one and put that difference into the activity
(124.8 / 126.9 / 133.3 columns at tt / ss / ff on wrom0, against a true 126.9
everywhere) -- a spurious ~7% spread landing straight in the corner ratios.
All three corners now read the same ten addresses, so the only thing moving
between corners is the measured energy.

**The worst case is not discarded, only demoted.** The `.lib` header quotes it
beside the average with the ratio, because a peak-current budget needs it and
an average-power figure does not.

The sample size is the remaining approximation: ten reads out of 134 rows sit
-3.5% to +1.7% off the exact array mean, and the tool prints that gap next to
every answer. Closing it costs nothing -- this is counting, not simulation:

```bash
ROM_ENERGY_READS=200 ./scripts/rom_char/regen_rom_libs.sh
```

---

## 3. Pin capacitance, and slew

### Input pin capacitance -- the `capacitance` attribute of every input pin

Each pin is ramped 0 -> VDD on its own and the charge it has to supply is
integrated: **C = Q/VDD**. That captures the whole load -- the pin's wire C,
the gate C of the first stage, and the Miller charge pushed back through that
stage as it switches.

* **Both edges are measured.** `c_rise` and `c_fall` should agree; a pin where
  they do not is state dependent and no single Liberty scalar can represent
  it. The summary prints the gap and ships the **larger** of the two.
* **`c_cyc` is the number that ships** -- one full `0 -> VDD -> 0`.
* **The whole periphery stays in the deck**: `addr0[0:2]` go to the column
  decoder, `addr0[3:]` to the row decoder, `clk0`/`cs0` to the control logic,
  so removing any block would leave some pin driving nothing.

```bash
./scripts/rom_char/run_pin_cap.sh wrom0
ngspice examples/wrom0/char/pincap_tt.sp
```
```
ngspice 1 -> run
ngspice 2 -> plot v(clk0) i(vpin1)
```

**What comes out of this deck** (`pincap_<corner>.log`), for each of the
thirteen input pins `i`:

| measurement | what it is | where it lands |
|---|---|---|
| `q_rise<i>`, `q_fall<i>` | the charge the pin supplies on each edge | the raw integral everything else is derived from |
| `c_cyc<i>_ff` | `(abs(Q_rise) + abs(Q_fall)) / (2*VDD)` | **the number that ships** as that pin's `capacitance`. A Liberty bus carries one value, so `addr0` gets the WORST bit (0.0095 pF at TT) and the header records the per-bit spread |
| `c_rise<i>_ff`, `c_fall<i>_ff` | the same split per edge | no `.lib` number -- the settling proof. The two must agree; a gap over 5% means the first stage was still switching when the window closed, and the summary prints it |

The cross-check, which produces no number the `.lib` needs -- run the deck
twice and compare, because the charge over a full swing must not depend on how
fast the pin is ramped:

```bash
PIN_TR=2n ./scripts/rom_char/run_pin_cap.sh wrom0     # ramp independence
```

**There is no whole-macro reference run.** There was one -- a `--keep-all`
deck with nothing deleted, no lumped load anywhere -- and it was removed. On
`wrom0` -- 1064 words x 32 bit, 34 kbit across 134 rows, and the smallest of
the four examples here -- it ran for hours at ~15 GB and was killed before it
finished; the cell array is the one block whose size the *user* picks, so on a
real ROM that deck does not run slowly, it dies. A check that only works on
the smallest possible macro cannot be part of a generator's flow.

What that leaves is a known limit rather than a hidden one. Every check here
runs the same reduced deck, so none of them can see an error the reduction
makes in all of them at once. That error is **bounded, not measured**:
doubling the lumped load the deleted array is replaced by moves `addr0[0]` by
4.9% and every other pin by under 0.6% ([limitations.md](docs/limitations.md)
item 5).

![Pin capacitance: the ramp and the charge it draws](docs/img/14-pincap.png)

### Wordline slew -- how fast a wordline really falls

The column deck cannot answer this: it holds every wordline at DC VDD. The
periphery deck can -- real decoder, real buffers, and the deleted array's load
put back as one cell gate per column plus the wordline's own wire C.

| measurement | what it is |
|---|---|
| `t_wlfall0` | `clk0` 50% -> wordline 50% (delay) |
| `t_wlslew0` | 80% -> 20% fall -- the sky130 Liberty convention |
| `t_wl1090_0` | 90% -> 10% fall |
| `tf` | `t_wl1090_0 / 0.8` -- the ramp to feed a PULSE/PWL |

```bash
./scripts/rom_char/run_wl_slew.sh wrom0
ngspice examples/wrom0/char/wlslew_tt.sp
```
```
ngspice 1 -> run
ngspice 2 -> plot v(clk0) v(wrom0_rom_row_decode_0/wl_0)
```

**What comes out of this deck** (`wlslew_<corner>.log`). None of it is a
`.lib` number directly -- this deck exists to give the HOLD measurement a real
wordline edge instead of a synthetic one:

| measurement | what it is | where it lands |
|---|---|---|
| `t_wlfall0` | clk0 50% -> wordline 50% | the delay itself; with `v_wl<k>_eval` it states the decoder polarity |
| `t_wlslew0` | 80% -> 20% fall | the sky130 Liberty slew convention, for comparison |
| `t_wl1090_0` | 90% -> 10% fall | **`/ 0.8` is the ramp `run_hold_bisect.sh` cuts the chain with** (`--wl-slew-ns`). Without it the hold would be bisected against an ideal edge the silicon never produces |

That is why `run_wl_slew.sh` has to run BEFORE `run_hold_bisect.sh`, and why
the hold is measured only where both logs exist -- which, since 2026-09-25, is
every macro at every corner. Where they are missing the `.lib` keeps
`hold = access` and says so in its header; that fallback is pessimistic by
5-12%, since the measured hold runs 88-95% of access.

![Wordline fall, driver and load both real](docs/img/15-wl-slew.png)

### Output slew, and the two `.lib` table axes

`t_dout_slew` comes from the same back-end deck as `t_bl2dout`, so the
CELL_TABLE's `index_2` (output load) is three measurements, not one number
copied three times. `index_1` (input transition) comes from a clk0 slew sweep:

```bash
SLEWS="0.05 0.5 1.5" ./scripts/rom_char/run_slew_sweep.sh wrom0
ngspice examples/wrom0/char/periph_slew0_tt.sp
```
```
ngspice 1 -> run
ngspice 2 -> plot v(clk0) v(wrom0_rom_column_decode_0/clk)
```

**What comes out of this sweep** (`periph_slew<n>_<corner>.log`, one run per
slew point):

| measurement | what it is | where it lands |
|---|---|---|
| `t_clk2pre` at each slew | the front-end term vs the clk0 edge | **the `index_1` axis** of every delay table. wrom0 TT: 0.7227 / 0.7406 / 0.7642 ns over 0.05 / 0.2 / 0.5 ns |
| the largest of them | | also the `t_clk2pre` used in the hold frame conversion, because that lengthens the converted hold, i.e. tightens it |

The axis is nearly flat, and that is the measurement rather than a
placeholder: a 10x change in the clock edge moves the front-end term by 5.7%
and `access` by 0.24%, because 15.34 ns of that sum is a bitline discharge
that cannot see clk0 at all.

Only term 1 of `access` depends on the clk0 edge -- terms 2 and 3 trigger off
the precharge net and the bitline, which cannot see clk0. That is also why the
output slew table stays flat over `index_1`.

![Front-end delay vs clk0 input slew](docs/img/16-slew-sweep.png)

### Address setup

```bash
./scripts/rom_char/run_addr_setup.sh wrom0
ngspice examples/wrom0/char/periph_setup_tt.sp
```
```
ngspice 1 -> run
ngspice 2 -> plot v(addr0[0]) v(clk0)
```

**What comes out of this deck** (`periph_setup_<corner>.log`):

| measurement | what it is | where it lands |
|---|---|---|
| `t_addr2dec0` .. `t_addr2dec7` | each address buffer -> the decoder NAND input it drives | the WORST of them becomes `setup_rising`, on `addr0` and on `cs0` |
| `t_clk2int` | clk0 -> the clock that gates that same NAND | not shipped: with `t_addr2dec` it gives the real requirement at the pin, `0.0307 - 0.3255 = -0.2948 ns`. The library ships the positive path delay anyway, and the header states both |

#### Why `cs0` inherits that number instead of getting its own

`cs0` ships the *address* setup, and its own path is never simulated. That is
a deliberate choice rather than an oversight, and it is worth spelling out
because the same question about **hold** was answered the opposite way.

**Hold: cs0 was split off, because a safe larger value existed.** The hold
experiment cuts the series chain mid-evaluate -- what a moving *address* does
to a clocked row decoder, and nothing else. `cs0` is not on the decode path at
all: it gates the precharge (`precharge = ~NAND(cs0, clk_int)`), so losing it
during evaluate turns the precharge PMOS back on and kills the read at *any*
point in the cycle. Applying the address's measured hold to `cs0` would have
*relaxed* its constraint on the strength of an experiment that never touched
it. There was somewhere safe to retreat to -- the full access window, which is
what the library declared before the measurement existed -- so `cs0` keeps
that, and the two pins carry different holds.

**Setup: there is no such retreat, so the gap is declared instead of
papered over.** A setup constraint is a *lower* bound; making it safer means
making it larger, and there is no larger value here that is defensible without
measuring one. Inventing a pessimistic pad would put a number in the `.lib`
that no measurement backs -- exactly the failure mode the rest of this flow is
built to avoid. So the address's measured path delay ships on `cs0` too, and
the fact that it was never measured on `cs0` is recorded in
[limitations.md](docs/limitations.md) item 7.

**What bounds it in the meantime is the netlist, not a guess.** `cs0` goes
straight to the A gate of `rom_control_nand` with no stage in between, and the
extraction keeps pin and gate as a single node. The address path has one
inverter (`inv_array_mod`) that `cs0`'s does not. So `cs0`'s real requirement
is *strictly smaller* than the number it ships -- the shipped value is
conservative for it, provably, from the topology. That is an argument from the
netlist rather than a simulation, which is why it is a stated limitation and
not a closed item.

The same reasoning decides the sign elsewhere: the measured `t_addr2dec*` is
0.0307 ns at TT, but the gate it feeds is clocked by `clk_int`, which arrives
`t_clk2int` = 0.3255 ns after `clk0` -- so the true requirement at the pin is
**-0.2948 ns**, i.e. the address may legally arrive *after* the clock edge.
The library keeps shipping the positive path delay, because a constraint
should not be relaxed as a side effect of changing what is being counted. The
`.lib` header states both numbers so a reader is never left guessing which one
they are holding.

`t_addr2dec*` is address pin -> the decoder output it drives; the worst of
them becomes the setup constraint.

![Address setup](docs/img/18-setup.png)

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
| `capacitance` per input pin | `c_cyc<i>_ff` |
| leakage | column `.op` x columns + periphery block slices, same clk0 state so they add |
| energy, active and idle | active: mean of 10 random reads, `<zeros in the selected row>` x `e_col_pj` + `e_periph_pj`; idle from the `!cs0` deck |
| pins, bus widths, area | the macro's LEF |

The falling-edge arc is not optional: without it STA reads an unlatched ROM as
if it held its output, and reports a false pass.

`t_pre` uses `t_pre_99`, not `t_pre_90` -- 90% recharge comes out ~0.5 ns and
would write a `min_pulse_width(fall)` 20x too small.

### Checked

```bash
./tests/run_tests.sh                 # output/lib/*.lib
./tests/run_tests.sh path/to/x.lib
```

Four layers, in order, exit status 1 if any fails:

| layer | what it proves |
|---|---|
| `test_checker.py` | the checker still catches the 15 planted defects in `tests/fixtures/`. A validator nobody validates turns every run green. |
| `check_lib.py` | **is this valid Liberty?** Syntax with a line number; table shape against the `lu_table_template` it names; monotonic `index_1`/`index_2`; every `timing()` has a known `timing_type`; delay arcs have all four tables; `related_pin` names a pin that exists; bus width matches its slice; no duplicate arcs; no negative delays; the pg_pin / `voltage_map` chain actually connects. |
| `test_rom_lib.py` | **does it say what this ROM does?** The falling-edge arc, the constraints, both power states, corner ordering. |
| OpenSTA | our parser checking our writer is a closed loop. This opens it, with the parser a consumer really uses. Skipped with a notice if `sta` is absent -- set `STA_BIN`. |

Two further layers run the generated behavioural Verilog through `iverilog`
and `vvp`, and are skipped with a notice when neither is installed.

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
iverilog -g2012 -o /tmp/rom.vvp output/verilog/wrom0.v && echo "syntax OK"
# or run the full testsuite (tests all .lib files, OpenSTA, and all .v models):
./tests/run_tests.sh
```

All Liberty and Verilog validation checks are automated on every push/PR via GitHub Actions (`.github/workflows/ci.yml`).

---

## Quick start

```bash
export ROM_MACROS_DIR=/path/to/your/macros     # default: <repo>/examples
export NGSPICE_BIN=ngspice MAGIC_BIN=magic
export PDK_ROOT=$HOME/OpenLane/pdks OPENRAM_TECH=$HOME/OpenRAM/technology

python3 scripts/rom_char/rom_paths.py --check <macro>   # macro has what the flow needs?

./scripts/rom_char/run_cap_extract.sh <macro>  # 1  parasitics (Magic, slow)
./scripts/rom_char/run_col_timing.sh           # 2  bitline discharge + precharge
./scripts/rom_char/run_backend_delay.sh        # 3  bitline -> dout, x3 loads
./scripts/rom_char/run_periphery_power.sh      # 4  periphery energy + cell gate C
./scripts/rom_char/run_addr_setup.sh           # 5  address setup
./scripts/rom_char/run_col_power.sh            # 6  column leakage
./scripts/rom_char/run_col_energy.sh           # 6  column energy
./scripts/rom_char/run_periphery_leak.sh       # 6b periphery leakage, gmin-swept
./scripts/rom_char/run_coldec_delay.sh         # 7  column decode vs discharge
./scripts/rom_char/run_pin_cap.sh              # 7  pin capacitances
./scripts/rom_char/regen_rom_libs.sh           # 8  write the .lib files
./tests/run_tests.sh                           # 9  validate them
python3 scripts/rom_char/gen_macro_behavioral_v.py
```

**How many simulations run at once is decided for you.** Every `run_*.sh`
above runs its decks in parallel, and the limit is memory rather than cores:
the periphery decks keep the row decoder, so each ngspice holds ~2.6 GB. So
`JOBS` defaults to `min(cores, free RAM / 3 GB)` -- 7 on a 28-core machine
with 22 GB free, 4 on a 16 GB laptop, 2 on an 8 GB one. Starting more than
fits drives the machine into swap, where it is slower than not starting them
at all.

Set `JOBS=<n>` to override it, or `ROM_JOB_MEM_GB=<n>` to change the per-job
budget. The count is read once, at start, and then holds for the whole run --
so it never drops below 2 however busy the machine looks at that instant. A
run that lasts hours must not be serialised by a squeeze that lasts seconds;
if you are deliberately starting a flow on a loaded machine, say `JOBS=` and
mean it.

**Not every deck costs 2.6 GB, and the stages say so.** A deck built out of
one extracted column -- the column timing and energy decks, the hold
bisection -- holds ~0.45 GB, so the same memory budget affords six times the
processes; the back-end deck, which keeps only the read path, sits between
them. Each stage asks for its own footprint (`stage_jobs` in `common.sh`,
`ROM_MEM_COLUMN` / `ROM_MEM_BACKEND` / `ROM_MEM_PERIPHERY`) instead of
inheriting the periphery's. An explicit `JOBS=` still wins over all of it.

**Work is taken from a rolling queue, not in batches.** Each stage keeps
`JOBS` runs in flight and starts the next one the moment a slot frees. The
earlier code launched `JOBS` runs and waited for *all* of them before
starting the next batch, so every batch cost as much as its slowest member --
with SS three times slower than FF in the same batch, most of the machine sat
idle most of the time. What still cannot overlap is stated where it happens:
a bisection picks each point from the previous answer, and the decks a
generator runs itself (the TT column and early-path decks) run inside their
own macro's turn. The macros themselves never wait for each other.

Step detail, per-script logs and troubleshooting:
[Requirements, the flow, and the files](docs/flow.md). Without a simulator,
[Understanding the macro](docs/macro.md) works on the netlist alone.

> A figure that shows as broken has not been captured yet -- the command above
> it is how to reproduce it. Figure conventions: [docs/img/README.md](docs/img/README.md).
> The waveform figures are ngspice's own plot window for the example macro
> named in the command beside them, screenshotted by hand: **no script in this
> repository captures a waveform**, because the figures are the independent
> check on what the flow computed and evidence made by the flow itself is not
> a check on it. The layout screenshots in section 1 are representative shots
> of the same architecture from a different macro.

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
