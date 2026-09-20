#!/bin/sh
# Run every test. No dependencies beyond python3; OpenSTA is used if present.
#
#   tests/run_tests.sh                 # checks $ROM_OUT_DIR/lib (default output/lib)
#   tests/run_tests.sh path/to/x.lib   # checks the files you name
#
# Exit status is 1 if anything failed, so it can gate a commit or a CI job.
#
# WHAT RUNS, AND WHY EACH LAYER EXISTS:
#   1. test_checker  -- proves the checker still catches the 11 defects in
#                       tests/fixtures/. A validator nobody validates turns
#                       every run green and everyone stops looking.
#   2. check_lib     -- is each generated file valid Liberty? (syntax, table
#                       shapes against their templates, arc completeness)
#   3. test_rom_lib  -- does it say what this macro actually does? (the
#                       falling-edge arc, the constraints, both power states,
#                       corner ordering)
#   4. OpenSTA       -- our parser checking our writer is a closed loop;
#                       this opens it, using the parser a consumer really
#                       uses. Skipped with a notice when sta is not installed.

set -e

HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(dirname "$HERE")

if [ $# -gt 0 ]; then
  LIBS="$*"
else
  LIB_DIR="${ROM_OUT_DIR:-$REPO/output}/lib"
  LIBS=$(ls "$LIB_DIR"/*.lib 2>/dev/null || true)
  if [ -z "$LIBS" ]; then
    echo "no .lib files in $LIB_DIR -- run scripts/rom_char/regen_rom_libs.sh first"
    exit 1
  fi
fi

rc=0

echo "== the checker itself =="
python3 "$HERE/test_checker.py" || rc=1

echo
echo "== Liberty structure =="
python3 "$HERE/check_lib.py" -v $LIBS || rc=1

echo
echo "== ROM semantics =="
python3 "$HERE/test_rom_lib.py" $LIBS || rc=1

echo
echo "== OpenSTA =="
STA="${STA_BIN:-sta}"
if command -v "$STA" >/dev/null 2>&1; then
  "$STA" -no_init -no_splash -exit "$HERE/read_liberty.tcl" $LIBS || rc=1
else
  echo "  SKIP  '$STA' not found -- set STA_BIN to an OpenSTA binary to run"
  echo "        the generated files through the parser a consumer really uses."
fi

echo
if [ $rc -eq 0 ]; then
  echo "ALL TESTS PASSED"
else
  echo "TESTS FAILED"
fi
exit $rc
