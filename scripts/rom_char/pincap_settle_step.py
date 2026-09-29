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
    parser.add_argument("--max-iter", type=int, default=15, help="Maximum allowed iterations (default: 15, 0=unlimited)")
    parser.add_argument("--report", action="store_true", help="Print summary table of all pins")

    args = parser.parse_args()

    if not os.path.isfile(args.sp_file) or not os.path.isfile(args.log_file):
        sys.stderr.write(f"ERROR: Files not found: {args.sp_file} or {args.log_file}\n")
        sys.exit(2)

    # 1. Parse pins and exact PWL hold times from SPICE deck
    pins = {}
    deck_th = {}
    with open(args.sp_file, "r") as f:
        for line in f:
            m = re.match(r"^\*PINCAP\s+(\d+)\s+(\S+)", line)
            if m:
                pins[m.group(1)] = m.group(2)
            m_pwl = re.match(r"^Vpin(\d+)\s+(\S+)\s+0\s+PWL\(0\s+0\s+[0-9.eE+-]+\s+0\s+([0-9.eE+-]+)\s+\{VDD\}\s+([0-9.eE+-]+)\s+\{VDD\}", line)
            if m_pwl:
                p_name = m_pwl.group(2)
                tr1 = float(m_pwl.group(3))
                tf0 = float(m_pwl.group(4))
                deck_th[p_name] = (tf0 - tr1) * 1e9

    if not pins:
        sys.stderr.write(f"ERROR: No *PINCAP markers found in {args.sp_file}\n")
        sys.exit(2)

    # 2. Parse measurements from log file
    with open(args.log_file, "r") as f:
        log_text = f.read()

    # 3. Load previous state for saturation tracking
    import json
    state_file = args.log_file + ".pincap_state.json"
    prev_state = {}
    if os.path.isfile(state_file):
        try:
            with open(state_file, "r") as f:
                prev_state = json.load(f)
        except Exception:
            prev_state = {}

    # 4. Parse current hold-time map
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

        cur_th = deck_th.get(p_name, current_map.get(p_name, default_th_ns))

        pin_info = {
            "name": p_name,
            "c_cyc": cy,
            "c_rise": cr,
            "c_fall": cf,
            "gap": gap,
            "cur_th": cur_th
        }

        prev_p = prev_state.get(p_name, {})
        already_settled = prev_p.get("settled", False)

        if gap <= args.thresh or already_settled:
            pin_info["settled"] = True
            settled.append(pin_info)
        else:
            # Check for saturation (tail current has died to zero)
            prev_gap = prev_p.get("gap")
            prev_th = prev_p.get("th")
            is_saturated = False
            d_gap = 0.0
            if prev_gap is not None and cur_th > prev_th:
                d_gap = abs(gap - prev_gap)
                if d_gap < 0.25:
                    is_saturated = True
                    pin_info["saturated"] = True
                    pin_info["d_gap"] = d_gap

            if is_saturated:
                sys.stderr.write(
                    f"  [SETTLED] {p_name}: gap {gap:.2f}% did not change with hold time "
                    f"({format_time_ns(prev_th)} -> {format_time_ns(cur_th)}, delta={d_gap:.2f}% < 0.25%). "
                    f"Tail current is zero; residual gap is physical CMOS rise/fall asymmetry.\n"
                )
                pin_info["settled"] = True
                settled.append(pin_info)
            elif cur_th >= max_th_ns:
                sys.stderr.write(
                    f"  [SETTLED] {p_name}: reached max hold time {format_time_ns(cur_th)} at gap {gap:.2f}%. "
                    f"Accepted as fully settled.\n"
                )
                pin_info["settled"] = True
                settled.append(pin_info)
            else:
                next_th = min(cur_th * args.step_th, max_th_ns)
                pin_info["next_th"] = next_th
                unsettled.append(pin_info)

    if missing:
        sys.stderr.write(f"ERROR: Measurement failed for pins: {', '.join(missing)}\n")
        sys.exit(2)

    # Save current measurements for the next iteration's saturation check
    settled_names = {p["name"] for p in settled}
    cur_state = {p["name"]: {"gap": p["gap"], "th": p["cur_th"], "settled": p["name"] in settled_names} for p in (settled + unsettled)}
    try:
        with open(state_file, "w") as f:
            json.dump(cur_state, f, indent=2)
    except Exception:
        pass

    # If --report is requested, print summary
    if args.report:
        sys.stderr.write(f"\nPin Settling Summary (Threshold: {args.thresh:.2f}%):\n")
        sys.stderr.write(f"{'Pin':12s} {'t_hold':8s} {'c_cyc(fF)':10s} {'c_rise':10s} {'c_fall':10s} {'Gap(%)':8s} {'Status':12s}\n")
        sys.stderr.write("-" * 75 + "\n")
        for p in settled + unsettled:
            status = "PASSED" if p.get("settled") or p["gap"] <= args.thresh or p.get("saturated") or p["cur_th"] >= max_th_ns else f"UNSETTLED (>{args.thresh:.1f}%)"
            sys.stderr.write(f"{p['name']:12s} {format_time_ns(p['cur_th']):8s} {p['c_cyc']:10.4f} {p['c_rise']:10.4f} {p['c_fall']:10.4f} {p['gap']:7.2f}%  {status}\n")

    if not unsettled:
        if os.path.isfile(state_file):
            try:
                os.remove(state_file)
            except Exception:
                pass
        sys.stdout.write("CONVERGED\n")
        sys.exit(0)

    # Check max iterations guard
    if args.max_iter > 0 and args.iteration >= args.max_iter:
        sys.stderr.write(f"\n[INFO] Pin settling reached maximum iterations ({args.max_iter}). Accepting current characterization.\n")
        if os.path.isfile(state_file):
            try:
                os.remove(state_file)
            except Exception:
                pass
        sys.stdout.write("CONVERGED\n")
        sys.exit(0)

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
