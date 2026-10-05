# tests/

Nothing in this flow used to read a generated `.lib` back. `gen_rom_lib.py`
wrote text and the first thing to parse it was whatever the user pointed at the
file, so a missing brace or a table with the wrong number of rows only surfaced
downstream, in someone else's tool. These tests close that gap.

```sh
tests/run_tests.sh                  # everything, against output/lib/*.lib
tests/run_tests.sh path/to/one.lib  # just the files you name
```

Exit status is 1 on any failure, so it can gate a commit or a CI job.
`regen_rom_libs.sh` also runs the structural pass by itself at the end of every
run — a file that does not parse never leaves the generator.

## The suites

There are three suites and eleven checks. `tests/run_tests.sh` always runs them
in this order:

| suite / directory | file | question it answers |
|---|---|---|
| `scripts_tests/` | `test_find_worst_column.py` | does worst/best column search handle scoping, zero-columns, determinism, and CLI? |
| `scripts_tests/` | `test_spice_utils.py` | unit tests for SPICE parser, SI units (`to_float`, `fix_units`, `blocks`), and CLI generator execution |
| `scripts_tests/` | `test_error_reporting.py` | does a dead, unsettled or *absent* simulation stay loud -- and can a log that this flow did not produce still reach a `.lib`? |
| `scripts_tests/` | `test_flow_resume.py` | does flow recovery, step skipping, and restart logic operate correctly? |
| `scripts_tests/` | `test_periph_settle.py` | does periphery energy use relative/noise-floor convergence, does ngspice stop/resume one transient, and is the final decision wired into production provenance? |
| `scripts_tests/` | `test_periphery_leak_paired.py` | does single-parse paired-op sweep correctly vary cs0 and gmin in one ngspice session? |
| `lib_tests/` | `test_checker.py` | does the checker still catch the 15 defects in `lib_tests/fixtures/`? |
| `lib_tests/` | `check_lib.py` | is this valid Liberty? |
| `lib_tests/` | `test_rom_lib.py` | does it say what this macro actually does (timing arcs, constraints, corners)? |
| `lib_tests/` | `read_liberty.tcl` | does OpenSTA accept the generated `.lib` files? |
| `verilog_tests/` | `iverilog` | do generated behavioural SystemVerilog models (`.sv`) compile and elaborate cleanly? |
| `verilog_tests/` | `test_verilog_model.py` | do behavioural SystemVerilog models (`.sv`) simulate correctly (precharge, access delay, invalidation, hold, cs0)? |

The error/provenance check asks about the numbers rather than
the file: a `.lib` can be perfectly valid Liberty, say exactly what a ROM says,
and carry a measurement of a circuit that no longer exists. It covers the four
silent failures -- a deck that crashed, one that exited zero having logged an
error, one that ran clean without settling, and a log that was simply left in
the tree by an older netlist or an older run. The last is answered by the
`<log>.prov` stamp `run_ng` writes and `regen_rom_libs.sh` refuses to work
without (see [`docs/flow.md`](../docs/flow.md)).

The checker fixtures run before generated libraries on purpose. A validator nobody validates is worse than no
validator: it turns every run green and everyone stops looking. `fixtures/`
holds one hand-written **valid** Liberty file plus a copy of it per defect,
each carrying exactly one — an unclosed group, a table with two rows against a
three-entry `index_1`, a `related_pin` naming a pin that does not exist, an
`index_2` that runs backwards, and so on. `test_checker.py` asserts the valid
one passes and that each broken one is rejected *for the right reason*, matched
on the message, so a check that starts firing for some unrelated reason still
counts as a failure.

The flow guard also runs `test_flow_resume.py`. It uses temporary macro trees
and fake stage executables to test failure followed by restart with changed
parameters, skipped earlier steps, full-mode ordering, missing prerequisites,
and restart commands. It does not run ngspice or change real macro outputs.
Run it independently with
`python3 tests/scripts_tests/test_flow_resume.py`.

`tests/lib_tests/check_lib.py` (on top of the small parser in `libparse.py`) is
generic — it knows nothing about ROMs. It reports a line number for everything
it rejects.

`tests/lib_tests/test_rom_lib.py` is where the ROM lives. Each check carries a docstring naming the
failure mode it exists to prevent; the one this suite was written for is that
`dout0` must carry **both** a `rising_edge` and a `falling_edge` arc. There is
no output latch, so the data dies when `clk0` falls; with only the rising arc,
STA assumes it holds until the next capture edge and reports a pass the silicon
does not honour. The test also insists the falling arc lands *earlier* than the
access time, since an invalidation after the data is valid says nothing.

The OpenSTA check is skipped with a notice when no OpenSTA is installed. The
in-repository parser checking the in-repository writer is a closed loop;
OpenSTA opens it using the parser a consumer really uses. `nix develop`
supplies the repository-pinned OpenSTA; outside that environment, point
`STA_BIN` at a binary to run it.

The elaboration check validates all behavioural SystemVerilog models (`output/verilog/*.sv`) using
`iverilog` if available, asserting error-free syntax and elaboration.
`tests/verilog_tests/test_verilog_model.py` runs dynamic simulation testbenches against
all behavioural SystemVerilog models (`output/verilog/*.sv`) using `iverilog` + `vvp`.
It asserts that the simulated output holds all ones during precharge, delays
valid data until `ACCESS_NS` has elapsed, preserves it through the falling edge
for the declared falling-edge arc, then invalidates it, and remains idle when
`cs0 = 0`.

## Scope boundaries

This suite validates every Liberty file it is given and every behavioural
model that exists in `output/verilog/`. It does not currently require a
one-to-one `.lib`/`.sv` inventory, so a missing model must also be caught by
reviewing the output inventory. It does not run Magic DRC or Netgen LVS;
passing these tests is characterization-model validation, not physical
sign-off.

## `wave/` -- the testbench you look at instead of run

Every check above is pass/fail: nothing in them is meant to be opened in a
wave viewer, and the behavioural testbench is built in a temporary directory, writes
no VCD, and drives the model through its *violations* on purpose.

`wave/` holds the opposite instrument. `tb_<macro>_wave.v` drives only legal
cycles and sweeps a run of addresses so the ROM contents can be read off the
waves, in Vivado's wave window or in gtkwave. It is generated, not written by
hand, so the timing in it cannot drift from the model's:

```sh
python3 scripts/rom_char/gen_wave_tb.py            # every macro
python3 scripts/rom_char/gen_wave_tb.py wrom0 --reads 64
```

It also writes `<macro>_rom.mem`. That file is not a convenience:
`rom_configs/<macro>.bin` is raw binary and `$readmemb` cannot read it -- it
aborts on the first byte and the array stays X -- so the contents are converted
to text and the testbench points its `INIT_FILE` there. The byte order inside a
word is not recorded anywhere in the `.bin`; little-endian is the default and
`--endian big` is the other choice.

The trace to read the data off is `dout_cap`, not `dout0`. `dout0` returns to
all ones on every falling edge, because precharge erases the read -- half of
every cycle is `FFFFFFFF` and that is the macro being honest. `dout_cap` is the
value a consumer clocked on the falling edge would capture. The run commands
for Vivado are in the header of each testbench and in `tb_<macro>_wave.tcl`.

Run both OpenSTA and Verilog checks locally through the pinned Nix environment:

```bash
nix develop --command env ROM_TESTS_STRICT=1 ./tests/run_tests.sh
```

## Adding a check

Put generic Liberty rules in `tests/lib_tests/check_lib.py` and anything that
depends on this macro's behaviour in `tests/lib_tests/test_rom_lib.py`, as a
function returning a list of failure strings, added to `CHECKS`. If it is a
rule the checker enforces, add a fixture: copy
`tests/lib_tests/fixtures/good.lib`, break exactly one thing, and add the file
with the message substring to `EXPECTED` in
`tests/lib_tests/test_checker.py`. Script-level tests belong in
`tests/scripts_tests/`; behavioural tests belong in `tests/verilog_tests/`.
