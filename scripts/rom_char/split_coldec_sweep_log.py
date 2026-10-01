#!/usr/bin/env python3
"""Validate one coldec sweep log and emit legacy per-address measure logs."""

from pathlib import Path
import argparse
import re


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("log")
    ap.add_argument("outdir")
    ap.add_argument("corner")
    ap.add_argument("--vdd", type=float, required=True)
    ap.add_argument("--settle-thresh", type=float, default=1.0)
    args = ap.parse_args()

    text = Path(args.log).read_text(errors="replace")
    values = {}
    pattern = r"^(a\d+_(?:rise(?:_prev)?|fall|sel\d+))\s*=\s*([-+0-9.eE]+)"
    for name, raw in re.findall(pattern, text, re.M):
        values[name] = float(raw)

    checked = []
    for address in range(8):
        rise = values.get(f"a{address}_rise")
        previous = values.get(f"a{address}_rise_prev")
        fall = values.get(f"a{address}_fall")
        levels = [values.get(f"a{address}_sel{select}") for select in range(8)]
        if rise is None or previous is None or fall is None or any(v is None for v in levels):
            raise SystemExit(f"address {address}: missing sweep measurements")
        high = [select for select, level in enumerate(levels)
                if level > args.vdd / 2.0]
        if high != [address]:
            raise SystemExit(
                f"address {address}: decoder is not one-hot; high selects={high}, levels={levels}")
        gap = 100.0 * abs(rise - previous) / max(abs(rise), abs(previous))
        if gap > args.settle_thresh:
            raise SystemExit(
                f"address {address}: not settled; consecutive rise delays differ by "
                f"{gap:.3f}% (limit {args.settle_thresh:.3f}%)")
        checked.append((address, rise, fall, gap, levels))

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    for address, rise, fall, gap, levels in checked:
        lines = [
            f"* split from {Path(args.log).name}; one parsed netlist, one transient",
            "Using KLU as Direct Linear Solver",
            f"t_pre2sel{address}_rise = {rise:.12e}",
            f"t_pre2sel{address}_fall = {fall:.12e}",
            f"t_pre2sel{address}_settle_gap_pct = {gap:.6f}",
        ]
        lines += [f"v_sel{select}_probe = {level:.12e}"
                  for select, level in enumerate(levels)]
        (outdir / f"coldec_a{address}_{args.corner}.log").write_text(
            "\n".join(lines) + "\n")
        print(f"addr{address}: rise={rise*1e9:.6f} ns fall={fall*1e9:.6f} ns "
              f"settle_gap={gap:.3f}% onehot=yes")


if __name__ == "__main__":
    main()
