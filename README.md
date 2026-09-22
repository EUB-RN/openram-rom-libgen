# openram-rom-libgen

Automated **timing and power characterization** for ROM macros built with
[OpenRAM](https://github.com/VLSIDA/OpenRAM), and **Liberty (`.lib`)
generation** from the result.

OpenRAM's own characterizer only writes a `.lib` for SRAM; its ROM compiler
emits just `.sp` / `.v` / `.lef` / `.gds`. This repository fills that gap: it
builds SPICE testbenches from the macro's own netlist, measures them with
ngspice at three corners, and writes the `.lib` that synthesis and STA need,
plus a behavioural Verilog model carrying the measured timing.

No number in the output is typed by hand -- every one is read back out of a
measurement log.

| deliverable | directory |
|---|---|
| Liberty, three corners per macro | `output/lib/<macro>_<CORNER>.lib` |
| behavioural model with measured timing | `output/verilog/<macro>.v` |

Override the root with `ROM_OUT_DIR`.

---

## Quick start

```sh
# 1. point the flow at your macros (default: <repo>/examples)
export ROM_MACROS_DIR=/path/to/your/macros
python3 scripts/rom_char/rom_paths.py --list

# 2. check one macro has everything the flow needs
python3 scripts/rom_char/rom_paths.py --check <macro>

# 3. tell the tools where ngspice, magic and the PDK are
export NGSPICE_BIN=ngspice
export MAGIC_BIN=magic
export PDK_ROOT=$HOME/OpenLane/pdks
export OPENRAM_TECH=$HOME/OpenRAM/technology

# 4. run the flow (see "The flow" below for what each step does)
./scripts/rom_char/run_cap_extract.sh <macro>
./scripts/rom_char/run_col_timing.sh
./scripts/rom_char/run_backend_delay.sh
./scripts/rom_char/run_periphery_power.sh
./scripts/rom_char/run_addr_setup.sh
./scripts/rom_char/run_col_power.sh
./scripts/rom_char/run_col_energy.sh
./scripts/rom_char/regen_rom_libs.sh
./tests/run_tests.sh
python3 scripts/rom_char/gen_macro_behavioral_v.py
```

If you only want to look around without a simulator, everything in
[Understanding the macro](#understanding-the-macro) works on the netlist alone.

---

## Understanding the macro

### The cell array is a NAND chain

![Cell array](docs/img/02-array-overview.png)

A bitline is not one transistor per row tied to ground -- it is every cell of
that column **in series**, from the bitline contact at the top down to a single
foot transistor at the bottom. There are two cell types:

```
one_cell   : X0 D G S gnd    -> drain and source are DIFFERENT nets = a real transistor
zero_cell  : X0 S G S gnd    -> drain and source are the SAME net   = a permanent short
```

![One cell next to a zero cell](docs/img/03-cell-one-vs-zero.png)

Every cell position holds a physical transistor. What programs the bit is
whether a metal strap shorts its source to its drain. **That strap is the
stored data** -- the via pattern you can see in the layout is the ROM contents.

![One column, cells abutted in series](docs/img/04-column-strip.png)

### How a read works

During evaluate, **all wordlines stay HIGH except the selected one**, which is
driven LOW. So the chain conducts through dozens of pass transistors:

| cell in the selected row | when its wordline goes low | chain | bitline | read |
|---|---|---|---|---|
| `one_cell` (transistor) | turns **off** | broken | stays at VDD | **1** |
| `zero_cell` (strap) | strap does not care | conducts | discharges | **0** |

This is also why the macro is slow: the discharge current flows through ~80
series transistors, so the bitline behaves as a distributed RC line and the
delay grows roughly **quadratically** with the chain length.

You can read any column straight out of the netlist:

```
$ python3 scripts/rom_char/rom_explore.py wrom0 --col 236
== wrom0 column 236 -- bitline chain (top to bottom, 134 rows)
   1 = one_cell  (series NMOS, gate=wl) -> resistance in the chain
   0 = zero_cell (source/drain shorted) -> wire only

   r0    1010110101001111101100111111010111001001
   r40   1011110010111001101010010110100110011111
   r80   1000011110011100101010011111101001010100
   r120  11111011111101

   series NMOS count = 82  (real transistors in the discharge path)
```

The column with the most `one_cell`s is the slowest one, and characterization
runs on it. That choice is made by the tools, never by hand.

### The precharge phase, and why it is part of the answer

Nothing ever drives a bitline high in this macro. A read is a question about
charge that was put there in the previous half cycle, which is what makes the
array *precharged*, and it makes the length of that half cycle part of the
access time rather than a detail of the testbench.

One cycle has two phases, and the `precharge` net is what separates them. It
gates two devices at once:

| `clk0` | `precharge` net | precharge PMOS (top of the column) | foot NMOS (bottom of the chain) | the bitline |
|---|---|---|---|---|
| low | low | **on** -- pulls the bitline to VDD | **off** -- the chain is cut from ground | charges |
| high | high | off | **on** -- the chain reaches ground | discharges, or does not: that is the bit |

Both devices are driven by the same net on purpose: the foot transistor is
what keeps a short from VDD to ground through the chain while the bitline is
being charged. It is also why the foot is never one of the programmable cells
-- its gate is the `precharge` net, not a wordline, and
`gen_col_tb_parasitic.py` identifies it by that gate rather than by its
position.

**The chain's internal nodes never reach VDD.** They are charged from the
bitline *through the cells*, and every cell is an NMOS pass transistor, so
each one loses a threshold; the deeper the node, the lower it settles.
Measured at the end of a settled 100 ns precharge phase on wrom0 column 236 at
TT: bitline 1.799 V, first chain node 1.070 V, node 41 0.843 V, node 81
0.821 V -- and they keep creeping up as the phase is made longer, which is the
next paragraph.
There is no steady state in which the chain is simply "full".

So the longer the precharge phase lasts, the more charge the next read has to
remove, and the slower that read is:

| precharge phase | settled `t_dis_50` (wrom0, TT) |
|---|---|
| 25 ns | 6.96 ns |
| 50 ns | 9.54 ns |
| 100 ns | 11.59 ns |
| 200 ns | 12.96 ns |
| 1 us | 14.85 ns |

Monotonic and saturating. The worst case is therefore the **longest** precharge
-- a ROM that has been sitting idle with `clk0` parked low, whose chain has
filled asymptotically, and whose next read is the slowest read the macro can
perform. That is a real operating condition and it is the one the `.lib` has
to cover, so the column deck runs at `TCLK=2u`: a 1 us precharge phase, far
into the saturated region.

**And the first cycle is not a measurement.** The deck sets `.ic` on the
bitline only; with `uic` every internal chain node starts at 0 V and jumps
within picoseconds to a capacitive-divider level set by each cell's parasitic
C to vdd and to gnd. That level is *higher* than what conduction produces, and
the nodes cannot come back down -- during precharge the foot is off, so they
can only be charged, never discharged. A longer first precharge does not wash
it out: wrom0 reads 16.5035 ns on cycle 1 whether the first phase is 25 ns,
100 ns or 1 us, against 14.8495 ns settled at that same 1 us phase.

| | cycle 1 (capacitive divider) | settled |
|---|---|---|
| bitline | 1.8000 V | 1.7990 V |
| chain node 1 | 1.2623 V | 1.0696 V |
| chain node 41 | 1.1171 V | 0.8426 V |
| chain node 81 | 1.1082 V | 0.8201 V |

Cycle 1 is nearly flat; the settled state is a gradient built by conduction.
Every measurement in the column deck therefore sits on the third cycle, and
the deck also emits `t_dis_50_prev` -- the same measurement one cycle earlier
-- so that settling is *proven* rather than assumed. If the two differ by more
than 1% the generator says so and the number must not be used. This is the
same rule the energy decks apply with `q_c2` against `q_c3`; the timing deck
did not have it until 2026-09-20, and measured its first cycle. The effect on
the numbers it produces:

| corner | cycle 1 | settled, 1 us phase |
|---|---|---|
| tt | 16.5035 ns | 14.8495 ns |
| ss | 41.9709 ns | 36.0231 ns |
| ff | 8.9101 ns | 8.2893 ns |

The old values were pessimistic for `access`, which is the safe direction, but
they reached that margin through a state the circuit never occupies -- and for
`retain_rise`/`retain_fall`, which come from the same deck, the artefact
pointed the other way: retain is an *early* bound, and an unphysically slow
discharge makes the output look like it holds its previous value longer than
it really does, which is exactly what lets a hold violation pass unnoticed.

#### Does a chain that never reaches VDD cost noise margin?

It is the obvious next question, and the deck cannot answer it: every wordline
is held at DC VDD, so the only case it simulates is a read of **0**. On a read
of **1** the selected cell breaks the chain and the bitline has to *stay* high
while every still-conducting node above the break shares charge with it -- and
the deeper the selected row, the more nodes hang on the bitline. Measured by
hand on wrom0 column 236 at TT, pulsing one wordline low during evaluate:

| | selected row at the top | selected row at the bottom (81 cells still conducting) |
|---|---|---|
| `v(bl)` at 20 ns | 1.8163 V | 1.8415 V |
| `v(bl)` at 200 ns | 1.8141 V | 1.8230 V |
| `v(bl)` min over a 1 us evaluate | 1.8000 V | 1.7336 V |
| `v(bl_b)` max (inverter output) | 0.0000 V | 0.0000 V |

The 1 level holds. Two mechanisms protect it: each pass transistor cuts itself
off once its node is within a threshold of the bitline, so the chain cannot
drag the bitline down to its own level; and 41 kohm of chain resistance makes
the redistribution far slower than the access time. The partially charged
chain costs **speed on a read of 0, not level on a read of 1** -- and the
bitline itself is driven by the precharge PMOS directly, with no pass
transistor in the way, so its high level is full rail to begin with.

(The readings above VDD at 20 ns are the precharge edge coupling into the
bitline through the cell capacitances. It is the small bump visible at the
start of every discharge if you plot the deck.)

What this does *not* cover is neighbour-column coupling, which the column deck
does not carry at all -- see limitation 1 below.

---

## What is measured, and how

![Macro floorplan](docs/img/01-macro-floorplan.png)

The macro has seven top-level blocks. Six appear in the measurements:

| block | timing | power |
|---|---|---|
| `rom_control_logic` (clock driver + NAND) | periphery deck | yes |
| `rom_row_decode` (address buffers, decoder, wl drivers) | periphery deck | yes |
| `rom_base_array` (cells + precharge) | column deck (worst column) | yes (x columns) |
| `rom_bitline_inverter` | back-end deck | yes (inside the column deck) |
| `rom_column_mux_array` | back-end deck | no |
| `rom_output_buffer` | back-end deck | no |
| `rom_column_decode` (addr[2:0] -> word_sel) | not measured | no |

### `access` is the sum of three measured terms

There is no output latch, so `dout0` is valid only during clk0's high phase,
and the path from clock to data crosses three stages. Each is measured in its
own deck:

| # | term | what | deck | log |
|---|---|---|---|---|
| 1 | front end | `clk0` -> `precharge` | periphery | `periph_active_<corner>.log` (`t_clk2pre`) |
| 2 | bitline | precharge -> bitline 50% | column | `col<N>_worst_case_parasitic*.log` (`t_dis_50`) |
| 3 | back end | bitline -> `dout0` | back end | `backend_<corner>_<load>.log` (`t_bl2dout`) |

The same path run backwards gives the **falling-edge arc**: when clk0 falls
the precharge PMOS pulls the bitline back to VDD and every dout0 bit returns
to 1, so the data is gone. The `.lib` carries that as a second `timing()`
group on `dout0` with `timing_type : falling_edge`, built from the *minimum*
of the same three terms (`t_clk2pre + t_pre_50 + t_bl2dout` at the smallest
load). The earliest invalidation is the number that matters -- what has to be
proven is that the consumer captured before the data went away. Without this
group STA reads an unlatched ROM as if it held its output and reports a false
pass.

![Bitline discharge and precharge](docs/img/05-col-discharge.png)

Term 2 dominates. The figure shows the same column at all three corners, with
the 50% crossing that defines `t_dis_50` and the 99% recharge that defines
`t_pre`.

![Front-end waveforms](docs/img/06-front-end.png)

The front-end deck also settles the decoder polarity by measurement rather than
assumption: after clk0 rises, the selected wordline **falls**. That is what
justifies holding every wordline at VDD in the column deck.

![Back-end delay at three output loads](docs/img/07-backend-loads.png)

The back-end deck is run once per output load, so the `index_2`
(`total_output_net_capacitance`) axis of the CELL_TABLE is a real measurement
and not three copies of one number. The bitline edge driving it is not a guess
either -- it uses the slope implied by the measured `t_dis_50`/`t_dis_10`.

Also measured: setup (`t_addr2dec*`), leakage (`.op`), per-column energy and
periphery energy, active and idle.

Every measurement uses **real Magic parasitic capacitance** and runs each
corner against its own sky130 models -- no fixed derating factor.

### The scaling trick

The 34k-transistor array is never simulated whole:

* **column slice** -- the worst column is isolated by walking the extracted
  netlist graph, measured, and the result multiplied by the column count
  (leakage, energy);
* **periphery slice** -- the array is deleted and its load (cell gate count x
  measured gate capacitance + parasitic wire C) is put back as a lump.

So runtime does not explode as the macro grows.

![Energy settling over cycles](docs/img/08-energy-settling.png)

Energy is measured as the charge drawn from the supply over a cycle, and the
last two cycles are compared: equal values are the proof that the circuit has
settled.

### Predicting a geometry change

![Access time vs chain length](docs/img/09-chain-vs-access.png)

Access scales with the square of the chain length, so changing `words_per_row`
has a predictable cost before anything is simulated.

---

## Size independence

When a ROM is regenerated (different `word_size`, `words_per_row` or `.bin`)
**no script needs editing**. Everything the flow needs is derived:

| fact | source |
|---|---|
| macro list | `<tree>/<macro>/<macro>.sp` directories |
| row / column count | netlist scan (scoped to `*_rom_base_array`) |
| worst column + series chain length | same scan (`one_cell` count) |
| address / data width | LEF pins (`PIN addr0[..]`, `PIN dout0[..]`) |
| word count | size of `rom_configs/<macro>.bin` |
| `word_size` / `words_per_row` | `config/<macro>.py` (cross-check) |
| power / ground pin names | LEF pins (`USE POWER`, `USE GROUND`) |

The single source of truth is
[`scripts/rom_char/rom_paths.py`](scripts/rom_char/rom_paths.py). The netlist
wins; if `word_size*8*words_per_row` disagrees with it you get a **warning**,
and if `words_per_row` is not a power of two it tells you the address space
will have holes. Geometry is cached in `<macro>/char/.geometry.json` and
refreshes itself when the netlist changes.

---

## Using your own ROM

A macro directory is expected to look like an OpenRAM ROM output:

```
<macro>/
  <macro>.sp            netlist          (required -- geometry comes from here)
  <macro>.lef           pins + area      (required -- pin list for the .lib)
  <macro>.gds           layout           (needed for parasitic extraction)
  config/<macro>.py     word_size, words_per_row   (optional, cross-check)
  rom_configs/<macro>.bin                (optional, word count for the model)
  char/                 generated decks and logs (created for you)
```

Check it before running anything:

```
$ python3 scripts/rom_char/rom_paths.py --check wrom0
macro directory : /path/to/examples/wrom0

files:
  ok      wrom0.sp                     schematic netlist -- geometry, worst column
  ok      wrom0.lef                    LEF -- pin list, bus widths and area for the .lib
  ok      wrom0.gds                    GDS -- needed by run_cap_extract.sh
  ...
sub-circuits expected by the flow:
  ok      wrom0_rom_base_array               cell array (geometry, worst column)
  ok      wrom0_rom_base_one_cell            cell with a real NMOS (series chain)
  ...
All good -- this macro can go through the flow.
```

The sub-circuit names it looks for are the ones OpenRAM's `rom_compiler`
emits:

```
<macro>_rom_base_array        <macro>_rom_control_logic
<macro>_rom_base_one_cell     <macro>_rom_row_decode
<macro>_rom_base_zero_cell    <macro>_rom_bitline_inverter
<macro>_precharge_cell        <macro>_rom_column_mux_array
                              <macro>_rom_output_buffer
```

If your ROM has the same architecture under different names, adjust those names
in the generators. If it is a **different architecture** -- NOR ROM, latched
output, differential read -- the decks themselves need rethinking: they encode
the precharged-NAND behaviour described above.

---

## Requirements

* Python 3.8+ (no third-party packages)
* **ngspice** -- for the measurement runs
* **Magic** 8.3+ -- for parasitic extraction
* sky130 PDK ngspice models
* an OpenRAM technology tree, for the extraction step only

| variable | default | purpose |
|---|---|---|
| `ROM_MACROS_DIR` | `<repo>/examples` | macro tree |
| `ROM_OUT_DIR` | `<repo>/output` | where `lib/` and `verilog/` are written |
| `NGSPICE_BIN` | `ngspice` | ngspice binary |
| `MAGIC_BIN` | `magic` | magic binary |
| `OPENRAM_TECH` | -- | required by `run_cap_extract.sh` |
| `PDK_ROOT` | `~/OpenLane/pdks` | where sky130A lives |
| `SKY130_LIB` | `$PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice` | model file |
| `JOBS` | `4` | parallel ngspice runs |
| `LOADS` | `1.7225 6.89 27.56` | `.lib` CELL_TABLE output load points (fF) |
| `ROM_CORNERS` | `tt:1.8:25:38.2 ss:1.6:100:19.1 ff:1.95:-40:60.7` | corner:VDD:temp:fmax(MHz) |

---

## The flow

```sh
# 1) real parasitic C extraction (Magic; once per macro, slow)
./scripts/rom_char/run_cap_extract.sh wrom0        #  -> wrom0_cap_only.spice

# 2) column timing: bitline discharge + precharge, three corners
./scripts/rom_char/run_col_timing.sh               #  -> col<N>_worst_case_parasitic*.log

# 2b) optional: per-cell wire resistance, and a deck that includes it
python3 scripts/rom_char/gen_resistance_model.py wrom0
python3 scripts/rom_char/gen_col_tb_parasitic.py wrom0 --with-resistance

# 3) back-end delay + output slew, three corners x three loads
./scripts/rom_char/run_backend_delay.sh            #  -> backend_<corner>_<load>.log

# 4) periphery energy (active/idle) + cell gate capacitance
JOBS=4 ./scripts/rom_char/run_periphery_power.sh   #  -> periph_{active,idle}_<corner>.log

# 5) address setup (needs the cellgate log from step 4)
./scripts/rom_char/run_addr_setup.sh               #  -> periph_setup_<corner>.log

# 6) column leakage and column energy
./scripts/rom_char/run_col_power.sh                #  -> col<N>_leak_<corner>.log
./scripts/rom_char/run_col_energy.sh               #  -> col<N>_energy_<corner>.log

# 7) write the .lib files (reads every log; nothing is entered by hand)
./scripts/rom_char/regen_rom_libs.sh               #  -> output/lib/<macro>_<CORNER>.lib

# 7b) validate what was just written (regen_rom_libs.sh already runs the
#     structural pass; this adds the ROM semantics and OpenSTA if installed)
./tests/run_tests.sh

# 8) behavioural Verilog
python3 scripts/rom_char/gen_macro_behavioral_v.py #  -> output/verilog/<macro>.v
```

Every script takes macro names as arguments; with none, **every macro in the
tree** is processed:

```sh
./scripts/rom_char/run_backend_delay.sh wrom1 wrom2
ROM_MACROS_DIR=/path/to/macros ./scripts/rom_char/regen_rom_libs.sh
```

Steps 2-6 are independent of each other (5 depends on 4); step 7 needs them
all. Step 1 is the slow one (tens of minutes); steps 4 and 5 take a few minutes
per corner, the rest are seconds.

### When something goes wrong

| symptom | cause |
|---|---|
| `regen_rom_libs.sh` prints `missing measurement (...)` | that step has not been run, or its ngspice run failed -- the message names the term |
| `no setup measurement -> using pessimistic bound` | step 5 was skipped; the `.lib` is safe but pessimistic |
| `ERROR: ... _cap_only.spice does not exist` | step 1 has not been run for that macro |
| `no cellgate log (run run_periphery_power.sh first)` | step 5 was run before step 4 |
| `WARNING: config says ... columns, netlist has ...` | the config and the layout disagree; the netlist is used |
| a measurement is `FAILED` in a summary table | the ngspice run did not converge -- look at the `.log` in `char/` |

---

## Files

| file | job |
|---|---|
| `rom_paths.py` | path resolution + geometry (single source of truth), pre-flight check |
| `common.sh` | shared base for `run_*.sh`: paths, corners, `macro_list`, `load_geom`, `meas` |
| `find_worst_column.py` | finds the worst column and its series chain from the netlist |
| `rom_explore.py` | array structure summary, column histogram, row map |
| `run_cap_extract.sh` | capacitance-only parasitic extraction with Magic |
| `gen_col_tb_parasitic.py` | isolated testbench for the worst column (graph walk, name independent) |
| `gen_resistance_model.py` | per-cell series wire resistance: Magic per cell + analytic where it segfaults |
| `make_corner_variant.py` | SS/FF variant of the TT deck (identical circuit) |
| `run_col_timing.sh` | ties those two together: column timing at three corners |
| `gen_backend_delay_tb.py` / `run_backend_delay.sh` | bitline -> `dout0` and output slew vs load |
| `gen_cell_gate_tb.py` | equivalent cell gate capacitance (`C = Q(VDD)/VDD`) |
| `gen_periphery_power_tb.py` / `run_periphery_power.sh` | periphery energy (cs0=0/1), front-end delay, setup |
| `run_addr_setup.sh` | `addr0` -> decoder NAND input setup measurement |
| `gen_col_power_tb.py` / `run_col_power.sh` / `run_col_energy.sh` | column leakage (`.op`) and column energy |
| `gen_power_tb.py` | brute-force full-macro deck, for cross-checks only |
| `gen_rom_lib.py` | LEF + measured values -> Liberty |
| `gen_macro_behavioral_v.py` | behavioural `.v` that reports timing violations |
| `regen_rom_libs.sh` | the top-level script that ties the flow together |
| `tests/` | validation of the generated `.lib` -- see [`tests/README.md`](tests/README.md) |

Figures live in `docs/img/`; see [`docs/img/README.md`](docs/img/README.md) for
what each one must show and how to capture it.

---

## Known limitations

Ordered by how much they can move a number:

1. **The column deck misses array-level parasitics.** It carries the parasitic
   Cs inside the cell sub-circuits, but not the C elements at the
   `*_rom_base_array` level (bitline wire and inter-column coupling). On the
   example macros those sum to about +3 fF against the ~5 fF the deck does
   carry, so the bitline term -- the largest term of `access` -- is somewhat
   optimistic. The back-end and periphery decks already handle this with an
   explicit alive/dead + negative-net-capacitance rule; porting that rule into
   `gen_col_tb_parasitic.py` is the obvious next fix.
2. **`rom_column_decode` is measured only at the worst address.**
   `run_coldec_delay.sh` (2026-09-22) closed the old gap -- the mux select used
   to be an ideal source in the back-end deck and the margin was an estimate.
   It is now measured, with the decoder driven by the *real* precharge edge and
   loading the *real* mux gates, and the outcome changes how access is written
   down: the decoder's `clk` and its `precharge` port are **both** tied to the
   internal precharge net, the same net `t_dis_50` triggers off, so it **races**
   the bitline instead of adding to it --
   `access = t_clk2pre + max(t_dis_50, t_coldec) + t_bl2dout`.
   It loses that race by 23-35x at every corner (0.35 ns at FF, 0.58 ns at TT,
   1.13 ns at SS, against 8-39 ns of bitline), so access is unchanged and the
   `.lib` header now records the margin. What is *not* covered: the full
   8-address sweep was run on wrom0 at TT only (each address drives exactly one
   select, `addr k -> sel_k`, 0.4454-0.5753 ns, ordered by the 44-79 fF of
   select wire load), and the other macros and corners were run at address 0,
   the slowest select. The periphery is the same circuit in all four macros and
   the numbers agree to four digits across them, so this is cheap rather than
   risky -- but a macro whose column decoder differs would need the full sweep.
3. **Wire resistance is modelled per cell, not extracted whole.** Magic
   segfaults extracting resistance for the whole macro, so
   `gen_resistance_model.py` extracts it per cell (where Magic is happy) and
   computes it from the .mag geometry plus the PDK sheet resistances where it
   is not. On the example macros: 505 ohm per `one_cell`, 0.24 ohm per
   `zero_cell` strap, 41.5 kohm over the worst chain. It is **included by
   default** in the column deck and moves the bitline term by **+15% at TT,
   +6.6% at SS, +28% at FF**; `NO_RESISTANCE=1` (or
   `gen_col_tb_parasitic.py --no-resistance`) builds the capacitance-only deck
   for comparison. The wordline is not affected: the array straps it to metal
   every 8 columns (33 polycont per row, 8.16 um apart), so only ~1.3 kohm of
   poly is ever in series and its RC is in the tens of picoseconds.
4. **The `index_1` (input slew) axis stops at 0.5 ns.** `run_slew_sweep.sh`
   measures it, but only the front-end term (`t_clk2pre`) depends on the clk0
   edge, so the bitline and back-end terms are reused across the axis and the
   output transition table stays flat along it.

   The axis is measured and monotonic -- it is also nearly flat, and that is a
   property of the macro rather than a gap in the data. `t_clk2pre` over the
   0.05 / 0.2 / 0.5 ns axis, identical in all four macros to within a few ps:

   | corner | 0.05 ns | 0.2 ns | 0.5 ns | spread |
   |---|---|---|---|---|
   | tt | 0.7227 | 0.7406 | 0.7642 | 5.7% |
   | ss | 1.3398 | 1.3555 | 1.4023 | 4.7% |
   | ff | 0.4603 | 0.4679 | 0.4725 | 2.7% |

   A 10x change in the clock edge stretches the front-end term by 5.7% at TT
   -- and `access` by 0.24%, from 17.3084 to 17.3499 ns, because 14.85 ns of
   that sum is a bitline discharge that cannot see clk0 at all. So a consumer
   reading three near-identical rows is seeing the measurement, not a
   placeholder: this macro genuinely does not care how fast its clock arrives.
   (Earlier runs did show a non-monotonic dip at TT; it came from the
   unsettled first cycle in the column deck and is gone since that fix.)

   The axis cannot be raised without first making the front-end measurement
   robust: above ~1 ns the precharge net bumps across VDD/2 before its real
   transition and
   `.measure ... RISE=1 TD=` latches the bump -- at 1.5 ns, TT, wrom0 that put
   `t_clk2pre` (0.1527 ns) *ahead* of `t_clk2int` (0.1544 ns), which is
   impossible since one drives the other through a NAND. `max_transition` on
   the inputs is the top of the axis, so the library never declares a slew it
   was not characterised at.
5. **Input pin capacitances are analytic estimates** from gate widths
   (`PIN_CAP` in `gen_rom_lib.py`), not measurements. `MAX_CAP`, `MIN_CAP` and
   `MAX_TRANSITION` in the same file are fixed constants too -- they are the
   remaining part of the `.lib` that is not read out of a log.
6. **Energy assumes every column discharges every cycle** (all wordlines held
   high), which is pessimistic by roughly 2x against random data.
7. **Periphery leakage is not counted** -- `cell_leakage_power` covers the
   column array only.
8. **One column and one dout bit** are measured and applied to every bit.
9. **The falling-edge arc needs `t_pre_50` from the column deck.** `bus(dout0)`
   carries a `timing_type : falling_edge` group giving the earliest time dout0
   leaves its valid level after clk0 falls (`t_clk2pre + t_pre_50 + t_bl2dout`
   at the smallest load). Against a log that predates `t_pre_50`,
   `regen_rom_libs.sh` warns and leaves that term out -- which makes the arc
   earlier, i.e. safe; re-running `run_col_timing.sh` picks it up.

---

## Power and ground in the `.lib`

The library declares its rails and then actually points at them:

```
voltage_map ( VCCD1, 1.80 )      rail name -> voltage
  pg_pin(vccd1) voltage_name : VCCD1;       pin -> rail
    related_power_pin : vccd1;              signal pin -> pg_pin
    related_pg_pin    : vccd1;              internal_power / leakage -> pg_pin
```

All four links have to exist for a multi-voltage power tool to walk from a
signal pin to its supply. Declaring `voltage_map` and never referencing it is not an error anywhere in
the toolchain: the analysis just comes out unattributed. `tests/check_lib.py` now refuses a reference that
does not resolve, and `tests/test_rom_lib.py` refuses a pin that carries none.

The pin names are read from the LEF (`USE POWER` / `USE GROUND`) rather than
being fixed to `vccd1`/`vssd1`, which would name nets a differently-built
macro does not have. The first power/ground pin in
the LEF becomes the primary rail and any others are written as backup rails.

---

## Validating the output

Without a reader of its own, a syntax error or a table with the wrong number
of rows only surfaces in someone else's tool. `tests/` closes that:

```sh
tests/run_tests.sh
```

Four layers: the checker's own fixtures (11 deliberately broken Liberty files,
so a green run means something), the generic Liberty structure, the ROM
semantics (both `dout0` arcs, the constraints, both power states, FF < TT < SS
ordering), and OpenSTA's own `read_liberty` where it is installed.
`regen_rom_libs.sh` runs the structural pass by itself at the end of every run,
so a file that does not parse never leaves the generator. Details in
[`tests/README.md`](tests/README.md).

---

## `examples/`

`wrom0`..`wrom3`: four ROM macros built on sky130 (1064 words x 32 bit, 134
rows x 256 columns) with all of their characterization logs. Use them to study
the flow without ngspice, or to check a change end to end -- regenerate and
compare against what is committed in `output/`:

```sh
./scripts/rom_char/regen_rom_libs.sh && git diff --stat output/
```
