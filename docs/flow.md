# Requirements, the flow, and the files

What has to be installed, what each step of the flow produces, and which script writes which log.

[<- back to the README](../README.md)

---

## Requirements

* Python 3.8+ (no third-party packages)
* **ngspice** -- for the measurement runs
* **Magic** 8.3+ -- for parasitic extraction
* sky130 PDK ngspice models
* an OpenRAM technology tree, for the extraction step only

| variable | default | purpose |
|---|---|---|
| `ROM_MACROS_DIR` | `<repo>/examples` | macro tree |
| `ROM_OUT_DIR` | `<repo>/output` | where `lib/` and `verilog/` are written |
| `NGSPICE_BIN` | `ngspice` | ngspice binary |
| `MAGIC_BIN` | `magic` | magic binary |
| `OPENRAM_TECH` | -- | required by `run_cap_extract.sh` |
| `PDK_ROOT` | `~/OpenLane/pdks` | where sky130A lives |
| `SKY130_LIB` | `$PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice` | model file |
| `JOBS` | `4` | parallel ngspice runs |
| `LOADS` | `1.7225 6.89 27.56` | `.lib` CELL_TABLE output load points (fF) |
| `ROM_CORNERS` | `tt:1.8:25:34.1 ss:1.6:100:18.3 ff:1.95:-40:48.2` | corner:VDD:temp:fmax(MHz). `fmax` only scales the `P = E x f` summary column -- the real bound is `minimum_period` in the `.lib` |

## The flow

```sh
# 1) real parasitic C extraction (Magic; once per macro, slow)
./scripts/rom_char/run_cap_extract.sh wrom0        #  -> wrom0_cap_only.spice

# 2) column timing: bitline discharge + precharge, three corners
./scripts/rom_char/run_col_timing.sh               #  -> col<N>_worst_case_parasitic*.log

# 2b) optional: per-cell wire resistance, and a deck that includes it
python3 scripts/rom_char/gen_resistance_model.py wrom0
python3 scripts/rom_char/gen_col_tb_parasitic.py wrom0 --with-resistance

# 3) back-end delay + output slew, three corners x three loads
./scripts/rom_char/run_backend_delay.sh            #  -> backend_<corner>_<load>.log

# 4) periphery energy (active/idle) + cell gate capacitance
JOBS=4 ./scripts/rom_char/run_periphery_power.sh   #  -> periph_{active,idle}_<corner>.log

# 5) address setup (needs the cellgate log from step 4)
./scripts/rom_char/run_addr_setup.sh               #  -> periph_setup_<corner>.log

# 6) column leakage and column energy
./scripts/rom_char/run_col_power.sh                #  -> col<N>_leak_<corner>.log
./scripts/rom_char/run_col_energy.sh               #  -> col<N>_energy_<corner>.log

# 6b) periphery leakage (one slice per block x a count, gmin-swept)
./scripts/rom_char/run_periphery_leak.sh           #  -> periph_leak_cs<n>_<corner>.total

# 6c) column decode vs the discharge it races, and the input pin capacitances
./scripts/rom_char/run_coldec_delay.sh             #  -> coldec_a<addr>_<corner>.log
./scripts/rom_char/run_pin_cap.sh                  #  -> pincap_<corner>.log

# 6d) OPTIONAL, and expensive. Every .lib term below has a pessimistic
#     fallback that regen_rom_libs.sh announces when it fires, so skipping
#     these gives a conservative library rather than a wrong one.
./scripts/rom_char/run_slew_sweep.sh               #  -> periph_slew<n>_<corner>.log
./scripts/rom_char/run_wl_slew.sh                  #  -> wlslew_<corner>.log
./scripts/rom_char/run_hold_bisect.sh              #  -> hold_<corner>.log   (needs wlslew)
./scripts/rom_char/run_addr2wl.sh                  #  -> addr2wl_<corner>.log

# 7) write the .lib files (reads every log; nothing is entered by hand)
./scripts/rom_char/regen_rom_libs.sh               #  -> output/lib/<macro>_<CORNER>.lib

# 7b) validate what was just written (regen_rom_libs.sh already runs the
#     structural pass; this adds the ROM semantics and OpenSTA if installed)
./tests/run_tests.sh

# 8) behavioural Verilog
python3 scripts/rom_char/gen_macro_behavioral_v.py #  -> output/verilog/<macro>.v

# 9) optional: redraw the waveform figures from what was just measured
./scripts/rom_char/run_waveform_capture.sh   # ngspice hardcopy -> docs/img/*.svg
```

Every script takes macro names as arguments; with none, **every macro in the
tree** is processed:

```sh
./scripts/rom_char/run_backend_delay.sh wrom1 wrom2
ROM_MACROS_DIR=/path/to/macros ./scripts/rom_char/regen_rom_libs.sh
```

Steps 2-6 are independent of each other (5 depends on 4, and 6d's hold bisect
depends on its own `wlslew` run); step 7 needs them all. `./flow.py <macro>`
runs steps 1-7 in one command, except the optional 6d group -- run those by
hand and re-run `regen_rom_libs.sh` to fold them in. Step 1 is the slow one (tens of minutes); steps 4 and 5 take a few minutes
per corner, the rest are seconds.

### Step 7 reads only what this flow produced

A log in `<macro>/char` outlives the netlist it was measured on, the deck it
came from and the run that wrote it. So every run writes a stamp beside its
log, `<log>.prov`: the deck, the log and the macro netlist by **content hash**
(mtimes are rewritten by a checkout or a copy, and say nothing about what is
in a file). A run that later turns out to be unusable -- unsettled, or one
whose re-run died leaving the previous log in place -- gets an `invalid` line
in that stamp saying why.

`regen_rom_libs.sh` checks all of it before reading a single value. An
unstamped or mismatched file is **not** treated as a missing one: missing has
documented fallbacks and the `.lib` header states each of them, while a
rejected file fails that corner outright -- no `.lib` is written for it, the
report groups the files by the `run_*.sh` that produces them, and the script
exits non-zero. Re-run the stage it names; there is no way to tell it to
accept an old log.

Logs characterised before 2026-09-24 carry no stamp, so they are all refused
until their stage is re-run.

### When something goes wrong

| symptom | cause |
|---|---|
| `regen_rom_libs.sh` prints `missing measurement (...)` | that step has not been run, or its ngspice run failed -- the message names the term |
| `regen_rom_libs.sh` prints `NOT REGENERATED -- ... not output of the current flow` | those logs carry no `.prov` stamp, or it no longer matches the deck/netlist on disk. Re-run the `run_*.sh` the report names; logs from before 2026-09-24 are unstamped and are all refused |
| `NOTHING WAS WRITTEN -- no corner had a complete set of current logs` | nothing in the tree was produced by the flow as it stands. Any `.lib` in `output/lib` is from an earlier run |
| `no setup measurement -> using pessimistic bound` | step 5 was skipped; the `.lib` is safe but pessimistic |
| `ERROR: ... _cap_only.spice does not exist` | step 1 has not been run for that macro |
| `no cellgate log (run run_periphery_power.sh first)` | step 5 was run before step 4 |
| `no periphery leakage log -> cell_leakage_power covers the ARRAY ONLY` | step 6b has not been run; the clock tree, decoders, wordline drivers and the read back end are scored as zero |
| a slice prints `NOT CONVERGED` in `run_periphery_leak.sh` | the gmin axis does not reach far enough down -- widen `GMINS` |
| `WARNING: config says ... columns, netlist has ...` | the config and the layout disagree; the netlist is used |
| a measurement is `FAILED` in a summary table | the ngspice run did not converge -- look at the `.log` in `char/` |

## Files

| file | job |
|---|---|
| `rom_paths.py` | path resolution + geometry (single source of truth), pre-flight check |
| `common.sh` | shared base for `run_*.sh`: paths, corners, `macro_list`, `load_geom`, `meas`, and the `<log>.prov` stamp that says which flow produced a log |
| `find_worst_column.py` | finds the worst column and its series chain from the netlist |
| `rom_explore.py` | array structure summary, column histogram, row map |
| `run_cap_extract.sh` | capacitance-only parasitic extraction with Magic |
| `gen_col_tb_parasitic.py` | isolated testbench for the worst column (graph walk, name independent) |
| `gen_resistance_model.py` | per-cell series wire resistance: Magic per cell + analytic where it segfaults |
| `make_corner_variant.py` | SS/FF variant of the TT deck (identical circuit) |
| `run_col_timing.sh` | ties those two together: column timing at three corners |
| `gen_backend_delay_tb.py` / `run_backend_delay.sh` | bitline -> `dout0` and output slew vs load |
| `gen_cell_gate_tb.py` | equivalent cell gate capacitance (`C = Q(VDD)/VDD`) |
| `gen_periphery_power_tb.py` / `run_periphery_power.sh` | periphery energy (cs0=0/1), front-end delay, setup |
| `run_addr_setup.sh` | `addr0` -> decoder NAND input setup measurement |
| `run_pin_cap.sh` | input pin capacitance per pin, `C = Q(VDD)/VDD`, both edges |
| `run_coldec_delay.sh` | column decode vs bitline discharge -- the race that sets the middle term of `access` |
| `run_wl_slew.sh` | wordline fall delay and slew, real driver and real load |
| `run_hold_bisect.sh` | the address hold: bisects the cut time at the cell nearest the bitline |
| `gen_addr_hold_tb.py` / `run_addr_hold.sh` | exploratory hold sweep; its verdict goes to stdout, the per-point artefacts are not read back |
| `run_addr2wl.sh` | `addr0` -> the wordline it drops, which carries the hold into the clk0 pin's time frame |
| `run_slew_sweep.sh` | the measured `index_1` (clk0 input slew) axis |
| `run_early_path.sh` | the fastest column, for the early/retain bound |
| `gen_random_read_energy.py` | active read energy: samples the address space and counts the discharging columns per read from the netlist's own cell types |
| `gen_col_power_tb.py` / `run_col_power.sh` / `run_col_energy.sh` | column leakage (`.op`) and column energy |
| `gen_periphery_leak_tb.py` / `run_periphery_leak.sh` | periphery leakage: one slice per block x a count, with a gmin sweep |
| `gen_power_tb.py` | **not part of the flow** -- a brute-force whole-macro power deck no script calls. Kept only for an occasional by-hand cross-check on a small macro; its cost follows the array, so it is not runnable on a real ROM (see the whole-macro reference note in the README) |
| `gen_rom_lib.py` | LEF + measured values -> Liberty |
| `gen_macro_behavioral_v.py` | behavioural `.v` that reports timing violations |
| `regen_rom_libs.sh` | the top-level script that ties the flow together |
| `run_waveform_capture.sh` | re-runs a measured deck with the waveform kept; ngspice's own `hardcopy` writes the figure |
| `tests/` | validation of the generated `.lib` -- see [`tests/README.md`](../tests/README.md) |

Figures live in `docs/img/`. The waveforms are ngspice's own `hardcopy` of
its own runs -- no plotting tool sits between the simulation and the picture
-- and `run_waveform_capture.sh` redraws them from the decks that were just
measured. The layout screenshots are yours to take.
[`docs/img/README.md`](img/README.md) says exactly what each figure has
to show and which command produces it.
