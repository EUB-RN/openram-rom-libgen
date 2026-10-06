#!/usr/bin/env python3
"""Derive an SS/FF corner variant from an existing TT parasitic testbench:
only the .lib selector, VDD and the temperature change -- the rest of the
circuit (real extracted parasitic capacitance included) stays IDENTICAL.

Usage: make_corner_variant.py <macro> [worst_column] <ss|ff>
       (with no column, it is derived from the netlist)
Input:  <macro_dir>/char/col<column>_worst_case_parasitic.sp
        (produced first by gen_col_tb_parasitic.py)
Output: col<column>_worst_case_parasitic_<ss|ff>.sp in the same directory
"""
import sys, re, os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rom_paths

# --tag must match the one gen_col_tb_parasitic.py was given.
TAG = "worst_case_parasitic"
ARGV = []
for _a in sys.argv[1:]:
    if _a.startswith("--tag="):
        TAG = _a.split("=", 1)[1]
    else:
        ARGV.append(_a)
if len(ARGV) < 2:
    sys.exit("usage: make_corner_variant.py <macro> [column] <ss|ff> "
             "[--tag=<name>]")
MACRO = ARGV[0]
# The column may be omitted: <macro> <ss|ff> -> worst column from the netlist
if len(ARGV) == 2:
    COL, CORNER = rom_paths.geometry(MACRO)["worst_col"], ARGV[1]
else:
    COL, CORNER = ARGV[1], ARGV[2]
SRC = os.path.join(rom_paths.char_dir(MACRO), f"col{COL}_{TAG}.sp")

PARAMS = {
    "ss": dict(vdd=1.6, temp=100, tag="SS_1p6V_100C"),
    "ff": dict(vdd=1.95, temp=-40, tag="FF_1p95V_n40C"),
}
if CORNER not in PARAMS:
    sys.exit("unknown corner %r -- this script derives %s from the TT deck; "
             "TT is the source, not a target."
             % (CORNER, "/".join(PARAMS)))
p = PARAMS[CORNER]

if not os.path.exists(SRC):
    sys.exit("no TT deck at %s -- run gen_col_tb_parasitic.py %s first"
             % (SRC, MACRO))

text = open(SRC).read()

# EVERY SUBSTITUTION IS CHECKED.
#
# This file produces the SS and FF column decks by rewriting three things in
# the TT one. A regex that matches nothing does not fail -- re.sub returns the
# input unchanged -- so a TT deck written even slightly differently (`.param
# VDD = 1.8` with spaces, say) used to yield a deck still carrying the TT
# models or the TT voltage, saved under an _ss name, while this script printed
# "VDD=1.6, temp=100C, lib=ss". The corner's whole .lib column would then come
# from a TT simulation and nothing anywhere would say so.
def sub_once(pattern, repl, label, src):
    out, n = re.subn(pattern, repl, src)
    if n == 0:
        sys.exit("%s: nothing in %s matched the %s pattern (%s). The deck "
                 "format has changed; this script would otherwise have "
                 "written a %s deck that is still TT."
                 % (os.path.basename(SRC), SRC, label, pattern, CORNER.upper()))
    return out

text = sub_once(r"(\.lib\s+\S+sky130\.lib\.spice)\s+tt", rf"\1 {CORNER}",
                "model-library corner selector", text)
text = sub_once(r"\.param\s+VDD\s*=\s*1\.8\b", f".param VDD={p['vdd']}",
                "supply voltage", text)
if ".temp" not in text:
    text = sub_once(r"\.param\s+VDD\s*=", f".temp {p['temp']}\n.param VDD=",
                    "temperature insertion point", text)

OUT = SRC.replace(".sp", f"_{CORNER}.sp")
open(OUT, "w").write(text)
print(f"written: {OUT}  (VDD={p['vdd']}, temp={p['temp']}C, lib={CORNER})")
