# Your own ROM (`user/`)

Put your own OpenRAM ROM macros under this directory and the flow will
generate the Liberty (`.lib`) and behavioural Verilog (`.v`) models for them.

This is the directory `shell.nix` points `ROM_MACROS_DIR` at, so inside
`nix-shell` a macro placed here is found with no further configuration. The
macros in `examples/` are study material; to work on those instead, set
`ROM_MACROS_DIR` to that tree by hand.

---

## Directory layout

One sub-directory per ROM, named after the macro:

```text
user/
└── <macro>/
    ├── <macro>.sp           REQUIRED: SPICE netlist -- geometry and the critical path come from here
    ├── <macro>.lef          REQUIRED: LEF -- pin list, directions and area
    ├── <macro>.gds          OPTIONAL: needed only for real parasitic C extraction
    ├── config/<macro>.py    OPTIONAL: word_size / words_per_row cross-check
    └── rom_configs/
        └── <macro>.bin      OPTIONAL: ROM contents; sets the word count for the Verilog model
```

> **Example:** for a macro named `rom_1024x32`, having
> `user/rom_1024x32/rom_1024x32.sp` and `user/rom_1024x32/rom_1024x32.lef`
> is enough to start.

Check a macro before running anything:

```bash
python3 scripts/rom_char/rom_paths.py --check <macro>
```

---

## Running it

### A: inside the isolated Nix environment (recommended)

```bash
nix-shell
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

Note what `flow.py` does *not* run: the address-hold measurement
(`run_wl_slew.sh` + `run_hold_bisect.sh` + `run_addr2wl.sh`) and the measured
input-slew axis (`run_slew_sweep.sh`). Their absence is announced and falls
back to a pessimistic value, so the result is conservative rather than wrong.
`flow.py`'s own docstring lists them, and [docs/flow.md](../docs/flow.md) has
the full step-by-step flow.

---

## Output (`output/`)

When the run finishes the deliverables are written to `output/`:

- **`output/lib/<macro>_TT_1p8V_25C.lib`** — typical (TT) corner
- **`output/lib/<macro>_SS_1p6V_100C.lib`** — slow (SS) corner
- **`output/lib/<macro>_FF_1p95V_n40C.lib`** — fast (FF) corner
- **`output/verilog/<macro>.v`** — behavioural Verilog carrying the measured delays
