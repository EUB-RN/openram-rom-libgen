#!/usr/bin/env python3
"""Shared SPICE netlist parsing and unit manipulation utilities.

Consolidates common SPICE netlist functions used across characterization
deck generators (gen_periphery_power_tb, gen_backend_delay_tb, gen_cell_gate_tb,
gen_col_tb_parasitic).

WHY THE PARSER IS STRICT
------------------------
Everything downstream of here is a number that ends up in a `.lib`. A parser
that quietly returns *less* than the file contains does not produce an error,
it produces an optimistic library -- so each structural defect this module can
detect is raised, not skipped. The three that used to pass silently:

  * an indented `.subckt` / `+` line (legal SPICE, emitted by hand-written and
    some third-party extractors) made the whole file parse to `{}`;
  * a second `.subckt` with a name already seen -- a cell pulled in twice by
    two `.include`s -- had its body appended to the first one, producing a
    merged circuit that exists nowhere;
  * a `.subckt` with no name swallowed its body.

OpenRAM's own output trips none of them; a user macro dropped in `user/` can.
"""

from __future__ import annotations

import collections
import re
from typing import Dict, Iterable, List, Optional, OrderedDict


# Standard SPICE engineering / SI suffixes (case-insensitive parsing).
# NOTE 'm' is MILLI and 'meg' is MEGA -- the classic SPICE trap. They are
# resolved by longest-match in to_float(), never by this table alone.
SUFFIX: Dict[str, float] = {
    "a": 1e-18,
    "f": 1e-15,
    "p": 1e-12,
    "n": 1e-9,
    "u": 1e-6,
    "m": 1e-3,
    "k": 1e3,
    "g": 1e9,
    "t": 1e12,
}

# Multi-character scale prefixes, longest first. 'mil' is SPICE's thousandth
# of an inch; it collides with 'm' (milli) on its first character, which is
# exactly why these are matched before SUFFIX.
LONG_SUFFIX = (
    ("meg", 1e6),
    ("mil", 25.4e-6),
)

# Unit NAMES that may trail a scale prefix. SPICE ignores them (1.5pF is
# 1.5e-12), but they are whitelisted rather than discarded wholesale so that a
# typo such as '1.5pZ' is still an error instead of 1.5e-12.
UNIT_NAMES = frozenset({
    "f", "farad", "farads",
    "h", "henry", "henrys", "henries",
    "s", "sec", "secs", "second", "seconds",
    "v", "volt", "volts",
    "a", "amp", "amps", "ampere", "amperes",
    "ohm", "ohms",
    "hz", "hertz",
    "m", "meter", "meters", "metre", "metres",
})


def to_float(tok: str) -> float:
    """Parse a number with an optional engineering/SI suffix and unit into float.

    Accepts the full SPICE suffix set (a f p n u m k meg mil g t, case
    insensitive) and an optional trailing unit name ('1.5pF', '2.5V', '50ohm').

    Raises ValueError on an invalid number, an unknown scale suffix, or a
    trailing word that is not a recognised unit.
    """
    tok_clean = tok.strip()
    m = re.match(r"^([0-9.eE+-]+?)([a-zA-Z]*)$", tok_clean)
    if not m:
        raise ValueError(f"Invalid numeric token: {tok!r}")
    val_str, tail = m.group(1), m.group(2).lower()

    try:
        val = float(val_str)
    except ValueError:
        # '1e-15' splits as ('1', 'e-15')? No -- 'e-15' is not [a-zA-Z]*, so the
        # non-greedy number group has already absorbed it. A failure here is a
        # genuinely malformed number ('.', '+-1').
        raise ValueError(f"Invalid numeric token: {tok!r}") from None

    scale = 1.0
    for word, factor in LONG_SUFFIX:
        if tail.startswith(word):
            scale, tail = factor, tail[len(word):]
            break
    else:
        # A scale prefix always wins over a unit name on the same letter:
        # in SPICE '1f' is a femto-unit, never one farad, and '1m' is a
        # milli-unit, never one metre. Only letters that are NOT scale
        # prefixes ('v', 'o' of ohm, 's') fall through to the unit check.
        if tail and tail[0] in SUFFIX:
            scale, tail = SUFFIX[tail[0]], tail[1:]

    if tail and tail not in UNIT_NAMES:
        raise ValueError(
            f"Unknown SI/engineering unit suffix: {tail!r} in {tok!r}")
    return val * scale


def fix_units(line: str) -> str:
    """Normalize w/l/pd/ps to microns and ad/as to square microns for ngspice.

    - w, l, pd, ps -> multiplied by 1e6 (meters to microns)
    - ad, as -> multiplied by 1e12 (m^2 to um^2) with 'u' suffix

    Attribute names are matched case-insensitively. They used to be matched
    lowercase-only, which meant an extractor emitting `W=1E-6` had its device
    left at 1e-6 *microns* -- a picometre transistor, simulated without
    complaint. Nothing downstream could have caught that.
    """
    line = re.sub(
        r"\b(w|l|pd|ps)=([0-9.eE+-]+[a-zA-Z]*)\b",
        lambda m: f"{m.group(1)}={to_float(m.group(2)) * 1e6:.6g}",
        line,
        flags=re.IGNORECASE,
    )
    line = re.sub(
        r"\b(ad|as)=([0-9.eE+-]+[a-zA-Z]*)\b",
        lambda m: f"{m.group(1)}={to_float(m.group(2)) * 1e12:.6g}u",
        line,
        flags=re.IGNORECASE,
    )
    return line


def blocks_from_lines(lines: Iterable[str],
                      source: str = "<lines>") -> OrderedDict[str, List[str]]:
    """Parse an iterable of SPICE netlist lines into a subcircuit dictionary.

    - Joins continuation lines starting with '+'
    - Skips comments (starting with '*') and blank lines
    - Leading whitespace is insignificant, as it is in SPICE
    - Groups content by subcircuit name: OrderedDict[subckt_name, List[logical_line]]
    - Logical line 0 of each subcircuit is the '.subckt ...' header

    Raises ValueError, naming the line number, for a `.subckt` with no name, a
    duplicate subcircuit name, a nested `.subckt`, a `.ends` outside any
    subcircuit, a continuation with nothing to continue, or a subcircuit left
    unterminated at end of file.
    """
    out: OrderedDict[str, List[str]] = collections.OrderedDict()
    cur: Optional[str] = None
    name: Optional[str] = None
    open_at = 0

    def fail(lineno: int, msg: str):
        raise ValueError(f"{source}:{lineno}: {msg}")

    def flush():
        nonlocal cur
        if cur is not None and name is not None:
            out[name].append(cur)
        cur = None

    lineno = 0
    for raw in lines:
        lineno += 1
        s = raw.strip()
        if not s or s.startswith("*"):
            continue
        if s.startswith("+"):
            if cur is None:
                fail(lineno, "continuation line '+' with no card to continue")
            cur += " " + s[1:].strip()
            continue
        flush()
        low = s.lower()
        if low.startswith(".subckt"):
            parts = s.split()
            if len(parts) < 2:
                fail(lineno, ".subckt with no name")
            if name is not None:
                fail(lineno, f"nested .subckt {parts[1]!r} inside {name!r} "
                             f"(opened at line {open_at}) -- not supported")
            if parts[1] in out:
                fail(lineno, f"duplicate .subckt {parts[1]!r} -- a second "
                             f"definition would be merged into the first, "
                             f"producing a circuit that exists nowhere")
            name = parts[1]
            open_at = lineno
            out[name] = []
            cur = s
        elif low.startswith(".ends"):
            if name is None:
                fail(lineno, ".ends outside any .subckt")
            flush()
            name = None
        else:
            cur = s
    flush()
    if name is not None:
        fail(lineno, f".subckt {name!r} (line {open_at}) is never closed "
                     f"by .ends")
    return out


def blocks(path: str) -> OrderedDict[str, List[str]]:
    """Parse a SPICE netlist file from disk into subcircuit name -> logical lines."""
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        return blocks_from_lines(f, source=path)
