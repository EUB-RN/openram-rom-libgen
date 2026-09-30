#!/usr/bin/env python3
"""Shared SPICE netlist parsing and unit manipulation utilities.

Consolidates common SPICE netlist functions used across characterization
deck generators (gen_periphery_power_tb, gen_backend_delay_tb, gen_cell_gate_tb,
gen_col_tb_parasitic).
"""

from __future__ import annotations

import collections
import re
from typing import Dict, Iterable, List, Optional, OrderedDict


# Standard SPICE engineering / SI suffixes (case-insensitive parsing)
SUFFIX: Dict[str, float] = {
    "f": 1e-15,
    "p": 1e-12,
    "n": 1e-9,
    "u": 1e-6,
    "m": 1e-3,
    "k": 1e3,
}


def to_float(tok: str) -> float:
    """Parse a number with an optional engineering/SI unit suffix into float.

    Supports f, p, n, u, m, k (case-insensitive).
    Raises ValueError on invalid token format.
    """
    tok_clean = tok.strip()
    m = re.match(r"^([0-9.eE+-]+)([a-zA-Z]?)$", tok_clean)
    if not m:
        raise ValueError(f"Invalid numeric token: {tok!r}")
    val_str, sfx = m.group(1), m.group(2).lower()
    if sfx and sfx not in SUFFIX:
        raise ValueError(f"Unknown SI/engineering unit suffix: {sfx!r} in {tok!r}")
    return float(val_str) * SUFFIX.get(sfx, 1.0)


def fix_units(line: str) -> str:
    """Normalize w/l/pd/ps to microns and ad/as to square microns for ngspice.

    - w, l, pd, ps -> multiplied by 1e6 (meters to microns)
    - ad, as -> multiplied by 1e12 (m^2 to um^2) with 'u' suffix
    """
    line = re.sub(
        r"\b(w|l|pd|ps)=([0-9.eE+-]+[a-zA-Z]?)\b",
        lambda m: f"{m.group(1)}={to_float(m.group(2)) * 1e6:.6g}",
        line,
    )
    line = re.sub(
        r"\b(ad|as)=([0-9.eE+-]+[a-zA-Z]?)\b",
        lambda m: f"{m.group(1)}={to_float(m.group(2)) * 1e12:.6g}u",
        line,
    )
    return line


def blocks_from_lines(lines: Iterable[str]) -> OrderedDict[str, List[str]]:
    """Parse an iterable of SPICE netlist lines into a subcircuit dictionary.

    - Joins continuation lines starting with '+'
    - Skips comments (starting with '*') and blank lines
    - Groups content by subcircuit name: OrderedDict[subckt_name, List[logical_line]]
    - Logical line 0 of each subcircuit is the '.subckt ...' header
    """
    out: OrderedDict[str, List[str]] = collections.OrderedDict()
    cur: Optional[str] = None
    name: Optional[str] = None

    def flush():
        nonlocal cur
        if cur is not None and name is not None:
            out[name].append(cur)
        cur = None

    for raw in lines:
        s = raw.rstrip("\r\n")
        if not s or s.startswith("*"):
            continue
        if s.startswith("+"):
            if cur is not None:
                cur += " " + s[1:].strip()
            continue
        flush()
        low = s.lower()
        if low.startswith(".subckt"):
            parts = s.split()
            if len(parts) > 1:
                name = parts[1]
                out.setdefault(name, [])
                cur = s
        elif low.startswith(".ends"):
            flush()
            name = None
        else:
            cur = s
    flush()
    return out


def blocks(path: str) -> OrderedDict[str, List[str]]:
    """Parse a SPICE netlist file from disk into subcircuit name -> logical lines."""
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        return blocks_from_lines(f)
