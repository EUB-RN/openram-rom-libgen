# Where the work stands

Last updated: 2026-09-22. Keep this file current when stopping mid-task.

## Done and verified

* The flow is size independent: macro list, worst column, best column, chain
  length, column count, address/data width are all derived (`rom_paths.py`);
  no hand-kept tables remain. `regen_rom_libs.sh` reads every number from a
  log and names the term when one is missing instead of writing a zero.
* Deliverables go to `output/lib/` and `output/verilog/`.
* `rom_paths.py --check <macro>` pre-flight exists and passes on all four
  macros.
* The array was confirmed to be a NAND chain from the schematic netlist, the
  GDS-extracted netlist and matching LVS device/net counts. `zero_cell` is a
  transistor whose source and drain are shorted by a metal1 strap; that strap
  is the stored bit.
* `bus(dout0)` carries both arcs: `rising_edge` (access) and `falling_edge`
  (the earliest invalidation, `t_clk2pre + t_pre_50 + t_bl2dout` at the
  smallest load). Without the second one STA reads an unlatched ROM as if it
  held its output and reports a false pass. The `t_pre_50` term is present in
  every committed log now, so the arc is complete rather than truncated.
* The power/ground chain is wired end to end: `voltage_map` -> `pg_pin` ->
  `related_power_pin`/`related_ground_pin` -> `related_pg_pin`, with the pin
  names read from the LEF (`USE POWER` / `USE GROUND`) rather than the
  hard-coded pair `vccd1`/`vssd1`.
* `tests/` reads the generated `.lib` back: 15 deliberately broken fixtures,
  the generic Liberty structure, the ROM semantics, and OpenSTA's
  `read_liberty` where a binary is installed. `regen_rom_libs.sh` runs the
  structural pass itself and exits non-zero if it fails. `tests/` is now
  tracked; the OpenSTA step still SKIPs here because no `sta` binary is
  installed.

## The 2026-09-20 re-characterisation: FINISHED

All four macros now carry the same three pieces of work -- wire resistance,
the measured `index_1` (clk0 slew) axis and the early path. Every step of the
run completed on 2026-09-20 (the queue table this file used to carry was
written mid-run and is gone; the outputs are the record).

Verified after the fact:

| check | result |
|---|---|
| settled bitline term in the `.lib` | wrom0 TT `t_dis_50` = 14.8495 ns, `t_dis_50_prev` identical to four decimals |
| periphery energy agrees across macros | TT 6.2507-6.2637 pJ, SS 4.9935-4.9942, FF 7.2561-7.2586 pJ |
| `index_1` measured, not flat | `t_clk2pre` 0.7227..0.7642 ns (wrom0 TT) |
| falling-edge arc complete | 2.4598 ns = 0.7642 + 0.2212 + 1.4744 |
| all four macros pre-flight | "All good -- this macro can go through the flow" |

Bitline term, wire resistance ON, settled (ns):

| macro | worst col | chain | tt | ss | ff |
|---|---|---|---|---|---|
| wrom0 | 236 | 82 | 14.8495 | 36.0231 | 8.2893 |
| wrom1 | 214 | 88 | 15.8106 | 38.3449 | 8.8438 |
| wrom2 | 236 | 91 | 16.1908 | 39.2307 | 9.0273 |
| wrom3 | 10  | 77 | 14.5181 | 35.5082 | 8.0605 |

## 2026-09-22

### The column decoder is now measured -- and it RACES, it does not add

`rom_column_decode` was the last block in the macro the flow never simulated
(README limitation 2). `run_backend_delay.sh` drives the eight column selects
with ideal DC sources, so nothing proved they were where they had to be when
the bitline data arrived; the margin was an estimate.

**What the netlist says.** At the top level of `<macro>.sp`:

    Xrom_column_decoder  addr0[0] addr0[1] addr0[2]
    +  word_sel_0 .. word_sel_7  precharge precharge  vccd1 vssd1

Its `clk` and its `precharge` port are **both** tied to the internal precharge
net -- the same net `t_dis_50` triggers off. So the column decoder does not sit
in series with the bitline: the two start on the same edge and race, and the
middle term of access is `max(t_dis_50, t_coldec)`, not a sum. That is why the
block never appeared in the access budget in the first place, and it is now
written down instead of assumed.

**How it is measured.** `gen_periphery_power_tb.py --with-coldec` keeps
`rom_column_decode` alongside the control logic and the row decoder, so the
decoder sees the precharge edge the real precharge driver produces rather than
a synthetic ramp. The column mux is deleted like every other block but its
gate load is put back by the same slice-x-count rule the cell array uses: 32
pass transistors per select plus 44-79 fF of wire. `run_coldec_delay.sh`
sweeps the column address and summarises the race.

**Polarity, measured and not assumed.** The opposite of the row decoder:
`rom_column_decode_wordline_buffer` inverts the precharged decode array, so all
eight selects are LOW during precharge (the mux is off, the 32 outputs float)
and only the selected one rises during evaluate. The seven unselected ones
report "failed" in the log, and that failure is the evidence.

**Result.** wrom0, TT, all eight addresses -- exactly one select rises each
time, `addr k -> sel_k`, and the spread tracks the select wire load (79 fF on
sel_0 down to 44 fF on sel_7):

| addr | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|---|
| t_pre2sel (ns) | 0.5753 | 0.5517 | 0.5497 | 0.5149 | 0.5426 | 0.5132 | 0.5205 | 0.4454 |

Address 0 is therefore the worst select, and that is the one run on every
macro and corner:

| macro | corner | t_pre2sel | t_dis_50 | margin |
|---|---|---|---|---|
| wrom0 | tt | 0.5753 | 14.8495 | 25.8x |
| wrom0 | ss | 1.1297 | 36.0231 | 31.9x |
| wrom0 | ff | 0.3546 |  8.2893 | 23.4x |
| wrom1 | tt | 0.5753 | 15.8106 | 27.5x |
| wrom1 | ss | 1.1301 | 38.3449 | 33.9x |
| wrom1 | ff | 0.3546 |  8.8438 | 24.9x |
| wrom2 | tt | 0.5753 | 16.1908 | 28.1x |
| wrom2 | ss | 1.1297 | 39.2307 | 34.7x |
| wrom2 | ff | 0.3546 |  9.0273 | 25.5x |
| wrom3 | tt | 0.5753 | 14.5181 | 25.2x |
| wrom3 | ss | 1.1297 | 35.5082 | 31.4x |
| wrom3 | ff | 0.3546 |  8.0605 | 22.7x |

`t_pre2sel` is identical across the four macros to four digits, which is the
expected answer and a check in itself: the periphery is the same circuit in
all of them, exactly as the periphery energy is. The cross-check that the
added block did not disturb the path it hangs off: this deck reports
`t_clk2pre` = 0.7630 ns against the 0.7642 ns of the committed
`periph_active_tt.log`, 0.2% apart.

The decoder loses the race by 23-35x everywhere, so **access is unchanged**.
All twelve `.lib` files were regenerated and each gained exactly seven lines --
the header block recording the margin -- and nothing else. `gen_rom_lib.py`
now takes `--t-coldec` and will switch the middle term to the decoder if a
future macro ever flips the race; `run_coldec_delay.sh` exits non-zero and
says so in that case, and a `.lib` built without the logs states outright that
the block was never simulated instead of staying silent.

**Two things had to be fixed to get here**, both worth knowing:

* `gen_periphery_power_tb.py`'s load reconstruction only descended into
  *sub-circuits*. The cell array wraps its transistors in `rom_base_one_cell`
  (named G/S/D ports), but the column mux instantiates the PDK model directly
  (`X0 bl_out sel bl gnd sky130_fd_pr__nfet_01v8 w=2.88u ...`), and those lines
  were skipped outright. Left as it was, the eight selects would have carried
  nothing but coupling C and the decoder would have come out far too fast.
* The `.ic` list that starts the precharged decoder chain nodes at VDD only
  scanned the row decoder. The column decode array is built from the very same
  `rom_base_one_cell` chain, so it needed the same treatment.

**Cost, and a warning.** Each run holds ~2.6 GB, because this deck keeps the
row decoder in order to get the real precharge edge. `JOBS=12` on a 31 GB
machine drove it into swap and one batch of twelve had not finished in 22
minutes. Budget ~3 GB per job. The full 8 x 3 x 4 sweep is over 9 CPU-hours
and mostly redundant; the two-phase invocation documented at the top of
`run_coldec_delay.sh` gets the same evidence in about half an hour, and is
what produced the tables above.

### Input pin capacitances are measured at last

They were the last purely ANALYTIC numbers in the `.lib` (README limitation
5): `PIN_CAP = {"clk0": 0.0025, "cs0": 0.0030, "_default": 0.0060}`, computed
from gate widths, with ONE value covering all eleven address bits. The
extraction said that could not be right on its face -- the top-level wire C
alone runs from 2.50 fF on `addr0[0]` to 4.92 fF on `addr0[9]`.

They were also wrong by about a factor of two:

| pin | analytic | measured (TT) | error |
|---|---|---|---|
| clk0  | 2.50 fF | 4.89 fF | -96% |
| cs0   | 3.00 fF | 5.67 fF | -90% |
| addr0 | 6.00 fF flat | 6.61 .. 9.49 fF | -58% at the worst bit |

**Method.** `gen_periphery_power_tb.py --pin-cap` keeps every block an input
pin touches -- control logic (`clk0`, `cs0`), row decoder (`addr0[3:]`) and
column decoder (`addr0[0:2]`) -- ramps one pin at a time with the others
parked, and integrates the charge that pin has to supply: `C = Q(VDD)/VDD`,
the same reduction `gen_cell_gate_tb.py` uses for the cell gate. That is the
right reduction for Liberty, whose `capacitance` is a single scalar a driver's
delay calculation multiplies: the shape of the non-linear C-V curve does not
enter, only the total charge does. It also captures what a gate-width formula
structurally cannot -- the pin's wire C, and the Miller charge pushed back
through the first stage as that stage switches.

**Three measurement bugs had to be found first**, all of the kind that returns
a plausible number rather than an error:

1. *Tolerances.* Tightening `abstol` to 1e-15 aborted the deck at t = 5e-14,
   before any pin had moved. It was also pointless: 10 fC over a 1 ns ramp is
   ~10 uA, four orders above the 1e-12 the energy deck uses.
2. *Timestep.* Asking for TR/200 (5 ps) and then TR/50 (20 ps) both collapsed
   at start-up. That argument is the SUGGESTED step; ngspice's LTE control
   refines it through the ramp, which is how the decks next door get
   sub-nanosecond numbers out of a 1 ns step.
3. *The integration window.* Integrating over the ramp alone was not ramp
   independent -- doubling `--pin-tr` moved five of thirteen pins by 10-13%.
   The stage the pin drives goes on switching after the pin has stopped, and
   how much of that tail falls inside the window depends on the ramp time.

Chasing (3) produced the finding that fixed the method. On `clk0` the two
edges TRADED PLACES between ramp times -- rise 4.403 / fall 4.898 at 1 ns
against rise 4.858 / fall 4.464 at 2 ns -- while the SUM held at 9.301 vs
9.322, 0.2% apart. The charge is conserved; only the boundary between the two
windows moves. So the shipped value is now the full cycle,
`C = (|Q_rise| + |Q_fall|) / (2*VDD)`, which is immune to where that boundary
falls, and the rise/fall split is kept as the settling proof: a gap over 5%
means the tail has not died inside the window.

**What is solid and what is not.** Eleven of the thirteen pins reproduce to
0.45% across two ramp times and to four significant figures across all four
macros. `addr0[0]` and `addr0[6]` do not: they move 4-5% with the ramp time,
and they are exactly the two the rise/fall check flags -- 21 flags over the 12
runs, always those two, in every macro and every corner. That is systematic,
not noise, and it is in the README as a known limitation rather than smoothed
over.

**How much the deleted blocks matter -- measured, not argued.** The deck
deletes the cell array and the column mux and puts their load back as lumped
C. Two things bound the error that introduces:

* The pins' top-level wire C does not touch the deleted blocks AT ALL. Of the
  38.32 fF of C elements landing on the thirteen pins, 0.000 fF has its far
  end inside a deleted block, so the alive/dead retarget rule never fires on
  a measured net. There is no wire-C approximation here to be wrong about.
* Doubling the entire array's gate load -- 34048 cells, a 100% perturbation --
  moves twelve of the thirteen pins by less than 0.6%, most by less than 0.3%.
  Since the lumped-C model errs by far less than 100%, its contribution to
  those twelve is bounded well below that. The exception is `addr0[0]` at
  -4.9%, i.e. the load model DOES matter on that pin at the 5% level -- the
  same pin the other two checks flag.

A third, independent sign points the same way: the four macros differ only in
the contents of the array that was deleted, and eleven of thirteen pins agree
to four significant figures across them.

(The first attempt at this experiment was to remove the put-back load
entirely. That deck does not converge at all -- "Timestep too small; initial
timepoint" -- because the wordline drivers are left with essentially no
capacitance against `.ic` nodes that start at VDD. There is no "no load"
reference point to compare against; perturbing the load is the runnable test.)

**In the .lib.** `gen_rom_lib.py --pin-cap` takes `<pin>=<fF>` pairs and
`regen_rom_libs.sh` fills them from `pincap_<corner>.log`. A Liberty bus
carries ONE capacitance on its ranged pin, so `addr0` ships the WORST bit
(0.0095 pF at TT) and the header records the full per-bit spread: telling a
driver it will find less load than it does is the unsafe direction. Without
the logs the `.lib` now says outright that these numbers are analytic instead
of letting a guess pass for a measurement.

### The read back end was missing from the leakage deck

`run_periphery_leak.sh` sliced the control path, the address buffers, the
wordline drivers and both decode arrays -- and stopped there. The macro
instantiates seven blocks at the top level; the deck covered four of them plus
the separately-measured array, so `rom_bitline_inverter` (256 instances),
`rom_column_mux_array` (256) and `rom_output_buffer` (32) were scored as ZERO
in `cell_leakage_power`. Nothing reported this: a slice that is not in the
list simply does not appear in the sum.

**Effect.** The periphery term roughly doubles and the bitline inverters alone
are the largest entry in it -- bigger than the 133 wordline drivers:

| corner | periphery before | after | cell_leakage_power before -> after |
|---|---|---|---|
| tt | 109.66 nA | 203.24 nA | 0.000366 -> 0.000535 mW |
| ss | 329.37 nA | 457.93 nA | 0.000824 -> 0.001029 mW |
| ff |  45.19 nA |  84.02 nA | 0.000164 -> 0.000240 mW |

**The idle state of the read path is derived, not chosen.** Every bitline is
high during precharge, so every bitline inverter holds its output at 0; all
eight column selects are low (measured in the column-decode work above), so
each mux transistor is off with its source at 0 and the node it drives leaks
down to 0 too; the output buffer therefore sits with its input at 0. Each of
those levels is driven explicitly in the deck, which is also what keeps `.op`
out of a singular matrix -- the floating-node failure this deck exists to
avoid.

**The mux measures ~0 and that is the answer, not a gap.** Both of its
terminals sit at 0 V in this state, so it passes 5e-19 A. It has no supply of
its own, so what it leaks is read with a 0 V source (an ammeter) on the node
it drives. The convergence rule needed a floor for it: comparing two gmin
points to 1% is meaningless at 1e-19 A, so a slice under 1e-6 nA is reported
as `ZERO (under ... floor)` instead of `NOT CONVERGED`. At that floor even the
256-wide mux array contributes under a pA.

**cs0 still makes no difference -- now that is a measurement.** With every
block in the deck, `cs0` = 0 and `cs0` = 1 agree to six decimals at all three
corners on all four macros (tt 203.236507 vs 203.236611 nA). cs0 gates the
precharge PATH: it changes what the macro does on a clock edge, not the static
state it sits in between edges, and leakage describes the latter. The two
`leakage_power` groups stay in the `.lib` with their `when` conditions and the
header now says outright that they were both run and came out equal, rather
than leaving a reader to wonder which one was copied.

Full sweep: 4 macros x 3 corners x 2 cs0 states x 4 gmin points, ~80 s per
state, no slice `NOT CONVERGED`. All twelve `.lib` files regenerated; the test
suite passes.

### The golden reference: STARTED, KILLED, NOT FINISHED -- pick this up first

**This is the one open thread. Everything else below is done.**

Why it exists: every check on the pin capacitances above -- ramp independence,
agreement across the four macros, insensitivity to a 2x change in the array
load, the corner ordering -- is a SELF-CONSISTENCY check. Each bounds how far
the answer moves when a knob moves, and all of them are structurally blind to
an error that every variant shares. The reduced deck deletes the cell array
and the column mux and puts their load back as lumped C; nothing above can
tell you what that reduction COST.

`gen_periphery_power_tb.py --pin-cap --keep-all` deletes nothing. The deck
goes from 2777 to 37883 device lines and from 19457 to 167539 capacitors --
the whole 34305-cell array is in it -- so there is no reduction left to be
wrong about, and the gap between it and the reduced deck IS the cost.

**What happened (2026-09-22).** wrom0, TT, three pins
(`clk0`, `addr0[0]`, `addr0[9]`). It ran for **2h37m at 100% CPU** and reached
**16.4 GB RSS**, which was 63% of a 31 GB machine and had pushed it 3 GB into
swap. It was still progressing -- CPU time tracked elapsed time exactly, so it
was computing, not stalled -- but `ngspice -b` prints no progress, so there was
no way to tell whether an hour or ten hours remained. It was killed to give the
machine back. **No result.**

**To resume:**

    GOLDEN_PINS="addr0[9]" JOBS=1 scripts/rom_char/run_pin_cap.sh wrom0

One pin instead of three cuts the transient from 126 ns to about 42 ns -- the
run time is set by the pin count, each pin getting its own slot -- so expect
roughly a third of 2h37m. Memory will NOT shrink with the pin count: it is set
by the circuit, so budget ~17 GB and run nothing else. `addr0[9]` gives the
TYPICAL reduction error; `addr0[0]` gives the WORST, since it is the pin the
settling check flags, the pin that moves 4-5% with the ramp time, and the pin
that moved -4.9% when the array load was doubled. Do `addr0[9]` first: if the
typical error is large, the worst one hardly matters.

Consider giving it a longer ramp as well. At `PIN_TR=2n` the transient doubles
but the timestep doubles with it, so the step COUNT is unchanged -- and the
reduced deck is known to be ramp independent on `addr0[9]`, so a 2 ns golden
run stays comparable.

**The infrastructure is in place and waiting for the log**, so resuming costs
one command and nothing else:

* `run_pin_cap.sh` runs it when `GOLDEN_PINS` is set (off by default), writes
  `pincap_golden_<corner>.{sp,log}`, and prints a reduced-vs-golden table.
* `tests/test_pin_cap.py` is the 5th layer of `tests/run_tests.sh`. It matches
  the two logs BY PIN NAME through their `*PINCAP` markers -- the golden run
  measures a subset and so has its own index numbering; matching by index
  would silently compare the wrong pins. Right now it prints a SKIP saying how
  to produce the reference.
* Both WARN outside `GOLDEN_BAND` (default 10%) and neither fails. The band is
  set from both sides: below ~5% it would fire on `addr0[0]` and `addr0[6]`,
  whose few-percent ramp sensitivity is already documented; a real reduction
  error is not a few percent, since the analytic estimate this work replaced
  was off by 58-96%. Revisit the band once there is a real number to set it
  against.

**What we have without it**, and what it is worth: an independent hand
calculation from OUTSIDE the simulation entirely -- Magic's extracted wire C
plus the PDK's `Cox*W*L` over the first-stage gate area:

| group | measured / hand calculation |
|---|---|
| the 11 address pins | 0.94 .. 0.99x |
| clk0, cs0 | 1.35 .. 1.50x |

The address pins landing just BELOW the hand figure is the right sign: a gate
is not at full inversion-Cox across a 0 -> VDD swing, it passes through
accumulation and depletion, so a charge-based measurement should come in under
`W*L*Cox`. clk0 and cs0 landing above is also expected -- their first stage is
a large driver into a heavy load and the hand calculation has no Miller term.
That bounds the magnitude and it is genuinely independent, but it does not
test the DELETION, which is what the golden run is for.

### `examples/` cleaned out: 752 MB -> 383 MB

(427 MB as it stands, the difference being the 20 new column-decode decks and
logs added below -- extracted decks, the same size class as `periph_*`.)

* **The dead column decks are gone** (the 2026-09-20 audit's item 7): 72 files,
  31 MB, for a worst column the flow stopped using -- `wrom0/col54_*`,
  `wrom1/col1_*`, `wrom2/col42_*`, `wrom3/col9_*`. Nothing read them and
  `ls | tail -1` picked the stale one. Each macro now carries exactly two
  column prefixes, the worst and the best.
* **Magic extraction intermediates (`*.ext`, 178 MB, 188 files)** and
  **netgen's machine-readable LVS dump (`*.lvs.json`, 191 MB)** are deleted and
  `.gitignore`d. No script reads either: `run_ext.sh` / `run_cap_extract.sh`
  rebuild the `.ext` from `<macro>.gds` and the flow only ever consumes
  `<macro>_cap_only.spice`, while the human-readable LVS verdict stays in
  `<macro>.lvs.report.gz` and `<macro>_lvs.log`. The four
  `<macro>_rom_base_array.ext` files alone were 142 MB.
* `rom_paths.py --check` still passes on all four macros afterwards, and the
  test suite still passes.

Note that these were already committed once, so the repository *history* is
not smaller -- only the working tree is, and only new clones of a future
history-rewritten repo would see the saving.

## Findings from the 2026-09-20 audit: what is closed and what is not

### CLOSED

**1. The bitline term was measured on an UNSETTLED first cycle.** Fixed
2026-09-20 and verified above. `gen_col_tb_parasitic.py` runs three cycles at
`TCLK=2u` (a 1 us precharge phase, the saturated idle-then-read case) and
measures the third with `TD` windows; it also emits `t_dis_50_prev` and
refuses to call the run settled if the two differ by more than 1%. The deck
previously could not tell a settled answer from a startup transient, which is
how the defect survived.

The direction mattered twice over. For `access` the artefact was conservative,
so the shipped library was merely loose (wrom0 TT 16.5035 against 14.8495 ns).
For `retain_rise`/`retain_fall` it pointed the WRONG way: retain is an EARLY
bound, and an unphysically slow discharge makes the output look like it holds
its previous value longer than it does -- exactly the direction that lets a
hold violation pass.

The physics behind it is worth keeping. With `.ic` on the bitline only, the 82
internal chain nodes start at 0 V under `uic` and jump within picoseconds to a
capacitive-divider level; cycle 1 is nearly flat while the settled state is a
gradient built by conduction through the chain. Proof that cycle 1 is not a
conduction state at all: it came out identical (16.5034/16.5035 ns) whether the
first precharge phase lasted 25 ns or 100 ns. And the settled value itself
depends on the precharge phase length, monotonic and saturating -- 6.96 ns at
25 ns of precharge up to 14.85 ns at 1 us -- because those nodes never reach
VDD. The worst case is therefore the LONGEST precharge: a ROM idle with clk0
parked low, whose chain has filled asymptotically, whose next read is the
slowest read the macro can perform. That is a real operating condition and it
is the one the `.lib` covers.

**2. The committed periphery energy logs predated the `method=gear` fix.**
Re-run and verified: all four macros now agree at every corner (table above).
The symptom was visible without knowing the cause -- the periphery is the same
circuit in all four macros, yet TT read 4.56 / 5.19 / 6.38 / 7.44 pJ.

**7. Dead files from an older worst-column choice.** Deleted today, see above.

**3. The column energy deck never got the `method=gear` fix.** FIXED.
`gen_col_power_tb.py` now writes an `.options` line in the energy branch too
(`gmin=1e-12 abstol=1e-12 reltol=1e-3 itl1=500 itl4=100 method=gear`), and
`--steps` / `--integrator` were added so the sweep that proves it can be
re-run. Re-measured on wrom0 column 236 at TT over 200/400/800/1600 steps:
trapezoidal 0.4956 / 0.4823 / 0.4849 / 0.4917 pJ (2.8%, not monotonic)
against gear 0.4805 / 0.4851 / 0.4858 / 0.4860 pJ (monotonic, 0.18% from the
second point on). Every macro and corner was re-run and the .lib files
regenerated; the old numbers were off by ~0.6% (up at TT, down at FF).

It also explained a second symptom: the cycle-2/cycle-3 settling gap the
energy deck prints. On trapezoidal wrom0 at TT read -2.757e-13 and -2.679e-13
C, a 2.8% gap that looked like a chain still filling; with gear the two agree
to five digits and the whole summary column now reads 0.0-0.6%. The gap was
the integrator, not the circuit.

**8. `gen_macro_behavioral_v.py` parses the `.lib` header comment.** FIXED.
`access` now comes from the DATA -- the largest entry of the `cell_rise`
table on the `rising_edge` arc of `dout0`, which is what the access time is.
The banner line is still read, but only as a cross-check: if it disagrees
with the table the script says so and uses the table, and if the banner is
reworded or dropped nothing changes (verified by rewording it in a copy of
`wrom0_SS_1p6V_100C.lib` -- same 39.3694 ns out). The regenerated `.v` files
carry the same numbers as before.

**9. Leftover Turkish comments** in `gen_rom_lib.py` and
`gen_periphery_power_tb.py`. Gone. The first pass only caught the ones with
non-ASCII characters, so six ASCII-only Turkish lines survived it (`olculen
buyuklukler`, `degerlendirme + pay`, `On-sarjli dizi ...`, `olculecek clk0
yukselen kenari` and two more); they were translated 2026-09-22. The check
that holds now is a word scan, not a character scan -- `grep -P "[^\x00-\x7F]"`
comes back clean either way and proves nothing.

### STILL OPEN

**2b. Nothing gates on the settling check.** `run_periphery_power.sh` prints
the last-two-cycle gap in a summary table and that is all. It stood at 24-40%
on the bad TT runs and nobody acted on it. It should fail the run, or at least
be re-read by `regen_rom_libs.sh` before the number is used. (The column deck
got exactly this treatment in the item-1 fix; the periphery deck did not.)

### NOT DEFECTS -- measurement artefacts that are understood

**4. `t_bl2dout` comes out SMALLER at SS than at TT** (wrom0: 1.4714 tt /
1.1835 ss / 1.3395 ff; wrom3: 1.2786 / 0.2842 / 1.3093). The back-end deck
drives the bitline with a ramp whose slope is that corner's own measured
`t_dis_50`/`t_dis_10`, and the delay is counted from the input crossing VDD/2.
At SS that ramp is several times slower, so the bitline inverter reaches its
own trip point *before* the input reaches VDD/2 and the term shrinks. The SUM
stays ordered, so `access` is right; it is the term-by-term comparison across
corners that is meaningless. The output slew the same deck reports at SS
(2.3-3.1 ns against 0.5-0.8 at TT) has the same origin, and that one does land
in the `.lib` as a declared transition time.

**5. `t_pre_99` is not ordered across corners either** (wrom1: tt 11.31, ss
10.32, ff 9.76 ns). The 99% target scales with the corner's VDD (1.782 V at TT
against 1.584 V at SS) and the last percent of an asymptotic recharge is what
decides it. It feeds `min_pulse_width(fall)`, so it is not wrong, but a
cross-corner comparison needs a fixed absolute threshold to mean anything.

**6. The `index_1` axis is nearly flat, and not monotonic at TT.** wrom0
`t_clk2pre` against the 0.05 / 0.2 / 0.5 ns slew axis: tt 0.7616 / 0.7594 /
0.8118 (6.9%, dips in the middle), ss 1.3801 / 1.4206 / 1.4668 (6.3%), ff
0.4772 / 0.4956 / 0.5102 (6.9%). `run_slew_sweep.sh`'s own closing note says a
spread near zero would be worth understanding before the axis is trusted;
6.9% with a dip at TT is close to that regime.

**1b. The read-1 case is never simulated -- checked by hand, it is fine.** The
column deck holds every wordline at DC VDD, so it only ever simulates a read
of 0. Measured by hand on wrom0 column 236 at TT, with one wordline pulsed low
during evaluate: with the selected row at the BOTTOM (81 conducting cells
hanging on the bitline) v(bl) is 1.8415 V at 20 ns, 1.8230 V at 200 ns, and
never falls below 1.7336 V over a 1 us evaluate; the bitline inverter never
leaves 0 V. Each pass transistor cuts itself off once its node is within a Vth
of the bitline, so the chain cannot drag the bitline to its own level, and the
41 kohm of chain resistance makes the redistribution far slower than the
access time. The partially charged chain costs SPEED on a read of 0, not LEVEL
on a read of 1. Still unmeasured: neighbour-column coupling (the column deck
does not carry it at all -- limitation 1) and the address dependence itself,
now known to be worth about 70 mV and not characterised per macro.

## Other known gaps

Listed in README.md under "Known limitations". The biggest one by far is now
item 1: **array-level parasitics missing from the column deck** (+3 fF against
the ~5 fF the deck carries, on the largest term of `access`). The back-end and
periphery decks already have the alive/dead + negative-net-capacitance rule
that fixes it; porting it into `gen_col_tb_parasitic.py` is the obvious next
piece of work.

The rest: the ~5% of ramp-time sensitivity left on `addr0[0]` and
`addr0[6]` after the pin-cap work, energy assuming every column
discharges, one column/one bit generalised, and the `index_1` axis stopping at
0.5 ns. Periphery leakage IS counted now (`run_periphery_leak.sh`: one slice
per block x a count, gmin-swept, `.op` in the idle state) and the slice list
covers every block the top-level cell instantiates since the read back end was
added -- it roughly TRIPLES `cell_leakage_power` (0.000169 -> 0.000535 mW at
TT). What is left open there is that only the idle state (clk0 low) is
characterised; the evaluate phase, with one wordline low and the chain feet
conducting, is not.

## Housekeeping

The cleanup, the re-characterisation and the column-decode work are committed
(4b1cb95..156b342 on main). `main` is ahead of `origin/main` and has not been
pushed.

Uncommitted:

* the periphery-leakage work (`run_periphery_leak.sh`, `periph_leak_*`, the
  `--leakage-idle-mw` path in `regen_rom_libs.sh` and `common.sh`) -- a
  separate line of work, left for its own commit
* `docs/img/*` (diagrams, not yet referenced from the README)

WHERE TO PICK UP: the golden reference, above. It is the only thing started
and not finished; one command resumes it and the test layer is already waiting
for its log.
