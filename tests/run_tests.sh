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
# WHAT RUNS, AND WHY EACH SUITE EXISTS:
#   1. scripts_tests/  -- unit and integration tests for deck parsers, generators,
#                         SPICE utilities, error/provenance handling, flow recovery/resume,
#                         adaptive periphery settling, and paired-op gmin sweeps.
#   2. lib_tests/      -- test_checker (fixtures validation), check_lib (Liberty
#                         syntax, shapes, templates, monotonic axes), test_rom_lib
#                         (ROM timing arcs, dual-edge dout0, constraints, corner ordering),
#                         and OpenSTA read_liberty validation.
#   3. verilog_tests/  -- behavioural SystemVerilog (.sv) elaboration (iverilog)
#                         and dynamic simulation testbench (precharge, access delay,
#                         falling-edge invalidation, cs0 gating, hold violations).

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

LIB_DIR="${ROM_OUT_DIR:-$REPO/output}/lib"
VERILOG_DIR="${ROM_OUT_DIR:-$REPO/output}/verilog"

if [ $# -gt 0 ]; then
  LIBS=""
  TARGET_SV=""
  for arg in "$@"; do
    if [ -f "$arg" ]; then
      case "$arg" in
        *.lib) LIBS="$LIBS $arg" ;;
        *.sv|*.v) TARGET_SV="$TARGET_SV $arg" ;;
      esac
    else
      # Bare macro name, e.g. "random_2k"
      m_libs=$(ls "$LIB_DIR"/${arg}_*.lib 2>/dev/null || true)
      if [ -n "$m_libs" ]; then
        LIBS="$LIBS $m_libs"
      fi
      if [ -f "$VERILOG_DIR/${arg}.sv" ]; then
        TARGET_SV="$TARGET_SV $VERILOG_DIR/${arg}.sv"
      elif [ -f "$VERILOG_DIR/${arg}.v" ]; then
        TARGET_SV="$TARGET_SV $VERILOG_DIR/${arg}.v"
      fi
    fi
  done
  LIBS=$(echo "$LIBS" | xargs)
  TARGET_SV=$(echo "$TARGET_SV" | xargs)
fi

if [ -z "$LIBS" ]; then
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

"$HERE/scripts_tests/run_scripts_tests.sh" || rc=1

echo
echo "================================================================="
echo "== 2. LIB TESTS (lib_tests/)                                  =="
echo "================================================================="
echo "== the checker itself =="
python3 "$HERE/lib_tests/test_checker.py" || rc=1

echo
echo "== Liberty structure =="
python3 "$HERE/lib_tests/check_lib.py" -v $LIBS || rc=1

echo
echo "== ROM semantics =="
python3 "$HERE/lib_tests/test_rom_lib.py" $LIBS || rc=1

echo
echo "== OpenSTA =="
STA="${STA_BIN:-sta}"
if command -v "$STA" >/dev/null 2>&1; then
  ROM_LIB_LIST="$LIBS" \
    "$STA" -no_init -no_splash -exit "$HERE/lib_tests/read_liberty.tcl" || rc=1
else
  echo "  SKIP  '$STA' not found -- set STA_BIN to an OpenSTA binary to run"
  echo "        the generated files through the parser a consumer really uses."
  skipped="$skipped OpenSTA"
fi

echo
echo "================================================================="
echo "== 3. VERILOG TESTS (verilog_tests/)                          =="
echo "================================================================="
echo "== Behavioural Verilog models elaboration =="
IV="${IVERILOG_BIN:-iverilog}"
VERILOG_DIR="${ROM_OUT_DIR:-$REPO/output}/verilog"
if command -v "$IV" >/dev/null 2>&1; then
  v_count=0
  v_candidates="${TARGET_SV:-$(ls "$VERILOG_DIR"/*.sv "$VERILOG_DIR"/*.v 2>/dev/null || true)}"
  for v in $v_candidates; do
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

echo
echo "== Behavioural Verilog model simulation testbench =="
vm_args=""
[ -n "$TARGET_SV" ] && vm_args="$TARGET_SV"
vm_out=$(python3 "$HERE/verilog_tests/test_verilog_model.py" $vm_args 2>&1) || rc=1
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
