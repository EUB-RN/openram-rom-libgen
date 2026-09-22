# Figures for the main README

Nothing here is drawn by hand. Every figure is either a screenshot of the
layout you already have, or a plot of measurements this flow produced.

There are three kinds, and only one of them asks anything of you:

| kind | who makes it | effort |
|---|---|---|
| **plots of logs** (08, 09, 12, 13) | `python3 docs/img/make_figures.py` | none -- the logs are already there |
| **waveforms** (05, 06, 07) | `scripts/rom_char/run_waveform_capture.sh` then `make_figures.py` | one re-run per deck, a few minutes |
| **layout** (01-04) | you, in Magic or KLayout | four screenshots, once per macro family |

Until a file exists its reference in the README shows as a broken image --
that is intentional, it says what is still missing.

Naming: keep the numeric prefix, use PNG, keep the width under ~1600 px.

---

## 1. Plots of numbers already measured -- no simulator

```sh
python3 docs/img/make_figures.py          # every macro it can find
python3 docs/img/make_figures.py wrom0    # just one
```

Each of these parses the same `.log` files `gen_rom_lib.py` reads, so a
re-characterisation moves the figures with it. A figure whose run is missing
is skipped, not faked.

| file | what it shows | fed by |
|---|---|---|
| `08-energy-settling.png` | charge drawn in cycle 2 vs cycle 3, both decks, three corners. Equal bars are the settling proof; the label is the gap. | `periph_active_*.log`, `col<N>_energy_*.log` |
| `09-chain-vs-access.png` | measured bitline delay against the number of series transistors in the worst column, with the per-corner cost of one more device. | `col<N>_worst_case_parasitic*.log` |
| `12-gmin-sweep.png` | every periphery slice's leakage across four decades of gmin. Flat = converged; sloped = the simulator talking. | `periph_leak_cs0_tt_g*.log` |
| `13-hold-sweep.png` | the read value against when the address is allowed to move. The smallest cut the read survives is the hold requirement. | `char/hold/cut*_tt.log` (`run_addr_hold.sh`) |

---

## 2. Waveforms -- one re-run per deck

**This is the part people ask about: which plots do I need out of ngspice?**

The answer is three, and you do not have to drive ngspice by hand to get
them. The characterisation decks ask only for `.measure` results, so ngspice
discards the waveform; `run_waveform_capture.sh` copies each deck, inserts a
`.save` of the few nodes the figure needs plus a `.control` block that writes
them to CSV, and re-runs it:

```sh
./scripts/rom_char/run_waveform_capture.sh wrom0   # writes <macro>/char/wave/*.csv
python3 docs/img/make_figures.py wrom0             # draws 05, 06, 07 from them
```

The node names are read out of each deck's own `.measure` lines, because the
extracted netlist names nodes after instances
(`wrom0_rom_row_decode_0/wl_0`) and those change with the macro.

### `05-col-discharge.png` -- the biggest term of `access`
**Deck:** `char/col<N>_worst_case_parasitic{,_ss,_ff}.sp` (`run_col_timing.sh`)
**Signals:** `v(precharge)` and the bitline `v(bl_0_<N>)`, three corners on
one pair of axes.
**Mark:** the 50% crossing (`t_dis_50`) and the 99% recharge (`t_pre_99`).
**Why:** this one measurement is ~85% of `access`, and the corner spread
(roughly 8 / 15 / 36 ns on the example macros) is the whole argument for
characterising three corners instead of derating one.

### `06-front-end.png` -- the decoder polarity, shown rather than asserted
**Deck:** `char/periph_active_tt.sp` (`run_periphery_power.sh`)
**Signals:** `v(clk0)`, the internal clock, the precharge net, and one
wordline.
**Mark:** `t_clk2pre`, and the wordline **falling** after `clk0` rises.
**Why:** the selected wordline goes LOW during evaluate. That is what
justifies the column deck holding every other wordline at VDD, and it is
worth seeing once rather than taking on trust.

### `07-backend-loads.png` -- the CELL_TABLE's second axis is real
**Deck:** `char/backend_tt_{17225,689,2756}.sp` (`run_backend_delay.sh`)
**Signals:** the driving bitline edge and `v(dout0[2])`, one trace per load
(1.7225 / 6.89 / 27.56 fF).
**Mark:** `t_bl2dout` and the 10-90% output slew.
**Why:** it shows the `index_2` axis of the `.lib` is three measurements and
not one number copied three times.

### Doing it by hand instead

If you would rather drive ngspice yourself -- to look at a node the capture
script does not save, say -- the same trick in one command:

```sh
awk '/^\.end$/{print ".save v(precharge) v(bl_0_236)";
                print ".control"; print "run";
                print "wrdata /tmp/col.csv v(precharge) v(bl_0_236)";
                print ".endc"} {print}' \
    examples/wrom0/char/col236_worst_case_parasitic.sp > /tmp/col.sp
ngspice -b -o /tmp/col.log /tmp/col.sp
```

`.save` is not optional on these decks: without it ngspice keeps every node
of the extracted netlist and the raw file runs to gigabytes. `wrdata` writes
plain columns (`time value time value ...`), which is why `make_figures.py`
can read them with no SPICE library at all.

An interactive `ngspice examples/.../col236_worst_case_parasitic.sp` followed
by `run` and `plot v(precharge) v(bl_0_236)` gets you the same picture on
screen, and a screenshot of that window is a perfectly good figure -- but it
carries ngspice's own black background and unlabelled axes, so prefer the CSV
route for anything that goes in the README.

---

## 3. Layout screenshots -- Magic or KLayout

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
**What:** `rom_base_one_cell` and `rom_base_zero_cell`, same zoom, side by
side in the README.
**Why:** the single most important pair of pictures in the repository. The
metal strap across the zero cell shorts source to drain -- that strap IS the
stored bit, and everything about the NAND chain follows from it.

### `04-column-strip.png` *(missing)*
**What:** a tall, narrow strip of one column, 10-15 cells.
**Why:** shows that cells abut and share diffusion, and that there is no
per-cell ground contact -- the reason the discharge path is one long series
chain instead of a transistor to ground.
