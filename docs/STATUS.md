# Project status

This file records the state of the current checkout. Design history belongs in
Git; known technical gaps belong in [limitations.md](limitations.md), and planned
work belongs in [todos.md](todos.md).

[<- back to the README](../README.md)

## Deliverables

- Four reference macros are stored under `examples/`: `wrom0` through `wrom3`.
- Each reference macro has three Liberty corners in `output/lib/` and one
  behavioural SystemVerilog model in `output/verilog/`.
- User macros live under `user/` and are generated independently; they are not
  part of the fixed reference inventory.

## Flow state

- `flow.py` provides pre-flight checks, standard and full characterization,
  named restart stages, Liberty generation, behavioural-model generation, and
  verification.
- Measurement logs are accepted only when their provenance stamp matches the
  current deck and macro netlist.
- Standard mode uses documented conservative fallbacks for address hold and
  the input-slew axis. `--full` measures those terms.
- Characterization-model validation does not replace Magic DRC or Netgen LVS.

## Verification

`tests/run_tests.sh` currently runs 19 checks:

- 13 script and flow tests;
- 4 Liberty checks, including OpenSTA when available;
- 2 SystemVerilog checks, including behavioural simulation when Icarus Verilog
  is available.

Run the reference set in strict mode before publishing generated output:

```bash
ROM_TESTS_STRICT=1 ./tests/run_tests.sh wrom0 wrom1 wrom2 wrom3
```

Strict mode fails if OpenSTA or Icarus Verilog is unavailable. A successful
non-strict run may contain skips, so its final summary must be read before the
result is reported as fully verified.

Current checkout result: the strict command above passes in `nix develop`.
All 13 script tests, 12 reference Liberty files, OpenSTA reads, and four
behavioural-model elaboration/simulation runs pass.

## Open work

The main modeling gaps are reduced-deck correlation, row-decoder wire
resistance, scalar setup/hold tables, limited slew coverage, sampled read
energy, and single-column/single-output characterization. See
[limitations.md](limitations.md) for scope and [todos.md](todos.md) for planned
changes.
