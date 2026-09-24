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
    7. a deck that RAN CLEAN but has not converged is a failure too. This is
       the third silent case and neither the exit code nor the log can see
       it: every .measure resolves, ngspice says nothing, and the number is
       a startup transient rather than the steady state. The decks that can
       tell measure the same quantity on two consecutive cycles;
       `check_settled` compares them against SETTLE_MAX_PCT and ledgers the
       mismatch like a crash. On 2026-09-06 that gap stood at 24-40% in the
       periphery energy run, was printed in the summary table, and nothing
       acted on it.

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

    # The stamp is written by the REAL run_ng path, not only by the unit
    # test above: a clean deck must leave one, and a dead deck must not leave
    # a usable one, or regen_rom_libs.sh is judging logs by a file nobody
    # writes.
    if not os.path.exists(os.path.join(tmp, "good.log.prov")):
        bad.append("run_ng accepted a healthy deck without stamping its log, "
                   "so the .lib generator will refuse the run it just made")
    for dead in ("loud", "quiet"):
        r = sh('. "$ROM_CHAR_DIR/common.sh"; prov_check "%s"; echo "RC=$?"'
               % os.path.join(tmp, dead + ".log"))
        if "RC=1" not in r.stdout:
            bad.append("the log of a deck that DIED (%s) passed the "
                       "provenance check" % dead)

    out = run_ng_case(tmp, "measfail", EXPECTED_MEASURE_FAILURE)
    if "RC=0" not in out:
        bad.append("an EXPECTED .measure failure was treated as fatal. The "
                   "flow relies on those: an unselected wordline has no edge "
                   "to measure, and 93 of the 311 committed logs contain one. "
                   "Failing on them would make every good run red")
    return bad


def check_settling():
    """An unsettled deck must fail the run, not just print a number.

    No ngspice needed: check_settled is arithmetic over two numbers the deck
    has already written to its log.
    """
    bad = []

    def case(gap):
        r = sh('. "$ROM_CHAR_DIR/common.sh"; ng_reset; '
               'check_settled "test-stage" "x.log" "ctx1 ctx2" "%s" "x.sp"; '
               'echo "RC=$?"; ng_summary; echo "SUM=$?"' % gap)
        return r.stdout + r.stderr

    lim = sh('. "$ROM_CHAR_DIR/common.sh"; echo "$SETTLE_MAX_PCT"').stdout.strip()
    if lim != "1.0":
        bad.append("the settling limit is %r, not the 1.0%% the column deck "
                   "uses for t_dis_50 -- the two checks must not drift apart"
                   % lim)

    out = case("0.59")                   # the worst committed periphery log
    if "RC=0" not in out or "SUM=0" not in out:
        bad.append("a SETTLED deck (0.59%, the worst value in the committed "
                   "logs) was reported as a failure -- the limit is too tight "
                   "to pass a good run")
    if "FAILED" in out:
        bad.append("a settled deck printed a failure report")

    out = case("1.00")                   # exactly at the limit is still fine
    if "RC=0" not in out:
        bad.append("a gap exactly AT the limit was failed; the check must be "
                   "strictly greater, or the limit cannot be quoted as a "
                   "pass/fail boundary")

    out = case("25.00")
    if "RC=1" not in out:
        bad.append("AN UNSETTLED DECK WAS TREATED AS SUCCESS -- this is the "
                   "case run_ng cannot see, because ngspice ran clean and the "
                   "number it produced is simply a transient")
    if "SUM=1" not in out:
        bad.append("ng_summary did not return 1 after an unsettled deck, so "
                   "the run would still exit zero")
    if "NOT SETTLED" not in out or "25.00" not in out:
        bad.append("the report does not say the deck is unsettled, or does "
                   "not quote the gap that made it one")
    if "ctx1 ctx2" not in out:
        bad.append("the unsettled report does not carry the context "
                   "(macro/corner/state), so it does not say WHICH run to redo")
    return bad


def check_settling_is_wired():
    """The helper existing is not the same as a script using it.

    Item 2b of the 2026-09-20 audit was exactly this shape: the periphery
    deck measured q_c2 and q_c3, the summary printed their gap, and no
    consumer ever compared them.
    """
    bad = []
    path = os.path.join(CHAR, "run_periphery_power.sh")
    # A mention is not a call: the first version of this guard was satisfied
    # by the comment that explains the call, which is exactly the failure it
    # is meant to catch. So: a non-comment line that INVOKES it.
    called = any(line.strip().startswith("check_settled ")
                 for line in open(path))
    if not called:
        bad.append("run_periphery_power.sh measures q_c2/q_c3 but no longer "
                   "calls check_settled -- the gap is back to being a remark "
                   "in a table")
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


def check_provenance(tmp):
    """A log may only be read if THIS flow produced it.

    The fourth silent case, and the one the other three leave open: the run
    never happened at all. A log in <macro>/char outlives the netlist it was
    measured on, the deck it came from and the run that wrote it -- re-extract
    the macro, rebuild a deck, copy the tree from another machine, and `meas`
    still finds a plausible number and returns it without a word.
    `regen_rom_libs.sh` then writes it into a .lib as a measured value.

    So run_ng stamps every clean log with <log>.prov (the deck, the log and
    the netlist it was built from, by CONTENT HASH -- mtimes are rewritten by
    any checkout or copy), check_settled/ng_fail withdraw that stamp when the
    run turns out to be unusable, and the library generator refuses anything
    that is not stamped. This pins down each of those.
    """
    bad = []
    d = os.path.join(tmp, "prov")
    os.makedirs(d, exist_ok=True)
    sp, lg, src = (os.path.join(d, n) for n in ("x.sp", "x.log", "netlist.sp"))

    def write(path, text):
        with open(path, "w") as fh:
            fh.write(text)

    def prov(cmd):
        return sh('. "$ROM_CHAR_DIR/common.sh"; G_SP="%s"; %s; echo "RC=$?"'
                  % (src, cmd))

    write(src, "* the netlist\n")
    write(sp, "* the deck\n")
    write(lg, "foo   =  1.0\n")

    out = prov('prov_check "%s"' % lg)
    if "RC=1" not in out.stdout or "not stamped" not in out.stdout:
        bad.append("AN UNSTAMPED LOG WAS ACCEPTED. Nothing in the tree is "
                   "proof that a log came from the current flow except the "
                   "stamp, so this is the whole check")

    prov('prov_write "test-stage" "%s" "%s" "ctx"' % (sp, lg))
    out = prov('prov_check "%s"' % lg)
    if "RC=0" not in out.stdout:
        bad.append("a log stamped by the flow was rejected: %s"
                   % out.stdout.strip())
    if out.stdout.strip() != "RC=0":
        bad.append("prov_check is not silent on a good log -- it would bury "
                   "the real rejections in noise")

    # 1. the deck changed: the log is from an older deck
    write(sp, "* the deck, with the measurement fixed\n")
    out = prov('prov_check "%s"' % lg)
    if "RC=1" not in out.stdout or "x.sp" not in out.stdout:
        bad.append("A LOG WHOSE DECK HAS SINCE CHANGED WAS ACCEPTED -- that "
                   "is a measurement of a circuit that is no longer the one "
                   "being characterised")
    write(sp, "* the deck\n")                    # put it back

    # ... but a deck that is simply ABSENT is the normal state: decks are
    # gitignored (204 MB) and rebuilt from the netlist on demand, so their
    # absence says nothing about the log, while the netlist hash still ties
    # it to this design. Refusing here would make a clone unable to
    # regenerate anything without re-running the whole flow.
    os.rename(sp, sp + ".away")
    out = prov('prov_check "%s"' % lg)
    if "RC=0" not in out.stdout:
        bad.append("a log whose deck has been cleaned away was refused, "
                   "although decks are gitignored and regenerated on demand: "
                   "%s" % out.stdout.strip())
    os.rename(sp + ".away", sp)

    # 2. the netlist changed: every log in the tree is about another macro
    write(src, "* the netlist, re-extracted with a new .bin\n")
    out = prov('prov_check "%s"' % lg)
    if "RC=1" not in out.stdout or "netlist.sp" not in out.stdout:
        bad.append("A LOG TAKEN ON A DIFFERENT NETLIST WAS ACCEPTED -- "
                   "regenerating the ROM would keep the old timing")
    write(src, "* the netlist\n")

    # 3. the log itself was edited or replaced
    write(lg, "foo   =  2.0\n")
    out = prov('prov_check "%s"' % lg)
    if "RC=1" not in out.stdout or "changed since it was stamped" not in out.stdout:
        bad.append("a log edited after it was stamped was still accepted")
    write(lg, "foo   =  1.0\n")

    # 4. a verdict against the run withdraws the stamp
    out = prov('prov_invalidate "%s" "NOT SETTLED -- 25%% gap"; '
               'prov_check "%s"' % (lg, lg))
    if "RC=1" not in out.stdout or "NOT SETTLED" not in out.stdout:
        bad.append("an invalidated run was still readable, or its reason was "
                   "lost -- an unsettled log is present and WRONG, which is "
                   "worse than absent")

    # 5. ng_fail must withdraw it: a failed RE-RUN leaves the previous run's
    #    log and stamp on disk, and that pair says the number is good.
    prov('prov_write "test-stage" "%s" "%s" "ctx"' % (sp, lg))
    out = prov('ng_reset; ng_fail "test-stage" "ctx" "%s" "%s" "1" "it died"; '
               'prov_check "%s"' % (sp, lg, lg))
    if "RC=1" not in out.stdout or "it died" not in out.stdout:
        bad.append("A FAILED RE-RUN LEFT THE PREVIOUS RUN'S STAMP STANDING, "
                   "so the .lib would keep a number the flow has just failed "
                   "to reproduce")
    return bad


def check_provenance_is_wired():
    """The stamp existing is not the same as the generator honouring it.

    Item 2c of the 2026-09-20 audit had this shape one level down: the gap was
    measured, printed, and never read back by the script that consumed the
    log.
    """
    bad = []
    regen = os.path.join(CHAR, "regen_rom_libs.sh")
    body = [l for l in open(regen) if not l.strip().startswith("#")]
    if not any("prov_check" in l for l in body):
        bad.append("regen_rom_libs.sh no longer calls prov_check -- it is "
                   "back to reading whatever log happens to be in the tree")
    if not any("exit $RC" in l or "exit \"$RC\"" in l for l in body):
        bad.append("regen_rom_libs.sh does not exit on a refused corner, so "
                   "a run that wrote nothing still reports success")
    common = open(os.path.join(CHAR, "common.sh")).read()
    if "prov_write" not in common.split("run_ng()")[1].split("ng_fail()")[0]:
        bad.append("run_ng no longer stamps the logs it accepts, so every "
                   "log in the tree looks like it came from nowhere")
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

        wired = check_settling_is_wired() + check_settling()
        for b in wired:
            print("  FAIL [settling gate] %s" % b)
        if wired:
            rc = 1
        else:
            print("  ok   an unsettled deck fails the run, at a 1% limit")

        prv = check_provenance_is_wired() + check_provenance(tmp)
        for b in prv:
            print("  FAIL [provenance] %s" % b)
        if prv:
            rc = 1
        else:
            print("  ok   only logs this flow produced can reach a .lib")

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
