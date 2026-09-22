#!/usr/bin/env python3
"""Cross-check the measured input pin capacitances against a GOLDEN reference.

WARNS, NEVER FAILS. This is deliberate and it is not laziness:

  * It is a MODELLING cross-check, not a correctness check. Everything else in
    tests/ asks "does the .lib say what this macro does" and a wrong answer
    there is a bug. Here the question is "how much did the reduction cost",
    and the answer is a number with error bars, not a yes or no.
  * The golden reference is expensive -- the deck goes from ~2.8k to ~38k
    devices and from 19k to 168k capacitors, and it runs for hours at ~15 GB.
    It will usually be ABSENT, and a test that is usually skipped and
    occasionally red is a test people learn to ignore.
  * A band tight enough to be useful is also tight enough to fire on the two
    pins whose few-percent ramp sensitivity is already documented.

So: it prints, it does not gate. This script exits 0 whatever it finds.

WHAT THE GOLDEN REFERENCE IS. The pin-capacitance deck deletes the cell array
and the column mux and puts their load back as lumped C. Every other check on
those numbers -- ramp independence, agreement across the four macros,
insensitivity to a 2x change in the array load, the corner ordering -- is a
SELF-CONSISTENCY check: it bounds how far the answer moves when a knob moves,
and it is structurally blind to an error that every variant shares. The golden
run (`gen_periphery_power_tb.py --pin-cap --keep-all`) deletes nothing, so
there is no reduction left to be wrong about, and the difference between the
two IS the cost of the reduction.

Produce one with:
    GOLDEN_PINS="clk0,addr0[0],addr0[9]" scripts/rom_char/run_pin_cap.sh wrom0

Usage: tests/test_pin_cap.py [--band 10] [macro ...]
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "scripts", "rom_char"))
import rom_paths                                          # noqa: E402

# Why 10%: the reduced deck reproduces itself to 0.45% across ramp times on
# eleven of the thirteen pins, and to 4-5% on addr0[0] and addr0[6], so a band
# at or below 5% fires on behaviour that is already written down. A real
# reduction error is not a few percent -- the analytic estimate this work
# replaced was off by 58-96%. 10% sits between the two.
DEFAULT_BAND = 10.0

CORNER_TAG = {"TT_1p8V_25C": "tt", "SS_1p6V_100C": "ss", "FF_1p95V_n40C": "ff"}


def pin_map(deck):
    """pin name -> measurement index, from the *PINCAP markers in a deck."""
    out = {}
    with open(deck) as fh:
        for line in fh:
            m = re.match(r"^\*PINCAP (\d+) (.+)$", line.rstrip("\n"))
            if m:
                out[m.group(2)] = int(m.group(1))
    return out


def measures(log):
    """measurement name -> value, from an ngspice .measure log."""
    out = {}
    with open(log) as fh:
        for line in fh:
            m = re.match(r"^(\w+)\s*=\s*(\S+)", line)
            if m:
                try:
                    out[m.group(1)] = float(m.group(2))
                except ValueError:
                    pass
    return out


def check(macro, band):
    """Compare reduced against golden for one macro. Returns a report list."""
    char = os.path.join(rom_paths.macro_dir(macro), "char")
    rows, seen_any = [], False
    for tag in ("tt", "ss", "ff"):
        gsp = os.path.join(char, "pincap_golden_%s.sp" % tag)
        glg = os.path.join(char, "pincap_golden_%s.log" % tag)
        rsp = os.path.join(char, "pincap_%s.sp" % tag)
        rlg = os.path.join(char, "pincap_%s.log" % tag)
        if not all(os.path.exists(p) for p in (gsp, glg, rsp, rlg)):
            continue
        seen_any = True
        gmap, rmap = pin_map(gsp), pin_map(rsp)
        gval, rval = measures(glg), measures(rlg)
        for pin, gi in sorted(gmap.items()):
            ri = rmap.get(pin)
            g = gval.get("c_cyc%d_ff" % gi)
            r = rval.get("c_cyc%d_ff" % ri) if ri is not None else None
            if g is None or r is None:
                rows.append((tag, pin, None, None, None))
                continue
            dev = (r - g) / g * 100.0 if g else 0.0
            rows.append((tag, pin, r, g, dev))
    return rows, seen_any


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("macros", nargs="*")
    ap.add_argument("--band", type=float, default=DEFAULT_BAND,
                    help="deviation in %% above which a warning is printed "
                         "(default %g)" % DEFAULT_BAND)
    args = ap.parse_args()

    macros = args.macros or rom_paths.discover()
    if not macros:
        print("  SKIP  no macros found")
        return 0

    any_golden, warned, checked = False, 0, 0
    for macro in macros:
        try:
            rows, seen = check(macro, args.band)
        except Exception as exc:                 # a missing tree is not a failure
            print("  SKIP  %s: %s" % (macro, exc))
            continue
        if not seen:
            continue
        any_golden = True
        for tag, pin, r, g, dev in rows:
            if r is None:
                print("  %-7s %-3s %-11s no comparable pair in the logs"
                      % (macro, tag, pin))
                continue
            checked += 1
            flag = ""
            if abs(dev) > args.band:
                flag = "  <-- WARNING: outside +-%g%%" % args.band
                warned += 1
            print("  %-7s %-3s %-11s reduced %8.4f  golden %8.4f  %+7.2f%%%s"
                  % (macro, tag, pin, r, g, dev, flag))

    if not any_golden:
        print("  SKIP  no golden-reference logs (pincap_golden_<corner>.log).")
        print("        These numbers come from a deck that deletes the cell")
        print("        array and puts its load back as lumped C. Every other")
        print("        cross-check on them is a self-consistency check and is")
        print("        blind to an error common to all variants; only a run")
        print("        with nothing deleted can see it. Produce one with:")
        print('          GOLDEN_PINS="clk0,addr0[0],addr0[9]" \\')
        print("            scripts/rom_char/run_pin_cap.sh <macro>")
        return 0

    print()
    if warned:
        print("  %d of %d comparisons are outside +-%g%%. The shipped .lib is"
              % (warned, checked, args.band))
        print("  NOT blocked by this -- it is a modelling cross-check. What it")
        print("  means is that deleting the cell array and replacing it with a")
        print("  lumped load costs more on those pins than the band allows,")
        print("  so either the band is wrong for this macro or the reduction")
        print("  is. Decide which before trusting those pins to a few percent.")
    else:
        print("  %d comparison(s), all within +-%g%%: the cell array and column"
              % (checked, args.band))
        print("  mux can be replaced by a lumped load without moving these pin")
        print("  capacitances more than that. This is the only check here that")
        print("  is not a self-consistency check.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
