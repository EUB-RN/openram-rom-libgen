# Your own ROM (`user/`)

Put your own OpenRAM ROM macros under this directory and the flow will
generate the Liberty (`.lib`) and behavioural SystemVerilog (`.sv`) models for
them.

This is the directory `shell.nix` points `ROM_MACROS_DIR` at, so inside
`nix-shell` a macro placed here is found without configuring the macro tree. The
macros in `examples/` are study material; to work on those instead, set
`ROM_MACROS_DIR` to that tree by hand.

The shell supplies the tools, not an OpenRAM source checkout. If the macro has
no `<macro>_cap_only.spice`, export
`OPENRAM_TECH=/path/to/OpenRAM/technology` so Magic can extract it from GDS.

---

## Directory layout

One sub-directory per ROM, named after the macro:

```text
user/
└── <macro>/
    ├── <macro>.sp           REQUIRED: SPICE netlist -- geometry and the critical path come from here
    ├── <macro>.lef          REQUIRED: LEF -- pin list, directions and area
    ├── <macro>.gds          OPTIONAL: needed only for real parasitic C extraction
    ├── mags/                OPTIONAL: base cell layouts (.mag) -- falls back to repo mags/
    ├── config/<macro>.py    OPTIONAL: word_size / words_per_row cross-check
    │   or <macro>.py        OPTIONAL: the same config at the macro root
    └── rom_configs/
        └── <macro>.bin      OPTIONAL: ROM contents; sets the word count for the model
```

> **Example:** for a macro named `rom_1024x32`, having
> `user/rom_1024x32/rom_1024x32.sp` and `user/rom_1024x32/rom_1024x32.lef`
> is enough to start.

Check a macro before running anything:

```bash
python3 scripts/rom_char/rom_paths.py --check <macro>
```

This pre-flight checks the inputs and expected ROM architecture. It does not
run DRC/LVS and does not certify that the GDS is physically clean.

---

## Running it

### A: inside the isolated Nix environment (recommended)

Run from the repository root, not from here:

```bash
nix develop        # flakes -- needs no channel configured
# or: nix-shell    # classic
./flow.py <macro>
```

### B: with a local Python

```bash
./flow.py <macro>
```

Or point it straight at a directory:

```bash
./flow.py user/<macro>
```

`./flow.py` with no macro name processes **every** macro found under the
macro tree, not just the first one.

There is a second mode:

```bash
./flow.py <macro> --full
```

The default measures every `.lib` term but two -- the address hold and the
`index_1` clock-slew axis -- and each of those two falls back to a value that
is pessimistic rather than wrong, announced in the `.lib` header and on
stderr. `--full` adds the four stages that measure them (`run_wl_slew.sh`,
`run_hold_bisect.sh`, `run_addr2wl.sh`, `run_slew_sweep.sh`), so those two
optional timing terms no longer use fallbacks. Other warnings or fallbacks
reported by the generated file still have to be resolved. It costs roughly an
afternoon per macro against tens of minutes.

`--pin-cap-gap <pct>` configures the target rise/fall capacitance settling gap
quota (default 12%), iteratively increasing pin hold times until slow internal
switching tails finish settling.

If a stage fails, `flow.py` prints a restart command. `./flow.py --list-steps`
shows the stable phase/stage names accepted by `--from-step`; keep `--full`
when restarting one of the four full-mode stages.

Both modes run everything else, `run_early_path.sh` included: it has no
pessimistic fallback -- without it the `.lib` carries no `retain_*` arcs at
all -- so it is not part of the choice.

The README has [the reasoning behind the
split](../README.md#the-two-modes-and-why-the-second-one-exists);
[docs/flow.md](../docs/flow.md) has the full step-by-step flow.

---

## Output (`output/`)

When the run finishes the deliverables are written to `output/`:

- **`output/lib/<macro>_TT_1p8V_25C.lib`** — typical (TT) corner
- **`output/lib/<macro>_SS_1p6V_100C.lib`** — slow (SS) corner
- **`output/lib/<macro>_FF_1p95V_n40C.lib`** — fast (FF) corner
- **`output/verilog/<macro>.sv`** — behavioural SystemVerilog carrying the measured delays

Treat these as usable deliverables only after `tests/run_tests.sh` passes for
the generated libraries and models. Physical DRC/LVS remains a separate
requirement; the characterization flow does not turn a failing layout into a
sign-off-clean macro.
