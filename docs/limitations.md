# Known limitations

What is not modelled, and how far off each one can put the answer.

[<- back to the README](../README.md)

---

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
3. **Wire resistance is modelled per cell, not extracted whole (an intentional design choice).**
   Magic (versions 8.3.628 / 8.3.629) segfaults when attempting resistance
   extraction (`extresist all` / `ext2spice extresist on`) on the whole macro
   due to the array size and degenerate shorted cells (`rom_base_zero_cell` source/drain short).
   Running the extraction command directly on a macro confirms this:
   ```bash
   cd examples/wrom0
   magic -dnull -noconsole << 'EOF'
   load wrom0
   extract style ngspice(si); extract all
   extresist tolerance 1; extresist all
   ext2spice hierarchy on; ext2spice format ngspice; ext2spice extresist on
   ext2spice -o wrom0_rc.spice
   quit -noprompt
   EOF
   # Fails with: Segmentation fault (core dumped)
   ```
   Because of this, `gen_resistance_model.py` extracts it per cell (where Magic is happy) and
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
5. **Input pin capacitances are measured, but two of the thirteen pins carry
   ~5% of uncertainty.** `run_pin_cap.sh` (2026-09-22) replaced the analytic
   `PIN_CAP` estimate; the old numbers were low by 58-96% (clk0 2.5 -> 4.9 fF,
   cs0 3.0 -> 5.7 fF, addr0 one flat 6.0 -> a measured 6.6..9.5 fF across the
   eleven bits). The measurement integrates the charge the pin itself supplies
   over a full swing, `C = Q(VDD)/VDD`, so it covers the pin's wire C, the gate
   C of the first stage, and the Miller charge pushed back as that stage
   switches -- none of which a gate-width formula sees.
   What is *not* settled: `addr0[0]` and `addr0[6]` are flagged by the deck's
   own rise-vs-fall settling check in every macro and every corner, they move
   4-5% when the ramp time is doubled, and `addr0[0]` also moves -4.9% when the
   deleted array's gate load is doubled (every other pin moves <0.6% under that
   same 2x perturbation). The other eleven pins reproduce to 0.45% across ramp
   times and to four significant figures across all four macros. A Liberty bus
   carries ONE capacitance, so `addr0` ships the worst bit.
   **The reduction itself is never validated against a full-array run, and it
   never will be.** The deck deletes the cell array and the column mux and
   puts their load back as lumped C; every check listed above runs that same
   reduced deck, so all of them are blind to an error common to all of them.
   The run that could see it -- the whole array simulated, nothing deleted --
   was built, and on `wrom0`, a *1 kbit* example, it reached 16.4 GB and 2h37m
   without finishing before it was killed. The array is the one block whose
   size the user picks, so that cost is unbounded by construction; the check
   was removed rather than shipped as something only the smallest macro can
   afford. What bounds the reduction instead is the -4.9% / <0.6% array-load
   sensitivity above, plus an independent hand calculation from Magic's
   extracted wire C and the PDK's `Cox*W*L` (the 11 address pins come in at
   0.94..0.99x of it, clk0 and cs0 at 1.35..1.50x, both the expected sign).
6. **`MAX_CAP`, `MIN_CAP` and `MAX_TRANSITION` are fixed constants**
   (`gen_rom_lib.py`). The first two are the endpoints of the characterised
   output-load axis, so they are at least tied to something measured; the
   transition limit is the top of the slew axis. They are the remaining part
   of the `.lib` that is not read out of a log.
7. **The setup/hold tables are scalar in all but shape.** Both constraints
   sit in a 3x3 `CONSTRAINT_TABLE`, but all nine cells of each carry the same
   value: the slew dependence of a constraint was not modelled, because it was
   predicted to move the number by an amount too small to matter. For **hold**
   that prediction rests on a measurement: access moves only 0.24% across the
   whole `index_1` axis (see limitation 4), so a slew-resolved hold table
   would be three copies of one number anyway.

   **The address hold is measured where the log exists, converted to the clk0
   pin's time frame, and not shared with cs0.** `run_hold_bisect.sh` cuts the
   chain at the cell nearest the bitline -- the worst place to cut -- and
   bisects the cut time until the read still lands within 10% of the rail. It
   answers in the *column deck's* frame: that deck is driven by a synthetic
   precharge source and has no `clk0` in it at all, so its answer is counted
   from the internal evaluate edge, while Liberty's `hold_rising` is
   referenced to the `clk0` pin. Two measured delays carry it across, and
   `run_addr2wl.sh` supplies the one that was missing -- `addr0` to the
   wordline it drops, taken during evaluate when the clocked decoder is
   transparent. On wrom0 at TT:

   | term | ns |
   |---|---|
   | cut time, from the internal evaluate edge | 15.6615 |
   | + `t_clk2pre` (clk0 -> that edge) | 0.7642 |
   | - `t_addr2wl` (addr0 -> the wordline) | 1.1875 |
   | **= hold at the clk0 pin** | **15.2382** |

   against 17.3271 ns of access: once the bitline is past the inverter's trip
   point the address no longer matters. The raw cut time was shipped once and
   was 0.42 ns optimistic; the two corrections nearly cancel, which is a
   coincidence rather than a reason, so the conversion is applied explicitly
   and written out term by term in the `.lib` header. Without the
   `addr2wl` log the header says outright that the number is in the deck's
   frame.

   That number ships on `addr0` only. `cs0` keeps the full access window,
   because the experiment never exercised it -- cs0 is not on the decode path
   at all. It gates the precharge (`precharge = ~NAND(cs0, clk_int)`), so
   losing it during evaluate turns the precharge PMOS back on, pulls the
   bitline to VDD and kills the read at *any* point in the cycle, including
   the late part the address is excused from.

   **And cs0 carries a second arc, `hold_falling` = 0.** The window above says
   cs0 must last until the data *exists*; what it cannot say is that cs0 must
   last until the data is *captured*, which happens on clk0's fall -- this
   macro has no latch, so the high phase is the whole life of the read. That
   is not a duration. A cs0 released at the end of a 17.3271 ns `hold_rising`
   satisfies the constraint and still re-opens the precharge 0.5 ns before the
   earliest legal capture edge, and with a slower clock the gap is larger
   still, because the requirement stretches with the period while a fixed
   number does not. Referenced to the falling edge, zero states it exactly for
   any period. `tests/test_rom_lib.py` refuses a `.lib` whose cs0 hold is
   shorter than its access time, and one that has no `hold_falling` at all. The remaining
   eleven macro/corner pairs have no hold log, so both pins keep
   `hold = access` there and the header says so.

   **Setup is a path delay, and the race it has to win is quantified.**
   `t_addr2dec*` measures `addr0 -> inv_array_mod/Z`, the A input of the
   clocked decoder NAND -- 0.0307 ns at TT. That is not the constraint by
   itself: the gate it feeds is clocked by `clk_int`, which arrives
   `t_clk2int` = 0.3255 ns after `clk0`, so the requirement at the pin is
   0.0307 - 0.3255 = **-0.2948 ns**. The address may legally arrive *after*
   clk0 rises. The library ships the positive path delay anyway -- it is the
   conservative of the two, and a constraint should not be relaxed as a side
   effect of changing what is being counted -- and the header states both
   numbers so a reader is not left guessing which one it is.

   `cs0` carries the same value and **is bounded by it**, which is why it
   needs no measurement of its own: from the netlist, `cs0` goes straight to
   the A gate of `rom_control_nand` with no stage in between, and the
   extraction keeps it as a single node, so there is nothing between pin and
   gate to measure. The address path has one inverter that cs0's does not, so
   cs0's requirement is strictly the smaller of the two.

   What is still *not* data: the slew dependence. `t_addr2dec*` is measured at
   one clk0 slew and the address buffer's own dependence on the `addr0` edge
   has never been swept. Given a race margin of 0.29 ns against a path delay
   of 0.03 ns, the effect is not expected to change any conclusion -- but that
   is an argument, not a sweep.
8. **Active energy is a 10-read sample, not an exhaustive average.**
   `internal_power` on clk0 for `when : "cs0"` used to be `<every column> x
   E_column + E_periphery`, i.e. every bitline discharging on every read --
   1.81-1.95x the real average on the example macros. Since 2026-09-24
   `gen_random_read_energy.py` scores each read as `<zeros in the selected row>
   x E_column + E_periphery`, counting the discharging columns from the
   netlist's own cell types (a `zero_cell` is a metal strap and conducts
   whatever its wordline does; a `one_cell` in the selected row is an NMOS
   whose gate has just fallen, so it opens the chain and that bitline stays at
   VDD), and `regen_rom_libs.sh` writes the average of 10 random reads.

   What is *still* approximate:
   * **The sample is 10 reads.** The tool prints the exact mean over every row
     next to it: the gap on the example macros is -3.5% to +1.7%, so a single
     `.lib` number can sit a few percent either side of the true average. The
     seed is per MACRO, not per corner, so all three corners sample the same
     ten addresses -- which columns discharge is a property of the contents,
     and a per-corner draw put ~7% of pure sampling noise into the corner
     ratios until that was fixed.
     `ROM_ENERGY_READS=200 scripts/rom_char/regen_rom_libs.sh` closes that at
     no simulation cost -- it is a counting exercise, not a run. 10 is the
     default only because it is what the model was specified as.
   * **`E_column` is the worst column's.** Every discharging bitline is scored
     at the charge measured on column `<worst>`, so per-read energy stays on
     the safe side of a column-by-column sum.
   * **It is contents-dependent by construction.** Reprogram the `.bin` and
     the number moves; that is the point, but it means the figure belongs to
     one ROM image rather than to the geometry.
   * **The worst case is not gone**, only demoted: the `.lib` header quotes it
     next to the average, because a peak-current budget still needs it.
9. **Leakage is measured in the idle state only.** `cell_leakage_power` covers
   the array *and* the periphery, but both halves are taken with `.op` at
   clk0 = 0 -- the precharge phase, chain feet off, every wordline high. That
   is the state a static leakage number describes, and both halves have to
   share it to be addable, but it means the evaluate phase (clk0 high, one
   wordline low, feet conducting) is not characterised. The two `cs0` states
   *are* both measured, and on the example macros they come out equal: while
   clk0 is low the control NAND's output does not depend on cs0. What is no
   longer missing is any BLOCK: since 2026-09-22 the slice list covers every
   instance of the top-level cell, the read back end included.
10. **One column and one dout bit** are measured and applied to every bit.
11. **The falling-edge arc needs `t_pre_50` from the column deck.**
    `bus(dout0)` carries a `timing_type : falling_edge` group giving the
    earliest time dout0 leaves its valid level after clk0 falls
    (`t_clk2pre + t_pre_50 + t_bl2dout` at the smallest load). Against a log
    that predates `t_pre_50`, `regen_rom_libs.sh` warns and leaves that term
    out -- which makes the arc earlier, i.e. safe; re-running
    `run_col_timing.sh` picks it up.
