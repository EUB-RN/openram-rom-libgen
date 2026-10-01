#!/usr/bin/env python3
"""Combine the eight column-address tests into one continuous transient.

Input is the ordinary five-cycle address-0 deck from
gen_periphery_power_tb.py --with-coldec.  Output keeps that exact circuit but
replaces addr0[2:0] with PWL sources, extends .tran to eight five-cycle blocks,
and adds bounded per-address measurements.  The netlist and device models are
therefore parsed/elaborated once instead of eight times.
"""

from pathlib import Path
import re
import sys


def spice_number(value):
    match = re.fullmatch(r"([0-9.]+)([a-zA-Z]*)", value)
    if not match:
        raise SystemExit(f"unsupported SPICE number: {value}")
    scales = {"": 1.0, "n": 1e-9, "u": 1e-6, "p": 1e-12}
    suffix = match.group(2).lower()
    if suffix not in scales:
        raise SystemExit(f"unsupported SPICE suffix: {suffix}")
    return float(match.group(1)) * scales[suffix]


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: gen_coldec_sweep_tb.py <base.sp> <sweep.sp>")
    source, output = map(Path, sys.argv[1:3])
    text = source.read_text()

    vdd_match = re.search(r"^\.param\s+VDD=([^\s]+)", text, re.M | re.I)
    tclk_match = re.search(r"^\.param\s+TCLK=([^\s]+)", text, re.M | re.I)
    tran_pattern = r"^\.tran\s+'?([^'\s]+)'?\s+'?5\*TCLK'?\s+uic\s*$"
    tran_match = re.search(tran_pattern, text, re.M | re.I)
    if not (vdd_match and tclk_match and tran_match):
        raise SystemExit("base deck lacks the expected VDD/TCLK/5-cycle transient")
    vdd = float(vdd_match.group(1))
    tclk = spice_number(tclk_match.group(1))
    block = 5 * tclk

    # Discover extracted node names from the normal deck, then remove its
    # unbounded measures. An unselected output may rise in a later address
    # block, so a TRIG/TARG search with no upper bound would misattribute it.
    measure_re = re.compile(
        r"^\.measure tran t_pre2sel(\d+)_(rise|fall) TRIG v\(([^)]+)\).*?\n"
        r"^\+\s+TARG v\(([^)]+)\).*?$", re.M | re.I)
    found = list(measure_re.finditer(text))
    rise = {int(m.group(1)): (m.group(3), m.group(4))
            for m in found if m.group(2).lower() == "rise"}
    fall = {int(m.group(1)): (m.group(3), m.group(4))
            for m in found if m.group(2).lower() == "fall"}
    if sorted(rise) != list(range(8)) or sorted(fall) != list(range(8)):
        raise SystemExit("could not discover all eight select measurements")
    text = measure_re.sub("", text)

    # Change address only at a block boundary, just after clk falls and the
    # precharge phase starts. Each address then gets the original five-cycle
    # settling budget. A finite 100 ps ramp avoids an ideal discontinuity.
    for bit in range(3):
        points = [(0.0, 0.0)]
        old = 0.0
        for address in range(1, 8):
            new = vdd if (address >> bit) & 1 else 0.0
            if new != old:
                at = address * block
                points += [(at, old), (at + 100e-12, new)]
                old = new
        points.append((8 * block, old))
        body = " ".join(f"{t:.12e} {value:.12g}" for t, value in points)
        replacement = f"Vaddr{bit} addr0[{bit}] 0 PWL({body})"
        text, count = re.subn(
            rf"^Vaddr{bit}\s+addr0\[{bit}\]\s+0\s+DC\s+.*$", replacement,
            text, count=1, flags=re.M)
        if count != 1:
            raise SystemExit(f"could not replace Vaddr{bit}")

    text = re.sub(tran_pattern,
                  f".tran '{tran_match.group(1)}' '{8 * block:.12e}' uic",
                  text, count=1, flags=re.M | re.I)

    measurements = ["", "* --- one transient, all eight column addresses ---"]
    for address in range(8):
        offset = address * block
        pre, selected = rise[address]
        # Compare the last two evaluate edges in the five-cycle block. The
        # later one is shipped; using the earlier pair left address 1 at a
        # measured 1.188% gap on wrom0/TT, just outside the flow's 1% limit.
        for suffix, cycle in (("_prev", 3.5), ("", 4.5)):
            trig = offset + (cycle - 0.05) * tclk
            targ = offset + cycle * tclk
            measurements += [
                f".measure tran a{address}_rise{suffix} TRIG v({pre}) "
                f"VAL='VDD/2' RISE=1 TD={trig:.12e}",
                f"+ TARG v({selected}) VAL='VDD/2' RISE=1 TD={targ:.12e}",
            ]
        trig_fall = offset + 3.95 * tclk
        targ_fall = offset + 4.00 * tclk
        probe = offset + 4.55 * tclk
        measurements += [
            f".measure tran a{address}_fall TRIG v({fall[address][0]}) "
            f"VAL='VDD/2' FALL=1 TD={trig_fall:.12e}",
            f"+ TARG v({fall[address][1]}) VAL='VDD/2' FALL=1 TD={targ_fall:.12e}",
        ]
        for select in range(8):
            measurements.append(
                f".measure tran a{address}_sel{select} "
                f"FIND v({rise[select][1]}) AT={probe:.12e}")

    text = re.sub(r"^\.end\s*$", "\n".join(measurements) + "\n.end", text,
                  count=1, flags=re.M | re.I)
    output.write_text(text)


if __name__ == "__main__":
    main()
