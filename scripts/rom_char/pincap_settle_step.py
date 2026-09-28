#!/usr/bin/env python3
"""
pincap_settle_step.py: Evaluates pin capacitance settling for a deck/log pair
and computes the adaptive hold-time map for the next iteration if any pin
exceeds the gap threshold quota.

Exit codes:
  0: All pins settled within quota (CONVERGED).
  1: Some pins exceeded quota; prints updated PIN_TH_MAP on stdout to continue iterations.
  2: Non-convergence limit reached (max iterations or max hold time exceeded).
"""

import sys
import os
import re
import argparse


def parse_time_ns(s):
    s = str(s).strip()
    if s.endswith("ns") or s.endswith("n"):
        return float(s.rstrip("ns").rstrip("n"))
    elif s.endswith("us") or s.endswith("u"):
        return float(s.rstrip("us").rstrip("u")) * 1e3
    elif s.endswith("ps") or s.endswith("p"):
        return float(s.rstrip("ps").rstrip("p")) * 1e-3
    return float(s) * 1e9 if float(s) < 1e-3 else float(s)


def format_time_ns(ns_val):
    return f"{ns_val:.2f}n"


def main():
    parser = argparse.ArgumentParser(description="Evaluate pin cap settling and compute next hold times")
    parser.add_argument("sp_file", help="SPICE deck file (.sp)")
    parser.add_argument("log_file", help="Simulation log file (.log)")
    parser.add_argument("--thresh", type=float, default=1.0, help="Target maximum rise/fall gap in %% (default: 1.0)")
    parser.add_argument("--step-th", type=float, default=1.5, help="Multiplier for hold time (default: 1.5)")
    parser.add_argument("--max-th", default="80n", help="Maximum hold time limit (default: 80n)")
    parser.add_argument("--default-th", default="10n", help="Default hold time (default: 10n)")
    parser.add_argument("--current-map", default="", help="Current PIN_TH_MAP string (e.g. 'pinA:15n,pinB:15n')")
    parser.add_argument("--iteration", type=int, default=1, help="Current iteration number (default: 1)")
    parser.add_argument("--max-iter", type=int, default=5, help="Maximum allowed iterations (default: 5)")
    parser.add_argument("--report", action="store_true", help="Print summary table of all pins")

    args = parser.parse_args()

    if not os.path.isfile(args.sp_file) or not os.path.isfile(args.log_file):
        sys.stderr.write(f"ERROR: Files not found: {args.sp_file} or {args.log_file}\n")
        sys.exit(2)

    # 1. Parse pins from SPICE deck
    pins = {}
    with open(args.sp_file, "r") as f:
        for line in f:
            m = re.match(r"^\*PINCAP\s+(\d+)\s+(\S+)", line)
            if m:
                pins[m.group(1)] = m.group(2)

    if not pins:
        sys.stderr.write(f"ERROR: No *PINCAP markers found in {args.sp_file}\n")
        sys.exit(2)

    # 2. Parse measurements from log file
    with open(args.log_file, "r") as f:
        log_text = f.read()

    # 3. Parse current hold-time map
    current_map = {}
    default_th_ns = parse_time_ns(args.default_th)
    max_th_ns = parse_time_ns(args.max_th)

    if args.current_map:
        for item in args.current_map.split(","):
            if ":" in item:
                k, v = item.split(":", 1)
                current_map[k.strip()] = parse_time_ns(v.strip())

    unsettled = []
    settled = []
    missing = []

    for idx, p_name in sorted(pins.items(), key=lambda x: int(x[0])):
        m_cy = re.search(rf"c_cyc{idx}_ff\s*=\s*([0-9.eE+-]+)", log_text)
        m_cr = re.search(rf"c_rise{idx}_ff\s*=\s*([0-9.eE+-]+)", log_text)
        m_cf = re.search(rf"c_fall{idx}_ff\s*=\s*([0-9.eE+-]+)", log_text)

        if not (m_cy and m_cr and m_cf):
            missing.append(p_name)
            continue

        cy = float(m_cy.group(1))
        cr = float(m_cr.group(1))
        cf = float(m_cf.group(1))
        lo = min(cr, cf)
        hi = max(cr, cf)
        gap = (hi - lo) / lo * 100.0 if lo > 0 else 0.0

        cur_th = current_map.get(p_name, default_th_ns)

        pin_info = {
            "name": p_name,
            "c_cyc": cy,
            "c_rise": cr,
            "c_fall": cf,
            "gap": gap,
            "cur_th": cur_th
        }

        if gap > args.thresh:
            next_th = min(cur_th * args.step_th, max_th_ns)
            pin_info["next_th"] = next_th
            unsettled.append(pin_info)
        else:
            settled.append(pin_info)

    if missing:
        sys.stderr.write(f"ERROR: Measurement failed for pins: {', '.join(missing)}\n")
        sys.exit(2)

    # If --report is requested, print summary
    if args.report:
        sys.stderr.write(f"\nPin Settling Summary (Threshold: {args.thresh:.2f}%):\n")
        sys.stderr.write(f"{'Pin':12s} {'t_hold':8s} {'c_cyc(fF)':10s} {'c_rise':10s} {'c_fall':10s} {'Gap(%)':8s} {'Status':12s}\n")
        sys.stderr.write("-" * 75 + "\n")
        for p in settled + unsettled:
            status = "PASSED" if p["gap"] <= args.thresh else f"UNSETTLED (>{args.thresh:.1f}%)"
            sys.stderr.write(f"{p['name']:12s} {format_time_ns(p['cur_th']):8s} {p['c_cyc']:10.4f} {p['c_rise']:10.4f} {p['c_fall']:10.4f} {p['gap']:7.2f}%  {status}\n")

    if not unsettled:
        sys.stdout.write("CONVERGED\n")
        sys.exit(0)

    # Check termination guards
    cannot_increase = [p for p in unsettled if p["cur_th"] >= max_th_ns]
    if args.iteration >= args.max_iter or cannot_increase:
        sys.stderr.write(f"\n[ERROR] Pin capacitance failed to settle within {args.thresh:.2f}% quota after {args.iteration} iteration(s).\n")
        for p in unsettled:
            reason = "reached max hold time limit" if p["cur_th"] >= max_th_ns else "exceeded max iterations"
            sys.stderr.write(f"  - {p['name']}: final gap {p['gap']:.2f}% (t_hold={format_time_ns(p['cur_th'])}, {reason})\n")
        sys.exit(2)

    # Build updated map
    next_map = dict(current_map)
    for p in unsettled:
        next_map[p["name"]] = p["next_th"]

    map_str = ",".join(f"{k}:{format_time_ns(v)}" for k, v in sorted(next_map.items()))
    sys.stderr.write(f"  -> Iteration {args.iteration}: {len(unsettled)} pin(s) exceed {args.thresh:.2f}% gap:\n")
    for p in unsettled:
        sys.stderr.write(f"     * {p['name']}: gap {p['gap']:.2f}% > {args.thresh:.2f}%, scaling hold time {format_time_ns(p['cur_th'])} -> {format_time_ns(p['next_th'])}\n")

    # Output map string for shell script
    sys.stdout.write(map_str + "\n")
    sys.exit(1)


if __name__ == "__main__":
    main()
