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

## The layers

| layer | file | question it answers |
|---|---|---|
| 1 | `test_checker.py` | does the checker still catch the defects it claims to? |
| 2 | `check_lib.py` | is this valid Liberty? |
| 3 | `test_rom_lib.py` | does it say what this macro actually does? |
| 4 | `read_liberty.tcl` | does OpenSTA accept it? |
| 5 | `iverilog` | do generated behavioural Verilog models compile and elaborate cleanly? |
| 6 | `test_verilog_model.py` | do behavioural Verilog models simulate correctly (precharge, access delay, invalidation, cs0)? |
| 0 | `test_error_reporting.py` | does a dead, unsettled or *absent* simulation stay loud -- and can a log that this flow did not produce still reach a `.lib`? |

Layer 0 sits before all of them because it asks about the numbers rather than
the file: a `.lib` can be perfectly valid Liberty, say exactly what a ROM says,
and carry a measurement of a circuit that no longer exists. It covers the four
silent failures -- a deck that crashed, one that exited zero having logged an
error, one that ran clean without settling, and a log that was simply left in
the tree by an older netlist or an older run. The last is answered by the
`<log>.prov` stamp `run_ng` writes and `regen_rom_libs.sh` refuses to work
without (see [`docs/flow.md`](../docs/flow.md)).

Layer 1 comes first on purpose. A validator nobody validates is worse than no
validator: it turns every run green and everyone stops looking. `fixtures/`
holds one hand-written **valid** Liberty file plus a copy of it per defect,
each carrying exactly one — an unclosed group, a table with two rows against a
three-entry `index_1`, a `related_pin` naming a pin that does not exist, an
`index_2` that runs backwards, and so on. `test_checker.py` asserts the valid
one passes and that each broken one is rejected *for the right reason*, matched
on the message, so a check that starts firing for some unrelated reason still
counts as a failure.

Layer 2 (`check_lib.py`, on top of the small parser in `libparse.py`) is
generic — it knows nothing about ROMs. It reports a line number for everything
it rejects.

Layer 3 is where the ROM lives. Each check carries a docstring naming the
failure mode it exists to prevent; the one this suite was written for is that
`dout0` must carry **both** a `rising_edge` and a `falling_edge` arc. There is
no output latch, so the data dies when `clk0` falls; with only the rising arc,
STA assumes it holds until the next capture edge and reports a pass the silicon
does not honour. The test also insists the falling arc lands *earlier* than the
access time, since an invalidation after the data is valid says nothing.

Layer 4 is skipped with a notice when no OpenSTA is installed. Layers 1–3 are
our parser checking our writer, which is a closed loop; this opens it using the
parser a consumer really uses. Point `STA_BIN` at a binary to run it.

Layer 5 validates all behavioural Verilog models (`output/verilog/*.v`) using
`iverilog` if available, asserting error-free syntax and elaboration.
Layer 6 (`test_verilog_model.py`) runs dynamic simulation testbenches against
all behavioural Verilog models (`output/verilog/*.v`) using `iverilog` + `vvp`.
It asserts that the simulated output holds all ones during precharge, delays
valid data until `ACCESS_NS` has elapsed, erases data immediately on the falling
clock edge, and remains idle when `cs0 = 0`.

## `wave/` -- the testbench you look at instead of run

Every layer above is pass/fail: nothing in them is meant to be opened in a
wave viewer, and layer 6's testbench is built in a temporary directory, writes
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

Both OpenSTA and Verilog checks are fully automated in CI via
`.github/workflows/ci.yml` on every push and pull request touching libraries or
models.

## Adding a check

Put generic Liberty rules in `check_lib.py` and anything that depends on this
macro's behaviour in `test_rom_lib.py`, as a function returning a list of
failure strings, added to `CHECKS`. If it is a rule the checker enforces, add a
fixture for it: copy `fixtures/good.lib`, break exactly one thing, and add the
file with the message substring to `EXPECTED` in `test_checker.py`.
