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
ap.add_argument("--addr-sw-eval", action="store_true",
                help="with --addr-alt: switch the address in the middle of "
                     "the EVALUATE phase instead of the precharge phase, and "
                     "measure addr0 -> wordline FALL (t_addr2wl<k>). That is "
                     "the delay the HOLD constraint needs: run_hold_bisect.sh "
                     "answers in the deck's own frame (its cut time is "
                     "counted from the internal precharge edge), while "
                     "Liberty's hold_rising is referenced to the clk0 PIN. "
                     "The conversion is hold = t_clk2pre + cut - t_addr2wl, "
                     "and this is the last term.")
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
ap.add_argument("--settle-max-cycles", type=int, default=None,
                help="keep one transient alive and stop/resume it every two "
                     "cycles until energy settles or this ceiling is reached")
ap.add_argument("--settle-thresh", type=float, default=1.0,
                help="relative q-cycle convergence limit for persistent settling (%%)")
ap.add_argument("--noise-floor-pj", type=float, default=0.1,
                help="absolute delta-E convergence limit for persistent settling (pJ)")
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
ap.add_argument("--pin-th", default=None,
                help="--pin-cap: hold time after ramp (default: 10 * pin_tr). "
                     "Allows slow nodes to settle before ramping down.")
ap.add_argument("--pin-th-map", default=None,
                help="--pin-cap: per-pin hold time map (e.g. 'addr0[0]:25n,addr0[6]:35n').")
ap.add_argument("--pin-tr", default="0.5n",
                help="--pin-cap: ramp time of the measured pin. It must be "
                     "slow enough that the charge is the pin's own and not a "
                     "displacement spike through the first gate, and fast "
                     "enough to stay in the regime a real driver works in.")
# THERE IS NO WHOLE-MACRO VARIANT OF THIS DECK, and that is deliberate. A
# --keep-all mode that deleted nothing -- the full cell array in the deck, as
# a reference the reduced deck could be checked against -- existed and was
# removed: on the 1 kbit example macros it already ran for hours at ~15 GB,
# and the array is the one block whose size the user chooses. A reference that
# gets exponentially more expensive with the ROM the user actually generates
# is not a reference, it is a trap. The cost of the reduction is bounded by
# the array-load sweep instead (see --pin-cap below and run_pin_cap.sh), which
# scales with the macro because it never simulates the array at all.
ap.add_argument("--pin-only", default=None,
                help="--pin-cap: comma-separated pin names to measure instead "
                     "of all of them. The run time is set by the number of "
                     "pins (each gets its own slot), so this is how a single "
                     "pin is re-measured without paying for the other twelve.")
ap.add_argument("--macros-dir", default=None,
                help="macro tree (default: ROM_MACROS_DIR / <repo>/examples)")
ap.add_argument("--paired", action="store_true",
                help="generate a paired deck: runs active (cs0=1), resets circuit state, "
                     "alters Vcs=0, and runs idle (cs0=0) in a single netlist parse.")
args = ap.parse_args()

if args.paired:
    args.cs = 1

if args.cycles < 4:
    sys.exit("ERROR: --cycles must be at least 4")
if args.settle_max_cycles is not None:
    if args.settle_max_cycles < args.cycles:
        sys.exit("ERROR: --settle-max-cycles must be >= --cycles")
    if args.pin_cap or args.with_coldec or args.addr_alt is not None:
        sys.exit("ERROR: persistent settling is only supported by the normal periphery-energy deck")

M = args.macro
SP = rom_paths.cap_netlist(M, args.macros_dir)
if not os.path.exists(SP):
    sys.exit(f"ERROR: {SP} does not exist -- run run_cap_extract.sh first")

from spice_utils import blocks, fix_units, to_float

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

def resolve_cell_gate_cap_ff():
    """Determine equivalent transistor gate capacitance per cell (in fF).

    Uses explicit --gate-cap-ff if provided, checks for cellgate_<corner>.log,
    or falls back to analytic calculation from cell transistor dimensions (Cox * W * L).
    """
    if args.gate_cap_ff is not None:
        return args.gate_cap_ff
    char_dir = rom_paths.char_dir(args.macro, args.macros_dir)
    cgl = os.path.join(char_dir, f"cellgate_{args.corner}.log")
    if os.path.exists(cgl):
        for line in open(cgl):
            m = re.search(r"c_one_ff\s*=\s*([0-9.eE+-]+)", line)
            if m:
                try:
                    return float(m.group(1))
                except ValueError:
                    pass
    w_val, l_val = 0.36, 0.15
    for sub in (f"{args.macro}_rom_base_one_cell", f"{args.macro}_rom_base_zero_cell"):
        if sub in B:
            dev, _, _ = cell_gate_model(sub)
            if dev:
                mw = re.search(r"\bw=([0-9.eE+-]+[a-zA-Z]?)", dev)
                ml = re.search(r"\bl=([0-9.eE+-]+[a-zA-Z]?)", dev)
                if mw and ml:
                    try:
                        w_val = to_float(mw.group(1)) * 1e6
                        l_val = to_float(ml.group(1)) * 1e6
                        break
                    except ValueError:
                        pass
    c_ox = 8.42
    corner_scale = {"tt": 1.0, "ss": 0.906, "ff": 1.087}.get(args.corner, 1.0)
    return c_ox * w_val * l_val * corner_scale

# --- BOUNDARY NETS & LUMPED LOAD REBUILD --------------------------------
# Pruned blocks (ARRAY and, with --with-coldec, MUX) leave boundary nets alive.
# Magic extracts negative substrate/fringe overlap terms on these boundary nets.
# The physical lumped load (wire + cell gates) directly absorbs the negative
# extraction term: C_final = C_lump - |C_neg| = C_lump + C_neg > 0.
boundary_nets = set()
for _sub in [ARRAY] + ([MUX] if COLDEC in KEEP_SUB and MUX in [l.split()[-1] for l in drop] else []):
    _inst = [l for l in drop if l.split()[-1] == _sub]
    if _inst:
        _ports = B[_sub][0].split()[2:]
        _p2n = dict(zip(_ports, _inst[0].split()[1:-1]))
        boundary_nets.update((set(_p2n.values()) & alive) - {SUPPLY_HI, SUPPLY_LO, "0"})

# Collect top-level C elements touching boundary nets vs internal nets
boundary_ext = collections.defaultdict(float)
kept_c = []
retarget = collections.Counter()
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
        if a in boundary_nets and b in (SUPPLY_HI, SUPPLY_LO, "0"):
            boundary_ext[a] += v
        elif b in boundary_nets and a in (SUPPLY_HI, SUPPLY_LO, "0"):
            boundary_ext[b] += v
        elif v > 0:
            kept_c.append(l)
    elif ao:
        if a in boundary_nets:
            boundary_ext[a] += v
        elif v > 0:
            retarget[a] += v
    elif bo:
        if b in boundary_nets:
            boundary_ext[b] += v
        elif v > 0:
            retarget[b] += v
    else:
        n_drop += 1

clamped = sum(1 for v in retarget.values() if v <= 0)
for i_rt, (n, v) in enumerate(sorted(retarget.items())):
    if v > 0:
        kept_c.append(f"C_rt{i_rt} {n} {SUPPLY_LO} {v*1e15:.5f}f")

def rebuild_load(sub, tag):
    """Put back the load a DELETED block leaves on the nets that are still alive.

    Computes lumped wire + active cell gate loads, absorbs any extracted
    overlap capacitance on the boundary net (C_final = C_lump + C_ext > 0),
    and emits a single positive lumped capacitor per boundary net.
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
    gate_cap_val = resolve_cell_gate_cap_ff() * 1e-15

    for i, (port, net) in enumerate(sorted(ports.items())):
        if net not in alive or net in (SUPPLY_HI, SUPPLY_LO, "0"):
            continue
        subs = [(sb, c) for (sb, pp), c in gate_cnt.items() if pp == port]
        cw = max(wire_c.get(port, 0.0), 0.0)
        ncell = 0
        for sb, c in sorted(subs):
            dev, _, cg = cell_gate_model(sb)
            if dev is None:
                continue
            cw += (cg + gate_cap_val) * c
            ncell += c

        # raw PDK devices whose gate sits on this net (the column mux)
        for (mdl, pp), c in sorted(dev_cnt.items()):
            if pp != port:
                continue
            t = dev_line[(mdl, pp)].split()
            dn, _ = device_nodes(t)
            pi = t.index(mdl)
            nets = [net if j == 1 else SUPPLY_LO for j in range(len(dn))]
            load_lines.append(fix_units(
                "X_%s%d_%d " % (tag, i, len(load_lines)) + " ".join(nets)
                + " " + " ".join(t[pi:]) + " m=%d" % c))
            ncell += c

        # Physical lumped load absorbs negative fringe/overlap from extraction
        cw_final = cw + boundary_ext.get(net, 0.0)
        if cw_final > 0:
            load_lines.append(f"C_{tag}{i} {net} {SUPPLY_LO} {cw_final*1e15:.5f}f")
        if ncell or cw_final > 0:
            load_report.append((port, ncell, cw_final))
    return load_lines, load_report

load_lines, load_report = rebuild_load(ARRAY, "wl")
if COLDEC in KEEP_SUB:
    mux_lines, mux_report = rebuild_load(MUX, "sel")
    load_lines += mux_lines
    load_report += mux_report

driven = {SUPPLY_HI, SUPPLY_LO, "0"} | {
    p for p in top_ports if re.match(r"^(clk0|cs0|addr0\[)", p)}

full_node_c = collections.Counter()

def descend_into_module(lines, mapping, depth=0):
    """Modül hiyerarşisinin en derinine (yaprak hücrelere) kadar iner,
    tüm iç kapasitansları üst seviye düğümlere eşleyerek toplar."""
    for line in lines:
        t = line.split()
        if not t:
            continue
        if t[0].startswith("C") and len(t) >= 4:
            a, b = mapping.get(t[1]), mapping.get(t[2])
            if a == b:
                continue
            try:
                val = to_float(t[3])
            except ValueError:
                continue
            if a is not None:
                full_node_c[a] += val
            if b is not None:
                full_node_c[b] += val
        elif t[0].startswith("X") and t[-1] in B:
            child = t[-1]
            body = B[child]
            ports = body[0].split()[2:]
            child_map = dict(zip(ports, (mapping.get(n) for n in t[1:-1])))
            descend_into_module(body[1:], child_map, depth + 1)

# Tutulan modüllerin ve wordline lumped C'nin içine inerek topla
descend_into_module(keep + kept_c + load_lines, {n: n for n in alive})

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
    # ARRAY is skipped: it is deleted and replaced by lumped load.
    if name in (TOP, ARRAY):
        continue
    clean_ls = []
    for l in B[name]:
        if l.startswith("C") and len(l.split()) >= 4:
            try:
                if to_float(l.split()[3]) <= 0:
                    continue
            except ValueError:
                pass
        clean_ls.append(fix_units(l) if l.startswith("X") else l)
    defs.append("\n".join(clean_ls))
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

# --- FRONT END DELAY: clk0 -> precharge ----------------------------------
# `access` in the .lib runs from the rising edge of clk0 until dout0 is valid.
# The column measurement (t_dis_50) triggers off the internal `precharge` net,
# so the piece from clk0 to precharge is not in it. That piece is measured
# here, and the total is
#
#     access = t_clk2pre + max(t_dis_50, t_coldec) + t_bl2dout
#              ^ here      ^ column deck            ^ gen_backend_delay_tb.py
#
# NOT `max(t_clk2pre, t_clk2wl)`. There is no clk0 -> wordline RISE arc to
# race against -- no wordline rises during evaluate at all -- and the wordline
# is not in series with the front-end term either: the row whose gate falls is
# strapped in the read-0 case the column deck characterises, so the discharge
# starts on the precharge edge. See the block further down that removed
# `t_clk2wl*` for the full reasoning and the numbers.
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
_vdd = to_float(args.vdd)
# Vclk below is PULSE(... TD={TCLK/2} ... PER={TCLK}), so clk0 RISES at
# TCLK/2 + k*TCLK and FALLS at (k+1)*TCLK. _edge is therefore the start of a
# PRECHARGE phase, not a rising edge -- the rising edge that closes it is half
# a cycle later. Everything below derives its windows from _clk_rise, and the
# other users of _edge (the evaluate window at ~line 655 and the address
# switching instant at ~line 677) read it with this same meaning.
_edge = (args.cycles - 2) * _tclk        # start of the measured PRECHARGE phase
_clk_rise = _edge + _tclk / 2.0          # the clk0 RISING edge being measured
_td_trig = _clk_rise - _tclk / 20.0
# The TARG window starts EXACTLY at that rising edge. Because the decoder is
# precharged, the wordlines also rise during the PRECHARGE phase, i.e. in
# [_edge, _clk_rise]; a TARG window that reaches back into it latches that
# rise instead of anything the measured edge caused, and the delay comes out
# NEGATIVE -- t_clk2wl = -99 ns, an entire phase backwards. That defect was
# in every committed log up to 2026-09-23: the window was opened at _edge,
# which is half a cycle EARLY, and the negative result was then read as
# "the wordline path is faster than the precharge path" and written into the
# docs. A delay cannot be negative; the sign was the bug reporting itself.
_td_targ = _clk_rise
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
# read off the names Magic generates; the first few wordlines are measured and
# the log says which one moved.
#
# THERE IS NO clk0 -> WORDLINE RISE ARC, so none is measured. A `t_clk2wl*`
# used to be emitted here and it never meant anything: no wordline rises
# during evaluate at all, so the TARG simply found the nearest rise in some
# OTHER phase. `.measure` takes a window START (TD) and has no end, so there
# is no window that fixes it -- with TD half a cycle early it reported
# -99 ns (the rise in the precharge phase BEFORE the edge) and with TD at the
# edge it reports +100.75 ns (the recovery in the phase AFTER evaluate ends).
# Both are the same artefact and neither is a delay. Measured on wrom0/TT
# 2026-09-23; the -99 ns form had been in every committed log and had been
# read as "the wordline path is faster than the precharge path", which is
# backwards -- t_wlfall0 = 1.5692 ns against t_clk2pre = 0.7642 ns.
#
# What replaces it is a BOUNDED probe: the wordline's LEVEL at a fixed
# instant inside the evaluate phase. `FIND ... AT=` cannot wander into a
# neighbouring phase the way a trig/targ search can, so this states the
# decoder polarity in a form that no window choice can corrupt:
#     v_wl<k>_eval ~ 0     -> row k is the SELECTED one, driven low
#     v_wl<k>_eval ~ VDD   -> row k is untouched, still high
# Together with t_wlfall<k> (which succeeds for the selected row and fails
# for every other) that is the polarity EVIDENCE, and it is what justifies
# the column deck holding every wordline at DC VDD: not "the unselected rows
# fall" -- they do not move at all -- but that the one row whose gate does
# fall is strapped (zero_cell) in the read-0 case the deck characterises, so
# the chain keeps conducting and the discharge starts on the precharge edge.
# The front-end term is therefore clk0 -> precharge, with the wordline NOT in
# series with it.
_t_wl_probe = _clk_rise + 0.45 * _tclk     # inside evaluate, after the fall
for k, n in enumerate(wl_meas):
    fe += [f".measure tran v_wl{k}_eval FIND v({n}) AT={_t_wl_probe:.6e}"]
    pad = " " * len(f"t_wlfall{k}")
    fe += [f".measure tran t_wlfall{k} TRIG v(clk0) VAL='VDD/2' RISE=1 "
           f"TD={_td_trig:.6e}",
           f"+                {pad}TARG v({n}) VAL='VDD/2' FALL=1 "
           f"TD={_td_targ:.6e}"]
    # THE WORDLINE'S OWN EDGE RATE, not its delay. gen_addr_hold_tb.py cuts
    # the series chain by dropping a wordline, and until this was measured it
    # did so with an ideal 100 ps step -- a number nobody had checked against
    # the real driver. Here the driver is the real
    # rom_row_decode_wordline_buffer and the load is the real one (the put-back
    # gate count plus the array's own wire C), so this IS the edge the macro
    # produces. Both conventions are written out: 20-80% is what the sky130
    # Liberty files use, 10-90% is closer to the full transition a SPICE PULSE
    # tf describes (tf ~ t_wl1090 / 0.8).
    for lo, hi, nm in ((0.8, 0.2, f"t_wlslew{k}"),
                       (0.9, 0.1, f"t_wl1090_{k}")):
        pad = " " * len(nm)
        fe += [f".measure tran {nm} TRIG v({n}) VAL='{lo}*VDD' FALL=1 "
               f"TD={_td_targ:.6e}",
               f"+                {pad}TARG v({n}) VAL='{hi}*VDD' FALL=1 "
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
# _edge starts the PRECHARGE phase and _clk_rise = _edge + TCLK/2 closes it
# (see the front-end block above).
#
# WHERE THE ADDRESS IS SWITCHED decides which question the deck answers:
#   precharge (default) -- SETUP: the address moves well before the edge and
#     what is measured is how long it takes to reach the decoder NAND.
#   evaluate (--addr-sw-eval) -- the HOLD conversion: the address moves while
#     the decoder is transparent, so the wordline of the newly selected row
#     actually falls and addr0 -> that fall can be measured. The decoder is
#     combinational during evaluate, so this delay does not depend on how far
#     into the phase the switch happens.
_t_sw = ((_clk_rise + _tclk / 4.0) if args.addr_sw_eval
         else (_edge + _tclk / 4.0))

# --- SETUP: addr0 -> decoder ----------------------------------------------
# The decoder is PRECHARGED: every wordline is high when evaluate begins and
# the SELECTED row is driven low (measured -- see the front-end block). So the
# address must be settled at the decoder INPUTS when clk0 rises, and that is
# exactly the path measured here:
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

        # --- the HOLD conversion term: addr0 -> WORDLINE FALL --------------
        # Only with --addr-sw-eval, because it is the only stimulus under
        # which a wordline actually falls in response to the ADDRESS rather
        # than the clock: during evaluate the decoder is transparent, so
        # moving the row address drops the newly selected row's wordline.
        #
        # WHY THE .lib NEEDS IT. run_hold_bisect.sh answers in the COLUMN
        # deck's frame: its cut time is counted from the internal precharge
        # source's rising edge, and that deck has no clk0 in it at all.
        # Liberty's hold_rising is referenced to the clk0 PIN. Two terms
        # separate the frames:
        #     hold(clk0 frame) = t_clk2pre + cut - t_addr2wl
        # the first carrying the edge from the pin to the array, the second
        # carrying the address from the pin to the wordline it drops. Shipping
        # the raw cut time silently assumes those two cancel.
        #
        # The measurement is taken on whichever of the probed wordlines
        # actually falls -- the row --addr-alt selects. Every other one
        # reports "failed", which is the same evidence the polarity block
        # above relies on.
        if args.addr_sw_eval:
            for _k, _n in enumerate(wl_meas):
                _nm = f"t_addr2wl{_k}"
                _pad = " " * len(_nm)
                fe += [f".measure tran {_nm} TRIG v({_trig_pin}) VAL='VDD/2' "
                       f"CROSS=1 TD={_td:.6e}",
                       f"+                {_pad}TARG v({_n}) VAL='VDD/2' "
                       f"FALL=1 TD={_td:.6e}"]
fe_txt = "\n".join(fe)

def _controlify(measures):
    """Turn .measure cards (including '+' continuations) into control commands."""
    commands = []
    for line in measures:
        if line.startswith(".measure "):
            commands.append("meas " + line[len(".measure "):])
        elif line.startswith("+") and commands:
            commands[-1] += " " + line[1:].strip()
    return commands


def _settled_front_end_measures(cycles):
    """The normal energy deck's timing measurements at a chosen late cycle."""
    edge = (cycles - 2) * _tclk
    clk_rise = edge + _tclk / 2.0
    td_trig = clk_rise - _tclk / 20.0
    td_targ = clk_rise
    wl_probe = clk_rise + 0.45 * _tclk
    measures = []

    def delay(name, node):
        pad = " " * len(name)
        return [f".measure tran {name} TRIG v(clk0) VAL={_vdd/2:.9e} RISE=1 TD={td_trig:.6e}",
                f"+                {pad}TARG v({node}) VAL={_vdd/2:.9e} RISE=1 TD={td_targ:.6e}"]

    if clk_int:
        measures += delay("t_clk2int", clk_int[0])
    for k, node in enumerate(wl_meas):
        measures.append(f".measure tran v_wl{k}_eval FIND v({node}) AT={wl_probe:.6e}")
        name = f"t_wlfall{k}"
        pad = " " * len(name)
        measures += [f".measure tran {name} TRIG v(clk0) VAL={_vdd/2:.9e} RISE=1 TD={td_trig:.6e}",
                     f"+                {pad}TARG v({node}) VAL={_vdd/2:.9e} FALL=1 TD={td_targ:.6e}"]
        for lo, hi, name in ((0.8, 0.2, f"t_wlslew{k}"),
                             (0.9, 0.1, f"t_wl1090_{k}")):
            pad = " " * len(name)
            measures += [f".measure tran {name} TRIG v({node}) VAL={lo*_vdd:.9e} FALL=1 TD={td_targ:.6e}",
                         f"+                {pad}TARG v({node}) VAL={hi*_vdd:.9e} FALL=1 TD={td_targ:.6e}"]
    if pre_net and args.cs:
        measures += delay("t_clk2pre", pre_net[0])
    return _controlify(measures)


def _persistent_stages(is_active=True, prefix=""):
    """Generate nested stop/measure/resume stages without wrapping in .control."""
    maximum = args.settle_max_cycles
    if maximum is None:
        return []
    candidates = list(range(args.cycles, maximum + 1, 2))
    if candidates[-1] != maximum:
        candidates.append(maximum)

    def final_measurements(cycles, indent, settled):
        p = " " * indent
        q2_from, q2_to = cycles - 3, cycles - 2
        q3_from, q3_to = cycles - 2, cycles - 1
        out = [
            f"{p}meas tran q_c2 integ i(Vvdd) from={q2_from*_tclk:.9e} to={q2_to*_tclk:.9e}",
            f"{p}meas tran q_c3 integ i(Vvdd) from={q3_from*_tclk:.9e} to={q3_to*_tclk:.9e}",
            f"{p}let e_periph_pj = abs(q_c3)*{_vdd:.9e}*1e12",
            f"{p}print e_periph_pj",
        ]
        if is_active:
            out += [p + command for command in _settled_front_end_measures(cycles)]
        marker = "PERIPH_SETTLED_CYCLES" if settled else "PERIPH_MAX_CYCLES"
        out.append(f"{p}echo {marker}={cycles}")
        return out

    def stage(index, indent=0):
        cycles = candidates[index]
        p = " " * indent
        q2_from, q2_to = cycles - 3, cycles - 2
        q3_from, q3_to = cycles - 2, cycles - 1
        tag = f"{prefix}c{cycles}"
        out = [
            f"{p}meas tran probe_q2_{tag} integ i(Vvdd) from={q2_from*_tclk:.9e} to={q2_to*_tclk:.9e}",
            f"{p}meas tran probe_q3_{tag} integ i(Vvdd) from={q3_from*_tclk:.9e} to={q3_to*_tclk:.9e}",
            f"{p}let probe_gap_{tag} = 999.99",
            f"{p}if abs(probe_q3_{tag}) > 1e-18",
            f"{p}  let probe_gap_{tag} = 100*abs(abs(probe_q2_{tag})-abs(probe_q3_{tag}))/abs(probe_q3_{tag})",
            f"{p}end",
            f"{p}let probe_delta_e_{tag} = abs(abs(probe_q2_{tag})-abs(probe_q3_{tag}))*{_vdd:.9e}*1e12",
            f"{p}let probe_settled_{tag} = 0",
            f"{p}if probe_gap_{tag} <= {args.settle_thresh}",
            f"{p}  let probe_settled_{tag} = 1",
            f"{p}end",
            f"{p}if probe_delta_e_{tag} < {args.noise_floor_pj}",
            f"{p}  let probe_settled_{tag} = 1",
            f"{p}end",
            f"{p}print probe_gap_{tag} probe_delta_e_{tag}",
        ]
        if index == len(candidates) - 1:
            out += [f"{p}if probe_settled_{tag} = 1"]
            out += final_measurements(cycles, indent + 2, True)
            out += [f"{p}else"]
            out += final_measurements(cycles, indent + 2, False)
            out += [f"{p}end"]
        else:
            out += [f"{p}if probe_settled_{tag} = 1"]
            out += final_measurements(cycles, indent + 2, True)
            next_cycles = candidates[index + 1]
            out += [f"{p}else",
                    f"{p}  stop when time = {next_cycles * _tclk:.9e}",
                    f"{p}  resume"]
            out += stage(index + 1, indent + 2)
            out += [f"{p}end"]
        return out

    lines = [f"stop when time = {candidates[0] * _tclk:.9e}",
             "run"]
    lines += stage(0)
    return lines


def _persistent_settling_control():
    """Generate nested stop/measure/resume control flow without restarting tran."""
    if args.settle_max_cycles is None:
        return ""
    lines = [".control"] + _persistent_stages(is_active=bool(args.cs)) + ["quit", ".endc"]
    return "\n".join(lines)


persistent_control = _persistent_settling_control()
caps_txt = "\n".join(kept_c)
loads_txt = "\n".join(load_lines)

if args.paired:
    if args.settle_max_cycles is not None:
        act_lines = _persistent_stages(is_active=True, prefix="act_")
        idle_lines = _persistent_stages(is_active=False, prefix="idle_")
        paired_ctrl = [
            ".control",
            "set num_threads=4",
            "echo PAIRED_MODE_BEGIN=active",
        ] + act_lines + [
            "echo PAIRED_MODE_END=active",
            "destroy all",
            "delete all",
            "reset",
            "alter Vcs=0",
            "echo PAIRED_MODE_BEGIN=idle",
        ] + idle_lines + [
            "echo PAIRED_MODE_END=idle",
            "rusage all",
            "quit",
            ".endc"
        ]
        # Keep the analysis endpoint one cycle beyond the last stop.  When a
        # stop condition coincides exactly with the .tran endpoint, ngspice
        # can leave "pause requested" latched across reset; in paired mode
        # that makes the idle run stop before it has produced any samples.
        energy_analysis = f""".tran '{args.tclk}/{args.steps}' '{args.settle_max_cycles + 1}*TCLK' uic
* Paired active+idle simulation with persistent adaptive settling:
* Netlist parsed once. Mode 1 (active) adapts from {args.cycles} to {args.settle_max_cycles} cycles.
* Resets state, alters Vcs=0, then Mode 2 (idle) adapts from {args.cycles} to {args.settle_max_cycles} cycles.
""" + "\n".join(paired_ctrl)
    else:
        energy_analysis = f""".tran '{args.tclk}/{args.steps}' '{args.cycles}*TCLK' uic
* Paired active+idle simulation: netlist is parsed once.
* Mode 1 (active, cs0=1) runs first, measuring energy and front-end timing.
* Then circuit state is reset, Vcs altered to 0, and Mode 2 (idle, cs0=0) runs.
.measure tran q_c2 integ i(Vvdd) from='{args.cycles - 3}*TCLK' to='{args.cycles - 2}*TCLK'
.measure tran q_c3 integ i(Vvdd) from='{args.cycles - 2}*TCLK' to='{args.cycles - 1}*TCLK'
.measure tran e_periph_pj param='abs(q_c3)*VDD*1e12'

* --- front-end delay (the first term of access) ---
{fe_txt}

.control
set num_threads=4
echo PAIRED_MODE_BEGIN=active
run
echo PERIPH_SETTLED_CYCLES={args.cycles}
echo PAIRED_MODE_END=active
destroy all
delete all
reset
alter Vcs=0
echo PAIRED_MODE_BEGIN=idle
run
echo PERIPH_SETTLED_CYCLES={args.cycles}
echo PAIRED_MODE_END=idle
rusage all
quit
.endc"""
elif persistent_control:
    energy_analysis = f""".tran '{args.tclk}/{args.steps}' '{args.settle_max_cycles + 1}*TCLK' uic
* One transient is loaded once. The control block pauses at --cycles, checks
* two completed cycles, and resumes the SAME solver state by two cycles only
* when needed. No candidate re-parses the deck or recomputes earlier cycles.
{persistent_control}"""
else:
    energy_analysis = f""".tran '{args.tclk}/{args.steps}' '{args.cycles}*TCLK' uic
* The LAST TWO cycles are measured separately: equal values show the circuit
* has SETTLED (with uic every node starts at 0). At cs0=1 the precharge network
* is so heavily loaded that 4 cycles were NOT enough -- on 2026-09-06 the c2/c3
* gap reached 30%, so the measurement window now moves with --cycles and the
* default cycle count was raised.
.measure tran q_c2 integ i(Vvdd) from='{args.cycles - 3}*TCLK' to='{args.cycles - 2}*TCLK'
.measure tran q_c3 integ i(Vvdd) from='{args.cycles - 2}*TCLK' to='{args.cycles - 1}*TCLK'
.measure tran e_periph_pj param='abs(q_c3)*VDD*1e12'

* --- front-end delay (the first term of access) ---
{fe_txt}"""

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
    if args.pin_only:
        want = [x.strip() for x in args.pin_only.split(",") if x.strip()]
        missing = [x for x in want if x not in pin_names]
        if missing:
            sys.exit(f"ERROR: --pin-only names pins that are not inputs of "
                     f"{M}: {missing}")
        pin_names = [p_ for p_ in pin_names if p_ in want]
    if not pin_names:
        sys.exit("ERROR: --pin-cap found no input pins at top level")
    _tr = to_float(args.pin_tr)
    _default_th = to_float(args.pin_th) if args.pin_th else 10 * _tr
    _pin_th_map = {}
    if args.pin_th_map:
        for item in args.pin_th_map.split(","):
            if ":" in item:
                k, v = item.split(":", 1)
                _pin_th_map[k.strip()] = to_float(v.strip())

    _t0 = 20e-9                   # let the precharged chain nodes settle first
    # A QUIET GAP AFTER EACH PIN. Without it (2026-09-22) the slots touched,
    # and ADJACENT pins moved by ~4% in OPPOSITE directions when --pin-tr was
    # doubled -- addr0[0] +4.65% against addr0[1] -4.02%, addr0[4] -4.14%
    # against addr0[5] +3.92% -- while each PAIR summed to within 0.3%. That
    # is one pin's settling tail crossing the boundary into its neighbour's
    # window, not a change in anyone's capacitance. The gap is dead time: no
    # measurement window covers it.
    pin_src, pin_meas, pin_rows = [], [], []
    current_t = _t0
    for i, p_ in enumerate(pin_names):
        _th_i = _pin_th_map.get(p_, _default_th)
        t_r0 = current_t
        t_r1 = t_r0 + _tr
        t_f0 = t_r1 + _th_i
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
            f"from={t_f0:.6e} to={t_f1 + _th_i:.6e}")
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
        current_t = t_f1 + 2 * _th_i
    pin_src_txt = "\n".join(pin_src)
    pin_meas_txt = "\n".join(pin_meas)
    t_end = current_t + 10e-9

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
if args.paired:
    mode = "PAIRED (cs0=1 active -> cs0=0 idle)"
else:
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
* Modül içine inme stratejisi: Alt devre hiyerarşisine inilerek tüm iç C toplandı
* Hiyerarşik negatif fringe terimleri lumped yük ve iç hücrelerle dengelendi (C_fx dummy eklenmedi)
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
.options klu gmin=1e-12 abstol=1e-12 reltol=1e-3 itl1=500 itl4=100 method=gear
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
    options_line = ".options klu gmin=1e-12 abstol=1e-12 reltol=1e-3 itl1=500 itl4=100 method=gear"
    tb = f"""* {M} -- PERIPHERY energy per cycle -- {mode}
* Kept:    rom_control_logic (clock driver + control_nand + prechg driver)
*          rom_row_decode    (address buffers + decoder + wl drivers)
{coldec_txt}{coldec_note}* Deleted: cell array / column mux / bitline and output
*          inverters. The deleted blocks' LOAD was put back:
*            {wl_n} wordlines, {cells} cell gates total (single lumped linear C per row)
*            + the array's internal parasitic wire C (lumped)
* Top-level C: {len(kept_c)} kept/merged, {n_drop} dropped (both ends dead),
*              {clamped} negative sums clamped (Magic substrate correction)
* Modül içine inme stratejisi: Alt devre hiyerarşisine inilerek tüm iç C toplandı
* Hiyerarşik negatif fringe terimleri lumped yük ve iç hücrelerle dengelendi (C_fx dummy eklenmedi)
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
{options_line}
* uic IS REQUIRED: the internal nodes of the precharged decoder have no DC
* path, so .op does not converge (tried 2026-09-06 -- still at the operating
* point after 10 minutes). The column measurement uses uic for the same reason.
{energy_analysis}
.end
"""
open(args.out, "w").write(tb)
cs_desc = "paired(1->0)" if args.paired else args.cs
print(f"written: {args.out}  ({M}, cs0={cs_desc}, corner={args.corner}, "
      f"{wl_n} wordlines / {cells} cell gates, {len(kept_c)} C)")
