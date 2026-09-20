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

## The four layers

| layer | file | question it answers |
|---|---|---|
| 1 | `test_checker.py` | does the checker still catch the defects it claims to? |
| 2 | `check_lib.py` | is this valid Liberty? |
| 3 | `test_rom_lib.py` | does it say what this macro actually does? |
| 4 | `read_liberty.tcl` | does OpenSTA accept it? |

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

## Adding a check

Put generic Liberty rules in `check_lib.py` and anything that depends on this
macro's behaviour in `test_rom_lib.py`, as a function returning a list of
failure strings, added to `CHECKS`. If it is a rule the checker enforces, add a
fixture for it: copy `fixtures/good.lib`, break exactly one thing, and add the
file with the message substring to `EXPECTED` in `test_checker.py`.
