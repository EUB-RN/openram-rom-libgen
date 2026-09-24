#!/usr/bin/env python3
"""Find the worst column and its series-chain length from an OpenRAM ROM netlist.

WHY THIS FILE EXISTS
--------------------
Every timing measurement in the flow rests on a single column:
`gen_col_tb_parasitic.py <macro> <column>` builds that column's bitline, and the
access/t_pre numbers in the .lib come from it. That column number used to be
supplied from OUTSIDE (155/67/83/116 on older macros) with no record of how it
had been found -- a gap that had to be filled by hand every time the macro was
regenerated. This script closes it.

WHAT IS COUNTED
---------------
In a NAND-style (series chain) ROM a bitline is as many cells in series as
there are rows. There are two cell types (see `<macro>.sp`):

    rom_base_one_cell   -> a real NMOS, gate on the wordline  (RESISTANCE)
    rom_base_zero_cell  -> source/drain shorted               (wire only)

What sets the discharge time is the NUMBER of `one_cell`s in that column --
i.e. how many real transistors are in series. The column with the most
`one_cell`s is the slowest one, and characterization must use it.

Cell instances in the netlist are named `Xbit_r<row>_c<column>`; the
sub-circuit name sits at the end of the continuation (`+`) lines.

WHY THE CHAIN LENGTH MATTERS TOO
--------------------------------
`t_access` scales roughly QUADRATICALLY with the chain length (distributed RC).
Three measured points (chain 267 -> 94.1 ns, 150 -> 31.7 ns, 75 -> 9.2 ns) give
1.32/1.41/1.64e-3 for t/L^2. So the chain length lets you predict what access
will be after a regeneration WITHOUT simulating, and the effect of changing
`words_per_row` shows up directly here.

Usage:
    python3 find_worst_column.py                 # every macro in the tree
    python3 find_worst_column.py wrom0 wrom2     # selected macros
    python3 find_worst_column.py --sp path/x.sp  # a netlist directly
"""

import argparse
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

INST_RE = re.compile(r"^Xbit_r(\d+)_c(\d+)\s*$")


def analyse(sp_path):
    """Return (rows, cols, worst_col, chain, average, minimum)."""
    with open(sp_path) as fh:
        lines = fh.read().split("\n")

    one = collections.Counter()
    rows, cols = set(), set()
    # CAREFUL: the name `Xbit_r<r>_c<c>` appears in THREE different
    # sub-circuits -- the main array, the row decoder array and the column
    # decoder array. Without scoping, decoder cells get counted too; the
    # contamination lands only on low column numbers, so both the chain length
    # AND THE CHOICE OF WORST COLUMN come out wrong (confirmed on wrom1/wrom2
    # on 2026-09-08: the column picked was not the real worst one, which made
    # the .lib optimistic). Hence only `*_rom_base_array` is counted.
    cur_subckt = None
    i = 0
    while i < len(lines):
        if lines[i].startswith(".SUBCKT "):
            cur_subckt = lines[i].split()[1]
        m = INST_RE.match(lines[i])
        if not m or not (cur_subckt or "").endswith("_rom_base_array"):
            i += 1
            continue
        rows.add(int(m.group(1)))
        col = int(m.group(2))
        cols.add(col)
        # the instance body is on the continuation lines; the sub-circuit name
        # is the last token
        j = i + 1
        buf = []
        while j < len(lines) and lines[j].startswith("+"):
            buf.append(lines[j][1:])
            j += 1
        if buf:
            subckt = " ".join(buf).split()[-1]
            if subckt.endswith("one_cell"):
                one[col] += 1
        i = j

    if not one:
        return None
    worst_col, chain = one.most_common(1)[0]
    # The BEST column matters as much as the worst one now: the worst column
    # bounds the late path (access, setup) and the best column bounds the
    # EARLY path (the retain times -- how soon dout0 can start moving). A .lib
    # with only the worst column carries no early data at all, and a hold
    # check against the capture flop then has nothing to fail on.
    best_col = min(one, key=lambda c: (one[c], c))
    return (len(rows), len(cols), worst_col, chain,
            sum(one.values()) / len(one), one[best_col], best_col)


def row_zero_counts(sp_path):
    """Return (rows, cols, {row: number of zero_cells in that row}).

    WHY A PER-ROW VIEW: `analyse` answers a timing question ("which column is
    slowest"), which only needs one_cells counted per COLUMN. Dynamic energy
    asks the opposite question about the same array. A read selects one row and
    drops its wordline; a column discharges only if the cell in that row is a
    `zero_cell` (a metal strap, which conducts whatever its wordline does) --
    a `one_cell` in the selected row is an NMOS whose gate has just gone low,
    so it opens the series chain and that bitline stays at VDD. So the charge
    drawn on the next precharge is set by the number of zero_cells in the
    SELECTED ROW, which is what this returns.

    The same `*_rom_base_array` scoping rule as `analyse` applies, and for the
    same reason: `Xbit_r<r>_c<c>` names are reused by the row and column
    decoder arrays, and counting those would contaminate the low rows.
    """
    with open(sp_path) as fh:
        lines = fh.read().split("\n")

    zero = collections.Counter()
    rows, cols = set(), set()
    cur_subckt = None
    i = 0
    while i < len(lines):
        if lines[i].startswith(".SUBCKT "):
            cur_subckt = lines[i].split()[1]
        m = INST_RE.match(lines[i])
        if not m or not (cur_subckt or "").endswith("_rom_base_array"):
            i += 1
            continue
        row = int(m.group(1))
        rows.add(row)
        cols.add(int(m.group(2)))
        zero.setdefault(row, 0)
        j = i + 1
        buf = []
        while j < len(lines) and lines[j].startswith("+"):
            buf.append(lines[j][1:])
            j += 1
        if buf and " ".join(buf).split()[-1].endswith("zero_cell"):
            zero[row] += 1
        i = j

    if not rows:
        return None
    return len(rows), len(cols), dict(zero)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("macros", nargs="*", default=None,
                    help="macro names (default: every macro in the tree)")
    ap.add_argument("--macros-dir", default=None,
                    help="macro tree (default: ROM_MACROS_DIR / <repo>/examples)")
    ap.add_argument("--sp", help="a netlist path directly (instead of a macro name)")
    args = ap.parse_args()

    targets = []
    if args.sp:
        targets.append((os.path.basename(args.sp).replace(".sp", ""), args.sp))
    else:
        # rom_paths is imported late: it IMPORTS this module, so importing it at
        # module level would be circular.
        sys.path.insert(0, HERE)
        import rom_paths
        names = args.macros or rom_paths.discover(args.macros_dir)
        if not names:
            sys.exit("no macros found in %s" % rom_paths.macros_dir(args.macros_dir))
        for n in names:
            targets.append((n, rom_paths.netlist(n, args.macros_dir)))

    print("%-8s %6s %6s %14s %11s %8s %6s %13s"
          % ("macro", "rows", "cols", "worst_column", "series_NMOS", "avg",
             "min", "best_column"))
    rows_out = []
    for name, path in targets:
        if not os.path.exists(path):
            print("%-8s  no netlist: %s" % (name, path), file=sys.stderr)
            continue
        r = analyse(path)
        if r is None:
            print("%-8s  no Xbit_r*_c* instances -- different netlist format?"
                  % name, file=sys.stderr)
            continue
        nrows, ncols, wcol, chain, avg, mn, bcol = r
        print("%-8s %6d %6d %14d %11d %8.1f %6d %13d"
              % (name, nrows, ncols, wcol, chain, avg, mn, bcol))
        rows_out.append((name, wcol, chain))

    if rows_out:
        # This output is for inspection only: rom_paths.py runs the same
        # analysis and feeds run_*.sh and regen_rom_libs.sh automatically.
        print("\nNext (the column argument is optional -- it comes from here):")
        for name, _wcol, _ in rows_out:
            print("  python3 gen_col_tb_parasitic.py %s" % name)


if __name__ == "__main__":
    main()
