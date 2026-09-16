#!/usr/bin/env python3
"""Build a power/energy testbench for the FULL circuit of a ROM macro (not one
column -- the whole array + decoders + buffers).

NOTE: this is the brute-force reference deck. The production flow does NOT use
it (the full macro does not converge in reasonable time); it measures a column
slice and a periphery slice instead -- see gen_col_power_tb.py and
gen_periphery_power_tb.py. Keep this one for cross-checks on small macros.

WHY ENERGY AND NOT POWER:
  Liberty's `internal_power` field holds -- despite the name -- ENERGY per
  switching event, not power (its units V*mA*ns => pJ). The power tool applies
  the frequency afterwards:  P_dynamic = E_cycle * f * activity.
  So we integrate the TOTAL CHARGE drawn from VDD over one cycle and convert it
  to energy -- the result is INDEPENDENT of frequency. (An older version
  measured `avg i(Vvdd)`, which depended on the chosen TCLK and was therefore
  meaningless without stating the frequency.)

Modes:
  idle    -- cs0=0, clk0=0 held; LEAKAGE current out of VDD (for
             leakage_power; independent of frequency anyway). The schematic
             netlist is enough because capacitors are open circuits in DC.
  active  -- cs0=1, clk0 toggling; .tran charge integral over ONE cycle ->
             energy (for internal_power). Dynamic energy goes as C*V^2, so the
             PARASITIC netlist must be used.

Usage: gen_power_tb.py <macro> <idle|active> <out.sp> [--tclk 200n]
       [--corner tt|ss|ff] [--vdd 1.8] [--temp 25] [--netlist <path>]
"""
import sys, re, argparse

import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rom_paths

ap = argparse.ArgumentParser()
ap.add_argument("macro")
ap.add_argument("mode", choices=["idle", "active"])
ap.add_argument("out")
ap.add_argument("--tclk", default="200n",
                help="cycle period in active mode; the energy must be "
                     "INDEPENDENT of it (verify by running two values)")
ap.add_argument("--corner", default="tt", choices=["tt", "ss", "ff"])
ap.add_argument("--vdd", default="1.8")
ap.add_argument("--temp", default="25")
ap.add_argument("--netlist", default=None,
                help="default: idle -> schematic .sp, active -> "
                     "_cap_only.spice (real parasitic C)")
ap.add_argument("--macros-dir", default=None,
                help="macro tree (default: ROM_MACROS_DIR / <repo>/examples)")
args = ap.parse_args()

MACRO, MODE, OUT = args.macro, args.mode, args.out
SCHEM = rom_paths.netlist(MACRO, args.macros_dir)
# active: the netlist with parasitics (dynamic energy depends on capacitance)
DEFAULT_NL = SCHEM if MODE == "idle" else os.path.join(
    rom_paths.macro_dir(MACRO, args.macros_dir), MACRO + "_cap_only_fixed.spice")
NL = args.netlist or DEFAULT_NL


def logical_lines(path):
    """Join SPICE '+' continuation lines into logical lines."""
    cur = None
    for line in open(path):
        s = line.rstrip("\n")
        if s.startswith("+"):
            cur = (cur or "") + " " + s[1:].strip(); continue
        if cur is not None:
            yield cur
        cur = s
    if cur is not None:
        yield cur


# read the top sub-circuit port order from the netlist (never hand-written)
ports = None
for l in logical_lines(NL):
    toks = l.split()
    if len(toks) >= 2 and toks[0].lower() == ".subckt" and toks[1] == MACRO:
        ports = toks[2:]
        break
if ports is None:
    sys.exit(f"ERROR: no .subckt {MACRO} port line found in {NL}")


def port_signal(p):
    if p == "clk0": return "clk"
    if p == "cs0": return "cs"
    if p.startswith("addr0["): return "0"          # address held at 0
    if p.startswith("dout0["): return f"d{p[6:-1]}"
    if p in ("vccd1", "vdd"): return "vdd"
    if p in ("vssd1", "gnd"): return "0"
    return p


conn = " ".join(port_signal(p) for p in ports)
# Magic output can contain uniquified ground nodes (gnd_uqN)
gnd_extra = sorted(set(re.findall(r"gnd_uq\d+", conn)))
gnd_src = "\n".join(f"Vgnd{n} {n} 0 DC 0" for n in gnd_extra)

HEAD = f""".lib {rom_paths.sky130_lib()} {args.corner}
.temp {args.temp}
.param VDD={args.vdd}
.include {NL}

Vvdd vdd 0 DC {{VDD}}
{gnd_src}"""

if MODE == "idle":
    # NOTE: .op (DC solution) does NOT converge at this size (~34k
    # transistors) -- on 2026-09-05 it timed out after 10 minutes without a
    # single line of output. The workaround is to hold the inputs and run a
    # SHORT transient, measuring the current once the circuit has settled (the
    # standard trick for large circuits). Leakage is still frequency
    # independent; the transient is only there to help the solver.
    tb = f"""* {MACRO} -- FULL MACRO, IDLE (cs0=0) LEAKAGE measurement
* Leakage is frequency independent; it goes into the .lib directly in mW.
* Transient settling instead of .op (see the note in the script).
{HEAD}
Vclk clk 0 DC 0
Vcs  cs  0 DC 0

Xdut {conn} {MACRO}

.options gmin=1e-12 abstol=1e-13 reltol=1e-3 itl1=1000 itl2=1000
.tran 1n 200n uic
* last 50 ns: the circuit is assumed settled
.measure tran i_leak avg i(Vvdd) from=150n to=200n
.measure tran p_leak_mw param='abs(i_leak)*VDD*1000'
.end
"""
else:
    # Charge integral over one FULL cycle -> energy. Cycle 1 is skipped as the
    # start-up transient; cycle 2 (TCLK..2*TCLK) is measured.
    tb = f"""* {MACRO} -- FULL MACRO, ACTIVE: ENERGY of one read cycle
* What is measured is a charge integral (coulombs) -> E = Q*VDD (joules) -> pJ.
* The energy is FREQUENCY INDEPENDENT; verify by changing --tclk.
{HEAD}
.param TCLK={args.tclk}
Vclk clk 0 PULSE(0 {{VDD}} {{TCLK/2}} 100p 100p {{TCLK/2-100p}} {{TCLK}})
Vcs  cs  0 DC {{VDD}}

Xdut {conn} {MACRO}

.tran '{args.tclk}/200' '3*TCLK'
* cycle 2: start-up transient excluded
.measure tran q_cycle integ i(Vvdd) from='TCLK' to='2*TCLK'
.measure tran e_cycle_pj param='abs(q_cycle)*VDD*1e12'
* average current, for comparison only (FREQUENCY DEPENDENT -- never in the .lib)
.measure tran i_avg avg i(Vvdd) from='TCLK' to='2*TCLK'
.end
"""

open(OUT, "w").write(tb)
print(f"written: {OUT}  (mode={MODE}, corner={args.corner}, netlist={NL.split('/')[-1]})")
