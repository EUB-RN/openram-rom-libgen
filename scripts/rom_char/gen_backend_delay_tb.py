#!/usr/bin/env python3
"""Measure the ROM's BACK END delay: bitline -> dout0.

WHY IT IS NEEDED:
  The existing `access` number (col<N>_worst_case_parasitic.log, t_dis_50)
  covers only the path up to the BITLINE:
      .measure t_dis_50 TRIG v(precharge) ... TARG v(bl_0_155) ...
  But `access` in the .lib runs from the rising edge of clk0 until dout0 is
  valid. Per the netlist (top level of <macro>.sp):
      bl_N -> rom_bitline_inverter -> bl_b_N -> rom_column_mux (pass
      transistors) -> rom_out_prebuf_k -> rom_output_buffer -> dout0[k]
  Those three stages were never measured. And since the bitline falls very
  slowly (13.8 ns from 50% to 10% on wrom0 at TT, ~52 mV/ns) the inverter
  threshold can trip much later or earlier than expected -- not a term you can
  guess.

METHOD (the same "slice x count" idea as the periphery script):
  From the extracted netlist (<macro>_cap_only.spice, real Magic parasitic C)
  ONLY the back-end instances are kept at top level:
      rom_bitline_inverter + rom_column_mux_array + rom_output_buffer
  The cell array, decoders and control logic are deleted. The nodes left
  dangling by the deleted blocks (bl_0_*, the column selects) are driven by
  ideal sources, so their load does not enter this delay -- which is correct,
  that part is already counted in t_dis_50.

  The driven bitline waveform is NOT a guess: it uses the real slope implied by
  the measured t_dis_50/t_dis_10 (0.4*VDD between the 50% and 10% points), so
  the inverter sees the slow edge it really sees.

  The NEGATIVE NET CAPACITANCE FIX is the same as in the periphery script and
  just as REQUIRED: without the positive terms of the deleted blocks, Magic's
  substrate correction terms make a net go negative and the solver blows up.

OUTPUT: delay as a function of dout0's output load -- the index_2
  (total_output_net_capacitance) axis of the .lib CELL_TABLE is now really
  measured; in earlier files all three load points carried the SAME number.

Usage:
  gen_backend_delay_tb.py <macro> <column> <out.sp>
      --t-dis-50 <s> --t-dis-10 <s> [--corner tt|ss|ff] [--vdd] [--temp]
"""
import argparse, collections, os, re, sys

import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rom_paths

ap = argparse.ArgumentParser()
ap.add_argument("macro")
ap.add_argument("col", type=int)
ap.add_argument("out")
ap.add_argument("--t-dis-50", type=float, required=True,
                help="measured: precharge 50%% -> bitline 50%% (seconds)")
ap.add_argument("--t-dis-10", type=float, required=True,
                help="measured: precharge 50%% -> bitline 10%% (seconds)")
ap.add_argument("--corner", default="tt", choices=["tt", "ss", "ff"])
ap.add_argument("--vdd", default="1.8")
ap.add_argument("--temp", default="25")
ap.add_argument("--load-ff", type=float, default=6.89,
                help="dout0 output load (fF). The .lib CELL_TABLE index_2 "
                     "points are 1.7225 / 6.89 / 27.56 -- each is run "
                     "SEPARATELY so the load axis is genuinely measured (in "
                     "earlier .libs all three carried the same number).")
ap.add_argument("--macros-dir", default=None,
                help="macro tree (default: ROM_MACROS_DIR / <repo>/examples)")
args = ap.parse_args()

M = args.macro
SP = rom_paths.cap_netlist(M, args.macros_dir)
if not os.path.exists(SP):
    sys.exit(f"ERROR: {SP} does not exist -- run run_cap_extract.sh first")

SUFFIX = {"f": 1e-15, "p": 1e-12, "n": 1e-9, "u": 1e-6, "m": 1e-3, "k": 1e3}
def to_float(tok):
    m = re.match(r"^([0-9.eE+-]+)([a-zA-Z]?)$", tok)
    if not m:
        raise ValueError(tok)
    return float(m.group(1)) * SUFFIX.get(m.group(2), 1.0)

def fix_units(line):
    line = re.sub(r"\b(w|l|pd|ps)=([0-9.eE+-]+[a-zA-Z]?)\b",
                  lambda m: f"{m.group(1)}={to_float(m.group(2))*1e6:.6g}", line)
    line = re.sub(r"\b(ad|as)=([0-9.eE+-]+[a-zA-Z]?)\b",
                  lambda m: f"{m.group(1)}={to_float(m.group(2))*1e12:.6g}u", line)
    return line

def blocks(path):
    out, cur, name = collections.OrderedDict(), None, None
    def flush():
        nonlocal cur
        if cur is not None and name is not None:
            out[name].append(cur)
        cur = None
    for raw in open(path):
        s = raw.rstrip("\n")
        if not s or s.startswith("*"):
            continue
        if s.startswith("+"):
            if cur is not None:
                cur += " " + s[1:].strip()
            continue
        flush()
        low = s.lower()
        if low.startswith(".subckt"):
            name = s.split()[1]
            out.setdefault(name, [])
            cur = s
        elif low.startswith(".ends"):
            flush(); name = None
        else:
            cur = s
    flush()
    return out

B = blocks(SP)
TOP = M
top_lines = B[TOP]
top_ports = top_lines[0].split()[2:]
top_insts = [l for l in top_lines if l.startswith("X")]
top_caps = [l for l in top_lines if l.startswith("C")]

KEEP_SUB = {f"{M}_rom_bitline_inverter", f"{M}_rom_column_mux_array",
            f"{M}_rom_output_buffer"}
keep = [l for l in top_insts if l.split()[-1] in KEEP_SUB]
if len(keep) != 3:
    sys.exit(f"ERROR: back-end instances missing: {[l.split()[-1] for l in top_insts]}")

SUPPLY_HI, SUPPLY_LO = "vccd1", "vssd1"
alive = {SUPPLY_HI, SUPPLY_LO, "0"}
for l in keep:
    alive.update(l.split()[1:-1])

# --- which mux transistor connects our column to which output? -----------
# The column->output mapping is NOT guessed from names; it is read out of the
# mux array netlist (the names Magic generates are not in order).
mux_sub = f"{M}_rom_column_mux_array"
mux_inst = [l for l in keep if l.split()[-1] == mux_sub][0]
mux_ports = B[mux_sub][0].split()[2:]
mp2n = dict(zip(mux_ports, mux_inst.split()[1:-1]))
cell_ports = B[f"{M}_rom_column_mux"][0].split()[2:]   # bl bl_out sel gnd
i_bl, i_out, i_sel = (cell_ports.index(x) for x in ("bl", "bl_out", "sel"))

inv_sub = f"{M}_rom_bitline_inverter"
inv_inst = [l for l in keep if l.split()[-1] == inv_sub][0]
ip2n = dict(zip(B[inv_sub][0].split()[2:], inv_inst.split()[1:-1]))
# Magic renames both the sub-circuit ports (in_N/out_N) and the top-level net
# names (e.g. wrom0_rom_base_array_0/bl_0_155), so the target column is found
# from the SUFFIX of the net name and then mapped back to a port name.
cand = [n for n in ip2n.values() if n.split("/")[-1] == f"bl_0_{args.col}"]
if len(cand) != 1:
    sys.exit(f"ERROR: bitline of column {args.col} is not unique: {cand}")
src_net = cand[0]
inv_n2p = {v: k for k, v in ip2n.items()}
src_port = inv_n2p[src_net]
# the inverter output for this bit: the Z of the same cell instance
inv_cell_out = None
for l in B[inv_sub][1:]:
    if not l.startswith("X"):
        continue
    t = l.split()
    sub = t[-1]
    if sub not in B:
        continue
    ports = B[sub][0].split()[2:]
    nets = t[1:-1]
    if "A" in ports and "Z" in ports and nets[ports.index("A")] == src_port:
        inv_cell_out = ip2n.get(nets[ports.index("Z")], nets[ports.index("Z")])
        break
if inv_cell_out is None:
    sys.exit("ERROR: could not find the bitline inverter output")

sel_net = out_net = None
for l in B[mux_sub][1:]:
    if not l.startswith("X"):
        continue
    t = l.split()
    if t[-1] != f"{M}_rom_column_mux":
        continue
    nets = t[1:-1]
    if mp2n.get(nets[i_bl]) == inv_cell_out:
        sel_net = mp2n[nets[i_sel]]
        out_net = mp2n[nets[i_out]]
        break
if sel_net is None:
    sys.exit(f"ERROR: no mux transistor found for column {args.col}")

# the dout0 bit of the output buffer fed by this prebuf
buf_sub = f"{M}_rom_output_buffer"
buf_inst = [l for l in keep if l.split()[-1] == buf_sub][0]
bp2n = dict(zip(B[buf_sub][0].split()[2:], buf_inst.split()[1:-1]))
n2bp = {v: k for k, v in bp2n.items()}
in_port = n2bp.get(out_net)
dout_net = None
for l in B[buf_sub][1:]:
    if not l.startswith("X"):
        continue
    t = l.split(); sub = t[-1]
    if sub not in B:
        continue
    ports = B[sub][0].split()[2:]; nets = t[1:-1]
    if "A" in ports and "Z" in ports and nets[ports.index("A")] == in_port:
        dout_net = bp2n.get(nets[ports.index("Z")], nets[ports.index("Z")])
        break
if dout_net is None:
    sys.exit("ERROR: could not find the dout0 bit")

# --- top-level C: alive/dead rule + negative-net fix ---------------------
kept_c, retarget = [], collections.Counter()
n_drop = 0
for l in top_caps:
    t = l.split()
    if len(t) < 4:
        continue
    try:
        v = to_float(t[3])
    except ValueError:
        continue
    ao, bo = t[1] in alive, t[2] in alive
    if ao and bo:
        kept_c.append(l)
    elif ao:
        retarget[t[1]] += v
    elif bo:
        retarget[t[2]] += v
    else:
        n_drop += 1
for i, (n, v) in enumerate(sorted(retarget.items())):
    if v > 0:
        kept_c.append(f"C_rt{i} {n} {SUPPLY_LO} {v*1e15:.5f}f")

# Nodes DRIVEN by a source: only the array bitlines (bl_0_*) and the column
# selects. The inverter OUTPUTS (bl_*) are not driven -- treating them as
# "driven" as well skipped the negative-net-capacitance fix and the solver blew
# up at the very first time point (2026-09-06).
bl_in_nets = {n for n in ip2n.values()
              if re.match(r"^bl_0_\d+$", n.split("/")[-1])}
sel_nets_all = {mp2n[q] for q in mux_ports
                if mp2n.get(q) and re.match(r"^sel_\d+$", q)}
driven = {SUPPLY_HI, SUPPLY_LO, "0"} | bl_in_nets | sel_nets_all
node_c = collections.Counter()
for l in kept_c:
    t = l.split()
    try:
        v = to_float(t[3])
    except (ValueError, IndexError):
        continue
    node_c[t[1]] += v
    node_c[t[2]] += v
n_fix, c_fix = 0, 0.0
for i, (n, v) in enumerate(sorted(node_c.items())):
    if v >= 0 or n in driven:
        continue
    kept_c.append(f"C_fx{i} {n} {SUPPLY_LO} {-v*1e15:.5f}f")
    n_fix += 1; c_fix += -v

# --- sub-circuit definitions actually used -------------------------------
need, seen = set(l.split()[-1] for l in keep), set()
while need - seen:
    n = (need - seen).pop()
    seen.add(n)
    for l in B.get(n, [])[1:]:
        if l.startswith("X") and l.split()[-1] in B:
            need.add(l.split()[-1])
defs = []
for name in sorted(seen):   # sorted: deterministic output file
    if name == TOP:
        continue
    defs.append("\n".join(fix_units(l) if l.startswith("X") else l
                          for l in B[name]))
    defs.append(".ends")
defs = "\n".join(defs)

# --- stimulus -------------------------------------------------------------
VDD = float(args.vdd)
# Measured slope: 0.4*VDD falls between the 50% and 10% points. At that slope
# a full VDD->0 transition takes TFALL. The edge starts at t=TSTART.
tfall = (args.t_dis_10 - args.t_dis_50) / 0.4
TSTART = 5e-9


hold_hi = "\n".join(
    f"Vbl{i} {n} 0 DC {{VDD}}"
    for i, n in enumerate(sorted(bl_in_nets - {src_net})))
sels = sorted(sel_nets_all)
sel_src = "\n".join(
    f"Vsel{i} {n} 0 DC " + ("{VDD}" if n == sel_net else "0")
    for i, n in enumerate(sels))

blocks_txt = [f"Cload {dout_net} {SUPPLY_LO} {args.load_ff:.5f}f"]
meas_txt = "\n".join([
    f".measure tran t_bl2dout TRIG v({src_net}) VAL='VDD/2' FALL=1",
    f"+                       TARG v({dout_net}) VAL='VDD/2' FALL=1",
    f".measure tran t_dout_slew TRIG v({dout_net}) VAL='0.9*VDD' FALL=1",
    f"+                         TARG v({dout_net}) VAL='0.1*VDD' FALL=1",
])

tb = f"""* {M} -- BACK END delay: bitline -> dout0  (column {args.col}, {args.corner})
* Path: bl_0_{args.col} -> bitline_inverter -> column_mux(sel) -> output_buffer -> dout0
* Kept: rom_bitline_inverter + rom_column_mux_array + rom_output_buffer
* Deleted: cell array / decoders / control logic (the nodes they leave behind
*          are driven by ideal sources -- that part is already in t_dis_50)
* Top-level C: {len(kept_c)} kept, {n_drop} dropped;
*   negative-net-capacitance fix on {n_fix} nodes / {c_fix*1e15:.1f} fF
* The driven bitline edge comes from the MEASURED slope:
*   t_dis_50={args.t_dis_50*1e9:.4f} ns, t_dis_10={args.t_dis_10*1e9:.4f} ns
*   -> full VDD->0 transition {tfall*1e9:.3f} ns
* Measured bit: {dout_net}   (select: {sel_net})   output load: {args.load_ff} fF

.lib {rom_paths.sky130_lib()} {args.corner}
.temp {args.temp}
.param VDD={args.vdd}
.param TFALL={tfall:.6e}
.param TSTART={TSTART:.6e}

Vvdd {SUPPLY_HI} 0 DC {{VDD}}
Vgnd {SUPPLY_LO} 0 DC 0

* the measured column's bitline: falls from precharged VDD at the measured slope
Vsrc {src_net} 0 PWL(0 {{VDD}} {{TSTART}} {{VDD}} '{TSTART:.6e}+{tfall:.6e}' 0)

* the other bitlines stay precharged
{hold_hi}

* column select
{sel_src}

{chr(10).join(blocks_txt)}

{chr(10).join(fix_units(l) for l in keep)}

{chr(10).join(kept_c)}

{defs}

.options gmin=1e-12 abstol=1e-12 reltol=1e-3 itl1=500 itl4=100
.ic v({src_net})={{VDD}}
.tran '(TSTART+TFALL)/2000' '2*(TSTART+TFALL)' uic
{meas_txt}
.end
"""
open(args.out, "w").write(tb)
print(f"written: {args.out}  ({M} column {args.col} -> {dout_net}, "
      f"{args.corner}, bl edge {tfall*1e9:.2f} ns, load {args.load_ff} fF)")
