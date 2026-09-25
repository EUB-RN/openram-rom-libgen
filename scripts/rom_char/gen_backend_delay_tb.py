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
  slowly (18.8 ns from 50% to 10% on wrom0 at TT, and only ~119 mV/ns
  through the inverter's own trip point) the inverter
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

  The driven bitline waveform is not a model of the discharge, it IS the
  discharge: the column deck's own samples, replayed through a PWL source.
  Earlier versions drove a straight ramp through the measured 50% and 10%
  points, which reproduced those two instants and nothing else -- a discharge
  decelerates, so that secant runs 3.1x flatter than the curve does where the
  bitline inverter actually trips, and the back end was measured against an
  edge no ROM produces.

  The NEGATIVE NET CAPACITANCE FIX is the same as in the periphery script and
  just as REQUIRED: without the positive terms of the deleted blocks, Magic's
  substrate correction terms make a net go negative and the solver blows up.

OUTPUT: delay as a function of dout0's output load -- the index_2
  (total_output_net_capacitance) axis of the .lib CELL_TABLE is now really
  measured; in earlier files all three load points carried the SAME number.

Usage:
  gen_backend_delay_tb.py <macro> <column> <out.sp>
      --bl-wave <char/wave/bl_<corner>.txt> [--corner tt|ss|ff] [--vdd] [--temp]
"""
import argparse, collections, os, re, sys

import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rom_paths

ap = argparse.ArgumentParser()
ap.add_argument("macro")
ap.add_argument("col", type=int)
ap.add_argument("out")
ap.add_argument("--bl-wave", required=True,
                help="the column deck's own bitline waveform, as written by "
                     "run_backend_delay.sh (wrdata: time, v(bitline), time, "
                     "v(precharge)). The settled discharge in it becomes the "
                     "stimulus verbatim -- see the module docstring.")
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
# "driven" as well skips the negative-net-capacitance fix and the solver blows
# up at the very first time point.
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
TSTART = 5e-9
# The bitline edge is the COLUMN DECK'S OWN WAVEFORM, replayed sample for
# sample. It used to be a straight ramp through the measured 50% and 10%
# points, and that ramp was 3.1x too slow where it matters: a bitline
# discharge decelerates, so the 50%-to-10% secant is far flatter than the
# curve's actual slope at the inverter's trip point (wrom0 TT: -0.0382 V/ns
# against -0.1185 V/ns at the VDD/2 the deck trips on). The back end saw an edge no ROM ever produces and
# reported t_bl2dout 48% high (1.7321 ns against 1.1677 ns) and t_dout_slew
# 31% high. Both errors were pessimistic, so no .lib was ever optimistic --
# but 0.56 ns of the access time was an artefact of the stimulus shape.
BL_FLOOR = 0.01      # the replay stops here; see read_bl_wave()

def read_bl_wave(path, vdd):
    """The settled discharge out of the column deck's dump.

    `wrdata` writes one time column per vector, so the file is
    time, v(bitline), time, v(precharge). The precharge column is what makes
    the window self-locating: the LAST rising crossing of VDD/2 on it is the
    edge that t_dis_50 itself triggers on, so the same discharge the .lib's
    middle term was measured on is the one replayed here -- no cycle number
    and no TCLK arithmetic to keep in step with the other deck.

    The replay ends once the bitline is under BL_FLOOR*VDD. PWL holds its
    last value, so the line sits at ~1% of VDD instead of a true zero; every
    threshold measured downstream (50%, 90%, 10% of VDD) is an order of
    magnitude above that, and stopping there keeps the deck's runtime where
    the ramp version had it -- the real tail is asymptotic and would add
    another ~35% of transient for nothing.
    """
    rows = []
    for ln in open(path):
        f = ln.split()
        if len(f) < 4:
            continue
        try:
            rows.append((float(f[0]), float(f[1]), float(f[3])))
        except ValueError:      # wrdata writes no header, but be safe
            continue
    if not rows:
        sys.exit(f"ERROR: {path} holds no samples")
    half = vdd / 2.0
    trig = None
    for i in range(1, len(rows)):
        if rows[i-1][2] < half <= rows[i][2]:
            trig = i
    if trig is None:
        sys.exit(f"ERROR: {path} has no rising precharge edge -- is it the "
                 f"{args.corner} dump of the column deck?")
    # t0 is the crossing itself, interpolated, not the first sample after it:
    # ngspice's .measure does the same, and a whole timestep of offset (200 ps
    # here) would put the t_dis_50 printed in this deck's header 0.2% away
    # from the column log it is supposed to be checkable against.
    (ta, _, pa), (tb, _, pb) = rows[trig-1], rows[trig]
    t0 = ta + (half - pa) / (pb - pa) * (tb - ta)
    wave = []
    for t, bl, _ in rows[trig:]:
        if wave and t <= wave[-1][0]:      # ngspice repeats a breakpoint time
            continue
        wave.append((t - t0, bl))
        if bl <= BL_FLOOR * vdd:
            break
    return wave

wave = read_bl_wave(args.bl_wave, VDD)
tfall = wave[-1][0]

def cross(frac):
    """When the replayed edge passes frac*VDD, by the same linear
    interpolation ngspice's .measure uses -- printed in the header so the
    deck can be checked against the column log it came from."""
    th = frac * VDD
    for i in range(1, len(wave)):
        (ta, va), (tb, vb) = wave[i-1], wave[i]
        if va > th >= vb:
            return ta + (va - th) / (va - vb) * (tb - ta)
    return float("nan")

# 12 significant digits: at a 200 ps sample the times are ~1e-8 with 1e-13
# steps between them, and %g would collapse neighbouring samples onto the
# same instant -- PWL then refuses the pair.
pwl = " ".join(f"{TSTART + t:.12e} {v:.6f}" for t, v in wave)


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
* The driven bitline edge is the COLUMN DECK'S OWN WAVEFORM, not a ramp:
*   {len(wave)} samples replayed from {os.path.basename(args.bl_wave)}
*   t_dis_50={cross(0.5)*1e9:.4f} ns, t_dis_10={cross(0.1)*1e9:.4f} ns
*   (these must match the column log -- they are the SAME curve)
*   replay ends at {BL_FLOOR*100:.0f}% of VDD, {tfall*1e9:.3f} ns in
* Measured bit: {dout_net}   (select: {sel_net})   output load: {args.load_ff} fF

.lib {rom_paths.sky130_lib()} {args.corner}
.temp {args.temp}
.param VDD={args.vdd}
.param TFALL={tfall:.6e}
.param TSTART={TSTART:.6e}

Vvdd {SUPPLY_HI} 0 DC {{VDD}}
Vgnd {SUPPLY_LO} 0 DC 0

* the measured column's bitline: the column deck's discharge, sample for sample
Vsrc {src_net} 0 PWL(0 {wave[0][1]:.6f} {pwl})

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
