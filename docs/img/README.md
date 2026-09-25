# Figures for the main README

Two kinds of picture, and **neither is drawn by a plotting tool**:

| kind | what it is | who makes it |
|---|---|---|
| **waveforms** | ngspice's own plot window, screenshotted | you, at the simulator |
| **layout** (01-04) | screenshots of the layout you already have | you, in Magic or KLayout |

There is no intermediate plotting step and there is not meant to be one. A
curve in this directory is the picture ngspice draws in its plot window -- not
a redrawing of numbers that came out of it.

**And nothing automated may produce one.** No script in this repository
captures a waveform, and none is to be added: not a `hardcopy` wrapper, not a
matplotlib call, not an AI. The figures are the independent evidence that the
committed numbers describe the circuit somebody actually simulated, and
evidence produced by the same machinery it is meant to check is not evidence.
A human runs the deck, looks at the plot window and keeps the picture.
`run_waveform_capture.sh`, which automated 05/06/07 with ngspice's own
`hardcopy`, was removed on 2026-09-25 for that reason.

Until a file exists its reference in the README shows as a broken image --
that is intentional, it says what is still missing.

---

## 1. Waveforms -- you take them at the simulator

The characterisation decks ask only for `.measure` results, so ngspice throws
the waveform away when it runs in batch. Open the deck interactively instead
and the plot window has it:

```sh
ngspice examples/wrom0/char/col236_worst_case_parasitic.sp
ngspice 1 -> run
ngspice 2 -> plot v(precharge) v(bl_0_236)
```

Then screenshot the window. That is the whole procedure, for every figure
below and every figure in section 1b -- they differ only in the deck and the
`plot` line, and both are printed with each entry.

Node names are the extracted netlist's, so they are named after instances
(`wrom0_rom_row_decode_0/wl_0`) and change with the macro; read them out of
the deck's own `.measure` lines rather than copying them from here.

The three entries below were `.svg` when a script drew them with `hardcopy`.
A screenshot is a `.png` and just as good a figure -- `hardcopy` only moved
the same picture onto white paper and into vector form.

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

## 1b. The per-block figures in the main README

The main README walks the reader block by block, and each block carries one
screenshot of its own deck, taken the way section 1 describes. The README
prints the exact command above every one of them; they are repeated here.

| file | deck | plot | captured |
|---|---|---|---|
| `10-col-deck.png` | `col236_worst_case_parasitic.sp` | `v(precharge) v(bl_0_236)` | yes |
| `11-periph-frontend.png` | `periph_active_tt.sp` | `v(clk0) v(wrom0_rom_row_decode_0/clk) v(wrom0_rom_row_decode_0/wl_0) v(wrom0_rom_column_decode_0/clk)` | yes |
| `12-backend-dout.png` | `backend_tt_2756.sp` | `v(wrom0_rom_base_array_0/bl_0_236) v(dout0[2])` | yes |
| `13-coldec.png` | `coldec_a0_tt.sp` | `v(wrom0_rom_column_decode_0/clk) v(wrom0_rom_column_decode_0/wl_0)` | yes, but from `periph_active_tt.sp` -- see below |
| `14-pincap.png` | `pincap_tt.sp` | `v(clk0) i(vpin1)` | yes |
| `15-wl-slew.png` | `wlslew_tt.sp` | `v(clk0) v(wrom0_rom_row_decode_0/wl_0)` | no |
| `16-slew-sweep.png` | `periph_slew0_tt.sp` | `v(clk0) v(wrom0_rom_column_decode_0/clk)` | no |
| `17-col-energy.png` | `col236_energy_tt.sp` | `i(vvdd)` | yes |
| `18-setup.png` | `periph_setup_tt.sp` | `v(addr0[0]) v(clk0)` | no |

The committed `13-coldec.png` shows the right two vectors but was taken from
`periph_active_tt.sp`, which instantiates the same `rom_column_decode` -- its
window title says so, and the README caption says so too. Re-capture it from
`coldec_a0_tt.sp` and the caveat in the caption goes away.

The six captured ones are the plot window as ngspice draws it -- black paper,
title bar and all -- not `hardcopy` output. That is fine per section 1 above;
`hardcopy` only moves the same picture onto white and into vector form.

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

**These are REPRESENTATIVE, and the README says so where they appear.** Unlike
the waveforms above -- which are ngspice's own output for a named example
macro and are reproducible with the command printed beside each one -- a
layout screenshot is a picture of whatever macro was open in the viewer. The
ones committed here come from a ROM of the same architecture, built by the
same OpenRAM `rom_compiler`, but NOT from `wrom0`..`wrom3`: the block labels
in them carry that macro's own prefix, which is exactly how a reader can tell.

That distinction has to survive, because the prose around these figures is
full of numbers -- chain lengths, cell counts, block names -- and every one of
them is read out of the example macros' netlists and logs, never off a
picture. A reader who takes the array shot as the example macro will try to
count transistors in it and get a different answer than the text gives. If you
replace these with shots of your own macro, say which macro in the README note
rather than deleting the note.

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
