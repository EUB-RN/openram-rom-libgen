# Figures for the main README

Two kinds of picture, and **neither is drawn by a plotting tool**:

| kind | what it is | who makes it |
|---|---|---|
| **waveforms** (05, 06, 07) | ngspice's own `hardcopy` of its own simulation | `scripts/rom_char/run_waveform_capture.sh` |
| **layout** (01-04) | screenshots of the layout you already have | you, in Magic or KLayout |

There is no intermediate plotting step and there is not meant to be one. A
curve in this directory is the picture ngspice draws in its plot window,
written to file instead of to the screen -- not a redrawing of numbers that
came out of it.

Until a file exists its reference in the README shows as a broken image --
that is intentional, it says what is still missing.

---

## 1. Waveforms -- ngspice draws them

```sh
./scripts/rom_char/run_waveform_capture.sh wrom0     # -> docs/img/0{5,6,7}-*.svg
```

The characterisation decks ask only for `.measure` results, so ngspice throws
the waveform away. The script copies each deck, inserts a `.save` of the few
nodes the figure needs plus a `.control` block that writes a raw file, and
re-runs it -- which also re-checks that the deck still reproduces its
committed number. A second ngspice pass loads those raw files and lets
ngspice write the figure itself:

```
.control
load col_ss.raw col_tt.raw col_ff.raw
set hcopydevtype=svg          * vector output; renders straight in the README
set hcopypscolor=1
set color0=white              * paper, instead of the plot window's black
set color1=black              * axes, grid and text
hardcopy 05-col-discharge.svg tran1.v(bl_0_236) tran2.v(bl_0_236) ...
.endc
```

`.save` is not optional on these decks: without it ngspice keeps every node
of the extracted netlist and the raw file runs to gigabytes. The node names
are read out of each deck's own `.measure` lines, because the extracted
netlist names nodes after instances (`wrom0_rom_row_decode_0/wl_0`) and those
change with the macro.

Working files (raw, generated decks, logs) land in `<macro>/char/wave/` and
are git-ignored. Only the SVG is committed.

### `05-col-discharge.svg` -- the biggest term of `access`
**Deck:** `char/col<N>_worst_case_parasitic{,_ss,_ff}.sp` (`run_col_timing.sh`)
**Vectors:** the bitline `v(bl_0_<N>)` at all three corners, plus
`v(precharge)` to show which half of the cycle is evaluate.
**Read it for:** `t_dis_50`, the 50% crossing, and the corner spread --
roughly 8 / 15 / 36 ns on the example macros. That one measurement is ~85% of
`access`, and the spread is the whole argument for characterising three
corners instead of derating one.

### `06-front-end.svg` -- the decoder polarity, shown rather than asserted
**Deck:** `char/periph_active_tt.sp` (`run_periphery_power.sh`)
**Vectors:** `v(clk0)`, the internal clock, the precharge net and one
wordline.
**Read it for:** `t_clk2pre`, and the selected wordline **falling** after
clk0 rises. That is what justifies the column deck holding every other
wordline at VDD.

### `07-backend-loads.svg` -- the CELL_TABLE's second axis is real
**Deck:** `char/backend_tt_{17225,689,2756}.sp` (`run_backend_delay.sh`)
**Vectors:** `v(dout0[2])` at each of the three output loads (1.7225 / 6.89 /
27.56 fF) and the bitline edge driving them.
**Read it for:** `t_bl2dout` and the output slew, three separate curves --
the `index_2` axis of the `.lib` is three measurements, not one number copied
three times.

### Doing it by hand

Any deck can be opened interactively; this is the same thing the script
automates:

```sh
ngspice examples/wrom0/char/col236_worst_case_parasitic.sp
ngspice 1 -> run
ngspice 2 -> plot v(precharge) v(bl_0_236)
```

A screenshot of that plot window is a perfectly good figure -- it is what
`05-col-discharge.png` was before the script existed. `hardcopy` just gets
the same picture on a white background and in vector form.

---

## 1b. Model screenshots -- taken by hand from the ngspice plot window

The main README walks the reader block by block, and each block carries one
screenshot of its own deck. These are **not** produced by
`run_waveform_capture.sh` -- open the deck interactively, `run`, `plot`, and
screenshot the plot window. The README prints the exact command above every
one of them; they are repeated here.

| file | deck | plot |
|---|---|---|
| `10-col-deck.png` | `col236_worst_case_parasitic.sp` | `v(precharge) v(bl_0_236)` |
| `11-periph-frontend.png` | `periph_active_tt.sp` | `v(clk0) v(wrom0_rom_row_decode_0/clk) v(wrom0_rom_row_decode_0/wl_0) v(wrom0_rom_column_decode_0/clk)` |
| `12-backend-dout.png` | `backend_tt_2756.sp` | `v(wrom0_rom_base_array_0/bl_0_236) v(dout0[2])` |
| `13-coldec.png` | `coldec_a0_tt.sp` | `v(wrom0_rom_column_decode_0/clk) v(wrom0_rom_column_decode_0/wl_0)` |
| `14-pincap.png` | `pincap_tt.sp` | `v(clk0) i(vpin1)` |
| `15-wl-slew.png` | `wlslew_tt.sp` | `v(clk0) v(wrom0_rom_row_decode_0/wl_0)` |
| `16-slew-sweep.png` | `periph_slew0_tt.sp` | `v(clk0) v(wrom0_rom_column_decode_0/clk)` |
| `17-col-energy.png` | `col236_energy_tt.sp` | `i(vvdd)` |
| `18-setup.png` | `periph_setup_tt.sp` | `v(addr0[0]) v(clk0)` |

Node names are from `wrom0`. The extracted netlist names nodes after
instances, so on another macro they change -- read them out of the deck's own
`.measure` lines:

```sh
grep -E "^\.meas|TARG" examples/<macro>/char/<deck>.sp
```

The precharge net is `<macro>_rom_column_decode_0/clk` in the periphery deck
and plain `precharge` in the column deck -- the same net, named by whichever
netlist the deck was cut from.

---

## 2. Layout screenshots -- Magic or KLayout

### `01-macro-floorplan.png`
**What:** the whole macro, zoomed to fit, with the seven top-level blocks
distinguishable.
**How:** open `<macro>.gds` (or `<macro>.mag`) and zoom to fit.
**Why:** the README's "what is modelled" table names the blocks one by one;
the reader needs to see where they sit. Label `rom_base_array`,
`rom_row_decode`, `rom_control_logic`, `rom_column_mux_array`,
`rom_column_decode`, `rom_bitline_inverter`, `rom_output_buffer` if your tool
can.

### `02-array-overview.png`
**What:** a zoom into `rom_base_array`, roughly 8x8 cells.
**Why:** shows the regularity, the bitline columns and the wordline rows.

### `03a-one-cell.png` / `03b-zero-cell.png`
**What:** `rom_base_one_cell` and `rom_base_zero_cell`, same zoom, shown side
by side in the README.
**Why:** the single most important pair of pictures in the repository. The
metal strap across the zero cell shorts source to drain -- that strap IS the
stored bit, and everything about the NAND chain follows from it.

### `04-column-strip.png` *(missing)*
**What:** a tall, narrow strip of one column, 10-15 cells.
**Why:** shows that cells abut and share diffusion, and that there is no
per-cell ground contact -- the reason the discharge path is one long series
chain instead of a transistor to ground.
