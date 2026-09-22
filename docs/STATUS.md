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

**9. Leftover Turkish comments** in `gen_rom_lib.py` and
`gen_periphery_power_tb.py`. Gone -- no Turkish characters remain in any
script.

### STILL OPEN

**3. The column energy deck never got the `method=gear` fix.**
`gen_col_power_tb.py` writes its `.options` line only in the idle (leakage)
branch, so the energy integral still runs on ngspice defaults with the
trapezoidal integrator. Measured on wrom0 column 236 at TT: trapezoidal gives
0.4956 / 0.4823 / 0.4849 / 0.4917 over a 200/400/800/1600 step sweep -- 2.8%
and not monotonic -- against 0.4851 / 0.4860 for gear, 0.18%. The committed
value is ~0.6% low. Same defect class as item 2, two orders of magnitude
smaller. The fix is one line, already proven in the sister deck.

**2b. Nothing gates on the settling check.** `run_periphery_power.sh` prints
the last-two-cycle gap in a summary table and that is all. It stood at 24-40%
on the bad TT runs and nobody acted on it. It should fail the run, or at least
be re-read by `regen_rom_libs.sh` before the number is used. (The column deck
got exactly this treatment in the item-1 fix; the periphery deck did not.)

**8. `gen_macro_behavioral_v.py` parses the `.lib` header comment.** `access`
is recovered with a regex over the text `TOTAL \(worst load\)\s*:\s*([\d.]+)`
-- out of the human-readable banner rather than out of the Liberty data.
Reword the banner in `gen_rom_lib.py` and the model silently loses its timing.
This is now a little more pressing than it was, since the column-decode work
added lines to that same banner (it did not touch the matched line).

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

The rest: analytic input pin capacitances, energy assuming every column
discharges, periphery leakage not counted, one column/one bit generalised, and
the `index_1` axis stopping at 0.5 ns.

## Housekeeping

Everything since the 2026-09-20 09:31 commit is still in the working tree:
the whole re-characterisation run (`char/` decks and logs, `output/lib/*`,
`output/verilog/*`), today's column-decode work
(`scripts/rom_char/run_coldec_delay.sh` and the `coldec_a*` decks and logs are
untracked; `gen_periphery_power_tb.py`, `gen_rom_lib.py` and
`regen_rom_libs.sh` are modified), today's deletions, the `.gitignore` update,
and `docs/img/*` (diagrams, not yet referenced from the README).
