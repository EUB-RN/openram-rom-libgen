#!/usr/bin/env bash
# Run all unit and integration tests for scripts/ (in tests/scripts_tests/).
#
# Usage:
#   ./tests/scripts_tests/run_scripts_tests.sh                 # run all script tests
#   ./tests/scripts_tests/run_scripts_tests.sh test_spice_utils.py  # run specific test
#
# Exit status is 1 if any test failed, 0 if all passed.

set -e

PYTHONDONTWRITEBYTECODE=1
export PYTHONDONTWRITEBYTECODE

HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(dirname "$(dirname "$HERE")")

echo "================================================================="
echo "== RUNNING SCRIPTS TESTS (tests/scripts_tests/)                =="
echo "================================================================="

rc=0
passed=0
failed=0

# Determine which test files to run
if [ $# -gt 0 ]; then
  TEST_FILES=""
  for arg in "$@"; do
    if [ -f "$arg" ]; then
      TEST_FILES="$TEST_FILES $arg"
    elif [ -f "$HERE/$arg" ]; then
      TEST_FILES="$TEST_FILES $HERE/$arg"
    else
      echo "ERROR: Test file '$arg' not found." >&2
      exit 1
    fi
  done
else
  TEST_FILES=$(ls "$HERE"/test_*.py 2>/dev/null | sort)
fi

start_total=$(date +%s)

for tf in $TEST_FILES; do
  tname=$(basename "$tf")
  echo
  echo "--> Running $tname..."
  t_start=$(date +%s%N 2>/dev/null || date +%s)

  if python3 "$tf"; then
    t_end=$(date +%s%N 2>/dev/null || date +%s)
    echo "  [PASS] $tname"
    passed=$((passed + 1))
  else
    echo "  [FAIL] $tname"
    failed=$((failed + 1))
    rc=1
  fi
done

end_total=$(date +%s)
elapsed=$((end_total - start_total))

echo
echo "================================================================="
echo "== SUMMARY: SCRIPTS TESTS                                      =="
echo "================================================================="
echo "  Passed: $passed"
echo "  Failed: $failed"
echo "  Total elapsed: ~${elapsed}s"

if [ $rc -ne 0 ]; then
  echo "  Result: SOME TESTS FAILED"
  exit 1
else
  echo "  Result: ALL SCRIPTS TESTS PASSED"
  exit 0
fi
