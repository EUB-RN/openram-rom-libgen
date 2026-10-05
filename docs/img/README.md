# Documentation figures

Waveform images are screenshots of interactive ngspice runs. Layout images are
screenshots from Magic or KLayout. They are supporting evidence, not generated
deliverables.

[<- back to the README](../../README.md)

## Inventory

| file | source | purpose |
|---|---|---|
| `00-flow.svg` | flow diagram | characterization stages |
| `01-macro-floorplan.png` | layout viewer | seven top-level blocks |
| `02-array-overview.png` | layout viewer | array organization |
| `03a-one-cell.png` | layout viewer | programmed one cell |
| `03b-zero-cell.png` | layout viewer | strapped zero cell |
| `example_one_col.png` | layout viewer | representative column strip |
| `05-col-discharge.png` | column deck | bitline discharge and precharge |
| `10-col-deck.png` | `col236_worst_case_parasitic.sp` | worst-column timing |
| `11-periph-frontend.png` | `periph_active_tt.sp` | clock, precharge, and wordline |
| `12-backend-dout.png` | `backend_tt_2756.sp` | bitline-to-output path |
| `13-coldec.png` | periphery deck | column-decoder polarity; recapture from `coldec_a0_tt.sp` when needed |
| `14-pincap.png` | `pincap_tt.sp` | pin voltage/current |
| `15-wl-slew.png` | `wlslew_tt.sp` | wordline polarity and edge shape; use the log for settled-cycle values |
| `16-slew-sweep.png` | `periph_slew0_tt.sp` | input-slew sweep |
| `17-col-energy.png` | `col236_energy_tt.sp` | supply current |
| `18-setup.png` | `periph_setup_tt.sp` | address setup race |
| `19-waveform-timing.png` | `tb_wrom0_wave.v` | Liberty timing on a legal read |
| `20-addr-hold.png` | hold-bisection deck | address hold cut |
| `21-addr2wl.png` | `addr2wl_tt.sp` | address-to-wordline delay |
| `22-cellgate.png` | `cellgate_tt.sp` | cell-gate displacement current |
| `23-early-path.png` | `col10_best_case_parasitic.sp` | fastest-column retain bound |
| `rom_wpr_delay_comparison.png` | layout viewer | `words_per_row` geometry comparison |

Front-end and back-end overlay images are not part of the current inventory;
the main documentation does not reference them.

## Reproducing a waveform

Open the matching deck, run it, and plot the nodes named by its `.measure`
statements. For example:

```text
ngspice examples/wrom0/char/col236_worst_case_parasitic.sp
ngspice 1 -> run
ngspice 2 -> plot v(precharge) v(bl_0_236)
```

Extracted node names include the macro instance name and may differ for another
macro. Inspect the deck instead of copying a `wrom0` node name:

```bash
grep -E '^\.meas|TARG' examples/<macro>/char/<deck>.sp
```

## Layout provenance

The committed layout screenshots illustrate the same OpenRAM ROM architecture
but are not asserted to be the `wrom0`-`wrom3` layouts. Numeric claims in the
documentation come from netlists and measurement logs, not from counting
features in these screenshots.
