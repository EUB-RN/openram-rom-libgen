#!/usr/bin/env python3
"""ROM hucresinin ESDEGER KAPI KAPASITANSINI olcer (kose basina).

NEDEN: gen_periphery_power_tb.py silinen hucre dizisinin wordline yukunu
geri koyarken hucre kapilarini DOGRUSAL C ile modelliyor. Enerji olcumu
icin dogru kucultme budur -- bir dugumu VDD'ye cikarmanin besleme kaynagindan
cektigi yuk Q(VDD)'dir, dolayisiyla

    C_esd = Q(VDD) / VDD

kullanmak CEVRIM ENERJISINI birebir korur (dogrusal olmayan C-V egrisinin
sekli enerjiye girmez, yalnizca toplam yuk girer).

Ciplak cihazi m=<adet> ile koymak da ayni enerjiyi verirdi, ama 264 kat
genis ve siddetli dogrusal olmayan bir kapasitans ngspice'i yakinsatmiyordu
(2026-09-06: uc ayri denemede "Timestep too small").

Bu deck TEK cihaz kosar -- saniyeler surer. Hucre ici parazitik C'ler
(C0/C2/C5 vb.) BURADA YOK; onlari periphery betigi cikarilan netlistten
ayrica topluyor, cift sayim olmaz.

Kullanim: gen_cell_gate_tb.py <macro> <out.sp> [--corner tt|ss|ff]
                              [--vdd 1.8] [--temp 25]
"""
import argparse, os, re, sys

import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rom_paths

ap = argparse.ArgumentParser()
ap.add_argument("macro")
ap.add_argument("out")
ap.add_argument("--corner", default="tt", choices=["tt", "ss", "ff"])
ap.add_argument("--vdd", default="1.8")
ap.add_argument("--temp", default="25")
ap.add_argument("--macros-dir", default=None,
                help="makro agaci (varsayilan: ROM_MACROS_DIR / <depo>/examples)")
args = ap.parse_args()

SP = rom_paths.cap_netlist(args.macro, args.macros_dir)
if not os.path.exists(SP):
    sys.exit(f"HATA: {SP} yok -- once run_cap_extract.sh calistirin")

SUFFIX = {"f": 1e-15, "p": 1e-12, "n": 1e-9, "u": 1e-6, "m": 1e-3, "k": 1e3}
def to_float(tok):
    m = re.match(r"^([0-9.eE+-]+)([a-zA-Z]?)$", tok)
    return float(m.group(1)) * SUFFIX.get(m.group(2), 1.0)

def fix_units(line):
    line = re.sub(r"\b(w|l|pd|ps)=([0-9.eE+-]+[a-zA-Z]?)\b",
                  lambda m: f"{m.group(1)}={to_float(m.group(2))*1e6:.6g}", line)
    line = re.sub(r"\b(ad|as)=([0-9.eE+-]+[a-zA-Z]?)\b",
                  lambda m: f"{m.group(1)}={to_float(m.group(2))*1e12:.6g}u", line)
    return line

# hucre alt-devresindeki ciplak cihaz satirini al (port adlariyla yazili)
def cell_device(sub):
    grab, cur, out = False, None, []
    for raw in open(SP):
        s = raw.rstrip("\n")
        if s.lower().startswith(f".subckt {sub.lower()} "):
            grab = True
            continue
        if not grab:
            continue
        if s.lower().startswith(".ends"):
            break
        if s.startswith("X"):
            out.append(s)
    return out[0] if out else None

cells = [f"{args.macro}_rom_base_one_cell", f"{args.macro}_rom_base_zero_cell"]
devs = []
for i, c in enumerate(cells):
    d = cell_device(c)
    if d is None:
        sys.exit(f"HATA: {c} icinde cihaz yok")
    t = d.split()
    # port adlari: G -> surulen dugum, kalanlar toprakta (bitline statik)
    nets = [f"g{i}" if n == "G" else "0" for n in t[1:5]]
    devs.append(f"X{i} " + " ".join(nets) + " " + " ".join(t[5:]))
devs = "\n".join(fix_units(d) for d in devs)

tb = f"""* {args.macro} -- hucre ESDEGER KAPI KAPASITANSI ({args.corner})
* C_esd = Q(VDD)/VDD  -- cevrim enerjisini koruyan kucultme.
* Kaynak/govde toprakta: wordline yukselirken hucrenin gordugu durum.
* Hucre ici parazitik C'ler BURADA YOK (periphery betigi ayrica ekler).

.lib {rom_paths.sky130_lib()} {args.corner}
.temp {args.temp}
.param VDD={args.vdd}
.param TR=10n

Vg0 g0 0 PWL(0 0 {{TR}} {{VDD}})
Vg1 g1 0 PWL(0 0 {{TR}} {{VDD}})

{devs}

.options gmin=1e-12 abstol=1e-15 reltol=1e-4
.tran 'TR/2000' '1.2*TR' uic
.measure tran q_one  integ i(Vg0) from=0 to='TR'
.measure tran q_zero integ i(Vg1) from=0 to='TR'
.measure tran c_one_ff  param='abs(q_one)/VDD*1e15'
.measure tran c_zero_ff param='abs(q_zero)/VDD*1e15'
.end
"""
open(args.out, "w").write(tb)
print(f"yazildi: {args.out}  ({args.macro}, {args.corner})")
