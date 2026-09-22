#!/usr/bin/env python3
"""Measure the PERIPHERY switching energy per cycle of a ROM macro.

WHY IT IS NEEDED -- the `when : "!cs0"` gap:
  The .lib files only had `internal_power(){ when : "cs0"; }` on clk0. The
  energy spent when a clock arrives while the macro is DESELECTED (cs0=0) was
  never written down. When OpenSTA finds no matching block it silently scores
  that state as zero -- not even a warning. The netlist shows that is wrong:

    Xrom_control  clk0 cs0 precharge clk_int ...     (top level of <macro>.sp)
      clk_int = clock_driver(clk0)          -> INDEPENDENT of cs0
      precharge = ~NAND(cs0, clk_int)       -> stuck at 0 while cs0=0

  so with cs0=0:
    * the row decoder (`<macro>_rom_row_decode`) keeps being driven by
      clk_int -> address buffers, decoder internals and the wordlines switch
      EVERY CYCLE,
    * the column decoder and the precharge array are driven by `precharge` ->
      they stay put and do not switch,
    * the bitlines are held at VDD with the foot transistor off -> leakage
      only (already covered by `leakage_power`).

  So the `!cs0` energy is ENTIRELY periphery. This script measures it.

METHOD -- the same as the rest of the flow ("a slice x a count", never every
cell individually):
  Just as gen_col_power_tb.py measures ONE column and multiplies, the cell
  array (tens of thousands of transistors) is NOT simulated here. From the
  extracted netlist (<macro>_cap_only.spice, real Magic parasitic C) only the
  periphery instances are kept:

    X<macro>_rom_control_logic_0   (tens of devices)
    X<macro>_rom_row_decode_0      (thousands -- address buffers, decoder and
                                    wordline drivers included)
                                   a few thousand devices: seconds in ngspice

  So that the deleted array's LOAD does not vanish, for every array port the
  devices attached to it by their GATE are counted and put back as ONE instance
  with `m=<count>` (SPICE's own multiplier -- the same gate capacitance without
  expanding hundreds of instances). On top of that the parasitic wire
  capacitance INSIDE the array (the sum of the C elements touching that port)
  is added as a lump. That way the wordlines see their real load.

  Top-level C elements: kept as-is when both ends are on surviving nodes;
  when one end goes into a deleted block that end is moved to vssd1 (counting
  coupling capacitance as a grounded lump -- standard and mildly PESSIMISTIC);
  dropped when both ends are dead.

WHY ENERGY AND NOT POWER:
  Liberty `internal_power` is ENERGY per switching event (pJ). The power tool
  applies the frequency: P = E * f * activity. We integrate charge and write
  E = Q*VDD.

Modes (--cs):
  0  -> the `when : "!cs0"` value: energy of one clk0 cycle while deselected.
  1  -> the PERIPHERY share of an active cycle. The `--energy-pj` number
        (columns x per-column energy) must be ADDED to it; regen_rom_libs.sh
        does that sum.

Usage:
  gen_periphery_power_tb.py <macro> <0|1> <out.sp>
      [--corner tt|ss|ff] [--vdd 1.8] [--temp 25] [--tclk 200n] [--addr N]
"""
import argparse, collections, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rom_paths

ap = argparse.ArgumentParser()
ap.add_argument("macro")
ap.add_argument("cs", type=int, choices=[0, 1],
                help="0 = idle (!cs0), 1 = selected (cs0)")
ap.add_argument("out")
ap.add_argument("--corner", default="tt", choices=["tt", "ss", "ff"])
ap.add_argument("--vdd", default="1.8")
ap.add_argument("--temp", default="25")
ap.add_argument("--tclk", default="200n",
                help="cycle period; the ENERGY must be INDEPENDENT of it "
                     "-- verify by running two different values")
ap.add_argument("--addr-alt", type=int, default=None,
                help="if given, the address is switched from --addr to this "
                     "during the PRECHARGE phase before the measured clock "
                     "edge, and the addr0 -> decoder delay (SETUP) is "
                     "measured. Because the decoder is PRECHARGED the address "
                     "must be settled WHEN evaluate begins: if the wrong "
                     "wordline falls it does not come back, just like a bitline.")
ap.add_argument("--addr", type=int, default=0,
                help="the address held constant (selects that row)")
ap.add_argument("--gate-cap-ff", type=float, default=None,
                help="EQUIVALENT gate capacitance per cell (fF), measured by "
                     "gen_cell_gate_tb.py. If given, the wordline load is "
                     "modelled as a LINEAR C instead of bare devices (same "
                     "energy, far more robust convergence).")
ap.add_argument("--clk-slew", default="0.5n",
                help="clk0 rise/fall time. This is the index_1 "
                     "(input_net_transition) axis of the .lib: the front-end "
                     "term t_clk2pre is the ONLY part of access that depends "
                     "on it, so run_slew_sweep.sh sweeps this and nothing "
                     "else. The default 0.5n is the value every earlier "
                     "measurement used.")
ap.add_argument("--steps", type=int, default=200,
                help="time steps per cycle")
ap.add_argument("--cycles", type=int, default=8,
                help="number of cycles to run (at least 4). The last two full "
                     "cycles are measured; equal values prove settling.")
ap.add_argument("--with-coldec", action="store_true",
                help="also keep rom_column_decode and measure the COLUMN "
                     "SELECT path (precharge -> word_sel_k). The column "
                     "decoder is clocked by the precharge net itself, so it "
                     "runs in PARALLEL with the bitline discharge rather than "
                     "in series with it; what this proves is that the "
                     "unselected selects have FALLEN before the bitline data "
                     "develops.")
ap.add_argument("--pin-cap", action="store_true",
                help="measure the INPUT PIN CAPACITANCES instead of energy. "
                     "Keeps every block an input pin touches (control logic, "
                     "row decoder, column decoder) and ramps one pin at a "
                     "time, integrating the charge that pin has to supply: "
                     "C = Q(VDD)/VDD, the same reduction gen_cell_gate_tb.py "
                     "uses. See run_pin_cap.sh.")
ap.add_argument("--pin-tr", default="1n",
                help="--pin-cap: ramp time of the measured pin. It must be "
                     "slow enough that the charge is the pin's own and not a "
                     "displacement spike through the first gate, and fast "
                     "enough to stay in the regime a real driver works in.")
ap.add_argument("--macros-dir", default=None,
                help="macro tree (default: ROM_MACROS_DIR / <repo>/examples)")
args = ap.parse_args()

M = args.macro
SP = rom_paths.cap_netlist(M, args.macros_dir)
if not os.path.exists(SP):
    sys.exit(f"ERROR: {SP} does not exist -- run run_cap_extract.sh first")

# --- unit fix-up: IDENTICAL to gen_col_tb_parasitic.py (validated) --------
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

# --- split the netlist into logical lines (continuations joined) ----------
def blocks(path):
    """subckt name -> list of logical lines (the first one is the header)."""
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
ARRAY = f"{M}_rom_base_array"
for need in (TOP, ARRAY):
    if need not in B:
        sys.exit(f"ERROR: no .subckt {need} in {SP}")

top_lines = B[TOP]
top_ports = top_lines[0].split()[2:]
top_insts = [l for l in top_lines if l.startswith("X")]
top_caps  = [l for l in top_lines if l.startswith("C")]

# --- instances to keep / delete -------------------------------------------
KEEP_SUB = {f"{M}_rom_control_logic", f"{M}_rom_row_decode"}
# The column decoder is a THIRD periphery block. It is kept only on demand
# because it changes what the deck measures, not what it burns: including it
# would move e_periph_pj, and the committed energy numbers are taken WITHOUT
# it (the .lib counts the column array separately). --with-coldec is
# therefore a timing run: only its t_pre2sel* measurements are usable.
COLDEC = f"{M}_rom_column_decode"
MUX = f"{M}_rom_column_mux_array"
if args.with_coldec or args.pin_cap:
    # --pin-cap needs it too: addr0[0:2] go to the COLUMN decoder and
    # addr0[3:] to the row decoder, so without it three address pins would be
    # measured driving nothing at all.
    KEEP_SUB.add(COLDEC)
keep = [l for l in top_insts if l.split()[-1] in KEEP_SUB]
drop = [l for l in top_insts if l.split()[-1] not in KEEP_SUB]
if len(keep) != len(KEEP_SUB):
    sys.exit(f"ERROR: periphery instances not found (want {sorted(KEEP_SUB)}, "
             f"found: {[l.split()[-1] for l in top_insts]})")

SUPPLY_HI, SUPPLY_LO = "vccd1", "vssd1"
alive = set([SUPPLY_HI, SUPPLY_LO, "0"])
for l in keep:
    alive.update(l.split()[1:-1])
alive.update(p for p in top_ports if re.match(r"^(clk0|cs0|addr0\[)", p))

# --- put back the load of the deleted cell array --------------------------
arr = B[ARRAY]
arr_ports = arr[0].split()[2:]
arr_inst = [l for l in drop if l.split()[-1] == ARRAY]
if not arr_inst:
    sys.exit(f"ERROR: no {ARRAY} instance at top level")
p2n = dict(zip(arr_ports, arr_inst[0].split()[1:-1]))

# Collect the load INSIDE the array, DESCENDING into nested sub-circuits (the
# precharge PMOSes, for instance, sit in the base_array > precharge_array >
# precharge_cell chain); looking only at the top level would leave the
# precharge net unloaded.
def gate_index(sub):
    ports = B[sub][0].split()[2:]
    return ports.index("G") if "G" in ports else None

gate_cnt = collections.Counter()      # (subckt, arr_port) -> adet
wire_c   = collections.Counter()      # arr_port -> toplam parazitik C (F)
dev_cnt  = collections.Counter()      # (model, arr_port) -> adet  (raw devices)
dev_line = {}                         # (model, arr_port) -> the X line to copy

# A device can reach `collect` in two shapes. The cell array wraps its
# transistors in sub-circuits (rom_base_one_cell, with named G/S/D ports), but
# the column mux instantiates the PDK model directly:
#     X0 bl_out sel bl gnd sky130_fd_pr__nfet_01v8 ad=... w=2.88u l=0.15u
# i.e. an X line whose "sub-circuit" is a model name and whose tail is
# parameters. Those were skipped outright, which for --with-coldec meant the
# eight column selects were left carrying nothing but coupling C -- 32 pass
# gates each, the entire load the decoder drives.
DEV_RE = re.compile(r"(nfet|pfet|nmos|pmos)", re.I)

def device_nodes(tokens):
    """(nodes, model) of a raw device X line, or (None, None) if it is not one."""
    pi = next((j for j, tok in enumerate(tokens) if "=" in tok), len(tokens))
    if pi < 2:
        return None, None
    model = tokens[pi - 1]
    if not DEV_RE.search(model):
        return None, None
    return tokens[1:pi - 1], model

def collect(sub, xlate, mult=1, depth=0):
    """xlate: sub-circuit local node name -> array port (only the ones we want)"""
    if depth > 8:
        return
    for l in B[sub][1:]:
        t = l.split()
        if l.startswith("X"):
            child, nets = t[-1], t[1:-1]
            if child not in B:
                # raw PDK device: standard MOS node order D G S B -> gate is #2
                dn, model = device_nodes(t)
                if dn and len(dn) >= 2:
                    g = xlate.get(dn[1])
                    if g:
                        dev_cnt[(model, g)] += mult
                        dev_line[(model, g)] = l
                continue
            gi = gate_index(child)
            if gi is not None:
                g = xlate.get(nets[gi])
                if g:
                    gate_cnt[(child, g)] += mult
                continue
            cports = B[child][0].split()[2:]
            sub_x = {cp: xlate[n] for cp, n in zip(cports, nets) if n in xlate}
            if sub_x:
                collect(child, sub_x, mult, depth + 1)
        elif l.startswith("C") and len(t) >= 4:
            try:
                v = to_float(t[3])
            except ValueError:
                continue
            for n in (t[1], t[2]):
                if n in xlate:
                    wire_c[xlate[n]] += v * mult

# The load on the GATE side of a cell: the device itself (m=<count>) plus the
# cell's internal gate parasitics (lumped). A SUB-CIRCUIT call with m=<count>
# is NOT used: ngspice implements m on an X line by EXPANDING the sub-circuit
# -- tens of thousands of instances, as expensive as simulating the whole
# array (measured 2026-09-06: one cycle had not finished in 2 minutes). A bare
# device with m is ONE device at SPICE level.
def cell_gate_model(sub):
    """(device line, sub-circuit ports, internal C landing on the gate [F])"""
    dev, cg = None, 0.0
    for l in B[sub][1:]:
        t = l.split()
        if l.startswith("X"):
            dev = l
        elif l.startswith("C") and len(t) >= 4 and "G" in (t[1], t[2]):
            try:
                cg += to_float(t[3])
            except ValueError:
                pass
    return dev, B[sub][0].split()[2:], cg

def rebuild_load(sub, tag):
    """Put back the load a DELETED block leaves on the nets that are still alive.

    Same 'slice x count' reduction for any block: descend into it, count the
    gates each of its ports drives, lump the internal wire parasitics, and emit
    one device with m=<count> plus one C per alive net. Called for the cell
    array (the wordline load) and, with --with-coldec, for the column mux array
    -- without the second call the eight column selects would drive nothing but
    their own wire C, and a decoder measured into no load is not a measurement.

    Returns (spice lines, [(port, cell count, lumped C)]).
    """
    inst = [l for l in drop if l.split()[-1] == sub]
    if not inst:
        sys.exit(f"ERROR: no {sub} instance at top level")
    ports = dict(zip(B[sub][0].split()[2:], inst[0].split()[1:-1]))
    gate_cnt.clear()
    wire_c.clear()
    dev_cnt.clear()
    dev_line.clear()
    collect(sub, {p: p for p in ports})
    load_lines, load_report = [], []
    # only load the nodes that are STILL ALIVE at top level
    for i, (port, net) in enumerate(sorted(ports.items())):
        if net not in alive or net in (SUPPLY_HI, SUPPLY_LO, "0"):
            continue
        subs = [(sb, c) for (sb, pp), c in gate_cnt.items() if pp == port]
        cw = max(wire_c.get(port, 0.0), 0.0)   # dizi ici tel parazitigi
        ncell = 0
        for sb, c in sorted(subs):
            dev, _, cg = cell_gate_model(sb)
            if dev is None:
                continue
            cw += cg * c
            ncell += c
            if args.gate_cap_ff is not None:
                # The gate load is modelled as a LINEAR C. That is the correct
                # reduction for energy: the charge drawn from VDD to pull a node to
                # VDD is Q(VDD), so using C_eq = Q(VDD)/VDD preserves the ENERGY
                # exactly. Placing the device with m=<count> gives the same energy
                # but creates a capacitance hundreds of times wider and strongly
                # NON-LINEAR, which kept ngspice from converging (2026-09-06:
                # "Timestep too small" in three separate attempts).
                cw += args.gate_cap_ff * 1e-15 * c
                continue
            t = dev.split()
            # The device nodes are written with sub-circuit port names. G -> the
            # measured net; the rest go to their own supply rail (tying a PMOS body
            # or source to ground gives the WRONG gate capacitance), and the
            # bitline side sits at ground -- bitlines are static in this run.
            nets = [net if n == "G"
                    else (SUPPLY_HI if n.startswith("vdd") else SUPPLY_LO)
                    for n in t[1:5]]
            load_lines.append(fix_units(
                "X_%s%d_%d " % (tag, i, len(load_lines)) + " ".join(nets) + " "
                + " ".join(t[5:]) + " m=%d" % c))
        # raw PDK devices whose gate sits on this net (the column mux)
        for (mdl, pp), c in sorted(dev_cnt.items()):
            if pp != port:
                continue
            t = dev_line[(mdl, pp)].split()
            dn, _ = device_nodes(t)
            pi = t.index(mdl)
            # gate -> the measured net; source/drain/body -> ground. The mux
            # passes a BITLINE, which is static in this run, so tying it low is
            # the strong-inversion (largest, pessimistic) gate capacitance.
            nets = [net if j == 1 else SUPPLY_LO for j in range(len(dn))]
            load_lines.append(fix_units(
                "X_%s%d_%d " % (tag, i, len(load_lines)) + " ".join(nets)
                + " " + " ".join(t[pi:]) + " m=%d" % c))
            ncell += c
        if cw > 0:
            load_lines.append(f"C_{tag}{i} {net} {SUPPLY_LO} {cw*1e15:.5f}f")
        if ncell or cw > 0:
            load_report.append((port, ncell, cw))
    return load_lines, load_report

load_lines, load_report = rebuild_load(ARRAY, "wl")
if COLDEC in KEEP_SUB:
    # The eight column selects drive 256 mux pass transistors between them.
    # Without this the decoder would be measured driving its own wire C alone
    # and would come out far too fast.
    mux_lines, mux_report = rebuild_load(MUX, "sel")
    load_lines += mux_lines
    load_report += mux_report

# --- top-level C elements: the alive/dead rule ----------------------------
kept_c, retarget = [], collections.Counter()
n_drop = 0
for l in top_caps:
    t = l.split()
    if len(t) < 4:
        continue
    a, b = t[1], t[2]
    try:
        v = to_float(t[3])
    except ValueError:
        continue
    ao, bo = a in alive, b in alive
    if ao and bo:
        kept_c.append(l)
    elif ao:
        retarget[a] += v
    elif bo:
        retarget[b] += v
    else:
        n_drop += 1
clamped = 0
for i_rt, (n, v) in enumerate(sorted(retarget.items())):
    if v <= 0:
        clamped += 1
        continue
    kept_c.append(f"C_rt{i_rt} {n} {SUPPLY_LO} {v*1e15:.5f}f")

# --- NEGATIVE NET CAPACITANCE FIX ----------------------------------------
# Magic's ext2spice (cthresh 0) writes NEGATIVE-valued Cs as substrate
# corrections; they only make sense together with the POSITIVE terms of the
# blocks they couple to. Deleting the cell array removed those positive terms
# and the NET capacitance of over a thousand nodes went negative -- which is
# fatal for the solver: every attempt blew up with "Timestep too small" at
# t~1e-13..1e-10 (2026-09-06, six different option/stimulus combinations).
# The fix is minimal: for each node whose NET SUM is negative, add a C that
# brings the sum back to zero. Nodes driven by a source (supplies, clk0, cs0,
# addr) are left alone -- capacitance does not set their voltage.
driven = {SUPPLY_HI, SUPPLY_LO, "0"} | {
    p for p in top_ports if re.match(r"^(clk0|cs0|addr0\[)", p)}
node_c = collections.Counter()
for l in kept_c + [x for x in load_lines if x.startswith("C")]:
    t = l.split()
    try:
        v = to_float(t[3])
    except (ValueError, IndexError):
        continue
    node_c[t[1]] += v
    node_c[t[2]] += v
n_fix, c_fix_tot = 0, 0.0
for i_fx, (n, v) in enumerate(sorted(node_c.items())):
    if v >= 0 or n in driven:
        continue
    kept_c.append(f"C_fx{i_fx} {n} {SUPPLY_LO} {-v*1e15:.5f}f")
    n_fix += 1
    c_fix_tot += -v

# --- sub-circuit definitions: only the ones ACTUALLY used ----------------
# Emitting unused definitions makes ngspice do pointless work (the column
# decoder / mux / bitline inverter blocks are ~10k lines).
need, seen = set(l.split()[-1] for l in keep), set()
while need - seen:
    n = (need - seen).pop()
    seen.add(n)
    for l in B.get(n, [])[1:]:
        if l.startswith("X"):
            sub = l.split()[-1]
            if sub in B:
                need.add(sub)
defs = []
for name in sorted(seen):   # sorted: deterministic output file
    if name in (TOP, ARRAY):
        continue
    ls = B[name]
    defs.append("\n".join(fix_units(l) if l.startswith("X") else l for l in ls))
    defs.append(".ends")
defs = "\n".join(defs)

keep_fixed = "\n".join(fix_units(l) for l in keep)

# --- initial condition for the precharged DECODER chain nodes ------------
# The row decoder is a NAND-chain structure too; its internal chain nodes have
# no DC path to ground. Starting them all at 0 with uic made ngspice shrink the
# time step until it gave up ("Timestep too small ... rom_base_one_cell_53/s").
# While clk_int is low the physically correct state is PRECHARGED
# -- the same trick as `.ic v(bl)={VDD}` in the column measurement.
# The column decoder (--with-coldec) is the same structure and needs the same
# treatment: its decode array is built from the very same rom_base_one_cell /
# rom_base_zero_cell chain as the bit array, so its internal nodes have no DC
# path either.
ic_nodes = [n for n in
            (l.split()[1:-1] for l in keep
             if l.split()[-1].endswith(("row_decode", "column_decode")))
            for n in n
            if re.search(r"rom_base_(one|zero)_cell_\d+/[SD]$", n)
            or re.search(r"/bl_\d+_\d+$", n)]
ic_txt = "\n".join(f".ic v({n})={{VDD}}" for n in sorted(set(ic_nodes)))

# --- FRONT END DELAY: clk0 -> precharge / wordline -----------------------
# `access` in the .lib runs from the rising edge of clk0 until dout0 is valid.
# The column measurement (t_dis_50) triggers off the internal `precharge` net,
# so the piece from clk0 to precharge/wordline is not in it.
# It is measured here; total: access = max(t_clk2pre, t_clk2wl) + t_dis_50
#                                    + t_bl2dout (gen_backend_delay_tb.py)
ctl = set(next(l for l in keep if l.split()[-1].endswith("control_logic"))
          .split()[1:-1])
rowd = set(next(l for l in keep if l.split()[-1].endswith("row_decode"))
           .split()[1:-1])
arrn = set(arr_inst[0].split()[1:-1])
supplies = {SUPPLY_HI, SUPPLY_LO, "0", "clk0", "cs0"}
clk_int = sorted(ctl & rowd - supplies)
pre_net = sorted(ctl & arrn - supplies)
wl_meas = [n for k in range(8)
           for n in rowd if re.search(r"/wl_%d$" % k, n)]
# RISE=N cannot be used: ngspice counts each signal's transitions SEPARATELY
# from t=0, so when internal nodes glitch at start-up, clk0's 2nd rise and the
# target's 2nd rise no longer belong to the same cycle (negative delays).
# Instead we use a TIME WINDOW (TD) starting just before the
# measured clock edge; both trig and targ then catch the first crossing after
# it. A late cycle is used so the circuit has settled.
_tclk = to_float(args.tclk)
_edge = (args.cycles - 2) * _tclk        # the clk0 rising edge to measure
_td_trig = _edge - _tclk / 20.0
# The TARG window starts EXACTLY at the edge: because the decoder is
# precharged, the wordlines also rise on clk0's FALLING edge (the precharge
# phase). Giving TARG a TD before the edge makes the measurement catch that
# falling-edge rise and produce a NEGATIVE delay (t_clk2wl = -99 ns).
_td_targ = _edge
fe = []
def _m(name, node):
    pad = " " * len(name)
    return [f".measure tran {name} TRIG v(clk0) VAL='VDD/2' RISE=1 "
            f"TD={_td_trig:.6e}",
            f"+                {pad}TARG v({node}) VAL='VDD/2' RISE=1 "
            f"TD={_td_targ:.6e}"]
if clk_int:
    fe += _m("t_clk2int", clk_int[0])
# Which wordline is selected depends on the address encoding and cannot be
# read off the names Magic generates; the first few wordlines are measured, and
# whichever one moves after clk0's RISING edge is the selected one (the others
# report "failed", which is expected and informative).
# The decoder POLARITY is measured rather than assumed: if all wordlines rise
# during the precharge phase (clk0 low), then in evaluate the UNSELECTED rows
# fall. Both the rise and the fall are measured so this conclusion is EVIDENCE,
# not an assumption -- and it is what justifies the column deck holding all
# wordlines at DC VDD, with the front-end term being clk0 -> precharge only.
for k, n in enumerate(wl_meas):
    fe += _m(f"t_clk2wl{k}", n)
    pad = " " * len(f"t_wlfall{k}")
    fe += [f".measure tran t_wlfall{k} TRIG v(clk0) VAL='VDD/2' RISE=1 "
           f"TD={_td_trig:.6e}",
           f"+                {pad}TARG v({n}) VAL='VDD/2' FALL=1 "
           f"TD={_td_targ:.6e}"]
if pre_net and args.cs:
    # with cs0=0 precharge never rises -- the measurement only means something at cs0=1
    fe += _m("t_clk2pre", pre_net[0])

# --- COLUMN DECODE: precharge -> column select ---------------------------
# README limitation 2 until 2026-09-22: the column decoder was the one block
# the flow never simulated. The back-end deck drives the eight selects with
# ideal DC sources, so nothing proved they are where they must be when the
# bitline data arrives.
#
# What the netlist says (top level of <macro>.sp):
#     Xrom_column_decoder  addr0[0] addr0[1] addr0[2]
#   +   word_sel_0 .. word_sel_7  precharge precharge  vccd1 vssd1
# Its `clk` and its `precharge` port are BOTH tied to the internal precharge
# net -- the same net t_dis_50 triggers off. So the column decoder does NOT
# sit in series with the bitline: the two start together and RACE. access is
# therefore
#     t_clk2pre + max(t_dis_50, t_pre2sel) + t_bl2dout
# and not a sum of four terms.
#
# POLARITY, measured 2026-09-22 and not assumed. The decode array is the same
# precharged NAND chain as the bit array, but rom_column_decode_wordline_buffer
# INVERTS it, so the selects behave the opposite way to the row decoder's
# wordlines: during precharge ALL EIGHT ARE LOW (the mux is fully off and the
# 32 outputs float), and during evaluate only the SELECTED one rises. The first
# run of this deck showed exactly that -- sel_0 rose 0.574 ns after precharge
# and sel_1..7 never crossed VDD/2 at all ("out of interval"), with --addr 0.
#
# So the binding check is the RISE of the selected select:
#     t_pre2sel_rise  <  t_dis_50
# i.e. the mux has to be open before the bitline has separated from VDD. It is
# a RACE, not a sum, which is why the column decoder never entered access.
#
# Both directions are measured on all eight so this stays evidence rather than
# assumption: the seven unselected ones report "failed", and that failure is
# the measurement. The FALL is taken from the precharge FALLING edge (the end
# of evaluate) -- the select lingering past it is what the falling-edge arc
# cares about, and triggering it off the rising edge just caught the previous
# cycle's deselect and reported -99 ns.
if args.with_coldec:
    cold = set(next(l for l in keep if l.split()[-1] == COLDEC).split()[1:-1])
    # the select nets: the decoder's wl_k, which are the mux's sel_k
    mux_inst = [l for l in drop if l.split()[-1] == MUX]
    if not mux_inst:
        sys.exit(f"ERROR: no {MUX} instance at top level")
    mp2n = dict(zip(B[MUX][0].split()[2:], mux_inst[0].split()[1:-1]))
    sel_nets = [mp2n[q] for q in sorted(
        (q for q in mp2n if re.match(r"^sel_\d+$", q)),
        key=lambda q: int(q.split("_")[1]))]
    missing = [n for n in sel_nets if n not in cold]
    if missing:
        sys.exit(f"ERROR: the column mux selects are not driven by "
                 f"{COLDEC}: {missing[:3]}")
    if not pre_net:
        sys.exit("ERROR: --with-coldec needs the precharge net, which is only "
                 "alive at cs0=1")
    _pre = pre_net[0]
    # evaluate is [clk0 rise, clk0 fall] = [_edge + TCLK/2, _edge + TCLK];
    # precharge follows clk0 by t_clk2pre at both ends.
    _t_eval_end = _edge + _tclk
    for k, n in enumerate(sel_nets):
        nm = f"t_pre2sel{k}_rise"
        pad = " " * len(nm)
        fe += [f".measure tran {nm} TRIG v({_pre}) VAL='VDD/2' RISE=1 "
               f"TD={_td_trig:.6e}",
               f"+                {pad}TARG v({n}) VAL='VDD/2' RISE=1 "
               f"TD={_td_targ:.6e}"]
        nm = f"t_pre2sel{k}_fall"
        pad = " " * len(nm)
        fe += [f".measure tran {nm} TRIG v({_pre}) VAL='VDD/2' FALL=1 "
               f"TD={_t_eval_end - _tclk / 20.0:.6e}",
               f"+                {pad}TARG v({n}) VAL='VDD/2' FALL=1 "
               f"TD={_t_eval_end:.6e}"]

# --- address bits and switching instant (used by both stimulus and measure) -
# The bit count is derived from top_ports (i.e. from the LEF pin list).
_abits = sorted(int(mm.group(1))
                for p_ in top_ports
                for mm in [re.match(r"addr0\[(\d+)\]$", p_)] if mm)
# The measured clk0 rising edge is at _edge + TCLK/2; the PRECHARGE phase
# before it is [_edge, _edge+TCLK/2]. The address is switched in the middle of
# that phase -> TCLK/4 before the edge, plenty of time for the decoder.
_t_sw = _edge + _tclk / 4.0

# --- SETUP: addr0 -> decoder ----------------------------------------------
# The decoder is PRECHARGED: every wordline rises during precharge and the
# UNSELECTED ones fall during evaluate. So the address must be settled at the
# decoder INPUTS when clk0 rises, and that is exactly the path measured here:
#     addr0 -> inv_array_mod (address buffer) -> the clocked decoder NAND
# This is the physical counterpart of setup_rising in the .lib; without it
# gen_rom_lib.py falls back to the analytic guess in BASE.
if args.addr_alt is not None:
    _sw_bits = [i for i in _abits
                if ((args.addr >> i) & 1) != ((args.addr_alt >> i) & 1)]
    if _sw_bits:
        _trig_pin = f"addr0[{_sw_bits[0]}]"
        _td = _t_sw - _tclk / 40.0        # start just before the transition

        def _ms(name, node):
            pad = " " * len(name)
            return [f".measure tran {name} TRIG v({_trig_pin}) VAL='VDD/2' "
                    f"CROSS=1 TD={_td:.6e}",
                    f"+                {pad}TARG v({node}) VAL='VDD/2' "
                    f"CROSS=1 TD={_td:.6e}"]

        # TARGET: the A input of the decoder NAND. Netlist structure:
        #     X..._nand2_dec_N  gnd vdd  <A>  clk  <Z>  <internal>
        # i.e. the address goes from the buffer STRAIGHT into a clocked NAND;
        # there is no separate predecode stage. The last point at which the
        # address must be stable is that A net -- the physical meaning of setup.
        #
        # The wordline buffer inputs (pbuf_dec) are NOT the target: because the
        # decoder is precharged, all wordlines are high during precharge and do
        # not move when the address changes (the measurement reports "failed").
        # Structure of rom_address_control_buf (from the netlist):
        #     addr0 -> inv_array_mod/Z -> nand2_dec(A=inv/Z, clk) -> A_out
        # so inv_array_mod's Z IS the A input of the decoder NAND. There is one
        # buffer per address bit; ALL are measured and the worst one is used.
        _samp = sorted(n for n in rowd if re.search(r"inv_array_mod_\d+/Z$", n))
        for _k, _n in enumerate(_samp):
            fe += _ms(f"t_addr2dec{_k}", _n)
fe_txt = "\n".join(fe)
caps_txt = "\n".join(kept_c)
loads_txt = "\n".join(load_lines)

# --- PIN CAPACITANCE ------------------------------------------------------
# README limitation 5 until 2026-09-22: `capacitance` on every input pin was
# an analytic guess from gate widths -- PIN_CAP = {"clk0": 0.0025, "cs0":
# 0.0030, "_default": 0.0060} in gen_rom_lib.py, i.e. ONE number for all
# eleven address bits. The extraction says that cannot be right: the top-level
# wire C alone runs from 6 C elements on addr0[0] to 41 on addr0[10].
#
# WHAT IS MEASURED. Each input pin is ramped 0 -> VDD on its own, with every
# other pin parked, and the charge it has to supply is integrated:
#
#     C = Q(VDD) / VDD
#
# the same reduction gen_cell_gate_tb.py uses for the cell gate, and for the
# same reason: Liberty `capacitance` is a single scalar a driver's delay
# calculation multiplies, so what matters is the total charge over the swing,
# not the shape of the non-linear C-V curve underneath it.
#
# This is the WHOLE load and not just a gate: the pin's top-level wire C, the
# gate C of every first-stage device it drives, and the Miller charge pushed
# back through that stage as it switches -- all of it comes out of the same
# integral, because it all comes out of the same source.
#
# THE FALLING RAMP IS MEASURED TOO, and it is not redundant. An input cap that
# differs between the two directions is a state-dependent one, and a single
# Liberty scalar cannot represent it; the runner compares them and the larger
# is what ships. Each pin also returns to 0 before the next one starts, so
# every pin is measured from the same quiescent state.
#
# THE STATE IT IS MEASURED IN: all pins at 0, i.e. clk0 low (precharge phase,
# the half of the cycle in which the address has to be stable anyway) and the
# macro deselected. That is a choice, and the rise-vs-fall comparison is what
# makes it a checkable one rather than an assumption.
if args.pin_cap:
    pin_names = [p_ for p_ in top_ports
                 if re.match(r"^(clk0|cs0|addr0\[\d+\])$", p_)]
    if not pin_names:
        sys.exit("ERROR: --pin-cap found no input pins at top level")
    _tr = to_float(args.pin_tr)
    # THE HOLD IS PART OF THE MEASUREMENT, not padding between edges. See the
    # window note below; it has to be long enough for the stage the pin drives
    # to finish switching, so it is generous rather than tight.
    _th = 10 * _tr
    _t0 = 20e-9                   # let the precharged chain nodes settle first
    # A QUIET GAP AFTER EACH PIN. Without it (2026-09-22) the slots touched,
    # and ADJACENT pins moved by ~4% in OPPOSITE directions when --pin-tr was
    # doubled -- addr0[0] +4.65% against addr0[1] -4.02%, addr0[4] -4.14%
    # against addr0[5] +3.92% -- while each PAIR summed to within 0.3%. That
    # is one pin's settling tail crossing the boundary into its neighbour's
    # window, not a change in anyone's capacitance. The gap is dead time: no
    # measurement window covers it.
    _slot = 2 * _tr + 3 * _th
    pin_src, pin_meas, pin_rows = [], [], []
    for i, p_ in enumerate(pin_names):
        t_r0 = _t0 + i * _slot
        t_r1 = t_r0 + _tr
        t_f0 = t_r1 + _th
        t_f1 = t_f0 + _tr
        pin_src.append(
            f"Vpin{i} {p_} 0 PWL(0 0 {t_r0:.6e} 0 {t_r1:.6e} {{VDD}} "
            f"{t_f0:.6e} {{VDD}} {t_f1:.6e} 0)")
        # THE WINDOW RUNS TO THE END OF THE HOLD, NOT TO THE END OF THE RAMP.
        # Integrating the ramp alone (2026-09-22) was not ramp independent:
        # doubling --pin-tr moved five of the thirteen pins by 10-13% while the
        # other eight stayed inside 0.3%. The reason is that the stage the pin
        # drives goes on switching after the pin has finished moving, and its
        # Miller current keeps coming back out of the pin. Cutting the integral
        # at the end of the ramp keeps whatever fraction of that tail happened
        # to fall inside, and that fraction depends on the ramp time -- which is
        # exactly the arbitrary knob it must not depend on.
        # Over ramp + hold the pin voltage ends flat and the tail has died, so
        # the integral is the TOTAL charge for the transition, which is what
        # C = Q/VDD means.
        pin_meas.append(
            f".measure tran q_rise{i} integ i(Vpin{i}) "
            f"from={t_r0:.6e} to={t_f0:.6e}")
        pin_meas.append(
            f".measure tran q_fall{i} integ i(Vpin{i}) "
            f"from={t_f0:.6e} to={t_f1 + _th:.6e}")
        pin_meas.append(
            f".measure tran c_rise{i}_ff param='abs(q_rise{i})/VDD*1e15'")
        pin_meas.append(
            f".measure tran c_fall{i}_ff param='abs(q_fall{i})/VDD*1e15'")
        # THE SHIPPED VALUE IS THE FULL CYCLE, not either edge on its own.
        # On clk0 the two edges TRADED PLACES when --pin-tr was doubled --
        # rise 4.403 / fall 4.898 at 1 ns against rise 4.858 / fall 4.464 at
        # 2 ns -- while the SUM held at 9.301 vs 9.322, 0.2% apart. The charge
        # is conserved; only the boundary between the two windows moves,
        # because a pin with a deep fanout is still settling when the fall
        # begins. Averaging the two edges is immune to where that boundary
        # falls, and it is the same quantity either way: the charge for one
        # full 0 -> VDD -> 0 round trip, over two swings.
        pin_meas.append(
            f".measure tran c_cyc{i}_ff "
            f"param='(abs(q_rise{i})+abs(q_fall{i}))/(2*VDD)*1e15'")
        # A machine-readable marker, not prose: run_pin_cap.sh and
        # regen_rom_libs.sh read this mapping back out of the deck. The first
        # attempt formatted it as "*  <i>  <name>" and a header line reading
        # "*   10 negative sums clamped" matched the same pattern, which put a
        # pin called "negative" into the .lib command line.
        pin_rows.append(f"*PINCAP {i} {p_}")
    pin_src_txt = "\n".join(pin_src)
    pin_meas_txt = "\n".join(pin_meas)
    t_end = _t0 + len(pin_names) * _slot + _th

# --- stimulus -------------------------------------------------------------
if args.addr_alt is None:
    addr_src = "\n".join(
        f"Vaddr{i} addr0[{i}] 0 DC {{{'VDD' if (args.addr >> i) & 1 else '0'}}}"
        for i in _abits)
else:
    # 100 ps transition -- so the stimulus itself does not enter the delay.
    _lines = []
    for i in _abits:
        a = (args.addr >> i) & 1
        b = (args.addr_alt >> i) & 1
        if a == b:
            _lines.append(f"Vaddr{i} addr0[{i}] 0 DC {{{'VDD' if a else '0'}}}")
        else:
            v0 = "{VDD}" if a else "0"
            v1 = "{VDD}" if b else "0"
            _lines.append(
                f"Vaddr{i} addr0[{i}] 0 PWL(0 {v0} {_t_sw:.6e} {v0} "
                f"{_t_sw + 100e-12:.6e} {v1})")
    addr_src = "\n".join(_lines)
cs_val = "{VDD}" if args.cs else "0"
mode = "ACTIVE (cs0=1)" if args.cs else "IDLE (cs0=0)  -->  when : \"!cs0\""
wl_n = sum(1 for p, c, w in load_report if re.match(r"^wl_", p))
cells = sum(c for p, c, w in load_report if re.match(r"^wl_", p))

# The PULSE edge is written into the deck verbatim, so it accepts any SPICE
# time literal ("50p", "0.5n", "1.5e-9").
slew = args.clk_slew

coldec_txt = (
    "*          rom_column_decode (--with-coldec: the 3->8 column decoder,\n"
    "*                             clocked by the precharge net itself)\n"
    if args.with_coldec else "")
coldec_note = (
    "* --with-coldec: this is a TIMING run. Keeping the column decoder adds its\n"
    "* switching to i(Vvdd), so e_periph_pj from this deck is NOT the number the\n"
    "* .lib uses -- only the t_pre2sel* measurements from it are usable.\n"
    if args.with_coldec else "")

if args.pin_cap:
    tb = f"""* {M} -- INPUT PIN CAPACITANCE ({args.corner})
* C = Q(VDD)/VDD per pin -- the charge the pin itself has to supply over a
* full swing. That is the whole load: top-level wire C, the gate C of the
* first stage, and the Miller charge pushed back through it as that stage
* switches, since all three come out of the same source.
*
* Kept: rom_control_logic (clk0, cs0), rom_row_decode (addr0[3:]),
*       rom_column_decode (addr0[0:2]) -- every block an input pin touches.
*       The deleted cell array and column mux are put back as load
*       ({wl_n} wordlines, {cells} cell gates) so the decoders switch against
*       what they really drive; that switching is what feeds Miller charge
*       back into the address pins.
* Top-level C: {len(kept_c)} kept/merged, {n_drop} dropped (both ends dead),
*              {clamped} negative sums clamped (Magic substrate correction)
* Negative NET capacitance fix: {n_fix} nodes, {c_fix_tot*1e15:.1f} fF total
*
* ONE PIN AT A TIME: pin i ramps up over {args.pin_tr}, holds, ramps back down
* and stays down, so every pin is measured from the SAME quiescent state (all
* pins at 0: clk0 low, i.e. the precharge phase, macro deselected).
* BOTH EDGES ARE MEASURED. c_rise/c_fall differing means the pin cap is state
* dependent and a single Liberty scalar cannot carry it -- run_pin_cap.sh
* compares them and ships the larger.
*
* pin index -> name:
{chr(10).join(pin_rows)}

.lib {rom_paths.sky130_lib()} {args.corner}
.temp {args.temp}
.param VDD={args.vdd}

Vvdd {SUPPLY_HI} 0 DC {{VDD}}
Vgnd {SUPPLY_LO} 0 DC 0

* --- one independent source per input pin (the ammeter IS the measurement) --
{pin_src_txt}

* --- periphery instances (with parasitics, verbatim from the extraction) ---
{keep_fixed}

* --- decoder chain nodes start precharged ({len(set(ic_nodes))} nodes) ---
{ic_txt}

* --- load of the deleted cell array and column mux ---
{loads_txt}

* --- top-level parasitic C ---
{caps_txt}

* --- sub-circuit definitions ---
{defs}

* These are EXACTLY the energy deck's options, and the tolerances are not a
* copy-paste: tightening abstol to 1e-15 (2026-09-22) aborted this deck at
* t = 5e-14 with "Timestep too small ... precharge_cell_132 ... pfet#body",
* before any pin had moved -- the same start-up convergence trouble the energy
* deck's comments document. It is also unnecessary. The integrals here look
* small as CHARGE (~10 fC) but the current is not: 10 fC over a {args.pin_tr}
* ramp is ~10 uA, four orders above abstol=1e-12.
* method=gear is kept for the reason it was introduced next door -- trapezoidal
* ringing on the extracted body nodes lands straight in a charge integral.
.options gmin=1e-12 abstol=1e-12 reltol=1e-3 itl1=500 itl4=100 method=gear
* uic: the precharged decoder chain nodes have no DC path, so .op does not
* converge (see the energy deck). The first {_t0*1e9:.0f} ns are settling time
* before the first pin is touched.
*
* THE STEP IS THE RAMP TIME, NOT A FRACTION OF IT. Asking for a fine step up
* front is what kills this deck: TR/200 (5 ps) aborted at t = 5e-14 and TR/50
* (20 ps) at t = 2e-13, both before any pin had moved, collapsing the timestep
* to 1e-23 on an extracted body node. The working decks next door all run at
* ~1 ns and get sub-nanosecond numbers out, because this argument is the
* SUGGESTED step: ngspice's own LTE control refines it through the ramp, and
* .measure interpolates on the internal timepoints rather than on this grid.
.tran '{_tr:.6e}' '{t_end:.6e}' uic

{pin_meas_txt}
.end
"""
else:
    tb = f"""* {M} -- PERIPHERY energy per cycle -- {mode}
* Kept:    rom_control_logic (clock driver + control_nand + prechg driver)
*          rom_row_decode    (address buffers + decoder + wl drivers)
{coldec_txt}{coldec_note}* Deleted: cell array / column mux / bitline and output
*          inverters. The deleted blocks' LOAD was put back:
*            {wl_n} wordlines, {cells} cell gates total (one instance + m=<count>)
*            + the array's internal parasitic wire C (lumped)
* Top-level C: {len(kept_c)} kept/merged, {n_drop} dropped (both ends dead),
*              {clamped} negative sums clamped (Magic substrate correction)
* Negative NET capacitance fix: {n_fix} nodes, {c_fix_tot*1e15:.1f} fF total
* cs0={args.cs}: {'precharge toggles' if args.cs else 'precharge STUCK AT 0 -- only the clk_int tree runs'}
* The energy must be FREQUENCY INDEPENDENT; verify by changing --tclk.

.lib {rom_paths.sky130_lib()} {args.corner}
.temp {args.temp}
.param VDD={args.vdd}
.param TCLK={args.tclk}

* The supply is CONSTANT. A ramp was tried and REMOVED: the .ic lines below
* start the chain nodes at VDD, and if the supply climbs from 0 at the same
* time the initial state is SELF-INCONSISTENT (node 1.8 V, source 0 V) and the
* solver blew up at t~1e-11 (2026-09-06, four different option sets).
Vvdd {SUPPLY_HI} 0 DC {{VDD}}
Vgnd {SUPPLY_LO} 0 DC 0
Vcs cs0 0 DC {cs_val}
* Edge rate {args.clk_slew} (--clk-slew). It is the .lib's index_1 axis: the
* front-end term t_clk2pre is the only part of access that depends on it.
* With a half period of 100 ns the CHARGE TRANSFERRED (= the energy) does not
* depend on the edge rate, so the energy numbers stay comparable across a
* sweep. A 100 ps step was tried early on and made convergence hard on a
* network this size, which is why the axis does not reach into the low
* picoseconds.
Vclk clk0 0 PULSE(0 {{VDD}} {{TCLK/2}} {slew} {slew} {{TCLK/2-{slew}}} {{TCLK}})
{addr_src}

* --- periphery instances (with parasitics, verbatim from the extraction) ---
{keep_fixed}

* --- decoder chain nodes start precharged ({len(set(ic_nodes))} nodes) ---
{ic_txt}

* --- load of the deleted cell array (slice x count) ---
{loads_txt}

* --- top-level parasitic C ---
{caps_txt}

* --- sub-circuit definitions ---
{defs}

* abstol: the 1e-15 used for the leakage measurement is NOT needed here (the
* currents are on the order of uA) and only makes convergence harder.
*
* method=gear IS REQUIRED (2026-09-19). With the default trapezoidal
* integrator this deck is not step converged: sweeping the step over
* 1 / 0.25 / 0.2 ns gave 5.1949 / 6.0798 / 5.9715 pJ -- a 17% spread that is
* not even monotonic -- and 0.1 ns ABORTED outright at t = 3 ps with
* "Timestep too small ... trouble with node ...nand2_dec...nfet_01v8#body".
* That is trapezoidal ringing on the extracted body nodes, and it lands
* straight in the i(Vvdd) charge integral this deck measures.
* With gear the same sweep over 1 / 0.5 / 0.4 / 0.2 / 0.1 ns gives
* 6.2581 / 6.2515 / 6.2479 / 6.2710 / 6.2746 pJ -- 0.43% across a 10x range,
* and nothing aborts. The step is therefore NOT the knob that matters here;
* --steps 200 stays the default.
* Rejected alternatives: cshunt=1e-18 did not stop the abort; relaxing the
* tolerances (abstol/gmin 1e-10, reltol 1e-2) ran to the end but returned
* 8.2109 pJ, 31% high -- it breaks the charge integral silently.
.options gmin=1e-12 abstol=1e-12 reltol=1e-3 itl1=500 itl4=100 method=gear
* uic IS REQUIRED: the internal nodes of the precharged decoder have no DC
* path, so .op does not converge (tried 2026-09-06 -- still at the operating
* point after 10 minutes). The column measurement uses uic for the same reason.
.tran '{args.tclk}/{args.steps}' '{args.cycles}*TCLK' uic
* The LAST TWO cycles are measured separately: equal values show the circuit
* has SETTLED (with uic every node starts at 0). At cs0=1 the precharge network
* is so heavily loaded that 4 cycles were NOT enough -- on 2026-09-06 the c2/c3
* gap reached 30%, so the measurement window now moves with --cycles and the
* default cycle count was raised.
.measure tran q_c2 integ i(Vvdd) from='{args.cycles - 3}*TCLK' to='{args.cycles - 2}*TCLK'
.measure tran q_c3 integ i(Vvdd) from='{args.cycles - 2}*TCLK' to='{args.cycles - 1}*TCLK'
.measure tran e_periph_pj param='abs(q_c3)*VDD*1e12'

* --- front-end delay (the first term of access) ---
{fe_txt}
.end
"""
open(args.out, "w").write(tb)
print(f"written: {args.out}  ({M}, cs0={args.cs}, corner={args.corner}, "
      f"{wl_n} wordlines / {cells} cell gates, {len(kept_c)} C)")
