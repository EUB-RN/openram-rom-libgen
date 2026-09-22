#!/usr/bin/env python3
"""PERIPHERY leakage deck: one static operating point, one slice per block.

`cell_leakage_power` in the .lib covers the cell array only (one column
measured with .op, multiplied by the column count -- gen_col_power_tb.py).
The periphery leaks too, and nothing measured it. This deck adds it.

WHY NOT THE PERIPHERY ENERGY DECK. gen_periphery_power_tb.py already builds a
reduced periphery netlist, but `.op` does not converge on it: the row decoder
is a precharged NAND chain whose internal nodes have no DC path, so the matrix
is singular there and dynamic gmin, true gmin and source stepping all fail
(measured: 8m22 of wall time, 2.7 GB, and a meaningless -5.96 mA). That deck
needs `.ic` and a transient, which is the method the column leakage
measurement rejected -- the charging current gets mistaken for leakage.

WHAT THIS DOES INSTEAD. The periphery is split into blocks that ARE static
CMOS and a chain that is not, and each is measured as ONE SLICE times a count
taken from the netlist -- the same trick the array already uses:

  ctl      rom_control_logic          x1     clock driver + NAND + prechg drv
  abuf     rom_address_control_buf    x<n>   inverter + two clocked NANDs
  wlbuf    <wl driver cell>           x<n>   two inverters per wordline
  dec      one row-decode column      x<n>   the SAME one_cell/zero_cell chain
                                             as a bitline, foot gated by the
                                             precharge net
  cdec     one column-decode column   x<n>   same structure, 3->8 decoder
  cwlbuf   <col dec driver cell>      x<n>
  binv     one bitline inverter       x<n>   one per COLUMN, input precharged
  mux      one column mux pass tx     x<n>   off in idle; the ammeter on the
                                             node it drives says how much it
                                             actually passes
  obuf     one output buffer          x<n>   one per DATA BIT

THE READ BACK END IS PART OF THE PERIPHERY. It was left out of the first
version of this deck and therefore scored as ZERO: 256 bitline inverters, 256
mux transistors and 32 output buffers on the example macros. Its idle state is
not a choice, it follows from the precharge phase: every bitline is high, so
every bitline inverter holds its output at 0; all eight column selects are low
(measured -- see run_coldec_delay.sh), so every mux transistor is off with its
source at 0 and the node it drives leaks down to 0 as well; the output buffer
therefore sits with its input at 0. Each of those levels is driven explicitly
here rather than left floating, which is also what keeps `.op` non-singular.

Every slice gets its OWN supply source, so a single `.op` yields every block's
current on a separate branch and one run covers the whole periphery.

THE STATE IS THE IDLE STATE: clk0 = 0, i.e. the precharge phase, which is the
state the array term is already measured in (all wordlines high, foot off).
`cell_leakage_power` is a single static number and both halves of it have to
belong to the same state or they cannot be added. cs0 is a parameter because
it changes what the control logic does with the precharge net.

BUILT FROM THE SCHEMATIC NETLIST, not the Magic extraction: leakage is a DC
quantity and parasitic capacitance has no DC effect. That also keeps the deck
at a few hundred devices instead of tens of thousands, so it parses in
seconds.

Usage: gen_periphery_leak_tb.py <macro> [--cs0 0|1] [--corner tt] [--vdd 1.8]
                                [--temp 25] [-o <deck.sp>]
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rom_paths                                        # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("macro")
ap.add_argument("--cs0", type=int, default=1, choices=(0, 1),
                help="chip select level (1 = selected, the default)")
ap.add_argument("--corner", default="tt")
ap.add_argument("--vdd", type=float, default=1.8)
ap.add_argument("--temp", type=float, default=25.0)
ap.add_argument("--col", type=int, default=None,
                help="row-decode column to slice (default: the first one)")
ap.add_argument("--gmin", default="1e-15",
                help="ngspice gmin for this run. run_periphery_leak.sh SWEEPS "
                     "it and keeps the value where the answer stops moving; "
                     "gmin too high adds artificial conductance to every node "
                     "and inflates the leakage.")
ap.add_argument("-o", "--out", default=None)
ap.add_argument("--macros-dir", default=None)
args = ap.parse_args()

M = args.macro
SP = rom_paths.netlist(M, args.macros_dir)
if not os.path.exists(SP):
    sys.exit(f"ERROR: {SP} does not exist")
SKY = os.environ.get(
    "SKY130_LIB",
    os.path.join(os.environ.get("PDK_ROOT", os.path.expanduser("~/OpenLane/pdks")),
                 "sky130A/libs.tech/ngspice/sky130.lib.spice"))


# --- netlist ---------------------------------------------------------------
# OpenRAM writes one element per LINE GROUP: a name, then "+" continuations
# carrying the nets and finally the sub-circuit name. Join them first and the
# rest is ordinary SPICE.
def read_netlist(path):
    joined, cur = [], None
    for raw in open(path):
        l = raw.rstrip("\n")
        if l.startswith("+"):
            cur = (cur or "") + " " + l[1:].strip()
        else:
            if cur is not None:
                joined.append(cur)
            cur = l
    if cur is not None:
        joined.append(cur)
    blocks, name = {}, None
    for l in joined:
        ls = l.strip()
        if ls.upper().startswith(".SUBCKT"):
            name = ls.split()[1]
            blocks[name] = [ls]
        elif ls.upper().startswith(".ENDS"):
            name = None
        elif name and ls and not ls.startswith("*"):
            blocks[name].append(ls)
    return blocks


B = read_netlist(SP)


def find(suffix):
    hits = [n for n in B if n.endswith(suffix)]
    if len(hits) != 1:
        sys.exit(f"ERROR: expected exactly one *{suffix} sub-circuit in {SP}, "
                 f"found {hits}")
    return hits[0]


def ports(sub):
    return B[sub][0].split()[2:]


def instances(sub):
    return [l for l in B[sub][1:] if l.startswith("X")]


CTL = find("_rom_control_logic")
ABUF = find("_rom_address_control_buf")
ABUF_ARR = find("_rom_address_control_array")
WLBUF_ARR = find("_rom_row_decode_wordline_buffer")
DEC_ARR = find("_rom_row_decode_array")
PRE_CELL = find("_precharge_cell")

# The driver CELL is whatever the wordline buffer array repeats.
def repeated_cell(arr):
    subs = {l.split()[-1] for l in instances(arr)}
    subs = {s for s in subs if s in B}
    if len(subs) != 1:
        sys.exit(f"ERROR: {arr} does not repeat a single cell: {subs}")
    return subs.pop()


WLBUF = repeated_cell(WLBUF_ARR)
N_ABUF = len(instances(ABUF_ARR))
N_WLBUF = len(instances(WLBUF_ARR))

# The column decoder is optional: a macro with one word per row has none.
# --- the read back end: bitline inverter -> column mux -> output buffer ---
BINV_ARR = find("_rom_bitline_inverter")
BINV = repeated_cell(BINV_ARR)
N_BINV = len(instances(BINV_ARR))

OBUF_ARR = find("_rom_output_buffer")
OBUF = repeated_cell(OBUF_ARR)
N_OBUF = len(instances(OBUF_ARR))

# The mux is optional for the same reason the column decoder is: a macro with
# one word per row has no column mux at all.
MUX_ARR = next((n for n in B if n.endswith("_rom_column_mux_array")), None)
MUX = repeated_cell(MUX_ARR) if MUX_ARR else None
N_MUX = len(instances(MUX_ARR)) if MUX_ARR else 0

CDEC_ARR = next((n for n in B if n.endswith("_rom_column_decode_array")), None)
CWLBUF_ARR = next((n for n in B
                   if n.endswith("_rom_column_decode_wordline_buffer")), None)
CWLBUF = repeated_cell(CWLBUF_ARR) if CWLBUF_ARR else None
N_CWLBUF = len(instances(CWLBUF_ARR)) if CWLBUF_ARR else 0


# --- one column of a decode array -----------------------------------------
# The decode array is a transposed ROM: one COLUMN per wordline, one ROW per
# address line, cells named <prefix>_r<row>_c<col>. The chain ends in a foot
# transistor gated by the precharge net, exactly like a bitline.
def decode_column(arr, col=None):
    cells = []
    for l in instances(arr):
        m = re.match(r"^X\S*_r(\d+)_c(\d+)\b", l)
        if m:
            cells.append((int(m.group(1)), int(m.group(2)), l))
    if not cells:
        sys.exit(f"ERROR: no <name>_r<row>_c<col> cells in {arr}")
    if col is None:
        col = min(c for _, c, _ in cells)
    chosen = [(r, l) for r, c, l in cells if c == col]
    if not chosen:
        sys.exit(f"ERROR: {arr} has no column {col}")
    chosen.sort()
    return col, [l for _, l in chosen]


def n_columns(arr):
    """How many columns the array has -- the multiplier for one slice."""
    cols = set()
    for l in instances(arr):
        m = re.match(r"^X\S*_r\d+_c(\d+)\b", l)
        if m:
            cols.add(int(m.group(1)))
    return len(cols)


DEC_COL, DEC_CELLS = decode_column(DEC_ARR, args.col)
N_DEC = n_columns(DEC_ARR)
if CDEC_ARR:
    CDEC_COL, CDEC_CELLS = decode_column(CDEC_ARR)
    N_CDEC = n_columns(CDEC_ARR)
else:
    CDEC_COL, CDEC_CELLS, N_CDEC = None, [], 0


# --- the sub-circuit definitions the deck actually needs -------------------
# Emitting the whole netlist would pull in the 34k-transistor bit array.
def closure(roots):
    need, seen = set(roots), set()
    while need - seen:
        n = (need - seen).pop()
        seen.add(n)
        for l in B.get(n, []):
            if l.startswith("X"):
                sub = l.split()[-1]
                if sub in B:
                    need.add(sub)
    return seen


def emit_defs(names):
    out = []
    for n in sorted(names):
        out.append("\n".join(B[n]))
        out.append(".ends")
    return "\n".join(out)


leaf_subs = {l.split()[-1] for l in DEC_CELLS + CDEC_CELLS}
DEFS = emit_defs(closure({CTL, ABUF, WLBUF, PRE_CELL, BINV, OBUF} |
                         ({CWLBUF} if CWLBUF else set()) |
                         ({MUX} if MUX else set()) |
                         leaf_subs))


# --- the slice instances ---------------------------------------------------
# Each slice hangs off its own supply source; the .op then reports one branch
# current per block. Signals are shared across slices on purpose -- the clock
# and the precharge net really are the same nets in the macro.
def inst(name, sub, nets):
    return "%s %s %s" % (name, " ".join(nets), sub)


def by_role(sub, mapping, default):
    """Map a sub-circuit's ports onto nets by matching the port NAME, so a
    macro that orders its ports differently still works."""
    out = []
    for p in ports(sub):
        key = p.lower()
        hit = next((v for k, v in mapping.items() if re.fullmatch(k, key)), None)
        out.append(hit if hit else default(p))
    return out


unresolved = []


def fallback(p):
    unresolved.append(p)
    return "n_%s" % re.sub(r"\W", "_", p)


VDD_OF = {"ctl": "vdd_ctl", "abuf": "vdd_abuf", "wlbuf": "vdd_wlbuf",
          "dec": "vdd_dec", "cdec": "vdd_cdec", "cwlbuf": "vdd_cwlbuf",
          "binv": "vdd_binv", "obuf": "vdd_obuf"}

ctl_nets = by_role(CTL, {
    r"clk_in|clk": "clk0", r"cs|cs0|csb": "cs0",
    r"prechrg|precharge": "precharge", r"clk_out": "clk_int",
    r"vdd|vccd\d*|vpwr": VDD_OF["ctl"], r"gnd|vssd\d*|vgnd": "gnd",
}, fallback)

abuf_nets = by_role(ABUF, {
    r"a_in": "a_in", r"a_out": "a_out", r"abar_out": "ab_out",
    r"clk": "clk_int",
    r"vdd|vccd\d*|vpwr": VDD_OF["abuf"], r"gnd|vssd\d*|vgnd": "gnd",
}, fallback)

wlbuf_nets = by_role(WLBUF, {
    r"a|in|in_0": "vhi", r"z|out|out_0": "wl_out",
    r"vdd|vccd\d*|vpwr": VDD_OF["wlbuf"], r"gnd|vssd\d*|vgnd": "gnd",
}, fallback)

pre_nets = by_role(PRE_CELL, {
    r"vdd|vccd\d*|vpwr": VDD_OF["dec"], r"gate": "precharge",
    r"bitline|bl": "dec_bl",
}, fallback)

lines = [inst("Xctl", CTL, ctl_nets),
         inst("Xabuf", ABUF, abuf_nets),
         inst("Xwlbuf", WLBUF, wlbuf_nets),
         inst("Xdec_pre", PRE_CELL, pre_nets)]

# the decode chain slice: rename its nets into this deck and hold every decode
# wordline HIGH (the precharge state), the foot staying on the precharge net
for i, l in enumerate(DEC_CELLS):
    t = l.split()
    sub = t[-1]
    nets = [("dec_bl" if re.fullmatch(r"bl_0_\d+", n)
             else "precharge" if n == "precharge"
             else "gnd" if n in ("gnd", "vssd1", "0")
             else "vhi" if re.fullmatch(r"wl_0_\d+", n)
             else "dec_%s" % re.sub(r"\W", "_", n))
            for n in t[1:-1]]
    lines.append("Xdec%d %s %s" % (i, " ".join(nets), sub))

if CDEC_ARR:
    cpre_nets = by_role(PRE_CELL, {
        r"vdd|vccd\d*|vpwr": VDD_OF["cdec"], r"gate": "precharge",
        r"bitline|bl": "cdec_bl",
    }, fallback)
    lines.append(inst("Xcdec_pre", PRE_CELL, cpre_nets))
    for i, l in enumerate(CDEC_CELLS):
        t = l.split()
        sub = t[-1]
        nets = [("cdec_bl" if re.fullmatch(r"bl_0_\d+", n)
                 else "precharge" if n == "precharge"
                 else "gnd" if n in ("gnd", "vssd1", "0")
                 else "vhi" if re.fullmatch(r"wl_0_\d+", n)
                 else "cdec_%s" % re.sub(r"\W", "_", n))
                for n in t[1:-1]]
        lines.append("Xcdec%d %s %s" % (i, " ".join(nets), sub))
    cwl_nets = by_role(CWLBUF, {
        r"a|in|in_0": "vhi", r"z|out|out_0": "cwl_out",
        r"vdd|vccd\d*|vpwr": VDD_OF["cwlbuf"], r"gnd|vssd\d*|vgnd": "gnd",
    }, fallback)
    lines.append(inst("Xcwlbuf", CWLBUF, cwl_nets))

# --- the read back end ------------------------------------------------------
# binv: input is the PRECHARGED bitline, i.e. VDD -- the same bitline state the
# array term is measured in. Its output therefore sits at 0, and that output is
# the node the mux hangs off, so it is wired through rather than re-asserted.
binv_nets = by_role(BINV, {
    r"a|in|in_0": "vhi", r"z|out|out_0": "binv_out",
    r"vdd|vccd\d*|vpwr": VDD_OF["binv"], r"gnd|vssd\d*|vgnd": "gnd",
}, fallback)
lines.append(inst("Xbinv", BINV, binv_nets))

# obuf: input is the mux output node, which the idle state leaves at 0.
obuf_nets = by_role(OBUF, {
    r"a|in|in_0": "mux_out", r"z|out|out_0": "dout",
    r"vdd|vccd\d*|vpwr": VDD_OF["obuf"], r"gnd|vssd\d*|vgnd": "gnd",
}, fallback)
lines.append(inst("Xobuf", OBUF, obuf_nets))

if MUX:
    # The mux transistor has no supply of its own: it is a pass device between
    # the bitline inverter's output and the output buffer's input. What it
    # leaks is therefore whatever the node it drives has to supply, and Vmux
    # (a 0 V source, i.e. an ammeter holding that node at its idle level) is
    # what reads it. sel is LOW in the precharge phase -- measured, not
    # assumed -- so this is the off device, which is the state 255 of the 256
    # are in during a read as well.
    mux_nets = by_role(MUX, {
        r"bl": "binv_out", r"bl_out": "mux_out", r"sel": "sel_lo",
        r"gnd|vssd\d*|vgnd": "gnd",
    }, fallback)
    lines.append(inst("Xmux", MUX, mux_nets))

if unresolved:
    print(f"{M}: WARNING: unmapped ports left floating: "
          f"{sorted(set(unresolved))}", file=sys.stderr)

counts = [("ctl", "rom_control_logic", 1),
          ("abuf", "address control buffer", N_ABUF),
          ("wlbuf", "wordline driver", N_WLBUF),
          ("dec", "row-decode column %d" % DEC_COL, N_DEC)]
if CDEC_ARR:
    counts += [("cdec", "column-decode column %d" % CDEC_COL, N_CDEC),
               ("cwlbuf", "column-decode driver", N_CWLBUF)]
counts += [("binv", "bitline inverter", N_BINV),
           ("obuf", "output buffer", N_OBUF)]
if MUX:
    counts += [("mux", "column mux pass transistor", N_MUX)]

hdr = "\n".join(
    "* %-7s %-32s x %-5d -> i(V%s)" % (tag, what, n, tag)
    for tag, what, n in counts)

deck = f"""* {M} -- PERIPHERY LEAKAGE -- cs0={args.cs0}, clk0=0 (precharge/idle)
* AUTO-GENERATED by scripts/rom_char/gen_periphery_leak_tb.py -- DO NOT EDIT
*
* One slice per block, each on its OWN supply source, so this single .op
* reports every block's leakage on a separate branch:
{hdr}
*
* The total is sum(slice x count). The cell array is NOT in here -- it is
* measured separately (gen_col_power_tb.py) and both halves are taken in the
* same state, clk0 = 0, so that they can be added. Everything else in the
* macro IS here: the read back end (bitline inverter, column mux, output
* buffer) used to be missing and was therefore scored as zero.
*
* Built from the SCHEMATIC netlist: leakage is a DC quantity, so parasitic
* capacitance has no effect on it, and the deck stays small enough for .op
* to converge where it does not on the extracted periphery netlist.
*
* gmin = {args.gmin} for THIS deck. gmin is the artificial conductance
* ngspice adds to every node to help it converge, and it is added in
* PARALLEL with the leakage being measured: set too high it simply becomes
* the answer. The column deck's sweep found gmin=1e-12 making 79% of its
* current artificial (0.656 nA against 0.366 nA settled). run_periphery_leak.sh
* sweeps this deck the same way and keeps the value where the answer stops
* moving; a single run at one gmin proves nothing.

.lib {SKY} {args.corner}
.temp {args.temp}
.param VDD={args.vdd}
.options gmin={args.gmin} abstol=1e-15 reltol=1e-3 itl1=500

* one supply per slice -- the branch currents ARE the measurement
Vctl    {VDD_OF["ctl"]}    0 DC {{VDD}}
Vabuf   {VDD_OF["abuf"]}   0 DC {{VDD}}
Vwlbuf  {VDD_OF["wlbuf"]}  0 DC {{VDD}}
Vdec    {VDD_OF["dec"]}    0 DC {{VDD}}
{f'Vcdec   {VDD_OF["cdec"]}   0 DC {{VDD}}' if CDEC_ARR else ''}
{f'Vcwlbuf {VDD_OF["cwlbuf"]} 0 DC {{VDD}}' if CDEC_ARR else ''}
Vbinv   {VDD_OF["binv"]}   0 DC {{VDD}}
Vobuf   {VDD_OF["obuf"]}   0 DC {{VDD}}
{'''* The mux has no supply of its own -- it is a pass device. Vmux is a 0 V
* source, i.e. an AMMETER, holding the node the mux drives at the level the
* idle state leaves it (0 V, every bitline inverter output being 0) and
* reading what that node has to supply. The sign convention is the same as
* the supply branches: positive means current drawn.
Vmux    mux_out 0 DC 0''' if MUX else ''}
* no ground source: ngspice aliases the name `gnd` to node 0, so one here
* would be a shorted VSRC. The supply branches are the measurement anyway.

* the idle state: clk0 low (precharge phase), cs0 as given.
* Every decode wordline is HIGH in this phase, which is why the wordline
* drivers are measured with their input at VDD and the decode chains with
* their gates at VDD -- the chain is cut by the FOOT, gated by the precharge
* net, not by a wordline. Same state as the array measurement.
Vclk  clk0 0 DC 0
Vcs   cs0  0 DC {{{args.vdd if args.cs0 else 0.0}}}
Vhi   vhi  0 DC {{VDD}}
Vain  a_in 0 DC 0
{'* every column select is LOW in the precharge phase (run_coldec_delay.sh)' if MUX else ''}
{'Vsel  sel_lo 0 DC 0' if MUX else ''}

{chr(10).join(lines)}

{DEFS}

* .op, NOT a transient: there is nothing to settle in a static state, and a
* transient would report charging current as leakage. The result is read from
* the "v<tag>#branch" lines of the log (`.measure op` prints no numbers).
.op
.end
"""

out = args.out or os.path.join(rom_paths.char_dir(M, args.macros_dir),
                               f"periph_leak_cs{args.cs0}_{args.corner}"
                               f"_g{args.gmin}.sp")
os.makedirs(os.path.dirname(out), exist_ok=True)
open(out, "w").write(deck)
print(f"written: {out}", file=sys.stderr)
for tag, what, n in counts:
    print(f"count {tag} {n}")
