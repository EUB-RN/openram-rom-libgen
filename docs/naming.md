# Reading a measurement name

Every number in this project comes from an ngspice `.measure`, and the names follow one grammar. `t_clk2wl` reads as *time, from `clk0`, to the wordline*.

[<- back to the README](../README.md)

---

Once the grammar is known, a name that does not appear in any table below is
still readable.

**1 -- the prefix is the physical quantity, and it fixes the unit:**

| prefix | quantity | unit in the log | example |
|---|---|---|---|
| `t_` | time -- a delay, a slew, or a crossing instant | s (tables here print ns) | `t_dis_50` |
| `c_` | capacitance | F, or fF when the name ends `_ff` | `c_cyc0_ff` |
| `q_` | charge, an integral of `i(Vvdd)` over a window | C | `q_c3` |
| `e_` | energy, `q x VDD`; the name ends `_pj` | pJ | `e_col_pj` |
| `i_` | current | A | `i_leak` |
| `p_` | power; the name ends `_mw` | mW | `p_leak_mw` |
| `bl_`, `blb_` | a *voltage* sampled on a bitline at one instant | V | `bl_hold_end` |

**2 -- the body is the arc, and the digit `2` in the middle reads as "to".**
`a2b` is the delay from node `a` to node `b`: `t_clk2pre` is `clk0` -> the
`precharge` net, `t_addr2dec` is an address input -> the decoder output it
drives, `t_bl2dout` is the bitline -> `dout0`. A body with no `2` names an
event on a single node instead: `t_dis_50` is a discharge, `t_pre_99` a
recharge.

**3 -- a trailing `_NN` is a percentage of the full VDD swing**, the threshold
the crossing was taken at: `t_dis_50` is the 50% crossing of the bitline
discharge (the one `access` is built from), `t_pre_99` is the 99% point of the
recharge (nearly-complete, which is what the precharge phase has to reach),
`t_dis_10` the 10% point. Two thresholds in one name mean a slew: `t_wl1090`
is a 90% -> 10% wordline fall, `t_wlslew` the 80% -> 20% fall sky130 Liberty
uses.

**4 -- a trailing bare digit is an index, not a threshold.** It selects which
pin, bit, or slice the measurement was taken on: `t_clk2wl0` is the arc to
wordline 0, `c_cyc3_ff` the cycle capacitance of pin index 3,
`t_pre2sel5_rise` the arc to `word_sel[5]`. Index and threshold can both be
present -- `t_wl1090_0` is the 90-10 slew of wordline 0.

**5 -- the remaining suffixes:**

| suffix | means |
|---|---|
| `_rise` / `_fall` | which edge of the target node was measured |
| `_prev` | the same quantity one cycle earlier, kept to prove the read settled (`t_dis_50_prev`) |
| `_slew` | a transition time, not a delay (`t_dout_slew`) |
| `_tot` | summed over every node or block, not per-instance (`c_fix_tot`) |
| `_ff`, `_pj`, `_mw` | the unit the `.measure param=` line already converted to |

**The abbreviations used in the bodies:**

| token | node or thing it names |
|---|---|
| `clk` | the `clk0` input pin |
| `int` | the internal clock node inside `rom_control_logic`, after the input buffer |
| `pre` | the `precharge` net -- the one that gates both the precharge PMOS and the foot NMOS |
| `wl` | a wordline out of `rom_row_decode` (it **falls** when selected) |
| `bl`, `blb` | bitline, and its complement |
| `dout` | the `dout0` output bus |
| `addr` | an address input pin |
| `dec` | a row-decoder output |
| `sel` | a `word_sel` line out of `rom_column_decode` |
| `coldec` | the column decoder itself |
| `col` | one bitline column of `rom_base_array` |
| `periph` | everything outside the array (control logic, decoders, back end) |
| `cellgate` | the gate capacitance of one array cell -- the lump the periphery deck loads itself with |
| `dis` | discharge (evaluate phase) |
| `eval` | the evaluate phase, clk0 high |
| `cyc` | one full cycle, 0 -> VDD -> 0 |
| `leak` | a static `.op` current, no switching |
| `fix` | the negative-net-capacitance correction applied to extracted parasitics |

**Worked examples:**

| name | read as | where it comes from |
|---|---|---|
| `t_clk2wl0` | time, `clk0` -> wordline 0 **rising** | periphery deck; expected to FAIL -- no wordline rises during evaluate, and that failure is half the polarity evidence |
| `t_wlfall0` | time, `clk0` -> wordline 0 **falling** | periphery deck; the half that succeeds, and what proves the selected wordline falls |
| `t_clk2pre` | time, `clk0` -> `precharge` net | periphery deck; term 1 of `access` |
| `t_dis_50` | time to the bitline's 50% **dis**charge crossing | column deck; term 2 of `access`, the dominant one |
| `t_pre_99` | time to 99% re**pre**charge | column deck; sets `min_pulse_width(fall)` |
| `t_bl2dout` | time, bitline -> `dout0` | back-end deck; term 3 of `access` |
| `t_addr2dec2` | time, address pin -> decoder output, index 2 | periphery deck; the setup constraint |
| `t_pre2sel5_rise` | time, `precharge` -> rising `word_sel[5]` | column-decode deck; must beat `t_dis_50` |
| `c_cyc0_ff` | capacitance of pin 0 in fF, from one full cycle | pin-cap deck; this is the number that ships in the `.lib` |
| `c_one_ff` | gate capacitance in fF of a cell storing a one | cell-gate deck; feeds the periphery lumped load |
| `q_c3` | charge over cycle 3 | energy decks; cycle 3, not cycle 1, so the deck has settled |
| `e_periph_pj` | periphery energy per cycle in pJ | periphery power deck |
| `p_leak_mw` | leakage power in mW | `.op` leakage decks |
| `bl_hold_end` | bitline **voltage** at the end of the hold window | address-hold deck; a level, not a time |
