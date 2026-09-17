#!/usr/bin/env python3
"""Measure the access / precharge time of the worst column of a ROM macro with
REAL Magic parasitic capacitance.

PREREQUISITE: <macro>_cap_only.spice must already exist -- from Magic:
  extract style ngspice(si); extract all
  ext2spice cthresh 0; ext2spice rthresh infinite; ext2spice extresist off
  ext2spice -o <macro>_cap_only.spice
(rthresh infinite + extresist off: CAPACITANCE ONLY, no resistance -- trying to
extract resistance for the whole macro at once segfaults Magic 8.3.629.
run_cap_extract.sh does all of this for you.)

The column is selected by WALKING THE GRAPH, not by matching names: the
internal nodes Magic emits carry automatic "instance/port" names (e.g.
wrom0_rom_base_one_cell_17122/D), not readable schematic names like
bl_int_N_M. Parameter units are converted too (w,l,pd,ps in metres and ad,as in
m^2 become bare microns and 'u'-suffixed micron^2, which is what ngspice
accepts) -- verified experimentally.

KNOWN LIMITATION: the deck carries the parasitic Cs found INSIDE the cell
sub-circuits, but not the C elements at the `*_rom_base_array` level (bitline
wire and inter-column coupling). On wrom0 column 236 those sum to about +3 fF
against the ~5 fF the deck does carry, i.e. the discharge time here is somewhat
optimistic. gen_backend_delay_tb.py and gen_periphery_power_tb.py handle the
same situation with an explicit alive/dead + negative-net-capacitance rule;
porting that rule here is the obvious next improvement.

Usage:  python3 gen_col_tb_parasitic.py <macro> [worst_column]
Example: python3 gen_col_tb_parasitic.py wrom0        # column found for you
         python3 gen_col_tb_parasitic.py wrom0 236    # or choose it
"""
import re, sys, os, collections, subprocess

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rom_paths

# Wire resistance is ON by default (see the note below); --no-resistance
# reproduces the old capacitance-only deck for comparison.
ARGV = [a for a in sys.argv[1:] if not a.startswith("--")]
WITH_R = "--no-resistance" not in sys.argv
if not ARGV:
    sys.exit("usage: gen_col_tb_parasitic.py <macro> [worst_column] "
             "[--no-resistance]")
MACRO = ARGV[0]
# With no column given it is DERIVED from the netlist (the column with the most
# series one_cells) -- no hand-kept table needed, see find_worst_column.py.
COL = int(ARGV[1]) if len(ARGV) > 1 else \
      rom_paths.geometry(MACRO)["worst_col"]
BASE = rom_paths.macro_dir(MACRO)
SP = rom_paths.cap_netlist(MACRO)
if not os.path.exists(SP):
    sys.exit(f"ERROR: {SP} does not exist -- run run_cap_extract.sh first")
START = f"bl_0_{COL}"

SUFFIX = {"f":1e-15, "p":1e-12, "n":1e-9, "u":1e-6, "m":1e-3, "k":1e3}
def to_float(tok):
    m = re.match(r"^([0-9.eE+-]+)([a-zA-Z]?)$", tok)
    return float(m.group(1)) * SUFFIX.get(m.group(2), 1.0)

def fix_units(line):
    def rl(m):
        return f"{m.group(1)}={to_float(m.group(2))*1e6:.6g}"
    def ra(m):
        return f"{m.group(1)}={to_float(m.group(2))*1e12:.6g}u"
    line = re.sub(r"\b(w|l|pd|ps)=([0-9.eE+-]+[a-zA-Z]?)\b", rl, line)
    line = re.sub(r"\b(ad|as)=([0-9.eE+-]+[a-zA-Z]?)\b", ra, line)
    return line

def logical_lines(path):
    cur, name = None, None
    for line in open(path):
        s = line.rstrip("\n")
        if not s or s.startswith("*"): continue
        if s.startswith("+"):
            cur = (cur or "") + " " + s[1:].strip(); continue
        if cur is not None: yield name, cur
        cur = None
        if s.lower().startswith(".subckt"): name = s.split()[1]; cur = s
        elif s.lower().startswith(".ends"): name = None
        else: cur = s
    if cur is not None: yield name, cur

blocks = collections.defaultdict(list)
for n, l in logical_lines(SP):
    if n: blocks[n].append(l)

arr = f"{MACRO}_rom_base_array"
edges = collections.defaultdict(list)
zero_insts = collections.defaultdict(list)
for l in blocks[arr]:
    if not l.startswith("X"): continue
    t = l.split(); nets, sub = t[1:-1], t[-1]
    if sub == f"{MACRO}_rom_base_one_cell":
        S, D = nets[0], nets[1]
        edges[S].append((D, l)); edges[D].append((S, l))
    elif sub == f"{MACRO}_rom_base_zero_cell":
        zero_insts[nets[0]].append(l)

visited = {START}
path_insts, cur, prev, steps = [], START, None, 0
while not cur.startswith("gnd") and cur != "0" and steps < 2000:
    cand = [(n, l) for n, l in edges.get(cur, []) if l not in path_insts]
    if not cand:
        print(f"ERROR: no forward neighbour for {cur}", file=sys.stderr); sys.exit(1)
    nxt, l = cand[0]
    path_insts.append(l); prev, cur = cur, nxt; steps += 1

n_one = len(path_insts)
path_nodes = [START]   # an ordered list, NOT a set, so the output file is
                        # deterministic from run to run
n = START
for l in path_insts:
    t = l.split(); nets = t[1:-1]
    other = nets[1] if nets[0] == n else nets[0]
    path_nodes.append(other); n = other

zero_on_path = []
for node in path_nodes:
    zero_on_path.extend(zero_insts.get(node, []))
n_zero = len(zero_on_path)

print(f"{MACRO} column {COL}: {n_one} series NMOS + {n_zero} dead cells "
      f"(by graph walk)", file=sys.stderr)

def get_subckt(name):
    return "\n".join(blocks_raw_lines(name))

def blocks_raw_lines(name):
    out, f = [], False
    for line in open(SP):
        s = line.rstrip("\n")
        if s.lower().startswith(f".subckt {name.lower()}"):
            f = True
        if f: out.append(s)
        if f and s.lower().startswith(".ends"): break
    return out

defs_raw = "\n".join(get_subckt(nm) for nm in
    [f"{MACRO}_rom_base_one_cell", f"{MACRO}_rom_base_zero_cell",
     f"{MACRO}_precharge_cell", f"{MACRO}_pinv_dec_3"])
defs = "\n".join(fix_units(l) if l.startswith("X") else l for l in defs_raw.splitlines())

# Series WIRE resistance, one resistor per chain cell (gen_resistance_model.py).
# The extraction this deck is built from is capacitance-only -- Magic segfaults
# extracting resistance for the whole macro -- so resistance is measured per
# cell and inserted here.
#
# This is ON BY DEFAULT because leaving it out is simply optimistic. Measured
# on wrom0, worst column 236 (82 cells x 505.4 ohm = 41.5 kohm):
#     corner   t_dis_50 without R   with R    difference
#     tt            14.3346 ns     16.5035 ns   +15.1%
#     ss            39.3750 ns     41.9709 ns    +6.6%
#     ff             6.9559 ns      8.9101 ns   +28.1%
# The wire resistance does not move with the corner while the channel
# resistance does, which is why the relative effect is largest at FF.
res_lines, r_cell = [], None
if WITH_R:
    rj = os.path.join(rom_paths.char_dir(MACRO), "resistance_model.json")
    if not os.path.exists(rj):
        sys.exit(f"ERROR: {rj} does not exist -- run\n"
                 f"       python3 gen_resistance_model.py {MACRO}\n"
                 f"       first, or pass --no-resistance to build the old "
                 f"capacitance-only deck.")
    import json as _json
    _rm = _json.load(open(rj))
    r_cell = _rm["cells"].get(f"{MACRO}_rom_base_one_cell", {}).get("series_ohm")
    if not r_cell:
        sys.exit("ERROR: no series resistance for the one_cell in " + rj)
    fixed = []
    for k, l in enumerate(path_insts):
        t = l.split()
        node = t[1]
        if node == START:          # the bitline node itself stays as it is
            newn = f"{START}_r"
            res_lines.append(f"Rw{k} {START} {newn} {r_cell:.4f}")
        else:
            newn = f"{node}_r{k}"
            res_lines.append(f"Rw{k} {node} {newn} {r_cell:.4f}")
        t[1] = newn
        fixed.append(" ".join(t))
    path_insts = fixed

chain_raw = "\n".join(path_insts + zero_on_path)
chain = "\n".join(fix_units(l) if l.startswith("X") else l for l in chain_raw.splitlines())
if res_lines:
    chain = chain + "\n" + "\n".join(res_lines)

wl_nodes = sorted(set(re.findall(r"wl_0_\d+", chain)), key=lambda s: int(s.split("_")[-1]))
wl_src = "\n".join(f"Vwl{i} {n} 0 DC {{VDD}}" for i, n in enumerate(wl_nodes))

gnd_extra = sorted(set(re.findall(r"gnd_uq\d+", chain + defs)))
gnd_src = "\n".join(f"Vgnd{n} {n} 0 DC 0" for n in gnd_extra)

tb = f"""* {MACRO} -- isolated measurement of column {COL} with REAL PARASITIC C
* {n_one} series NMOS + {n_zero} dead cells (graph walk, name independent)
* wire resistance: {f"{r_cell:.1f} ohm per cell ({n_one} x = {n_one*r_cell/1000:.1f} kohm)" if r_cell else "NOT included (capacitance-only extraction)"}

.lib {rom_paths.sky130_lib()} tt

.param VDD=1.8
.param TCLK=200n

Vvdd vdd 0 DC {{VDD}}
{gnd_src}
Vprecharge precharge 0 PULSE(0 {{VDD}} {{TCLK/2}} 100p 100p {{TCLK/2-100p}} {{TCLK}})

{wl_src}

Xprechg_pmos {START} precharge vdd gnd {MACRO}_precharge_cell
Xbl_inv gnd vdd vdd {START} bl_b {MACRO}_pinv_dec_3

{chain}

{defs}

.ic v({START})={{VDD}}
.measure tran t_dis_50 TRIG v(precharge) VAL='VDD/2' RISE=1
+                      TARG v({START})   VAL='VDD/2' FALL=1
.measure tran t_dis_10 TRIG v(precharge) VAL='VDD/2' RISE=1
+                      TARG v({START})   VAL='0.1*VDD' FALL=1
.measure tran t_pre_90 TRIG v(precharge) VAL='VDD/2' FALL=1
+                      TARG v({START})   VAL='0.9*VDD' RISE=1
.measure tran t_pre_99 TRIG v(precharge) VAL='VDD/2' FALL=1
+                      TARG v({START})   VAL='0.99*VDD' RISE=1

.tran 100p '2*TCLK'
.end
"""
# The file name does NOT change with --no-resistance: make_corner_variant.py,
# run_backend_delay.sh, run_col_power.sh, run_col_energy.sh and
# regen_rom_libs.sh all look for this exact name.
outp = os.path.join(rom_paths.char_dir(MACRO),
                    f"col{COL}_worst_case_parasitic.sp")
open(outp, "w").write(tb)
print(f"written: {outp}", file=sys.stderr)

logp = outp.replace(".sp", ".log")
# ngspice path from the environment (NGSPICE_BIN); it used to be a hard-coded
# nix store path.
NG = os.environ.get("NGSPICE_BIN", "ngspice")
try:
    subprocess.run([NG, "-b", "-o", logp, outp], capture_output=True, text=True)
except FileNotFoundError:
    sys.exit(f"ERROR: ngspice not found ('{NG}'). Set NGSPICE_BIN to its path.\n"
             f"       The deck was written: {outp}")
log = open(logp).read()
import re as re2
for pat in ("t_dis_50", "t_dis_10", "t_pre_90", "t_pre_99"):
    m = re2.search(pat + r"\s*=\s*([0-9.eE+-]+)", log)
    print(f"{MACRO} {pat} = {m.group(1) if m else 'NOT FOUND'}")
errs = [l for l in log.splitlines() if "error" in l.lower() or "shorted" in l.lower() or "modelname" in l.lower()]
if errs:
    print(f"{MACRO} ERRORS:")
    for e in errs[:5]:
        print(" ", e)
