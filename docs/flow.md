# Requirements, the flow, and the files

What has to be installed, what each step of the flow produces, and which script writes which log.

[<- back to the README](../README.md)

---

## Requirements

> 📖 **Full toolchain installation, ngspice KLU solver details, Nix environment, and storage cleanup:** See [docs/requirements.md](requirements.md).

* Python 3.10+ (no third-party packages; the CLI uses modern type syntax)
* **ngspice with KLU** -- every deck selects KLU, and the runner rejects
  KLU-less builds or legacy-SPARSE fallback results
* **Magic** 8.3+ -- for parasitic extraction
* **Icarus Verilog** (`iverilog` + `vvp`) -- for behavioural model checks
* **OpenSTA** (`sta`) -- for consumer-side Liberty parsing
* sky130 PDK ngspice models
* an OpenRAM technology tree, for the extraction step only

| variable | default | purpose |
|---|---|---|
| `ROM_MACROS_DIR` | populated `<repo>/user`, otherwise `<repo>/examples` | macro tree; `shell.nix` explicitly selects `<repo>/user` |
| `ROM_OUT_DIR` | `<repo>/output` | where `lib/` and `verilog/` are written |
| `NGSPICE_BIN` | `ngspice` | ngspice binary |
| `MAGIC_BIN` | `magic` | magic binary |
| `IVERILOG_BIN` / `VVP_BIN` | `iverilog` / `vvp` | behavioural model validation |
| `STA_BIN` | `sta` | OpenSTA binary |
| `OPENRAM_TECH` | -- | required by `run_cap_extract.sh` |
| `PDK_ROOT` | `~/OpenLane/pdks` | where sky130A lives |
| `SKY130_LIB` | `$PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice` | model file |
| `JOBS` | `flow.py`: `4`; direct scripts: `min(cores, MemAvailable / ROM_JOB_MEM_GB)` | ngspice runs in flight. `--jobs`/`JOBS` is a fixed override; only direct scripts with `JOBS` unset use stage-specific auto-sizing |
| `ROM_JOB_MEM_GB` | `3` | per-job memory budget the default is computed from (the periphery decks' ~2.6 GB) |
| `LOADS` | `1.7225 6.89 27.56` | `.lib` CELL_TABLE output load points (fF) |
| `ROM_CORNERS` | `tt:1.8:25:34.1 ss:1.6:100:18.3 ff:1.95:-40:48.2` | corner:VDD:temp:fmax(MHz). `fmax` only scales the `P = E x f` summary column -- the real bound is `minimum_period` in the `.lib` |
| `PIN_GAP_THRESH` | `12.0` through `flow.py` / `run_pin_cap.sh` | maximum pin rise/fall capacitance gap in percent; `--pin-cap-gap` sets the same value |
| `SETTLE_MAX_PCT` | `1.0` | energy-cycle convergence limit; `PERIPH_SETTLE_MAX_PCT` and `COL_SETTLE_MAX_PCT` override it per stage |
| `PERIPH_NOISE_FLOOR_PJ` | `0.10` | periphery-only absolute energy-difference floor; below it, tiny idle energy is settled even when its relative percentage is large |
| `SKIP_STEP1` | `0` | direct `run_periphery_power.sh` only: set to `1` to reuse existing `cellgate_<corner>.log` files instead of measuring cell-gate C again |

## The flow

```sh
# 1) real parasitic C extraction (Magic; once per macro, slow)
./scripts/rom_char/run_cap_extract.sh wrom0        #  -> wrom0_cap_only.spice

# 2) column timing: bitline discharge + precharge, three corners
./scripts/rom_char/run_col_timing.sh               #  -> col<N>_worst_case_parasitic*.log

# 2b) optional: per-cell wire resistance, and a deck that includes it
python3 scripts/rom_char/gen_resistance_model.py wrom0
python3 scripts/rom_char/gen_col_tb_parasitic.py wrom0 --with-resistance

# 2c) the same deck on the BEST column -- the early bound, retain_rise/fall.
#     In both modes: with no log here the .lib carries no retain_* at all, and
#     a missing arc is not a conservative one the way a too-long hold is.
./scripts/rom_char/run_early_path.sh               #  -> col<N>_best_case_parasitic*.log

# 3) back-end delay + output slew, three corners x three loads
#    (re-runs step 2's column decks first, keeping the bitline waveform: the
#     back end is driven by that discharge replayed, not by a ramp fitted to
#     it. ~2 min a corner, cached in char/wave/bl_<corner>.txt)
./scripts/rom_char/run_backend_delay.sh            #  -> backend_<corner>_<load>.log

# 4) periphery energy (active/idle) + cell gate capacitance
JOBS=4 ./scripts/rom_char/run_periphery_power.sh   #  -> periph_{active,idle}_<corner>.log   (JOBS= only to override the automatic count)

# 5) address setup (needs the cellgate log from step 4)
./scripts/rom_char/run_addr_setup.sh               #  -> periph_setup_<corner>.log

# 6) column leakage and column energy
./scripts/rom_char/run_col_power.sh                #  -> col<N>_leak_<corner>.log
./scripts/rom_char/run_col_energy.sh               #  -> col<N>_energy_<corner>.log

# 6b) periphery leakage (one deck/corner, cs0 altered in-place, gmin-swept)
./scripts/rom_char/run_periphery_leak.sh           #  -> periph_leak_cs<n>_<corner>.total

# 6c) column decode vs the discharge it races, and the input pin capacitances
./scripts/rom_char/run_coldec_delay.sh             #  one transient/corner, 8 addresses
                                                   #  -> coldec_a<addr>_<corner>.log
./scripts/rom_char/run_pin_cap.sh                  #  -> pincap_<corner>.log

# 6d) --full ONLY, and expensive. Every .lib term below has a pessimistic
#     fallback that regen_rom_libs.sh announces when it fires, so the standard
#     mode gives a conservative library rather than a wrong one. `./flow.py
#     <macro> --full` runs these four in this order; run_hold_bisect needs
#     wlslew, and the other three need cellgate_<corner>.log from step 4.
./scripts/rom_char/run_wl_slew.sh                  #  -> wlslew_<corner>.log
./scripts/rom_char/run_hold_bisect.sh              #  -> hold_<corner>.log   (needs wlslew)
./scripts/rom_char/run_addr2wl.sh                  #  -> addr2wl_<corner>.log
./scripts/rom_char/run_slew_sweep.sh               #  -> periph_slew<n>_<corner>.log

# 7) write the .lib files (reads every log; nothing is entered by hand)
./scripts/rom_char/regen_rom_libs.sh               #  -> output/lib/<macro>_<CORNER>.lib

# 8) behavioural SystemVerilog
python3 scripts/rom_char/gen_macro_behavioral_v.py #  -> output/verilog/<macro>.sv

# 9) validate both deliverables (regen_rom_libs.sh already runs the
#    structural Liberty pass; this adds script, semantic, OpenSTA and SV tests)
./tests/run_tests.sh
```

Figures are not step 10. Nothing in this flow draws one: a waveform figure is
taken by a person, interactively, at ngspice's own plot window --
[`docs/img/README.md`](img/README.md) says why and gives the deck and the
`plot` line for each.

Every measurement/generation script except `run_cap_extract.sh` takes macro
names as arguments; with none, **every macro in the tree** is processed.
Extraction accepts exactly one macro, and `flow.py` loops over selected macros:

```sh
./scripts/rom_char/run_backend_delay.sh wrom1 wrom2
ROM_MACROS_DIR=/path/to/macros ./scripts/rom_char/regen_rom_libs.sh
```

The displayed order is the supported dependency order: the back end reuses
the column waveform; setup and pin capacitance need the cell-gate result;
the full-mode stages need cell-gate or wordline-slew logs. Liberty generation
needs the required measurement set, SystemVerilog needs Liberty, and the test
runner validates both.
`./flow.py <macro>` runs steps 1-7 in one command in standard mode, using safe
conservative fallbacks for address hold and clock slew.
`./flow.py <macro> --full` runs all steps including the 6d group, measuring
the address hold in the pin frame and clock-slew dependence.
`--pin-cap-gap <pct>` sets the target rise/fall settling gap quota (default 12%),
triggering iterative hold-time refinement if needed.
Column energy starts at 6 cycles and adds two per retry. Periphery energy starts
at 8 cycles, or 12 for macros with at least 128 rows, but loads ngspice only
once: a batch control block pauses at two-cycle boundaries and resumes the same
transient state until it settles. Earlier cycles are neither re-parsed nor
recomputed. Periphery accepts either a last-two-cycle gap at most 1% or an
absolute energy difference below 0.10 pJ. Both stop at their stage limit
(`COL_MAX_CYCLES=16`, `PERIPH_MAX_CYCLES=20` by default).

### Concurrency, memory budgeting, and job queues

**The unified flow defaults to four concurrent simulations.** Change it with `./flow.py <macro> --jobs <n>` or `JOBS=<n>`. `flow.py` exports that value to every stage, so a flow invocation has one explicit limit throughout.

When a `run_*.sh` stage is invoked directly and `JOBS` is unset, `common.sh` chooses `min(cores, MemAvailable / ROM_JOB_MEM_GB)`, with a 3 GB default budget and a fallback of 4 if detection fails. The count is sampled once and has a floor of two (unless the machine has only one CPU). Starting more jobs than memory can hold drives ngspice into swap and is usually slower.

**Not every deck costs 2.6 GB, and the stages say so.** A deck built out of one extracted column -- the column timing and energy decks, the hold bisection -- holds ~0.45 GB, so the same memory budget affords six times the processes; the back-end deck, which keeps only the read path, sits between them. For direct script use, each stage asks for its own footprint (`stage_jobs` in `common.sh`, `ROM_MEM_COLUMN` / `ROM_MEM_BACKEND` / `ROM_MEM_PERIPHERY`). An explicit `JOBS` -- including the value exported by `flow.py` -- wins over stage-specific auto-sizing.

**Work is taken from a rolling queue, not in batches.** Each stage keeps `JOBS` runs in flight and starts the next one the moment a slot frees. The earlier code launched `JOBS` runs and waited for *all* of them before starting the next batch, so every batch cost as much as its slowest member -- with SS three times slower than FF in the same batch, most of the machine sat idle most of the time. What still cannot overlap is stated where it happens: a bisection picks each point from the previous answer, and the decks a generator runs itself (the TT column and early-path decks) run inside their own macro's turn. The macros themselves never wait for each other.

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

The CLI can restart at a main phase or a named simulation stage:

```sh
./flow.py --list-steps
./flow.py <macro> --from-step 2 --jobs 2
./flow.py <macro> --from-step periphery-power
./flow.py <macro> --from-step pin-cap
./flow.py <macro> --full --from-step hold-bisect
./flow.py <macro> --from-step 3   # Liberty -> SystemVerilog -> tests
```

Here `1`-`5` mean the **CLI phases** (pre-flight, simulations, Liberty,
SystemVerilog, tests), not the measurement numbers above. Names select a
stage within the simulation phase. The selected stage and all subsequent
stages run again; earlier stages do not. Existing outputs must be retained.
A named simulation restart requires the extracted netlist; restarting after
`periphery-power` also checks that the required corner's `cellgate` logs exist,
and `hold-bisect` requires the earlier `wlslew` logs. These checks detect missing
files, not whether every earlier measurement matches new parameter choices.
Liberty generation retains its existing provenance validation.

Change parameters on the restart command, and keep `--full` for a full run.
If the change affects earlier measurements too, restart from the earliest
affected stage. No automatic checkpoint or per-corner completion state is
stored. See [Continuing after a failed step](../README.md#continuing-after-a-failed-step).

| symptom | cause |
|---|---|
| `regen_rom_libs.sh` prints `missing measurement (...)` | that step has not been run, or its ngspice run failed -- the message names the term |
| `regen_rom_libs.sh` prints `NOT REGENERATED -- ... not output of the current flow` | those logs carry no `.prov` stamp, or it no longer matches the deck/netlist on disk. Re-run the `run_*.sh` the report names; logs from before 2026-09-24 are unstamped and are all refused |
| `NOTHING WAS WRITTEN -- no corner had a complete set of current logs` | nothing in the tree was produced by the flow as it stands. Any `.lib` in `output/lib` is from an earlier run |
| `no setup measurement -> using pessimistic bound` | step 5 was skipped; the `.lib` is safe but pessimistic |
| `ERROR: ... _cap_only.spice does not exist` | step 1 has not been run for that macro |
| `no cellgate log (run run_periphery_power.sh first)` | step 5 was run before step 4 |
| `no periphery leakage log -> cell_leakage_power covers the ARRAY ONLY` | step 6b has not been run; the clock tree, decoders, wordline drivers and the read back end are scored as zero |
| a slice prints `NOT CONVERGED` in `run_periphery_leak.sh` | the adaptive sweep reached `GMIN_FLOOR` without two stable intervals; inspect the log, then lower the floor only if the solver remains numerically trustworthy |
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
| `gen_resistance_model.py` | per-cell series wire resistance: Magic per cell + analytic + fallback to shared `mags/` or generic baseline |
| `make_corner_variant.py` | SS/FF variant of the TT deck (identical circuit) |
| `run_col_timing.sh` | ties those two together: column timing at three corners |
| `gen_backend_delay_tb.py` / `run_backend_delay.sh` | bitline -> `dout0` and output slew vs load |
| `gen_cell_gate_tb.py` | equivalent cell gate capacitance (`C = Q(VDD)/VDD`) |
| `gen_periphery_power_tb.py` / `run_periphery_power.sh` | periphery energy (cs0=0/1), front-end delay, setup |
| `run_addr_setup.sh` | `addr0` -> decoder NAND input setup measurement |
| `run_pin_cap.sh` | input pin capacitance per pin, `C = Q(VDD)/VDD`, both edges |
| `pincap_settle_step.py` | iterative pin capacitance settling step helper: evaluates rise/fall gap and scales hold time per pin (called by `run_pin_cap.sh`) |
| `periph_settle_step.py` | periphery energy convergence: relative gap, absolute noise floor and final provenance verdict; the generated deck now owns persistent stop/resume |
| `run_coldec_delay.sh` | column decode vs bitline discharge -- the race that sets the middle term of `access` |
| `run_wl_slew.sh` | wordline fall delay and slew, real driver and real load |
| `run_hold_bisect.sh` | the address hold: bisects the cut time at the cell nearest the bitline |
| `gen_addr_hold_tb.py` | hold deck generator (used by `run_hold_bisect.sh`) |
| `run_addr2wl.sh` | `addr0` -> the wordline it drops, which carries the hold into the clk0 pin's time frame |
| `run_slew_sweep.sh` | the measured `index_1` (clk0 input slew) axis |
| `run_early_path.sh` | the fastest column, for the early/retain bound |
| `gen_random_read_energy.py` | active read energy: samples the address space and counts the discharging columns per read from the netlist's own cell types |
| `gen_col_power_tb.py` / `run_col_power.sh` / `run_col_energy.sh` | column leakage (`.op`) and column energy |
| `gen_periphery_leak_tb.py` / `run_periphery_leak.sh` | periphery leakage: one slice per block x a count, with a gmin sweep |
| `archive/` | retired/standalone prototype scripts (`gen_power_tb.py`, `run_pin_cap_iter.py`, `run_addr_hold.sh`, `run_periphery_power_dynamic.sh`) |
| `gen_rom_lib.py` | LEF + measured values -> Liberty |
| `gen_macro_behavioral_v.py` | behavioural SystemVerilog (`.sv`) model that checks constraints and reports timing violations |
| `regen_rom_libs.sh` | the top-level script that ties the flow together |
| `spice_utils.py` | shared SPICE parsing, SI-unit conversion and block helpers used by deck generators |
| `tests/` | three suites / eleven checks for scripts, generated `.lib` files and `.sv` models -- see [`tests/README.md`](../tests/README.md) |

Figures live in `docs/img/`. The waveforms are screenshots of ngspice's own
plot window -- no plotting tool sits between the simulation and the picture,
and no script takes them either: they are the independent check on what the
flow computed, so a person captures them. The layout screenshots are yours to
take too.
[`docs/img/README.md`](img/README.md) says exactly what each figure has
to show and which command produces it.
