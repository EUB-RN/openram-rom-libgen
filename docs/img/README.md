# Figures for the main README

This directory holds the images referenced by the top-level `README.md`.
Nothing here is drawn by hand: every figure is either a screenshot of the
layout you already have, or a plot of measurements this flow produces.

Until a file exists, its reference in the README shows as a broken image --
that is intentional, it tells you what is still missing.

Naming: keep the numeric prefix, use PNG, keep the width under ~1600 px.

---

## Layout figures (Magic or KLayout screenshots)

### `01-macro-floorplan.png`
**What:** the whole macro, zoomed out, with the seven top-level blocks
distinguishable.
**How:** open `<macro>.gds` (or `<macro>.mag`) and zoom to fit.
**Why it earns its place:** the README's "what is modelled" table lists the
blocks one by one; the reader needs to see where they sit. If your tool can
label them, label `rom_base_array`, `rom_row_decode`, `rom_control_logic`,
`rom_column_mux_array`, `rom_column_decode`, `rom_bitline_inverter`,
`rom_output_buffer`.

### `02-array-overview.png`
**What:** a zoom into `rom_base_array` covering roughly 8x8 cells.
**How:** zoom into the middle of the array; keep enough cells that the
repeating pattern is obvious.
**Why:** shows the regularity, the bitline columns and the wordline rows, and
gives the reader the same view they will see in their own layout.

### `03-cell-one-vs-zero.png`
**What:** one `rom_base_one_cell` and one `rom_base_zero_cell` side by side,
labelled.
**How:** zoom to two vertically abutted cells where one is programmed 0; keep
the cell-name labels visible.
**Why:** this is the single most important figure in the repository. The metal
strap across the zero cell shorts source to drain -- that strap IS the stored
bit. Everything about the NAND chain follows from this one picture.

### `04-column-strip.png`
**What:** a tall, narrow strip of one column, maybe 10-15 cells.
**How:** zoom into a single column and stretch the view vertically.
**Why:** shows that cells abut and share diffusion, and that there is no
per-cell ground contact -- the reason the discharge path is a long series
chain instead of one transistor to ground.

---

## Waveform figures (from your own ngspice runs)

The decks this flow writes do not save waveforms by default (the runs only
need `.measure` results). To capture one, run the deck with a raw file:

```sh
ngspice -b -r /tmp/col.raw examples/<macro>/char/col<N>_worst_case_parasitic.sp
```

Then plot the raw file with whatever you prefer. Keep the axes in ns and V,
and mark the measurement thresholds -- the point of these figures is to show
what the numbers in the `.lib` actually refer to.

### `05-col-discharge.png`
**Signals:** `precharge` and the bitline `bl_0_<N>`, for tt / ss / ff on the
same axes.
**Mark:** the 50% crossing (`t_dis_50`) and the 99% recharge (`t_pre_99`).
**Why:** this is the biggest term of `access`, and the figure makes the corner
spread visible (roughly 7 / 14 / 39 ns on the example macros).

### `06-front-end.png`
**Signals:** `clk0`, `clk_int`, `precharge` and one wordline, from
`char/periph_active_tt.sp`.
**Mark:** `t_clk2pre`, and the wordline FALLING after clk0 rises.
**Why:** it proves the decoder polarity instead of asserting it -- the selected
wordline falls during evaluate, which is what justifies holding all wordlines
at VDD in the column deck.

### `07-backend-loads.png`
**Signals:** `dout0` for the three output loads (1.7225 / 6.89 / 27.56 fF)
from `char/backend_tt_*.sp`, plus the driving bitline edge.
**Mark:** `t_bl2dout` and the 10-90% slew.
**Why:** shows that the `index_2` axis of the CELL_TABLE is a real
measurement, not three copies of one number.

### `08-energy-settling.png`
**Signals:** the supply current or its running integral over the simulated
cycles, from a periphery run.
**Mark:** the two measured windows (`q_c2`, `q_c3`).
**Why:** explains why the flow measures the last two cycles and compares them
-- equal values are the settling proof.

---

## Plot from numbers (no simulator needed)

### `09-chain-vs-access.png`
**What:** measured access time against series-chain length, with a quadratic
fit.
**Data:** the three points recorded in the repository -- chain 267 -> 94.1 ns,
150 -> 31.7 ns, 75 -> 9.2 ns -- plus your own macros
(`find_worst_column.py` prints the chain length, the `.lib` header prints the
access).
**Why:** it is the one figure that lets a reader predict what a geometry change
will cost before running anything.
