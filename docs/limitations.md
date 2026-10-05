# Known limitations

This document lists current modeling boundaries. Historical fixes are kept in
Git, not here.

[<- back to the README](../README.md)

## 1. Reduced column context

The column deck retains one physical column and extracted array capacitance.
Capacitance coupled to deleted neighbours is reduced to ground, so data-dependent
coupling from simultaneously switching columns is not modeled. Use
`--no-array-c` only for comparison; it removes array-level capacitance.

## 2. Column-decoder coverage

Access uses

$$t_{access}=t_{clk2pre}+\max(t_{dis\_50},t_{coldec})+t_{bl2dout}$$

because column decode and bitline discharge start from the same precharge edge.
The flow measures all eight decoder addresses in one transient per corner, but
does not model every possible physical variation across custom decoder layouts.

## 3. Wire resistance

Whole-macro Magic resistance extraction is unreliable on large arrays with
shorted zero-cell straps. The flow instead derives per-cell interconnect
resistance with `gen_resistance_model.py` and injects it into the column deck.
The JSON output records whether each value came from Magic, geometry analysis,
or the generic Sky130 fallback.

This model covers interconnect resistance, not MOS channel resistance; ngspice
already models the latter with BSIM4 devices. Row-decoder cell interconnect
resistance is not yet injected into the periphery and `addr2wl` decks.

## 4. Input-slew range

Full mode measures clock slew at 0.05, 0.2, and 0.5 ns. The front-end delay is
slew-dependent, while the bitline and back-end terms are reused across that
axis. Inputs slower than 0.5 ns are outside the characterized range. Standard
mode uses a documented flat conservative axis.

## 5. Reduced periphery correlation

The periphery deck replaces the array and column mux with lumped loads. Pin
capacitance uses adaptive per-pin settling, but there is no completed
whole-macro transient reference: an experimental `wrom0` run exceeded about
15 GB without finishing. Sensitivity tests bound the reduction error; they do
not independently validate it.

## 6. Fixed Liberty limits

`MIN_CAP`, `MAX_CAP`, and `MAX_TRANSITION` are generator constants.
`MIN_CAP`/`MAX_CAP` match the characterized output-load axis, and
`MAX_TRANSITION` matches the top of the input-slew axis, but none is read from a
measurement log.

## 7. Scalar setup and hold constraints

Setup and hold use 3x3 Liberty table shapes with one repeated value. Slew/load
dependence of the constraints is not characterized.

Address hold is measured by array-cut bisection, includes the worst-load
back-end delay, and is converted to the `clk0` pin frame:

$$t_{hold}=t_{clk2pre}+(t_{cut,array}+t_{bl2dout})-t_{addr2wl}$$

When required logs are absent, standard mode uses `hold = access`. `cs0` keeps
the full access-window requirement and a falling-edge gating constraint because
it controls precharge rather than row selection.

Setup uses the measured address-buffer path as a conservative positive
constraint. The dependence on address-input slew is not swept.

## 8. Sampled read energy

Active energy defaults to ten deterministic sampled reads. The calculation
uses ROM contents to count discharging columns and charges each with the
worst-column energy. It is therefore content-dependent and conservative per
discharging column, but it is not an exhaustive mean. Increase
`ROM_ENERGY_READS` for a larger sample; this is a counting pass and requires no
additional SPICE simulation.

## 9. Idle-state leakage

`cell_leakage_power` combines array and periphery `.op` results at `clk0 = 0`.
Evaluate-state leakage is not characterized. Both `cs0` states are measured,
and the periphery slice inventory is checked against top-level instances.

## 10. Spatial sampling

One selected column and one output bit are characterized and applied to every
bit. Within-macro spatial variation is not represented.

## 11. Falling-edge fallback

The output invalidation arc uses
`t_clk2pre + t_pre_50 + t_bl2dout` at the smallest load. If `t_pre_50` is
missing, generation warns and omits that term, producing an earlier,
conservative invalidation arc. Re-run `run_col_timing.sh` to measure it.

## 12. Physical sign-off is separate

The test suite validates scripts, Liberty structure and semantics, OpenSTA
parsing, and behavioural SystemVerilog. It does not run or replace Magic DRC or
Netgen LVS.

## 13. Large row decoders

The periphery deck keeps `rom_row_decode` intact. Its device count grows with
row and address count, so large macros can require substantial time and memory
or encounter convergence problems. Decoder slicing and equivalence regression
remain planned work; see [todos.md](todos.md).
