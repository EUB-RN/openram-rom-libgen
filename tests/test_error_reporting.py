#!/usr/bin/env python3
"""A dead simulation must be loud, and must stay loud.

WHY THIS LAYER EXISTS
---------------------
Every deck in the characterization flow used to be run as

    $NG -b -o "$log" "$deck" >/dev/null 2>&1 || true

in the background as often as not. That discards the exit status AND the
diagnostics: a deck that died produced no message, no non-zero exit and an
empty or absent log. The failure surfaced much later as a missing .measure --
or not at all, because several terms in the .lib have a documented fallback
for "the log is not there", and a fallback is indistinguishable from a
measurement that was never attempted.

THE EXIT CODE ALONE DOES NOT CATCH IT, which is the reason this file is not
just a grep. Measured on ngspice 11:

    unknown subckt          -> exit 1, "Simulation interrupted due to error!"
    .measure on a bad node   -> exit 0, "Error: no such vector as ..."
    empty netlist            -> exit 1, "Error: incomplete or empty netlist"

The middle one is the dangerous case: ngspice reports success while the
measurement it was asked for never happened. `run_ng` in common.sh therefore
judges a run by its status AND by its log, and this test pins that behaviour
down with all three cases.

WHAT IS CHECKED
    1. a run that exits non-zero is reported and returns 1
    2. a run that exits ZERO but logged a fatal error is also reported
    3. a healthy run is silent and returns 0
    4. the expected .measure failures the flow relies on are NOT fatal
       (an unselected wordline has no edge to measure; 93 of the 311
       committed logs contain "failed!" and are perfectly good runs)
    5. ng_summary names every failed stage and returns 1
    6. no ngspice invocation anywhere in scripts/ has gone back to
       swallowing its status

Usage:
    python3 tests/test_error_reporting.py
Exit status is 1 if anything failed.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CHAR = os.path.join(REPO, "scripts", "rom_char")

GOOD = """* healthy deck
V1 a 0 PULSE(0 1 0 100p 100p 1n 2n)
R1 a b 1k
C1 b 0 1p
.tran 10p 5n
.measure tran foo FIND v(b) AT=2n
.end
"""

# exits 1 and says so
DEAD_LOUD = """* references a model that does not exist
V1 a 0 DC 1
X1 a b 0 nonexistent_model w=1u l=1u
.tran 1n 10n
.measure tran foo FIND v(a) AT=5n
.end
"""

# exits ZERO -- the case an exit-code check misses. Kept deliberately
# circuit-less: with a real circuit present ngspice notices earlier and exits
# 1 ("no data saved for Transient analysis"), which the exit code would have
# caught anyway. This form is the one that returns success.
DEAD_QUIET = """* a measure against a node that does not exist, and no circuit
.tran 1n 10n
.measure tran foo FIND v(nosuchnode) AT=5n
.end
"""

# a .measure that cannot resolve is NORMAL here: the flow reads those
# failures as evidence (only the selected wordline has an edge to measure).
# The circuit is healthy and fully driven; only the THRESHOLD is unreachable,
# so the .measure fails while the simulation is perfect. (An earlier version
# of this fixture left a node floating at DC and tripped "singular" -- a
# genuinely degenerate deck, and the fatal list was right to flag it.)
EXPECTED_MEASURE_FAILURE = """* an unreachable threshold -- the flow's own kind of expected failure
V1 a 0 PULSE(0 1 0 100p 100p 1n 2n)
R1 a b 1k
C1 b 0 1p
.tran 10p 5n
.measure tran never TRIG v(a) VAL=0.5 RISE=1 TARG v(a) VAL=5.0 RISE=1
.end
"""


def sh(script, env=None):
    e = dict(os.environ)
    e["ROM_CHAR_DIR"] = CHAR
    if env:
        e.update(env)
    return subprocess.run(["sh", "-c", script], capture_output=True, text=True,
                          cwd=REPO, env=e)


def run_ng_case(tmp, name, deck_text):
    """Return (rc, combined output) of one run_ng call."""
    sp = os.path.join(tmp, name + ".sp")
    lg = os.path.join(tmp, name + ".log")
    with open(sp, "w") as fh:
        fh.write(deck_text)
    r = sh('. "$ROM_CHAR_DIR/common.sh"; ng_reset; '
           'run_ng "test-stage" "%s" "%s" "ctx1 ctx2"; echo "RC=$?"; '
           'ng_summary; echo "SUM=$?"' % (sp, lg))
    return r.stdout + r.stderr


def check_behaviour(tmp):
    bad = []
    if not shutil.which(os.environ.get("NGSPICE_BIN", "ngspice")):
        return None                      # caller turns this into a SKIP

    out = run_ng_case(tmp, "loud", DEAD_LOUD)
    if "RC=1" not in out:
        bad.append("a deck that exits non-zero was not reported as a failure")
    if "stage=test-stage" not in out:
        bad.append("the failure report does not name the stage")
    if "ctx1 ctx2" not in out:
        bad.append("the failure report does not carry the context (macro/corner)")
    if "reason :" not in out or "unknown subckt" not in out:
        bad.append("the failure report does not say WHY -- ngspice's own "
                   "message must be quoted, not just an exit code")
    if "SUM=1" not in out:
        bad.append("ng_summary did not return 1 after a failure")

    out = run_ng_case(tmp, "quiet", DEAD_QUIET)
    if "RC=1" not in out:
        bad.append("A DECK THAT EXITS ZERO BUT LOGGED A FATAL ERROR WAS "
                   "TREATED AS SUCCESS -- this is the case the exit code "
                   "cannot see, and the reason run_ng reads the log at all")
    # The reason must NAME something, not fall back to "exited N with no
    # recognised message". ngspice reports this case as either "no such
    # vector as v(nosuchnode)" or "can't parse 'nosuchnode'" depending on
    # where it gives up, and both identify the offending node.
    if "nosuchnode" not in out:
        bad.append("the exit-zero failure was caught but its reason does not "
                   "name the cause -- the report has to quote ngspice, not "
                   "just say that something went wrong")
    if "no recognised message" in out:
        bad.append("the reason fell back to the generic message although "
                   "ngspice had said exactly what was wrong")

    out = run_ng_case(tmp, "good", GOOD)
    if "RC=0" not in out:
        bad.append("a healthy deck was reported as a failure")
    if "FAILED" in out:
        bad.append("a healthy deck printed a failure report")
    if "SUM=0" not in out:
        bad.append("ng_summary did not return 0 on a clean run")

    out = run_ng_case(tmp, "measfail", EXPECTED_MEASURE_FAILURE)
    if "RC=0" not in out:
        bad.append("an EXPECTED .measure failure was treated as fatal. The "
                   "flow relies on those: an unselected wordline has no edge "
                   "to measure, and 93 of the 311 committed logs contain one. "
                   "Failing on them would make every good run red")
    return bad


def check_no_swallowing():
    """No ngspice call in the flow may discard its status.

    A static guard, because the behavioural test above only covers run_ng: a
    new script could still call $NG directly tomorrow, and the failure would
    be silent again.
    """
    bad = []
    allowed = {
        # run_ng is the wrapper itself
        "common.sh",
    }
    for name in sorted(os.listdir(CHAR)):
        if not name.endswith(".sh") or name in allowed:
            continue
        path = os.path.join(CHAR, name)
        for n, line in enumerate(open(path), 1):
            s = line.strip()
            if s.startswith("#") or "$NG " not in s:
                continue
            bad.append("%s:%d calls ngspice directly instead of through "
                       "run_ng, so its failure is not reported: %s"
                       % (name, n, s[:70]))
    return bad


def main():
    rc = 0
    tmp = tempfile.mkdtemp(prefix="rom_err_")
    try:
        static = check_no_swallowing()
        for b in static:
            print("  FAIL [no swallowed ngspice status] %s" % b)
        if static:
            rc = 1
        else:
            print("  ok   every ngspice call goes through run_ng")

        beh = check_behaviour(tmp)
        if beh is None:
            print("  SKIP  ngspice not found -- the behavioural half of this "
                  "layer did not run")
        else:
            for b in beh:
                print("  FAIL [failure reporting] %s" % b)
            if beh:
                rc = 1
            else:
                print("  ok   dead decks are reported with stage, context and "
                      "reason -- including the ones ngspice calls success")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    print("test_error_reporting: %s" % ("FAILED" if rc else "ok"))
    return rc


if __name__ == "__main__":
    sys.exit(main())
