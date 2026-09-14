#!/usr/bin/env python3
"""ROM'un ARKA UC gecikmesini olcer: bitline -> dout0.

NEDEN GEREKLI:
  Mevcut `access` sayisi (col<N>_worst_case_parasitic.log, t_dis_50) yalnizca
  BITLINE'a kadar olan yolu kapsiyor:
      .measure t_dis_50 TRIG v(precharge) ... TARG v(bl_0_155) ...
  Oysa .lib'deki `access`, clk0 yukselen kenarindan dout0'in gecerli
  olmasina kadar gecen suredir. Netliste gore (wrom0.sp ust seviye):
      bl_N -> rom_bitline_inverter -> bl_b_N -> rom_column_mux (264:8 gecis
      transistoru) -> rom_out_prebuf_k -> rom_output_buffer -> dout0[k]
  Bu uc kademe HIC olculmemisti. Ustelik bitline cok yavas dusuyor
  (wrom0 TT'de %50->%10 gecisi 13.8 ns, ~52 mV/ns), yani evirici esigi
  cok gec/erken tetiklenebilir -- tahminle gecilecek bir terim degil.

YONTEM (periphery betigiyle ayni "dilim x adet" mantigi):
  Cikarilan netlistten (<macro>_cap_only.spice, gercek Magic parazitik C)
  ust seviyede YALNIZCA arka uc ornekleri tutulur:
      rom_bitline_inverter (528 cihaz) + rom_column_mux_array (264)
      + rom_output_buffer (16)                          = 808 cihaz
  Hucre dizisi, kod cozucu ve kontrol mantigi silinir. Silinen bloklarin
  ucundaki dugumler (bl_0_*, kolon sec) ideal kaynakla surulur, dolayisiyla
  onlarin yuku gecikmeye girmez -- zaten girmemesi gerekir, o kisim
  t_dis_50'de sayili.

  Surulen bitline dalga sekli TAHMIN DEGIL: olculen t_dis_50/t_dis_10'dan
  cikan gercek egim kullanilir (%50 -> %10 arasi 0.4*VDD). Boylece evirici
  gercekte gordugu yavas kenari gorur.

  NEGATIF NET KAPASITANS DUZELTMESI periphery betigindeki ile ayni ve
  yine ZORUNLU: Magic'in alt-taban duzeltme terimleri silinen bloklarin
  pozitif terimleri olmadan net negatife donuyor ve cozucu patliyor.

CIKTI: dout0'in cikis yukune GORE gecikme -- .lib CELL_TABLE'inin
  index_2 (total_output_net_capacitance) ekseni artik gercekten olculur;
  onceki dosyalarda uc yuk noktasi da AYNI sayiyi tasiyordu.

Kullanim:
  gen_backend_delay_tb.py <macro> <kolon> <out.sp>
      --t-dis-50 <s> --t-dis-10 <s> [--corner tt|ss|ff] [--vdd] [--temp]
"""
import argparse, collections, os, re, sys

ap = argparse.ArgumentParser()
ap.add_argument("macro")
ap.add_argument("col", type=int)
ap.add_argument("out")
ap.add_argument("--t-dis-50", type=float, required=True,
                help="olculen: precharge %%50 -> bitline %%50 (saniye)")
ap.add_argument("--t-dis-10", type=float, required=True,
                help="olculen: precharge %%50 -> bitline %%10 (saniye)")
ap.add_argument("--corner", default="tt", choices=["tt", "ss", "ff"])
ap.add_argument("--vdd", default="1.8")
ap.add_argument("--temp", default="25")
ap.add_argument("--load-ff", type=float, default=6.89,
                help="dout0 cikis yuku (fF). .lib CELL_TABLE index_2 "
                     "noktalari: 1.7225 / 6.89 / 27.56 -- her biri AYRI "
                     "kosulur, boylece yuk ekseni gercekten olculur "
                     "(onceki .lib'lerde uc nokta da ayni sayiyi tasiyordu).")
ap.add_argument("--repo", default="/home/hpw/Desktop/2026_teknofest_Silicore")
args = ap.parse_args()

M = args.macro
SP = f"{args.repo}/asic/macros/{M}/{M}_cap_only.spice"
if not os.path.exists(SP):
    sys.exit(f"HATA: {SP} yok")

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
    sys.exit(f"HATA: arka uc ornekleri eksik: {[l.split()[-1] for l in top_insts]}")

SUPPLY_HI, SUPPLY_LO = "vccd1", "vssd1"
alive = {SUPPLY_HI, SUPPLY_LO, "0"}
for l in keep:
    alive.update(l.split()[1:-1])

# --- hangi mux transistoru bizim kolonu hangi cikisa baglar? -------------
# Kolon->cikis eslemesi ISIMDEN TAHMIN EDILMEZ; mux dizisinin netlisti
# uzerinden okunur (Magic'in urettigi isimler sirali degil).
mux_sub = f"{M}_rom_column_mux_array"
mux_inst = [l for l in keep if l.split()[-1] == mux_sub][0]
mux_ports = B[mux_sub][0].split()[2:]
mp2n = dict(zip(mux_ports, mux_inst.split()[1:-1]))
cell_ports = B[f"{M}_rom_column_mux"][0].split()[2:]   # bl bl_out sel gnd
i_bl, i_out, i_sel = (cell_ports.index(x) for x in ("bl", "bl_out", "sel"))

inv_sub = f"{M}_rom_bitline_inverter"
inv_inst = [l for l in keep if l.split()[-1] == inv_sub][0]
ip2n = dict(zip(B[inv_sub][0].split()[2:], inv_inst.split()[1:-1]))
# Magic alt-devre portlarini in_N/out_N diye yeniden adlandiriyor; hedef
# kolonu UST SEVIYE ag adindan (bl_0_<kolon>) bulup port adina ceviriyoruz.
# Magic hem alt-devre portlarini (in_N/out_N) hem ust seviye ag adlarini
# (wrom0_rom_base_array_0/bl_0_155) yeniden adlandiriyor; hedef kolonu
# ag adinin SONEKINDEN buluyoruz.
cand = [n for n in ip2n.values() if n.split("/")[-1] == f"bl_0_{args.col}"]
if len(cand) != 1:
    sys.exit(f"HATA: kolon {args.col} bitline'i tek olarak bulunamadi: {cand}")
src_net = cand[0]
inv_n2p = {v: k for k, v in ip2n.items()}
src_port = inv_n2p[src_net]
# eviricinin bu bit icin cikisi: ayni hucre ornegindeki Z
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
    sys.exit("HATA: bitline eviricisinin cikisi bulunamadi")

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
    sys.exit(f"HATA: kolon {args.col} icin mux transistoru bulunamadi")

# cikis tamponunun bu prebuf'a bagli dout0 biti
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
    sys.exit("HATA: dout0 biti bulunamadi")

# --- ust seviye C: yasayan/olu kurali + negatif net duzeltmesi ------------
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

# Kaynakla SURULEN dugumler: yalnizca dizi bitline'lari (bl_0_*) ve kolon
# secleri. Eviricinin CIKISLARI (bl_*) surulmuyor -- onlari da "driven"
# saymak negatif net kapasitans duzeltmesini atlatiyordu ve cozucu ilk
# zaman noktasinda patliyordu (2026-09-06).
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

# --- kullanilan alt-devre tanimlari --------------------------------------
need, seen = set(l.split()[-1] for l in keep), set()
while need - seen:
    n = (need - seen).pop()
    seen.add(n)
    for l in B.get(n, [])[1:]:
        if l.startswith("X") and l.split()[-1] in B:
            need.add(l.split()[-1])
defs = []
for name in seen:
    if name == TOP:
        continue
    defs.append("\n".join(fix_units(l) if l.startswith("X") else l
                          for l in B[name]))
    defs.append(".ends")
defs = "\n".join(defs)

# --- uyaran ---------------------------------------------------------------
VDD = float(args.vdd)
# Olculen egim: %50 -> %10 arasinda 0.4*VDD dusuyor. Bu egimle VDD->0 tam
# gecis suresi: TFALL. Kenar t=TSTART'ta basliyor.
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

tb = f"""* {M} -- ARKA UC gecikmesi: bitline -> dout0  (kolon {args.col}, {args.corner})
* Yol: bl_0_{args.col} -> bitline_inverter -> column_mux(sel) -> output_buffer -> dout0
* Tutulan: rom_bitline_inverter + rom_column_mux_array + rom_output_buffer
* Silinen: hucre dizisi / kod cozucu / kontrol mantigi (ucundaki dugumler
*          ideal kaynakla surulur -- o kisim zaten t_dis_50'de sayili)
* Ust seviye C: {len(kept_c)} korundu, {n_drop} atildi;
*   negatif net kapasitans duzeltmesi {n_fix} dugum / {c_fix*1e15:.1f} fF
* Surulen bitline kenari OLCULEN egimden: t_dis_50={args.t_dis_50*1e9:.4f} ns,
*   t_dis_10={args.t_dis_10*1e9:.4f} ns -> VDD->0 tam gecis {tfall*1e9:.3f} ns
* Olculen bit: {dout_net}   (sec: {sel_net})   cikis yuku: {args.load_ff} fF

.lib /home/hpw/OpenLane/pdks/sky130A/libs.tech/ngspice/sky130.lib.spice {args.corner}
.temp {args.temp}
.param VDD={args.vdd}
.param TFALL={tfall:.6e}
.param TSTART={TSTART:.6e}

Vvdd {SUPPLY_HI} 0 DC {{VDD}}
Vgnd {SUPPLY_LO} 0 DC 0

* olculen kolonun bitline'i: on-sarjli VDD'den olculen egimle iner
Vsrc {src_net} 0 PWL(0 {{VDD}} {{TSTART}} {{VDD}} '{TSTART:.6e}+{tfall:.6e}' 0)

* diger bitline'lar on-sarjda kalir
{hold_hi}

* kolon secimi
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
print(f"yazildi: {args.out}  ({M} kolon {args.col} -> {dout_net}, "
      f"{args.corner}, bl kenari {tfall*1e9:.2f} ns, yuk {args.load_ff} fF)")
