#!/usr/bin/env python3
"""Measure the EQUIVALENT GATE CAPACITANCE of a ROM cell, per corner.

WHY: when gen_periphery_power_tb.py puts back the wordline load of the deleted
cell array, it models the cell gates as a LINEAR C. For an energy measurement
that is the correct reduction -- the charge a supply delivers to pull a node to
VDD is Q(VDD), so using

    C_eq = Q(VDD) / VDD

preserves the CYCLE ENERGY exactly (the shape of the non-linear C-V curve does
not enter the energy, only the total charge does).

Placing the bare device with m=<count> would give the same energy, but a
capacitance hundreds of times wider and strongly non-linear kept ngspice from
converging (2026-09-06: "Timestep too small" in three separate attempts).

This deck simulates a SINGLE device -- it takes seconds. The cell's internal
parasitic Cs (C0/C2/C5 and friends) are NOT here; the periphery script collects
those from the extracted netlist separately, so nothing is counted twice.

Usage: gen_cell_gate_tb.py <macro> <out.sp> [--corner tt|ss|ff]
                           [--vdd 1.8] [--temp 25]
"""
import argparse, os, re, sys

import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rom_paths

ap = argparse.ArgumentParser()
ap.add_argument("macro")
ap.add_argument("out")
ap.add_argument("--corner", default="tt", choices=["tt", "ss", "ff"])
ap.add_argument("--vdd", default="1.8")
ap.add_argument("--temp", default="25")
ap.add_argument("--macros-dir", default=None,
                help="macro tree (default: ROM_MACROS_DIR / <repo>/examples)")
args = ap.parse_args()

SP = rom_paths.cap_netlist(args.macro, args.macros_dir)
if not os.path.exists(SP):
    sys.exit(f"ERROR: {SP} does not exist -- run run_cap_extract.sh first")

SUFFIX = {"f": 1e-15, "p": 1e-12, "n": 1e-9, "u": 1e-6, "m": 1e-3, "k": 1e3}
def to_float(tok):
    m = re.match(r"^([0-9.eE+-]+)([a-zA-Z]?)$", tok)
    return float(m.group(1)) * SUFFIX.get(m.group(2), 1.0)

def fix_units(line):
    line = re.sub(r"\b(w|l|pd|ps)=([0-9.eE+-]+[a-zA-Z]?)\b",
                  lambda m: f"{m.group(1)}={to_float(m.group(2))*1e6:.6g}", line)
    line = re.sub(r"\b(ad|as)=([0-9.eE+-]+[a-zA-Z]?)\b",
                  lambda m: f"{m.group(1)}={to_float(m.group(2))*1e12:.6g}u", line)
    return line

# grab the bare device line from the cell sub-circuit (written with port names)
def cell_device(sub):
    grab, cur, out = False, None, []
    for raw in open(SP):
        s = raw.rstrip("\n")
        if s.lower().startswith(f".subckt {sub.lower()} "):
            grab = True
            continue
        if not grab:
            continue
        if s.lower().startswith(".ends"):
            break
        if s.startswith("X"):
            out.append(s)
    return out[0] if out else None

cells = [f"{args.macro}_rom_base_one_cell", f"{args.macro}_rom_base_zero_cell"]
devs = []
for i, c in enumerate(cells):
    d = cell_device(c)
    if d is None:
        sys.exit(f"ERROR: no device inside {c}")
    t = d.split()
    # port names: G -> the driven node, the rest to ground (static bitline)
    nets = [f"g{i}" if n == "G" else "0" for n in t[1:5]]
    devs.append(f"X{i} " + " ".join(nets) + " " + " ".join(t[5:]))
devs = "\n".join(fix_units(d) for d in devs)

tb = f"""* {args.macro} -- cell EQUIVALENT GATE CAPACITANCE ({args.corner})
* C_eq = Q(VDD)/VDD -- the reduction that preserves cycle energy.
* Source/body grounded: what the cell sees while the wordline rises.
* The cell's internal parasitic Cs are NOT here (the periphery script adds them).

.lib {rom_paths.sky130_lib()} {args.corner}
.temp {args.temp}
.param VDD={args.vdd}
.param TR=10n

Vg0 g0 0 PWL(0 0 {{TR}} {{VDD}})
Vg1 g1 0 PWL(0 0 {{TR}} {{VDD}})

{devs}

.options gmin=1e-12 abstol=1e-15 reltol=1e-4
.tran 'TR/2000' '1.2*TR' uic
.measure tran q_one  integ i(Vg0) from=0 to='TR'
.measure tran q_zero integ i(Vg1) from=0 to='TR'
.measure tran c_one_ff  param='abs(q_one)/VDD*1e15'
.measure tran c_zero_ff param='abs(q_zero)/VDD*1e15'
.end
"""
open(args.out, "w").write(tb)
print(f"written: {args.out}  ({args.macro}, {args.corner})")
