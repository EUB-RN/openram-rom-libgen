#!/usr/bin/env python3
"""Dynamic read energy from an AVERAGE OF RANDOM READS, not from the worst case.

WHY THIS FILE EXISTS
--------------------
`internal_power` on clk0 for `when : "cs0"` used to be written as

    E = <column count> x E_column + E_periphery          (256 x E_col + E_per)

i.e. every bitline in the macro discharging on every read. That is the worst
case, and it is not a rare one -- it is impossible unless the selected row is
all zeros. What actually happens in one read cycle:

  * clk0 = 0 (precharge): every bitline bl_0..bl_<cols-1> is pulled to VDD.
  * clk0 = 1 (evaluate) : the selected row's wordline FALLS. A column whose
    cell in that row is a `zero_cell` is a metal strap -- it conducts whatever
    the wordline does, the series chain stays closed, and that bitline
    discharges to ground. A column whose cell is a `one_cell` is an NMOS whose
    gate has just gone low: it opens the chain and that bitline STAYS at VDD.
  * next precharge: charge is drawn from VDD only for the bitlines that
    actually discharged.

So the energy of one read is set by the number of zeros in the SELECTED ROW:

    E_i = N_discharge(row_i) x E_column + E_periphery

On the example macros the array is about half zeros (wrom0: 126.9 of 256 per
row on average), so the all-columns assumption is ~1.9x pessimistic. This tool
samples `--reads` random addresses out of the macro's valid address space,
computes E_i for each, and reports the average -- which is what belongs in the
.lib for a data sheet number, the worst case being available separately.

WHAT IS MEASURED AND WHAT IS COMPUTED
-------------------------------------
Nothing here simulates. The two energy terms are MEASURED, and read from the
logs the existing runs write:

    E_column    char/col<worst>_energy_<corner>.log   e_col_pj
                (run_col_energy.sh -- charge per discharged column per cycle)
    E_periphery char/periph_active_<corner>.log       e_periph_pj
                (run_periphery_power.sh -- clock tree, address buffers, row
                 decoder, wordlines, mux, output buffer)

What this tool adds is the ACTIVITY: how many columns of the array discharge
on a given read, counted from the netlist's own cell types. E_column is taken
at the worst column, so per-read energy stays on the safe side of a
column-by-column sum.

REPRODUCIBILITY, AND WHY THE CORNER IS NOT IN THE SEED
-----------------------------------------------------
The default seed is derived from the MACRO NAME ALONE, so a .lib regenerated
from unchanged inputs carries an unchanged number -- the same rule every other
value in this flow follows. `--seed <n>` pins a different draw and
`--seed random` takes a fresh one from the OS.

The corner is deliberately NOT part of it. How many columns discharge on a
given read is a property of the ROM CONTENTS, not of the process corner: the
same address selects the same row and that row holds the same zeros at tt, ss
and ff. Only E_column and E_periphery move with the corner. Seeding per corner
drew a different sample at each one and let that difference leak into the
activity -- on wrom0 the sampled mean came out 124.8 / 126.9 / 133.3 columns
at tt / ss / ff against a true 126.9 everywhere, i.e. a spurious 6.8% spread
between two corners that is pure sampling noise. With one seed per macro all
three corners read the SAME ten addresses and the corner ratios carry nothing
but the measured energies.

Usage:
    python3 gen_random_read_energy.py wrom0 --corner tt
    python3 gen_random_read_energy.py wrom0 --corner tt --energy-only
    python3 gen_random_read_energy.py wrom0 --corner ss --reads 100 --seed 7
"""

from __future__ import annotations

import argparse
import os
import random
import statistics
import sys
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import find_worst_column                                # noqa: E402
import rom_paths                                        # noqa: E402


def meas(log_path, name):
    """The value of an ngspice .measure line, or None. Same rule as common.sh."""
    if not os.path.exists(log_path):
        return None
    with open(log_path) as fh:
        for line in fh:
            if line.startswith(name + " "):
                parts = line.split()
                if len(parts) >= 3:
                    try:
                        return float(parts[2])
                    except ValueError:
                        return None
    return None


def address_space(geom, rows):
    """(number of addresses, words_per_row).

    The word count comes from the .bin (rom_paths); it is the only thing that
    knows the LAST row is usually partly unprogrammed -- wrom0 is 134 rows x 8
    words = 1072 slots for 1064 words. Sampling the slots instead of the words
    would read addresses the ROM does not hold. With no .bin the whole array is
    addressable as far as anything here can tell, so fall back to that and say
    so in the report.
    """
    wpr = geom["words_per_row"] or 1
    words = geom["words"]
    if words:
        return words, wpr, True
    return rows * wpr, wpr, False


def sample(macro, corner, reads, seed, macros_dir=None):
    """Run the model. Returns a dict with the per-read table and the average."""
    geom = rom_paths.geometry(macro, macros_dir, quiet=True)
    scan = find_worst_column.row_zero_counts(geom["sp"])
    if scan is None:
        raise SystemExit("ERROR: no Xbit_r*_c* instances in %s -- is this an "
                         "OpenRAM ROM netlist?" % geom["sp"])
    rows, cols, zeros = scan

    char = geom["char"]
    e_col_log = os.path.join(char, "col%d_energy_%s.log"
                             % (geom["worst_col"], corner))
    e_per_log = os.path.join(char, "periph_active_%s.log" % corner)
    e_col = meas(e_col_log, "e_col_pj")
    e_per = meas(e_per_log, "e_periph_pj")
    missing = []
    if e_col is None:
        missing.append("e_col_pj in %s (run run_col_energy.sh)" % e_col_log)
    if e_per is None:
        missing.append("e_periph_pj in %s (run run_periphery_power.sh)"
                       % e_per_log)
    if missing:
        raise SystemExit("ERROR: %s: missing measurement --\n       %s"
                         % (macro, "\n       ".join(missing)))

    naddr, wpr, from_bin = address_space(geom, rows)
    rng = random.Random(seed)
    table = []
    for _ in range(reads):
        addr = rng.randrange(naddr)
        row = addr // wpr
        n_dis = zeros.get(row, 0)
        table.append((addr, row, n_dis, n_dis * e_col + e_per))

    energies = [t[3] for t in table]
    all_rows = sorted(zeros.values())
    return {
        "macro": geom["macro"],
        "corner": corner,
        "rows": rows,
        "cols": cols,
        "words": naddr,
        "words_per_row": wpr,
        "words_from_bin": from_bin,
        "seed": seed,
        "e_col": e_col,
        "e_periph": e_per,
        "e_col_log": e_col_log,
        "e_periph_log": e_per_log,
        "table": table,
        "e_avg": sum(energies) / len(energies),
        "e_sd": statistics.stdev(energies) if len(energies) > 1 else 0.0,
        "e_min": min(energies),
        "e_max": max(energies),
        # The whole-array figures: not part of the model, but the only way to
        # see how much of the answer is sampling noise.
        "zeros_mean": sum(all_rows) / len(all_rows),
        "zeros_min": all_rows[0],
        "zeros_max": all_rows[-1],
        "e_worst": cols * e_col + e_per,
        "e_array_mean": (sum(all_rows) / len(all_rows)) * e_col + e_per,
    }


def report(r):
    """The human-readable summary, as a list of lines."""
    out = []
    a = out.append
    a("%s %s: dynamic read energy, average of %d random reads"
      % (r["macro"], r["corner"], len(r["table"])))
    a("  array        : %d rows x %d columns, %d words x %d per row"
      % (r["rows"], r["cols"], r["words"], r["words_per_row"]))
    if not r["words_from_bin"]:
        a("                 (no .bin -- the whole array is assumed addressable)")
    a("  E_column     : %.4f pJ per discharged column  (%s)"
      % (r["e_col"], os.path.basename(r["e_col_log"])))
    a("  E_periphery  : %.4f pJ per cycle              (%s)"
      % (r["e_periph"], os.path.basename(r["e_periph_log"])))
    a("  seed         : %s" % r["seed"])
    a("")
    a("  %-5s %10s %8s %12s %12s" % ("read", "address", "row", "discharged",
                                     "E (pJ)"))
    for i, (addr, row, n_dis, e) in enumerate(r["table"], 1):
        a("  %-5d %10d %8d %12d %12.4f" % (i, addr, row, n_dis, e))
    a("")
    a("  average      : %.4f pJ   (min %.4f, max %.4f, sd %.4f)"
      % (r["e_avg"], r["e_min"], r["e_max"], r["e_sd"]))
    a("  worst case   : %.4f pJ   (all %d columns discharging -- %.2fx)"
      % (r["e_worst"], r["cols"], r["e_worst"] / r["e_avg"]))
    # The sampling error, stated rather than left for the reader to wonder
    # about: the exact mean over EVERY row is cheap here, and the gap between
    # it and the sampled average is what the sample size costs.
    a("  whole array  : %.4f pJ   (exact mean over all %d rows, %.1f of %d"
      % (r["e_array_mean"], r["rows"], r["zeros_mean"], r["cols"]))
    a("                 columns discharging; per-row spread %d..%d). The"
      % (r["zeros_min"], r["zeros_max"]))
    a("                 sample is %+.2f%% against it."
      % ((r["e_avg"] - r["e_array_mean"]) / r["e_array_mean"] * 100.0))
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("macro", help="macro name (or a path to its directory)")
    ap.add_argument("--corner", default="tt",
                    help="corner tag: tt / ss / ff (default tt)")
    ap.add_argument("--reads", type=int, default=10,
                    help="how many random reads to average (default 10)")
    ap.add_argument("--seed", default=None,
                    help="RNG seed: an integer for a pinned draw, 'random' "
                         "for a fresh one. Default: derived from the macro "
                         "name alone -- reproducible, and the SAME reads at "
                         "every corner, since which columns discharge is a "
                         "property of the contents and not of the corner.")
    ap.add_argument("--macros-dir", default=None,
                    help="macro tree (default: ROM_MACROS_DIR / <repo>/examples)")
    ap.add_argument("--energy-only", action="store_true",
                    help="print the average in pJ and nothing else "
                         "(what regen_rom_libs.sh reads)")
    ap.add_argument("--log", action="store_true",
                    help="also write char/random_energy_<corner>.log")
    args = ap.parse_args(argv)

    if args.reads < 1:
        ap.error("--reads must be at least 1")

    name = rom_paths.macro_name(args.macro)
    if args.seed is None:
        # The macro name only -- see "REPRODUCIBILITY" above: putting the
        # corner in here made the activity factor differ between corners,
        # which is physically wrong and moved the corner ratios by ~7%.
        seed = zlib.crc32(name.encode()) & 0xFFFFFFFF
    elif str(args.seed).lower() == "random":
        seed = int.from_bytes(os.urandom(4), "big")
    else:
        try:
            seed = int(args.seed)
        except ValueError:
            ap.error("--seed takes an integer or 'random'")

    r = sample(args.macro, args.corner, args.reads, seed, args.macros_dir)

    if args.energy_only:
        print("%.4f" % r["e_avg"])
    else:
        print("\n".join(report(r)))

    if args.log:
        path = os.path.join(rom_paths.char_dir(args.macro, args.macros_dir),
                            "random_energy_%s.log" % args.corner)
        with open(path, "w") as fh:
            fh.write("\n".join(report(r)) + "\n")
            # A machine-readable tail, in the same `name value` shape the
            # ngspice logs use, so `meas` reads this file too.
            fh.write("\ne_read_avg_pj       =  %.6e\n" % r["e_avg"])
            fh.write("e_read_worst_pj     =  %.6e\n" % r["e_worst"])
            fh.write("n_reads             =  %d\n" % len(r["table"]))
            fh.write("seed                =  %d\n" % seed)
        if not args.energy_only:
            print("\nwritten: %s" % path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
