#!/bin/sh
# Run every test. No dependencies beyond python3; OpenSTA is used if present.
#
#   tests/run_tests.sh                 # checks $ROM_OUT_DIR/lib (default output/lib)
#   tests/run_tests.sh path/to/x.lib   # checks the files you name
#
# Exit status is 1 if anything failed, so it can gate a commit or a CI job.
#
# ROM_TESTS_STRICT=1 turns every SKIP into a failure. Set it where the tools
# are supposed to be installed -- CI does -- so that a green run cannot mean
# "OpenSTA was missing, so we did not check".
#
# WHAT RUNS, AND WHY EACH LAYER EXISTS:
#   1. test_checker  -- proves the checker still catches the 15 defects in
#                       tests/fixtures/. A validator nobody validates turns
#                       every run green and everyone stops looking.
#   1b. test_error_reporting -- a deck that dies must say WHICH STAGE died
#                       and WHY. The whole flow used to run ngspice as
#                       `... >/dev/null 2>&1 || true`, so a dead deck left no
#                       message, no log and a zero exit -- and several .lib
#                       terms have a fallback for "the log is missing", which
#                       is indistinguishable from a run that never happened.
#   2. check_lib     -- is each generated file valid Liberty? (syntax, table
#                       shapes against their templates, arc completeness)
#   3. test_rom_lib  -- does it say what this macro actually does? (the
#                       falling-edge arc, the constraints, both power states,
#                       corner ordering)
#   4. OpenSTA       -- our parser checking our writer is a closed loop;
#                       this opens it, using the parser a consumer really
#                       uses. Skipped with a notice when sta is not installed.
#   5. Verilog       -- validates behavioural Verilog models with iverilog if
#                       installed (syntax and elaboration check). Skipped with
#                       a notice when iverilog is not installed.
#   6. test_verilog_model -- executes dynamic simulation testbenches against
#                       the behavioural Verilog models with iverilog + vvp to
#                       prove precharge, evaluate access delay, falling edge
#                       invalidation and chip-select gating. Skipped when
#                       iverilog/vvp is not installed.

set -e

# No .pyc files. Python validates a cached module by the source's mtime, and
# an edit that lands in the SAME SECOND as the cache was written is taken as
# unchanged -- so the suite runs the OLD module and reports a state the source
# does not describe. Seen for real: a restored check_lib.py kept reporting the
# blinded version's results. In an edit-then-test loop the reverse is just as
# possible, and that direction is a false PASS.
PYTHONDONTWRITEBYTECODE=1
export PYTHONDONTWRITEBYTECODE

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
# Layers that did not run. A green banner must not be able to mean "everything
# was checked" when three of the six layers can silently skip -- OpenSTA when
# it is not installed and the Verilog layers when there are no models. Each
# skip is recorded and named at the end.
skipped=""

echo "== the checker itself =="
python3 "$HERE/test_checker.py" || rc=1

echo
echo "== a dead simulation is reported, not swallowed =="
python3 "$HERE/test_error_reporting.py" || rc=1

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
  # The files go through the environment, NOT after the script name. OpenSTA
  # takes exactly one positional argument -- the cmd_file -- and anything
  # after it makes the binary print its usage text and exit 1 without running
  # the script at all. read_liberty.tcl's own empty-argv guard cannot catch
  # that: the script never starts. One newline-separated variable also keeps
  # paths with spaces in one piece, which a bare $LIBS does not.
  ROM_LIB_LIST="$LIBS" \
    "$STA" -no_init -no_splash -exit "$HERE/read_liberty.tcl" || rc=1
else
  echo "  SKIP  '$STA' not found -- set STA_BIN to an OpenSTA binary to run"
  echo "        the generated files through the parser a consumer really uses."
  skipped="$skipped OpenSTA"
fi

echo
echo "== Behavioural Verilog models =="
IV="${IVERILOG_BIN:-iverilog}"
VERILOG_DIR="${ROM_OUT_DIR:-$REPO/output}/verilog"
if command -v "$IV" >/dev/null 2>&1; then
  v_count=0
  # .sv: the models use fork/join_none, so they are SystemVerilog and are
  # named accordingly. .v is still swept up, both for a tree generated before
  # the rename and for a hand-written model someone dropped in.
  for v in "$VERILOG_DIR"/*.sv "$VERILOG_DIR"/*.v; do
    [ -f "$v" ] || continue
    v_count=$((v_count + 1))
    mod=$(basename "$v"); mod=${mod%.*}
    if "$IV" -g2012 -s "$mod" "$v" -o /dev/null >/dev/null 2>&1; then
      echo "  ok   $(basename "$v")"
    else
      echo "  FAIL $(basename "$v")  iverilog syntax/elaboration error"
      "$IV" -g2012 -s "$mod" "$v" -o /dev/null || true
      rc=1
    fi
  done
  if [ $v_count -eq 0 ]; then
    echo "  SKIP  no Verilog models found in $VERILOG_DIR"
    skipped="$skipped verilog-elaboration"
  fi
else
  echo "  SKIP  'iverilog' not found -- set IVERILOG_BIN or install iverilog to validate"
  echo "        behavioural Verilog models."
  skipped="$skipped verilog-elaboration"
fi
echo "== Behavioural Verilog model simulation testbench =="
vm_out=$(python3 "$HERE/test_verilog_model.py" 2>&1) || rc=1
printf '%s\n' "$vm_out"
case "$vm_out" in
  *SKIP*) skipped="$skipped verilog-simulation" ;;
esac

echo
# STRICT: a layer that could not run is a FAILURE, not a notice.
#
# Locally a skip is the right answer -- someone without OpenSTA should still
# be able to run the rest. In CI it is not: there every tool IS installed on
# purpose, so a skip means the install silently did not take, and a green run
# would then mean "the layers that happened to work are clean" while claiming
# to mean "the library was validated". That is the same swallowed failure the
# flow's ngspice wrapper exists to prevent, one level up.
if [ -n "$skipped" ] && [ -n "$ROM_TESTS_STRICT" ]; then
  echo "STRICT: these layers did not run:$skipped"
  echo "ROM_TESTS_STRICT is set, so that is a failure rather than a notice --"
  echo "every tool the suite needs is supposed to be present here."
  rc=1
fi
if [ $rc -ne 0 ]; then
  echo "TESTS FAILED"
elif [ -n "$skipped" ]; then
  echo "PASSED, BUT NOT EVERYTHING RAN -- skipped:$skipped"
  echo "Green means the layers that ran are clean. It does NOT mean:"
  # Name only what was actually skipped. A blanket disclaimer that names a
  # layer which DID run is the same defect as a green banner that hides one:
  # both make the summary say something the run does not support.
  case "$skipped" in *OpenSTA*)
    echo "  - that the library was checked by the parser a consumer uses" ;;
  esac
  case "$skipped" in *verilog-elaboration*)
    echo "  - that the behavioural models compile and elaborate" ;;
  esac
  case "$skipped" in *verilog-simulation*)
    echo "  - that the behavioural models were simulated" ;;
  esac
else
  echo "ALL TESTS PASSED (every layer ran)"
fi
exit $rc
