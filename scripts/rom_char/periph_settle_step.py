#!/usr/bin/env python3
"""
periph_settle_step.py: Evaluates periphery energy settling (q_c2 vs q_c3)
and computes the dynamic adaptive jump for the next iteration.

Instead of fixed tiny steps (+2 cycles), it adapts based on gap magnitude:
  * gap <= THRESH or delta_E < NOISE_FLOOR: CONVERGED (exit 0)
  * gap < 5%: fine adjustment (+2 cycles)
  * 5% <= gap < 20%: moderate adjustment (+4 cycles)
  * 20% <= gap < 50%: aggressive jump (+6 cycles)
  * gap >= 50%: large jump (+8 cycles)

Outputs key-value shell format or JSON for clean integration into bash scripts.

Exit codes:
  0: Settled (CONVERGED).
  1: Not settled, next cycle count proposed.
  2: Max cycles reached without convergence.
"""

import sys
import os
import re
import argparse
import json
import math


def predict_next_corner_cycles(first_cycles, second_cycles):
    """Extrapolate the next corner from the last two settled corners.

    If convergence moved from 14 to 18 cycles, keep the same multiplicative
    slowdown for the next corner: 18 * (18 / 14) = 23.14, rounded up to the
    next even cycle (24).  Even counts match the two-cycle measurement cadence.
    """
    if first_cycles <= 0 or second_cycles <= 0:
        raise ValueError("settled cycle counts must be positive")
    predicted = math.ceil((second_cycles * second_cycles) / first_cycles)
    predicted = max(predicted, second_cycles)
    return predicted if predicted % 2 == 0 else predicted + 1


def parse_meas_val(log_path, name):
    """Extract a float value from an ngspice .measure output line."""
    if not os.path.isfile(log_path):
        return None
    pattern = re.compile(rf"^\s*{re.escape(name)}\s*=\s*([+-]?[\d.]+(?:[eE][+-]?\d+)?)", re.MULTILINE)
    with open(log_path, "r", errors="ignore") as f:
        content = f.read()
    m = pattern.search(content)
    if m:
        try:
            return float(m.group(1))
        except ValueError:
            return None
    return None


def evaluate_settling(q2, q3, vdd, current_cycles, max_cycles=20, thresh_pct=1.0, noise_floor_pj=0.1):
    """
    Returns (settled, gap_pct, delta_e_pj, next_cycles, reason)
    """
    if q2 is None or q3 is None:
        return False, None, None, current_cycles, "missing q_c2 or q_c3 measurement"

    abs_q2 = abs(q2)
    abs_q3 = abs(q3)
    delta_q = abs(abs_q2 - abs_q3)
    delta_e_pj = delta_q * vdd * 1e12

    if abs_q3 > 1e-18:
        gap_pct = (delta_q / abs_q3) * 100.0
    else:
        gap_pct = 999.99

    # Condition 1: Relative percentage within quota
    if gap_pct <= thresh_pct:
        return True, gap_pct, delta_e_pj, current_cycles, f"gap {gap_pct:.2f}% <= {thresh_pct:.2f}% (converged)"

    # Condition 2: Absolute energy difference is below physical noise floor
    if noise_floor_pj is not None and delta_e_pj < noise_floor_pj:
        return True, gap_pct, delta_e_pj, current_cycles, f"delta_E {delta_e_pj:.4f} pJ < noise floor {noise_floor_pj:.2f} pJ (converged)"

    # Check max cycles
    if current_cycles >= max_cycles:
        return False, gap_pct, delta_e_pj, current_cycles, f"reached max cycles ({current_cycles}) with gap {gap_pct:.2f}%"

    # Dynamic adaptive jump calculation
    if gap_pct >= 50.0:
        jump = 8
    elif gap_pct >= 20.0:
        jump = 6
    elif gap_pct >= 5.0:
        jump = 4
    else:
        jump = 2

    next_cycles = min(current_cycles + jump, max_cycles)
    return False, gap_pct, delta_e_pj, next_cycles, f"gap {gap_pct:.2f}% > {thresh_pct:.2f}%, jumping +{jump} -> {next_cycles} cycles"


def main():
    parser = argparse.ArgumentParser(description="Evaluate periphery energy settling")
    parser.add_argument("log_file", nargs="?", default=None, help="ngspice log file (.log)")
    parser.add_argument("--q2", type=float, default=None, help="Direct q_c2 charge value")
    parser.add_argument("--q3", type=float, default=None, help="Direct q_c3 charge value")
    parser.add_argument("--vdd", type=float, default=1.8, help="Supply voltage (default: 1.8)")
    parser.add_argument("--current-cycles", type=int, default=8, help="Current cycles (default: 8)")
    parser.add_argument("--max-cycles", type=int, default=20, help="Maximum allowed cycles (default: 20)")
    parser.add_argument("--thresh", type=float, default=1.0, help="Settling threshold in %% (default: 1.0)")
    parser.add_argument("--noise-floor-pj", type=float, default=0.1, help="Absolute energy noise floor in pJ (default: 0.1)")
    parser.add_argument("--json", action="store_true", help="Output JSON instead of shell env format")
    parser.add_argument("--predict-cycles", nargs=2, type=int,
                        metavar=("FIRST", "SECOND"),
                        help="predict the next corner from two settled cycle counts")

    args = parser.parse_args()

    if args.predict_cycles is not None:
        try:
            print(predict_next_corner_cycles(*args.predict_cycles))
        except ValueError as exc:
            parser.error(str(exc))
        return

    q2 = args.q2
    q3 = args.q3

    if args.log_file:
        if q2 is None:
            q2 = parse_meas_val(args.log_file, "q_c2")
        if q3 is None:
            q3 = parse_meas_val(args.log_file, "q_c3")

    settled, gap_pct, delta_e_pj, next_cyc, reason = evaluate_settling(
        q2=q2,
        q3=q3,
        vdd=args.vdd,
        current_cycles=args.current_cycles,
        max_cycles=args.max_cycles,
        thresh_pct=args.thresh,
        noise_floor_pj=args.noise_floor_pj
    )

    if args.json:
        out = {
            "settled": settled,
            "gap_pct": round(gap_pct, 4) if gap_pct is not None else None,
            "delta_e_pj": round(delta_e_pj, 6) if delta_e_pj is not None else None,
            "current_cycles": args.current_cycles,
            "next_cycles": next_cyc,
            "max_cycles": args.max_cycles,
            "reason": reason
        }
        print(json.dumps(out, indent=2))
    else:
        # Shell exportable format
        print(f"SETTLED={'1' if settled else '0'}")
        print(f"GAP_PCT={gap_pct:.2f}" if gap_pct is not None else "GAP_PCT=-1")
        print(f"DELTA_E_PJ={delta_e_pj:.6f}" if delta_e_pj is not None else "DELTA_E_PJ=-1")
        print(f"CURRENT_CYCLES={args.current_cycles}")
        print(f"NEXT_CYCLES={next_cyc}")
        print(f"REASON=\"{reason}\"")

    if settled:
        sys.exit(0)
    elif args.current_cycles >= args.max_cycles:
        sys.exit(2)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
