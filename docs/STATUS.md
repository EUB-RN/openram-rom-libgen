# Where the work stands

Last updated: 2026-09-17. Keep this file current when stopping mid-task.

## Done and verified

* The flow is size independent: macro list, worst column, chain length, column
  count, address/data width are all derived (`rom_paths.py`); no hand-kept
  tables remain. `regen_rom_libs.sh` reads every number from a log.
* All comments, docstrings, generated `.lib`/`.v` text and the README are in
  English.
* Deliverables go to `output/lib/` and `output/verilog/`.
* `rom_paths.py --check <macro>` pre-flight exists.
* The committed `output/` files were reproduced numerically identical to the
  previously committed ones before the resistance work started, so any change
  from here is attributable to the resistance model alone.
* The array was confirmed to be a NAND chain from the schematic netlist, the
  GDS-extracted netlist and matching LVS device/net counts. `zero_cell` is a
  transistor whose source and drain are shorted by a metal1 strap; that strap
  is the stored bit.

## In progress: wire resistance is now ON by default, but NOT yet re-measured

`gen_resistance_model.py` (new) extracts per-cell series wire resistance:
Magic on a single cell (it segfaults only on the whole macro, and on
`zero_cell`, whose source and drain are the same net), analytic from the .mag
geometry plus the PDK sheet resistances where Magic fails.

Measured on wrom0: `one_cell` 505.4 ohm, `zero_cell` strap 0.24 ohm,
`precharge_cell` 676.5 ohm, worst chain 41.5 kohm.
Wordline resistance is a non-issue: the array straps the wordline to metal
every 8 columns (33 polycont per row, 8.16 um apart), so its RC is ~10 ps.

`gen_col_tb_parasitic.py` now inserts those resistors by default
(`--no-resistance` reproduces the old deck), and `run_col_timing.sh` builds the
resistance model first. The file names did not change, so every downstream
script keeps working.

Effect measured on wrom0 column 236, but **only wrom0 and only by hand so far**:

| corner | t_dis_50 without R | with R | difference |
|---|---|---|---|
| tt | 14.3346 ns | 16.5035 ns | +15.1% |
| ss | 39.3750 ns | 41.9709 ns | +6.6% |
| ff | 6.9559 ns | 8.9101 ns | +28.1% |

### TO RESUME: re-run the flow so the .lib files include resistance

Nothing in `output/` reflects the resistance yet -- the committed .lib files
are optimistic by the amounts above. Run, in this order (~20-30 min total):

```sh
export PDK_ROOT=$HOME/OpenLane/pdks       # gen_resistance_model needs the tech file
export MAGIC_BIN=magic
./scripts/rom_char/run_col_timing.sh      # 4 macros x 3 corners, ~10 min
./scripts/rom_char/run_backend_delay.sh   # MUST be re-run: its driving edge
                                          # comes from t_dis_50 / t_dis_10
./scripts/rom_char/regen_rom_libs.sh
python3 scripts/rom_char/gen_macro_behavioral_v.py
git diff --stat output/                   # every .lib should move
```

Steps 4-6 of the flow (periphery energy, address setup, column leakage/energy)
do NOT need re-running: the resistance does not change them measurably
(t_pre moved by 0.5%, leakage is a DC operating point).

After the run, update the "Known limitations" item 3 in README.md: it currently
says the resistance is measured but not switched on.

## Open: `.lib` has no falling_edge arc on dout0

Confirmed by inspection: `bus(dout0)` carries a single `timing()` group with
`timing_type : rising_edge`. The header of the same file states that dout0
becomes INVALID when clk0 falls, but nothing in the Liberty data says so, so
STA assumes the data is stable until the next capture edge -- a false pass.

What to add in `gen_rom_lib.py`: a second `timing()` group on dout0 with
`timing_type : falling_edge`, whose delay is the time from clk0 falling to the
output leaving its valid level (i.e. the precharge path taking dout0 back to
all ones). That number is not measured yet; the front-end term `t_clk2pre`
plus the bitline recharge (`t_pre_90`) bounds it, but a direct measurement
(trigger on clk0 falling, target dout0 crossing) in the back-end deck would be
better.

## Other known gaps

Listed in README.md under "Known limitations": array-level parasitics missing
from the column deck (+3 fF of ~8 fF), `rom_column_decode` never measured, flat
input-slew axis, analytic input pin capacitances, energy assumes every column
discharges, periphery leakage not counted, one column/one bit generalised.

## Housekeeping

Everything up to and including the output/ restructuring is committed
(`0e2c8c2 outputs and working directory parametric`). Uncommitted at the time
of writing, i.e. the resistance work:

    M README.md                                   (limitations item 3 rewritten)
    M scripts/rom_char/gen_col_tb_parasitic.py     (resistance on by default)
    M scripts/rom_char/run_col_timing.sh           (builds the resistance model first)
    ? scripts/rom_char/gen_resistance_model.py     (new)
    ? examples/wrom0/char/resistance_model.json    (wrom0 only so far)
    ? docs/STATUS.md                               (this file)
