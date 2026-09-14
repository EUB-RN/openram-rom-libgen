#!/usr/bin/env python3
"""Bir ROM makrosu icin GERCEK Magic parazitik kapasitansiyla en kotu
kolonun erisim/on-sarj suresini olcer (schematik-only gen_col_tb.py'nin
parazitikli versiyonu).

ON KOSUL: <macro>_cap_only.spice zaten uretilmis olmali -- Magic ile:
  extract style ngspice(si); extract all
  ext2spice cthresh 0; ext2spice rthresh infinite; ext2spice extresist off
  ext2spice -o <macro>_cap_only.spice
(rthresh infinite + extresist off: SADECE kapasitans, direnc DAHIL DEGIL --
extresist tum makroyu (~34k hucre) tek seferde islemeye calisirken Magic
8.3.629'da segfault veriyor; bkz. docs/guides/rom_lib_uretimi.md.)

Kolon secimi isim eslestirmesiyle DEGIL, graf yuruyusuyle yapilir --
Magic'in cikardigi ic dugumler "instance/port" tarzi otomatik isimler tasir
(orn. wrom0_rom_base_one_cell_17122/D), schematik'teki bl_int_N_M gibi
okunabilir isimler DEGIL. Parametre birimleri de (w,l,pd,ps metre; ad,as
m^2) ngspice'in kabul ettigi bicime (w,l,pd,ps ciplak mikron; ad,as 'u'
sonekli mikron^2) cevrilir -- deneysel olarak dogrulandi, bkz. Bolum 5.

Kullanim: python3 gen_col_tb_parasitic.py <macro> <en_kotu_kolon>
Ornek:    python3 gen_col_tb_parasitic.py wrom0 155
"""
import re, sys, collections, subprocess

MACRO = sys.argv[1]
COL = int(sys.argv[2])
BASE = f"/home/hpw/Desktop/2026_teknofest_Silicore/asic/macros/{MACRO}"
SP = f"{BASE}/{MACRO}_cap_only.spice"
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
        print(f"HATA: {cur} icin ileri komsu yok", file=sys.stderr); sys.exit(1)
    nxt, l = cand[0]
    path_insts.append(l); prev, cur = cur, nxt; steps += 1

n_one = len(path_insts)
path_nodes = [START]   # sirali liste -- set DEGIL, cikti dosyasi calistirma
                        # bagimsiz (deterministik) olsun diye
n = START
for l in path_insts:
    t = l.split(); nets = t[1:-1]
    other = nets[1] if nets[0] == n else nets[0]
    path_nodes.append(other); n = other

zero_on_path = []
for node in path_nodes:
    zero_on_path.extend(zero_insts.get(node, []))
n_zero = len(zero_on_path)

print(f"{MACRO} kolon {COL}: {n_one} seri NMOS + {n_zero} olu hucre (graf yuruyusuyle)", file=sys.stderr)

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

chain_raw = "\n".join(path_insts + zero_on_path)
chain = "\n".join(fix_units(l) if l.startswith("X") else l for l in chain_raw.splitlines())

wl_nodes = sorted(set(re.findall(r"wl_0_\d+", chain)), key=lambda s: int(s.split("_")[-1]))
wl_src = "\n".join(f"Vwl{i} {n} 0 DC {{VDD}}" for i, n in enumerate(wl_nodes))

gnd_extra = sorted(set(re.findall(r"gnd_uq\d+", chain + defs)))
gnd_src = "\n".join(f"Vgnd{n} {n} 0 DC 0" for n in gnd_extra)

tb = f"""* {MACRO} -- GERCEK PARAZITIK C ile kolon {COL} izole olcum
* {n_one} seri NMOS + {n_zero} olu hucre (graf yuruyusu, isim-bagimsiz)

.lib /home/hpw/OpenLane/pdks/sky130A/libs.tech/ngspice/sky130.lib.spice tt

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
outp = f"{BASE}/char/col{COL}_worst_case_parasitic.sp"
open(outp, "w").write(tb)
print(f"yazildi: {outp}", file=sys.stderr)

logp = outp.replace(".sp", ".log")
r = subprocess.run(
    ["/nix/store/4ssrcgdvyb8car0yxay8cwfa5wc89f1w-ngspice-45/bin/ngspice",
     "-b", "-o", logp, outp], capture_output=True, text=True)
log = open(logp).read()
import re as re2
for pat in ("t_dis_50", "t_dis_10", "t_pre_90", "t_pre_99"):
    m = re2.search(pat + r"\s*=\s*([0-9.eE+-]+)", log)
    print(f"{MACRO} {pat} = {m.group(1) if m else 'BULUNAMADI'}")
errs = [l for l in log.splitlines() if "error" in l.lower() or "shorted" in l.lower() or "modelname" in l.lower()]
if errs:
    print(f"{MACRO} HATALAR:")
    for e in errs[:5]:
        print(" ", e)
