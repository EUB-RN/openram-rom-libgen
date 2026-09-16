#!/usr/bin/env python3
"""Make the inside of a ROM macro VISIBLE -- a learning / inspection tool.

WHY THIS FILE EXISTS
--------------------
`find_worst_column.py` produces one number (the worst column) but not WHERE it
came from. This script reads the same netlist and shows the middle of the
story: how many cells live in which sub-circuit, how the series-NMOS count is
distributed across columns, and what a chosen column looks like row by row.

THREE COMMANDS
--------------
    python3 rom_explore.py wrom0             # summary + histogram + worst 10
    python3 rom_explore.py wrom0 --col 54    # row-by-row map of that column
    python3 rom_explore.py wrom0 --compare   # base_array vs decoder counting

THE CORE IDEA (understand this and the rest is detail)
------------------------------------------------------
In a NAND-style ROM a bitline is all the cells of that column IN SERIES.

    rom_base_one_cell  : bl_h --[NMOS gate=wl]-- bl_l   -> RESISTANCE in chain
    rom_base_zero_cell : bl   --[   shorted   ]-- bl    -> WIRE only

So the number of real transistors in the chain is the `one_cell` count of that
column. Discharge time grows roughly QUADRATICALLY with it (distributed RC).
The column with the most `one_cell`s is the slowest one, and characterization
runs on it.

CAREFUL: `Xbit_r*_c*` names are NOT unique in the netlist -- the same name
repeats in the data array, the row decoder and the column decoder. Counting
must be limited to `.SUBCKT <macro>_rom_base_array`, otherwise decoder cells
get added to data columns (see --compare).
"""

import argparse
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rom_paths
MACROS_DIR = rom_paths.macros_dir()
INST_RE = re.compile(r"^Xbit_r(\d+)_c(\d+)\s*$")


def parse(sp_path):
    """Return {sub_circuit: {(row, column): 'one'|'zero'}}."""
    cells = collections.defaultdict(dict)
    lines = open(sp_path).read().split("\n")
    sub = None
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith(".SUBCKT"):
            sub = line.split()[1]
        m = INST_RE.match(line)
        if not m:
            i += 1
            continue
        j, buf = i + 1, []
        while j < len(lines) and lines[j].startswith("+"):
            buf.append(lines[j][1:])
            j += 1
        name = " ".join(buf).split()[-1] if buf else ""
        if name.endswith("one_cell") or name.endswith("zero_cell"):
            cells[sub][(int(m.group(1)), int(m.group(2)))] = (
                "one" if name.endswith("one_cell") else "zero")
        i = j
    return cells


def base_array(cells, macro):
    key = macro + "_rom_base_array"
    if key in cells:
        return cells[key]
    if not cells:
        sys.exit("no cells found -- different netlist format?")
    return cells[max(cells, key=lambda k: len(cells[k]))]


def chains(grid):
    """column -> number of series NMOS (one_cell)."""
    c = collections.Counter()
    for (_, col), kind in grid.items():
        if kind == "one":
            c[col] += 1
    return c


def show_summary(macro, cells):
    grid = base_array(cells, macro)
    rows = 1 + max(r for r, _ in grid)
    cols = 1 + max(c for _, c in grid)
    ch = chains(grid)
    vals = [ch.get(c, 0) for c in range(cols)]
    worst = max(range(cols), key=lambda c: ch.get(c, 0))

    print("== %s -- data array (%s_rom_base_array)" % (macro, macro))
    print("   %d rows x %d columns = %d cells" % (rows, cols, rows * cols))
    print("   one bitline = a SERIES chain of %d cells" % rows)
    print()
    print("   series NMOS per column (one_cell):")
    print("     worst  : column %-4d -> %d   <-- characterization must use this"
          % (worst, ch[worst]))
    print("     average:               %.1f" % (sum(vals) / len(vals)))
    print("     best   : column %-4d -> %d"
          % (min(range(cols), key=lambda c: ch.get(c, 0)), min(vals)))
    print()

    lo, hi = min(vals), max(vals)
    nb = 20
    width = max(1, (hi - lo + 1) / nb)
    hist = collections.Counter(int((v - lo) / width) for v in vals)
    peak = max(hist.values())
    print("   distribution (%d columns):" % cols)
    for b in range(nb):
        n = hist.get(b, 0)
        if not n:
            continue
        print("     %3d-%3d | %-40s %d"
              % (lo + b * width, lo + (b + 1) * width - 1,
                 "#" * int(40 * n / peak), n))
    print()
    print("   slowest 10 columns:")
    for col, n in sorted(ch.items(), key=lambda kv: -kv[1])[:10]:
        print("     column %-4d %3d series NMOS   (inspect: %s --col %d)"
              % (col, n, macro, col))
    print()
    print("   next: python3 gen_col_tb_parasitic.py %s %d"
          % (macro, worst))


def show_column(macro, cells, col):
    grid = base_array(cells, macro)
    rows = 1 + max(r for r, _ in grid)
    seq = [grid.get((r, col)) for r in range(rows)]
    n_one = sum(1 for s in seq if s == "one")
    print("== %s column %d -- bitline chain (top to bottom, %d rows)"
          % (macro, col, rows))
    print("   1 = one_cell  (series NMOS, gate=wl) -> resistance in the chain")
    print("   0 = zero_cell (source/drain shorted) -> wire only")
    print()
    for r0 in range(0, rows, 40):
        chunk = seq[r0:r0 + 40]
        print("   r%-4d %s" % (r0, "".join(
            "1" if s == "one" else "0" if s == "zero" else "." for s in chunk)))
    print()
    print("   series NMOS count = %d  (real transistors in the discharge path)"
          % n_one)
    print("   chain length vs t_access is ~QUADRATIC: measured L=267->94.1 ns,"
          " 150->31.7 ns, 75->9.2 ns")


def show_compare(macro, cells):
    print("== %s -- which sub-circuits contain `Xbit_r*_c*` names" % macro)
    for sub, g in sorted(cells.items(), key=lambda kv: -len(kv[1])):
        print("   %-40s %6d cells" % (sub, len(g)))
    print()
    only = chains(base_array(cells, macro))
    allc = collections.Counter()
    for g in cells.values():
        allc.update(chains(g))
    w1, c1 = max(only.items(), key=lambda kv: kv[1])
    w2, c2 = max(allc.items(), key=lambda kv: kv[1])
    print("   data array only : worst column %-4d chain %d   <-- CORRECT" % (w1, c1))
    print("   everything mixed: worst column %-4d chain %d" % (w2, c2))
    if (w1, c1) != (w2, c2):
        print("   -> letting decoder cells into the count changes the answer.")


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("macro", help="macro name (wrom0) or a path to a .sp")
    ap.add_argument("--col", type=int, help="show the row map of this column")
    ap.add_argument("--compare", action="store_true",
                    help="compare data-array counting against decoder counting")
    a = ap.parse_args()

    if a.macro.endswith(".sp"):
        path, macro = a.macro, os.path.basename(a.macro)[:-3]
    else:
        macro = a.macro
        path = os.path.join(MACROS_DIR, macro, macro + ".sp")
    if not os.path.exists(path):
        sys.exit("no netlist: " + path)

    cells = parse(path)
    if a.compare:
        show_compare(macro, cells)
    elif a.col is not None:
        show_column(macro, cells, a.col)
    else:
        show_summary(macro, cells)


if __name__ == "__main__":
    main()
