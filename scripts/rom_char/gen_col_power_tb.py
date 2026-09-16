#!/usr/bin/env python3
"""Measure leakage and cycle energy on ONE ISOLATED COLUMN of a ROM macro.

WHY A COLUMN AND NOT THE WHOLE MACRO:
  The full macro (~34k transistors) takes 28+ minutes and 7.3 GB of RAM in
  ngspice, and the flow needs 24 runs (4 macros x 3 corners x 2 modes) -- not
  practical. In this precharged architecture both leakage and dynamic energy
  decompose PER COLUMN, because every column does the same work every cycle:
    leakage = N x (sub-threshold leakage of the off foot transistor) + periphery
    energy  = N x (charge/discharge energy of one bitline)           + periphery
  (N = column count, taken from the netlist -- see rom_paths.py)
  The column netlist carries PARASITIC C (the output of
  gen_col_tb_parasitic.py), so the capacitances dynamic energy needs are in.

WHY ENERGY AND NOT POWER:
  Liberty `internal_power` is ENERGY per switching event (pJ), not power. The
  power tool applies the frequency: P = E * f * activity. So we integrate the
  charge (coulombs) and write E = Q*VDD -> INDEPENDENT of frequency.

Modes:
  idle    -- precharge held at 0 (precharge phase, foot OFF): DC leakage (.op).
             gmin=1e-15 is required -- 1e-12 inflated the result by 79% (see
             the idle block below).
  active  -- precharge toggles: charge integral of one FULL cycle -> energy.

Usage:
  gen_col_power_tb.py <macro> <column> <idle|active> <out.sp>
      [--corner tt|ss|ff] [--vdd 1.8] [--temp 25] [--tclk 200n]
"""
import sys, re, argparse, os

import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rom_paths

ap = argparse.ArgumentParser()
ap.add_argument("macro")
ap.add_argument("col", type=int)
ap.add_argument("mode", choices=["idle", "active"])
ap.add_argument("out")
ap.add_argument("--corner", default="tt", choices=["tt", "ss", "ff"])
ap.add_argument("--vdd", default="1.8")
ap.add_argument("--temp", default="25")
ap.add_argument("--tclk", default="200n",
                help="cycle period in active mode; the ENERGY should be "
                     "independent of it -- verify by running two values")
ap.add_argument("--macros-dir", default=None,
                help="macro tree (default: ROM_MACROS_DIR / <repo>/examples)")
args = ap.parse_args()

SRC = os.path.join(rom_paths.char_dir(args.macro, args.macros_dir),
                   f"col{args.col}_worst_case_parasitic.sp")
# The column count comes from the netlist -- the "total = N x this value" line
# in the deck header used to be a hard-coded 264, which became misleading as
# soon as the macro was regenerated.
NCOL = rom_paths.geometry(args.macro, args.macros_dir)["cols"]
if not os.path.exists(SRC):
    sys.exit(f"ERROR: {SRC} does not exist -- run gen_col_tb_parasitic.py first")

# Read the existing (validated) column testbench and reuse its circuit body
# verbatim, changing only stimuli and measurements. Same circuit as timing.
body, in_defs = [], False
for line in open(SRC):
    s = line.rstrip("\n")
    ls = s.lstrip().lower()
    # skip header/stimulus/analysis -- the circuit and subckt definitions STAY
    # CAREFUL: ".ends" also starts with ".end" -- sub-circuit terminators must
    # NOT be dropped, or ngspice reports "Mismatch of .subckt ... .ends".
    first = ls.split()[0] if ls.split() else ""
    if first in (".lib", ".temp", ".param", ".tran", ".measure", ".ic", ".end"):
        continue
    if s.startswith("+") and body and body[-1] == "":   # .measure continuation
        continue
    if re.match(r"^V(vdd|precharge|wl\d+|gndgnd_uq\d+)\b", s):
        continue
    body.append(s)

circuit = "\n".join(l for l in body if l.strip())

# find the wordline and derived-ground nodes used by the circuit
wl_nodes = sorted(set(re.findall(r"\bwl_0_\d+\b", circuit)),
                  key=lambda s: int(s.split("_")[-1]))
gnd_extra = sorted(set(re.findall(r"\bgnd_uq\d+\b", circuit)))

wl_src = "\n".join(f"Vwl{i} {n} 0 DC {{VDD}}" for i, n in enumerate(wl_nodes))
gnd_src = "\n".join(f"Vg{n} {n} 0 DC 0" for n in gnd_extra)

HEAD = f""".lib {rom_paths.sky130_lib()} {args.corner}
.temp {args.temp}
.param VDD={args.vdd}

Vvdd vdd 0 DC {{VDD}}
{gnd_src}
{wl_src}"""

if args.mode == "idle":
    tb = f"""* {args.macro} column {args.col} -- IDLE LEAKAGE (per column)
* precharge=0: precharge phase, foot transistor OFF, bitline at VDD.
* Dominant leakage path: VDD -> prechg PMOS(on) -> chain(on) -> foot(OFF) -> gnd
* Whole-macro leakage ~ {NCOL} x (this value) + periphery.
{HEAD}
Vprecharge precharge 0 DC 0

{circuit}

* gmin: the artificial conductance ngspice adds to EVERY node to converge.
* Set too high it CONTAMINATES the leakage measurement. Sweep of 2026-09-05:
*   gmin=1e-12 -> 0.656 nA   (79% artificial!)
*   gmin=1e-15 -> 0.366 nA
*   gmin=1e-18 -> 0.366 nA   (same -> converged)
* 1e-15 is sufficient and safe.
.options gmin=1e-15 abstol=1e-15 reltol=1e-3 itl1=500
* .op IS USED (NOT a transient): in a transient with "uic" every node starts
* at 0 and charges slowly through a resistive chain of dozens of transistors;
* even at 600 ns it had not settled (65 -> 19 -> 8.7 nA, still falling) and the
* charging current was mistaken for leakage, ~100x too high. .op converges on
* this column (136 devices) where it did not on the full macro (34k).
* The result is read from the "vvdd#branch" line of the log (`.measure op`
* produces no numeric output in ngspice).
.op
.end
"""
else:
    tb = f"""* {args.macro} column {args.col} -- ACTIVE CYCLE ENERGY (per column)
* Charge integral drawn from VDD over one full cycle -> E = Q*VDD.
* The energy is FREQUENCY INDEPENDENT; verify by changing --tclk.
* Whole-macro energy ~ {NCOL} x (this value) + periphery.
{HEAD}
.param TCLK={args.tclk}
Vprecharge precharge 0 PULSE(0 {{VDD}} {{TCLK/2}} 100p 100p {{TCLK/2-100p}} {{TCLK}})

{circuit}

.tran '{args.tclk}/400' '4*TCLK' uic
* Cycles 2 AND 3 are measured separately: equal values prove the circuit has
* SETTLED (with uic every node starts at 0 and the chain fills slowly).
* Cycle 3 is the more settled one, so THAT is what goes into the .lib.
* FREQUENCY INDEPENDENCE VERIFIED (2026-09-05, wrom0 column 155, TT):
*   TCLK=200n -> q_c3 = 2.342e-13 C
*   TCLK=400n -> q_c3 = 2.419e-13 C   (period 2x, charge 3.3% different)
.measure tran q_c2 integ i(Vvdd) from='TCLK' to='2*TCLK'
.measure tran q_c3 integ i(Vvdd) from='2*TCLK' to='3*TCLK'
.measure tran e_col_pj param='abs(q_c3)*VDD*1e12'
.end
"""

open(args.out, "w").write(tb)
print(f"written: {args.out}  ({args.macro} column {args.col}, {args.mode}, "
      f"corner={args.corner}, {len(wl_nodes)} wordlines)")
