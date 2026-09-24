# Where the work stands

Last updated: 2026-09-24. Keep this file current when stopping mid-task.

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
(limitations.md item 2). `run_backend_delay.sh` drives the eight column selects
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

They were the last purely ANALYTIC numbers in the `.lib` (limitations.md item
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
not noise, and it is in docs/limitations.md as a known limitation rather than smoothed
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

### The golden reference: REMOVED -- it does not scale with the ROM

**It was started, it was killed, and it is now gone from the tree.** The pin
capacitance MEASUREMENT is untouched: every pin, every corner, the reduced
deck, the numbers in the shipped `.lib`. What was removed is only the
whole-macro reference run the reduced deck used to be compared against.

What it was: `gen_periphery_power_tb.py --pin-cap --keep-all` deleted nothing.
The deck went from 2777 to 37883 device lines and from 19457 to 167539
capacitors -- the whole 34305-cell array in it -- so there was no reduction
left to be wrong about, and the gap between it and the reduced deck WAS the
cost of the reduction.

**Why it is gone.** On 2026-09-22 it was run on wrom0, TT, three pins
(`clk0`, `addr0[0]`, `addr0[9]`). It ran **2h37m at 100% CPU** and reached
**16.4 GB RSS** -- 63% of a 31 GB machine, 3 GB into swap. It was still
progressing (CPU time tracked elapsed time exactly), but `ngspice -b` prints
no progress, so there was no way to tell whether an hour or ten remained. It
was killed. No result.

Cutting it to one pin would have cut the run time by about a third and the
memory not at all, and that is the point: **wrom0 is a 1 kbit example**, the
smallest thing this generator ever builds. The cell array is the one block
whose size the USER picks. A reference whose cost follows the array is not a
reference for a generator -- on a real ROM the deck does not run slowly, it
dies, and a check that only works on the smallest possible macro cannot sit in
the flow. So `--keep-all`, `--pin-only`'s reference role, `GOLDEN_PINS`,
`GOLDEN_BAND` and `tests/test_pin_cap.py` (the old 5th test layer) were all
removed rather than left as a knob nobody can afford to turn.

**What this costs us, stated plainly.** Every remaining check on the pin
capacitances -- ramp independence, rise vs fall, agreement across the four
macros, the corner ordering -- runs the same reduced deck, so all of them are
structurally blind to an error the reduction makes in every variant at once.
That error is now BOUNDED rather than measured, from two directions:

* **the array-load sensitivity**: doubling the lumped load the deleted array
  is replaced by moves `addr0[0]` by -4.9% and every other pin by under 0.6%.
* **an independent hand calculation** from outside the simulation entirely --
  Magic's extracted wire C plus the PDK's `Cox*W*L` over the first-stage gate
  area:

| group | measured / hand calculation |
|---|---|
| the 11 address pins | 0.94 .. 0.99x |
| clk0, cs0 | 1.35 .. 1.50x |

The address pins landing just BELOW the hand figure is the right sign: a gate
is not at full inversion-Cox across a 0 -> VDD swing, it passes through
accumulation and depletion, so a charge-based measurement should come in under
`W*L*Cox`. clk0 and cs0 landing above is also expected -- their first stage is
a large driver into a heavy load and the hand calculation has no Miller term.
That bounds the magnitude and it is genuinely independent; what it does not do
is test the DELETION. Nothing runnable does, and `docs/limitations.md` item 5
says so instead of promising a check that cannot be paid for.

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
  `.gitignore`d. No script reads either: `run_cap_extract.sh`
  rebuilds the `.ext` from `<macro>.gds` and the flow only ever consumes
  `<macro>_cap_only.spice`, while the human-readable LVS verdict stays in
  `<macro>.lvs.report.gz` and `<macro>_lvs.log`. The four
  `<macro>_rom_base_array.ext` files alone were 142 MB.
* `rom_paths.py --check` still passes on all four macros afterwards, and the
  test suite still passes.

Note that these were already committed once, so the repository *history* is
not smaller -- only the working tree is, and only new clones of a future
history-rewritten repo would see the saving.

## 2026-09-23

### Hold reaches the behavioural Verilog

The generated `<macro>.v` carried `SETUP_NS` and reported setup violations,
but had no hold parameter at all -- it was checking the 0.03 ns constraint and
saying nothing about the 15 ns one. What it did have was an unconditional
"addr0 changed DURING evaluate" error covering the WHOLE evaluate phase: the
old `hold = access` model, correct while hold was a declaration and wrong once
it became a measurement.

**Now.** `read_lib_timing` pulls a hold per pin GROUP -- the first
`hold_rising` inside `bus(addr0)` and the first inside `pin(cs0)` -- so the
model cannot flatten the two back together, and the .v carries `HOLD_NS` and
`HOLD_CS_NS` separately. On wrom0 at TT: 15.2382 and 17.3271 ns. (The shipped
models are built from SS, where no hold has been measured yet, so both are
still the access window there.) A `.lib` with no `hold_rising` falls back to
the full access window -- the pessimistic direction -- with a warning, rather
than skipping the macro.

**The behaviour, not just the parameter -- and it took two passes.** The first
version fired only inside the window and did nothing at all after it. That is
wrong, and the way it is wrong is worth recording: "the read in flight
survives a late address change" and "the phase survives it" are DIFFERENT
claims, and the hold measurement only establishes the first. Past `HOLD_NS`
the bitline is through the inverter's trip point, so the read already on its
way lands -- but the newly selected row's zeros start discharging their
bitlines the moment the address moves, and outside precharge there is no
pull-up anywhere in the array to undo that. dout0 stays correct for about one
more access time and then becomes the AND, if the evaluate phase is still
open. Ignoring the late change would call the data good for an arbitrarily
long high phase, which the silicon does not.

So the model now carries three behaviours: corruption inside the window
(immediate, the read never becomes valid), survival immediately after it, and
DELAYED corruption once the new row has had a discharge time. The delay used
is `ACCESS_NS`; the true path is `addr0 -> wordline -> bitline -> dout0`,
slightly longer than access, so the model corrupts slightly early -- the safe
direction. A stated simplification: every address bit is treated as a ROW bit,
while the low bits drive the column mux and a column-only change re-routes
dout0 to other bitlines of the same row (different data, not corrupt data, in
a mux delay rather than a discharge time). Modelling that as the AND is
pessimistic, which is the direction to be wrong in.

cs0 gets its own message on deselection inside `HOLD_CS_NS`, separate from the
evaluate-too-short one, because the cause is a constraint on cs0 rather than a
clock waveform.

**Both halves are simulated, and both were proved able to fail.**
`tests/test_verilog_model.py` gained two cases that run under iverilog: an
address change at HOLD/2 must corrupt the read to the bit-wise AND of the two
rows (0x12345678 & 0xA5A5A5A5 = 0x00240420, since the array has no pull-up
outside precharge and a second row can only discharge more bits), and the same
change after the window must do nothing. Mutation-tested rather than assumed:

| mutation | which case caught it |
|---|---|
| ignore the late change (the first version of this fix) | "late change never corrupted dout0" |
| remove the window gate (restore `hold = access`) | "destroyed the read in flight" |
| remove the in-window corruption | "did not corrupt the read" |

Three behaviours, three mutations, three different assertions firing -- none of
them is decorative.

A latent crash turned up while testing this: `read_lib_timing` had an early
`return None, None, None` for a missing .lib, which stopped unpacking once the
function returned five values. It only fires when the .lib is absent, which is
why the normal run never hit it.

### B3: the silent 3 ns hold fallback -- why it existed, and why nothing caught it

`hold` starts as `BASE["hold"] = 3.00` ns, the analytic guess from before
anything in `gen_rom_lib.py` was measured, and every key of `BASE` is turned
into a CLI option with that default. Two separate mistakes then kept it alive
and invisible, and they were the SAME mistake twice:

* **The override was anchored to the wrong quantity.** The rule that replaces
  the guess is `hold = access_eff`, and `access_eff` cannot be formed without
  the back-end load sweep -- so the override is guarded by `if be:`. The
  question "do I know the hold?" was being answered by "do I have the back-end
  sweep?", which is a different question with the same answer most of the time.
* **So was its disclosure.** The entire hold paragraph in the `.lib` header
  sits inside that same `if be:` block. The one branch where hold is a guess
  is exactly the branch where the text that would say so is skipped. The
  `else` branch warns about *access* being incomplete and says nothing about
  hold. Fallback and warning were hung off one condition and cancelled.

Without `--measured` the guess is also derated, so at SS it ships as
3.00 x 1.50 = 4.50 ns -- against a real requirement of ~39 ns. A hold that is
too short is the unsafe direction: STA passes a design that loses its read.

**Why it never bit.** `regen_rom_libs.sh` lists `be` among the terms whose
absence skips the macro entirely, so the sign-off flow cannot reach the
fallback. Only a call by hand can -- and the script's own docstring shows such
calls as examples.

**Fixed.** A `hold_is_analytic` flag anchored to hold itself, set false by
either path that establishes a real value (`hold = access_eff`, or
`--hold-measured`). When it survives, the `.lib` carries a warning block
written OUTSIDE the `if be:` guard -- the branch that needs it -- and the
script prints one on stderr as well. Verified on both fallback paths:
3.0000 ns under `--measured`, 4.5000 ns without it, each announced in both
places. The normal flow prints nothing, and the test suite passes.

Not made fatal: the by-hand call is a documented use and the file now states
loudly what it is. The flow that matters already refuses.

### cs0 is pinned to the capture edge, not to a duration

Following the hold split, one question survived: is `hold_rising` = access
(17.3271 ns) actually enough for cs0? It is not, and the reason is a category
error rather than a number being too small.

dout0 becomes valid AT access and is captured on clk0's FALL -- this macro has
no latch, so the high phase is the entire life of the read. `min_pulse_width`
puts the earliest legal falling edge at 17.8271 ns. A cs0 released at 17.3271
therefore satisfies the constraint exactly as written and still re-opens the
precharge PMOS half a nanosecond before the data is taken. Worse, the gap is
not fixed: drive the macro with a slower clock, which is legal, and the
requirement grows with the period while the constant does not. **No value of
hold_rising can express this**, `pw_high` included.

The requirement is not a duration, it is an EVENT: cs0 must reach the falling
edge. Liberty writes that as a hold against that edge, so every control pin
now carries `hold_falling` = 0 alongside its `hold_rising`. Zero is exact --
the capture is ON the edge -- and it holds for any clock period. Both arcs are
kept: each is independently true, and a tool that only reads hold_rising still
gets a meaningful number rather than nothing. It also keeps the analytic
0.5 ns margin inside `pw_high` out of a constraint, which taking pw_high as
the hold would not have.

`check_lib.py` already allowed `hold_falling` and its duplicate-arc rule keys
on (timing_type, related_pin), so the two coexist. `tests/test_rom_lib.py`
now fails a `.lib` whose cs0 lacks the arc -- verified by deleting it from a
copy. The behavioural Verilog follows the same logic: its cs0 check is no
longer "deselected within HOLD_CS_NS" but "deselected while the phase is
open", because that is the real deadline.

**Why this mattered enough to chase.** The macro's user has no way to know
this from the pinout, and before the arc existed the STA tool had no way to
know it either. A cs0 pulled at the wrong moment produced a silent wrong read
that every check in the flow would have passed.

### Simulation failures are no longer swallowed

Every deck in the flow was run as

    $NG -b -o "$log" "$deck" >/dev/null 2>&1 || true

in the background as often as not -- 20 call sites. That throws away the
exit status AND the diagnostics. A deck that died left no message, no
non-zero exit and often no usable log, and the failure surfaced much later
as a missing `.measure`, or not at all: several `.lib` terms have a
documented fallback for "the log is not there", and a fallback is
indistinguishable from a run that never happened.

**THE EXIT CODE ALONE DOES NOT CATCH IT.** Measured on ngspice 11 rather
than assumed:

| deck | exit | log |
|---|---|---|
| unknown subckt | 1 | "Simulation interrupted due to error!" |
| `.measure` on a node that does not exist, no circuit | **0** | "Error: no such vector as ..." |
| empty netlist | 1 | "Error: incomplete or empty netlist" |

The middle row is the dangerous one: ngspice reports success while the
measurement it was asked for never happened. So `run_ng` judges a run by
its status AND by its log.

**The fatal list is calibrated, not guessed.** Scanning all 311 committed
logs: each of the thirteen patterns appears in ZERO of them, while
`Error: measure` and `failed!` appear in 93 and are EXPECTED -- an
unselected wordline has no edge to measure, and the flow reads those
failures as evidence. So the list separates a dead run from a healthy one
with no false positive on the existing corpus.

**What a failure now prints:** the STAGE that died, the macro/corner
context, ngspice's own verdict, the root-cause line (the fatal signature is
often ngspice's last word rather than its first -- "fatal error in ngspice,
exit(1)" after "Could not find library file ..."), the exit code, and the
paths to the deck and log, both kept for inspection.

    !! FAILED stage=cell-gate-cap [wrom0 tt]
       reason : ERROR: fatal error in ngspice, exit(1)
       cause  : Error: Could not find library file /nonexistent/sky130.lib.spice
       exit   : 1
       deck   : examples/wrom0/char/cellgate_tt.sp
       log    : /tmp/cg.log

Backgrounded jobs report through a per-shell ledger file, since a subshell
cannot set a variable in its parent. Every `run_*.sh` calls `ng_reset` at
the start and `ng_summary` at the end, so the script exits non-zero and
names every stage whose numbers are missing from the output.

**Guarded two ways.** `tests/test_error_reporting.py` is a new suite layer:
behaviourally it pins all four cases (exit non-zero, exit ZERO with a fatal
log, healthy, and an EXPECTED `.measure` failure that must NOT be fatal),
and statically it fails if any script in `scripts/rom_char/` calls `$NG`
directly again. The static half earned its place immediately -- it found
two call sites a grep for `|| true` had missed, because they swallowed with
`&` and with `|| { ... }` instead.

Verified end to end on the real flow: `run_col_power.sh` is unchanged on a
healthy run, and with a sabotaged deck it reports the stage, keeps the
artefacts and exits 1.

### Hold is now in Liberty's time frame, and cs0's setup is bounded

Two loose ends from the hold work, both closed by measuring rather than
arguing.

**B2: the hold was in the wrong frame.** `run_hold_bisect.sh` answers the
right physical question but in the COLUMN deck's frame -- that deck is driven
by a synthetic `precharge` source and has no `clk0` in it at all, so its cut
time is counted from the internal evaluate edge. Liberty's `hold_rising` is
referenced to the `clk0` PIN. Two delays separate them:

    hold(clk0) = t_clk2pre + cut - t_addr2wl

`t_clk2pre` was already measured. `t_addr2wl` -- the address reaching the
wordline it drops -- was not, and could not be: every existing deck switches
the address during PRECHARGE, when the clocked decoder is opaque and no
wordline moves.

**How it is measured now.** `gen_periphery_power_tb.py --addr-sw-eval`
switches the address in the middle of EVALUATE, when the decoder is
transparent, so the newly selected row's wordline actually falls, and
`t_addr2wl<k>` times it. The bit to switch is derived, not fixed:
`addr0[0 .. log2(words_per_row)-1]` drive the COLUMN mux and toggling one of
those moves no wordline at all, so the first ROW bit is
`log2(G_WORDS_PER_ROW)` (3 on the example macros) and address 0 -> 2^3 moves
the selection from row 0 to row 1. `run_addr2wl.sh` drives it.

**Result, wrom0 at TT.** Exactly one probed wordline falls -- `wl_1`, the row
the new address selects -- and the other seven report "failed", which is the
same evidence the polarity block relies on:

| term | ns |
|---|---|
| cut time, from the internal evaluate edge | 15.6615 |
| + `t_clk2pre` | 0.7642 |
| - `t_addr2wl1` | 1.1875 |
| **= hold at the clk0 pin** | **15.2382** |

So the raw cut time that shipped was **0.42 ns optimistic**. The two
corrections nearly cancel, which is exactly what made this easy to miss --
and a coincidence, not a reason. `gen_rom_lib.py` does the conversion, writes
it out term by term in the header, warns and ships 0 rather than a negative
hold if it ever inverts, and says outright that the number is in the deck's
frame when the `addr2wl` log is absent. `t_clk2pre` is taken at the LARGEST
point of the slew axis, which lengthens the converted hold, i.e. tightens it.

A cross-check came free: the same deck reports `t_addr2dec7` = 0.0306 ns
against the 0.0307 ns of the committed setup log, measured at a completely
different instant in the cycle.

**cs0's setup: bounded by the netlist, not left unknown.** `cs0` was given the
address's setup although its own path had never been measured. It turns out
there is nothing to measure: `cs0` goes straight to the A gate of
`rom_control_nand` with no stage in between, and the extraction keeps it as a
single node, so the pin and the gate are electrically the same point.

What the constraint really is, is a RACE, and both halves of it are already
measured. Both the decoder NAND and the control NAND are clocked by
`clk_int`:

| path | ns |
|---|---|
| addr0 -> the clocked decoder NAND | 0.0307 |
| clk0 -> the same gate (`t_clk2int`) | 0.3255 |
| requirement at the pin | **-0.2948** |

The setup is NEGATIVE: the address may arrive after clk0 rises and still be in
time. The library keeps shipping the positive path delay -- it is the
conservative of the two, and relaxing a constraint as a side effect of
changing what is being counted is the mistake this whole line of work exists
to avoid -- but the header now states both numbers. And cs0 is covered: its
path lacks the inverter the address path has, so its requirement is strictly
the smaller of the two. That is a proof, not a deferral.

### `t_clk2wl*` was measuring the wrong half of the cycle -- removed, not repaired

A tooling bug, not a modelling one, and it had propagated into the docs.

**What was wrong.** `gen_periphery_power_tb.py` opened the front-end TARG
window at `_edge = (cycles-2)*TCLK`, with the comment calling that "the clk0
rising edge to measure". It is not: `Vclk` is `PULSE(... TD={TCLK/2} ...)`, so
clk0 RISES at `TCLK/2 + k*TCLK` and `_edge` is the start of a PRECHARGE phase,
half a cycle early. The other users of `_edge` in the same file (the evaluate
window, the address switching instant) read it with the correct meaning; only
the front-end block misread it.

**What it produced.** `t_clk2wl0 = -9.927404e-08` -- a delay of minus 99
nanoseconds, the wordline's rise in the phase BEFORE the trigger -- in all
twelve committed periphery logs, every macro and every corner.

**The chain effect, which is the part worth remembering.** A negative delay is
impossible and should have ended the matter on sight. Instead the sign was
read as speed, and `regen_rom_libs.sh` carried the conclusion in a comment:
"cross-checked against the wordline path with t_clk2wl0: in all three corners
the wordline is FASTER than the precharge path, so precharge is the critical
one." The sound measurement in the same log says the opposite --
`t_wlfall0` = 1.5692 ns against `t_clk2pre` = 0.7642 ns, i.e. the wordline
moves 0.8 ns LATER. `run_backend_delay.sh` had it as
`access = max(t_clk2wl, t_clk2pre)`, a race that does not exist, and
`docs/naming.md` credited `t_clk2wl0` with proving a polarity it never saw.

**Why moving the window is not enough.** With TD at the true rising edge the
same measure reports **+100.75 ns**: the wordline falls during evaluate and
its next RISE is the recovery in the following precharge phase.
`.measure` takes a window start and has no end, so no TD makes this arc
meaningful -- because the arc does not exist. No wordline rises during
evaluate at all.

**What replaced it.** The rise measure is gone. In its place is a BOUNDED
probe, `v_wl<k>_eval` -- `FIND v(wl_k) AT=` a fixed instant inside the
evaluate phase, which cannot wander into a neighbouring phase the way a
trig/targ search can. Read with `t_wlfall<k>` it states the decoder polarity
in a form no window choice can corrupt. wrom0/TT, addr 0, measured
2026-09-23:

| probe | wl_0 | wl_1 .. wl_7 |
|---|---|---|
| `v_wl<k>_eval` | 6.17e-08 V | 1.800000 V, all seven |
| `t_wlfall<k>` | 1.5692 ns | failed, all seven |

One row is driven to ground, the other seven never move. That is the whole
polarity statement, and neither half of it depends on where a search window
opens.

**What the polarity actually justifies.** The column deck holds every wordline
at DC VDD, and the reason is NOT "the unselected rows fall" -- they do not
move at all. It is that the one row whose gate does fall is strapped
(`zero_cell`) in the read-0 case the deck characterises, so the chain keeps
conducting and the discharge starts on the precharge edge. The wordline is
not in series with the front-end term. Same conclusion as before, correct
reasoning behind it.

**No .lib number moves, and that is measured rather than argued.** wrom0/TT
was re-run twice -- once with the window moved, once with the arc replaced --
and every other measured value in the log is bit-identical through both:
`t_clk2pre` 7.642059e-10, `t_clk2int` 3.255197e-10, `t_wlfall0` 1.569241e-09,
`t_wl1090_0` 1.246524e-10 (the hold bisect's input) and the energy integral
`q_c3` -3.47674e-12. Nothing consumed `t_clk2wl*`.

**A third consumer had the same off-by-half-a-cycle.**
`run_waveform_capture.sh` drew `docs/img/06-front-end.svg` over a window
centred on `6*TCLK` -- where clk0 FALLS -- while its own title read "clk0
rises, the selected wordline FALLS". Now `6.5*TCLK`, and it takes the
wordline node from `t_wlfall0` since `t_clk2wl0` no longer exists. The
committed SVG is stale until that capture is re-run.

**Still stale: the committed logs.** They carry the -99 ns line and no
`v_wl*_eval`. Since no shipped number depends on them, re-running the whole
periphery flow is record hygiene rather than a correction -- noted here so
the next reader of a log knows which side of this fix it is from.

### The address hold is measured -- and cs0 does NOT inherit it

`run_hold_bisect.sh` produced its first number (wrom0, TT: **15.6615 ns**
against 17.3271 ns of access, `char/hold_tt.log`), and feeding it through
`regen_rom_libs.sh` exposed a modelling defect in `gen_rom_lib.py`: the
measured value was written onto EVERY input pin, cs0 included.

**Why that is wrong.** The deck drops a wordline in mid-evaluate, i.e. cuts
the series chain. That is what a moving ADDRESS does to a clocked row decoder
and it is the only thing the experiment exercises. Its finding -- the read is
decided once the bitline is through the inverter's trip point, so the tail of
access does not constrain the address -- is exactly what does NOT carry over
to cs0. cs0 is not on the decode path at all:

    precharge = ~NAND(cs0, clk_int)

so cs0 going away during evaluate turns the precharge PMOS back ON, the
bitline is pulled to VDD and the read dies -- at ANY point in the cycle,
including the late part the address is excused from. The correct cs0 hold is
the full access window, which is what the library declared BEFORE the
measurement existed. The measurement therefore relaxed a constraint by
1.6656 ns on the strength of an experiment that never touched it, and in the
unsafe direction.

**The fix.** `gen_rom_lib.py` now keeps two constraint tables: `hold_rows`
(the address buses, measured where a log exists) and `hold_ctrl_rows` (every
other input -- cs0 today, any control pin a future macro adds), which stays at
`access_eff` regardless. Both are named in the `.lib` header, with the
reasoning, so a reader is not left to infer why two input pins carry different
holds. On the eleven macro/corner pairs with no hold log nothing changes: both
tables are `access_eff` and the header says the address hold is unmeasured.

**What now catches it.** `tests/test_rom_lib.py` gained a check
(`cs0 held for the whole read`, the 10th) that fails any `.lib` whose cs0 hold
is shorter than its own access time. Verified the way a check has to be:
run against the defective files it reported two failures on wrom0 TT, and
passes on the regenerated set.

**Still open in the same area.** SETUP has the identical problem and no
comparable fix: the measured path is `addr0 -> inv_array_mod/Z` and cs0 is
given that same number although its own path through the control NAND was
never measured. Unlike hold there is no safe larger value to fall back to
without measuring one, so it is recorded in docs/limitations.md as a limitation rather
than patched. Also unaddressed: the measured hold is in the deck's own time
frame (the cut time is counted from the PRECHARGE source's rising edge -- the
column deck has no clk0 at all) while Liberty's `hold_rising` is referenced to
the clk0 pin. The conversion is `+t_clk2pre` and `-t_addr2wl`; from the
committed logs those are about +0.76 and -1.28 ns at TT, so the shipped number
is roughly 0.5 ns conservative -- but that is two corrections nearly
cancelling, not a frame conversion, and nothing states which frame the number
is in.

## 2026-09-24

### Active energy is an average of random reads, not the worst case

`internal_power` on clk0 for `when : "cs0"` was

    E = <every column> x e_col_pj + e_periph_pj

-- every bitline in the macro discharging on every read. That is not a rare
case, it is an impossible one unless the selected row is all zeros, and it put
the shipped number 1.7-2.0x over the truth.

**What actually discharges.** A read precharges every bitline to VDD while
clk0 = 0, then drops the selected row's wordline. A column whose cell in that
row is a `zero_cell` is a metal strap: it conducts whatever its wordline does,
the series chain stays closed, and that bitline discharges. A column whose
cell is a `one_cell` is an NMOS whose gate has just gone low: it opens the
chain, that bitline stays at VDD, and the next precharge draws nothing for it.
So the energy of one read is set by the **number of zeros in the selected
row** -- about half the array on the example macros (wrom0: 126.9 of 256 per
row).

**What was built.** `gen_random_read_energy.py` samples addresses out of the
macro's valid address space (`words` from the `.bin`, `row = addr /
words_per_row`), counts the discharging columns per read from the netlist's
own cell types (`find_worst_column.row_zero_counts`, same
`*_rom_base_array` scoping rule as the worst-column scan), and averages

    E_i = <zeros in row_i> x e_col_pj + e_periph_pj

Nothing here simulates: both energy terms are still the measured ones, and
only the ACTIVITY is new. `regen_rom_libs.sh` calls it with `--energy-only
--log`, so the per-read table lands in `char/random_energy_<corner>.log` and
the `.lib` cites that file.

**Reproducibility.** The seed is derived from the macro name and the corner,
not from the clock, so regenerating from unchanged inputs cannot move the
number -- the same rule the rest of the flow follows. `--seed <n>` pins
another draw and `--seed random` takes a fresh one.

**Result** (all four macros, all three corners, 10 reads each; "array mean" is
the exact mean over every row, printed by the tool as the sampling-error
check):

| macro | corner | 10-read avg (pJ) | array mean (pJ) | worst case (pJ) | worst/avg |
|---|---|---|---|---|---|
| wrom0 | tt | 66.36 | 67.79 | 130.45 | 1.97x |
| wrom0 | ss | 46.61 | 47.60 | 90.99 | 1.95x |
| wrom0 | ff | 111.54 | 114.03 | 222.73 | 2.00x |
| wrom1 | tt | 71.04 | 71.76 | 139.90 | 1.97x |
| wrom1 | ss | 49.69 | 50.18 | 97.20 | 1.96x |
| wrom1 | ff | 120.01 | 121.24 | 239.84 | 2.00x |
| wrom2 | tt | 71.44 | 70.28 | 135.21 | 1.89x |
| wrom2 | ss | 50.48 | 49.67 | 94.99 | 1.88x |
| wrom2 | ff | 124.06 | 121.98 | 238.33 | 1.92x |
| wrom3 | tt | 70.14 | 72.70 | 129.97 | 1.85x |
| wrom3 | ss | 49.01 | 50.77 | 90.23 | 1.84x |
| wrom3 | ff | 120.57 | 125.11 | 226.69 | 1.88x |

The `worst/avg` column is now near-constant *within* a macro and differs
*between* macros, which is the shape it should have: the ratio is set by the
contents. What residual corner-to-corner movement is left in it (1.95-2.00x on
wrom0) is real -- `E_periphery` is a fixed additive term that does not scale
with the column count, so it weighs differently against `E_column` at each
corner.

**The same ten reads at every corner.** The seed is derived from the macro
name ALONE. Putting the corner in it -- which is how this was first written --
drew a different sample at each corner and let sampling noise into the
ACTIVITY, which is physically wrong: how many columns discharge is set by the
ROM contents, and the same address selects the same row with the same zeros at
tt, ss and ff. On wrom0 the sampled mean came out 124.8 / 126.9 / 133.3
columns at tt / ss / ff against a true 126.9 everywhere, a spurious 6.8%
spread that landed straight in the corner ratios. Fixed the same day; all
three corners now read the same ten addresses (wrom0: 123.9 at all three) and
the only thing that moves between corners is the measured energy.

**The sample size is the one thing left to watch.** Ten reads out of 134 rows
puts the average -3.5% to +1.7% off the exact array mean, and that spread is
printed next to every answer rather than left to be discovered. It costs
nothing to close -- this is counting, not simulation -- so
`ROM_ENERGY_READS=200 scripts/rom_char/regen_rom_libs.sh` is available; 10 is
the default only because that is what the model was specified as.

**The worst case is not discarded**, only demoted. `gen_rom_lib.py` takes
`--energy-worst-pj` and the `.lib` header quotes it beside the average, with
the ratio, because a peak-current budget needs it and an average-power figure
does not. `run_col_energy.sh` now reports both totals as well (`E_worst` and a
flat-50% `E_avg` estimate), and says which of the two `P@fmax` is quoted for.

All twelve `.lib` files were regenerated and pass `tests/check_lib.py`.

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

**2b. Nothing gated on the settling check.** FIXED 2026-09-23.
`run_periphery_power.sh` measured `q_c2` and `q_c3` on consecutive cycles,
printed their gap in the summary table, and no consumer ever compared them.
The gap stood at 24-40% on the bad TT runs and nobody acted on it.

`check_settled` (`common.sh`) now compares them against `SETTLE_MAX_PCT`,
default **1.0%** -- the same limit `gen_col_tb_parasitic.py` applies to
`t_dis_50` against `t_dis_50_prev`. Over it, the row goes into the same ledger
a crashed deck uses, so `ng_summary` reports both together and the run exits
non-zero. The table is still printed in full first: one run shows every macro
and corner before it fails.

This is the THIRD silent-failure mode, and the one neither of the first two
guards can see. A crashed deck is caught by its exit code; a deck that exits
zero having logged `Error: no such vector` is caught by `run_ng` reading the
log. Here ngspice is correct and silent -- every `.measure` resolves, the exit
status is 0, and the number is simply a startup transient rather than the
steady state. Only the circuit's own two-cycle comparison can tell.

The exposure was asymmetric and worst where it was least visible. The active
value is `N_cols x E_col + E_periph` (wrom0 TT: 130.4458 pJ, of which the
periphery is 6.2581), so a 30% periphery error moves it ~1.4%. The idle value
(`when : "!cs0"`, 3.5379 pJ) **is** the periphery term, so the same error is a
30% error in the shipped number.

All 24 committed periphery logs are between 0.11% and 0.59%, so the 1% limit
is a loose ceiling on the current data rather than a tight one. The gap that
once read 24-40% was the trapezoidal integrator, not the circuit (item 3) --
which is the point: the settling column was the signal that detected that
defect, and it was the one signal with no teeth.
`tests/test_error_reporting.py` now covers the limit, the boundary, the
report's contents and the fact that the script still calls the check.

**2c. `regen_rom_libs.sh` read whatever log was in the tree.** FIXED
2026-09-24, and wider than it was written: re-reading the `q_c2`/`q_c3` gap
at the point `PA`/`PI` are taken would have closed the unsettled case only,
and the unsettled log is one member of a family. A log in `<macro>/char`
outlives everything -- the netlist it was measured on, the deck it came from,
the run that wrote it. Re-extract the macro with a new `.bin`, fix a
measurement and rebuild a deck, have a re-run die halfway, copy the tree from
another machine: the old log is still there with a plausible number in it,
`meas` finds a line and returns it, and the `.lib` calls it measured.

So the question is no longer "is this number bad in a way I know how to test"
but "did **this** flow produce this file", and it is answered where the file
is written rather than guessed where it is read. `run_ng` stamps every log it
accepts with `<log>.prov` (`common.sh`): the deck, the log and the macro
netlist, **by content hash** -- mtimes are rewritten by any checkout, copy or
rsync, so they record when a file arrived rather than what is in it. The two
files the flow derives instead of simulating (`periph_leak_cs<n>_<corner>.total`,
`hold_<corner>.log`) are stamped by the scripts that write them, and the TT
decks a generator runs itself (`gen_col_tb_parasitic.py`, in `run_col_timing.sh`
and `run_early_path.sh`) go through `prov_adopt`, which judges them by the
same fatal signatures first.

A verdict against a run withdraws the stamp rather than deleting the file:
`check_settled` and `ng_fail` write an `invalid` line carrying the reason, so
an unsettled log -- and a log whose **re-run** has just failed, which is the
case that leaves the previous run's numbers standing -- is refused with that
reason quoted. That is item 2c proper, closed as a special case of the rule.

`regen_rom_libs.sh` checks all 27 files it may read for a macro and corner
before it reads a single value. A rejected file is NOT treated as a missing
one: missing has documented fallbacks (hold = access, a flat `index_1`,
ARRAY-ONLY leakage, an analytic setup bound), all safe and all stated in the
`.lib` header, and quietly taking one of those roads while a rejected log sits
next to it is precisely the failure being closed. A rejection fails that
corner -- no `.lib` is written for it, the report groups the files by the
`run_*.sh` that produces them, it names any `.lib` left over from an earlier
run in `output/lib`, and the script exits non-zero. A run where no corner
survived writes nothing, skips the structural check (it would be reading the
previous run's files and reporting them green) and says so.

The cost is deliberate and worth stating: **every log committed before
2026-09-24 is unstamped, so it is refused.** `.prov` files are content-hashed
against the netlist, not the deck's presence (decks are gitignored and rebuilt
on demand), so a clone regenerates fine -- but the existing corpus has to be
re-run once to carry stamps. There is no flag to accept an unstamped log; the
adoption gesture and the failure it exists to prevent are the same gesture.
`tests/test_error_reporting.py` covers the stamp, each way of invalidating it,
the missing-deck case and the fact that `regen_rom_libs.sh` still honours it.

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

Listed in docs/limitations.md. The biggest one by far is now
item 1: **array-level parasitics missing from the column deck** (+3 fF against
the ~5 fF the deck carries, on the largest term of `access`). The back-end and
periphery decks already have the alive/dead + negative-net-capacitance rule
that fixes it; porting it into `gen_col_tb_parasitic.py` is the obvious next
piece of work.

The rest: the ~5% of ramp-time sensitivity left on `addr0[0]` and
`addr0[6]` after the pin-cap work, one column/one bit generalised, and the
`index_1` axis stopping at 0.5 ns. Energy no longer assumes every column
discharges (2026-09-24, above); what is left there is the size of the sample
the average is taken over. Periphery leakage IS counted now (`run_periphery_leak.sh`: one slice
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

WHERE TO PICK UP: nothing here is half-finished any more. The one thread that
was -- the whole-macro golden pin-cap reference -- is closed by REMOVAL, not
by a result: its cost grows with the array the user chooses, so it was never
runnable on a real ROM. See "The golden reference: REMOVED" above for what the
pin capacitances are bounded by instead.
