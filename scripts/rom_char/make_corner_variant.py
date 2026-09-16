#!/usr/bin/env python3
"""Var olan TT gercek-parazitik testbench'inden SS/FF kose varyanti uretir:
.lib secicisini, VDD'yi ve sicakligi degistirir -- devrenin geri kalani
(gercek parazitik kapasitans dahil) BIREBIR AYNI kalir.

Kullanim: make_corner_variant.py <macro> [en_kotu_kolon] <ss|ff>
          (kolon verilmezse netlistten turetilir)
Kaynak dosya: <makro_dizini>/char/col<kolon>_worst_case_parasitic.sp
              (once gen_col_tb_parasitic.py ile uretilmis olmali)
Cikti: ayni dizine col<kolon>_worst_case_parasitic_<ss|ff>.sp
"""
import sys, re, os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rom_paths

if len(sys.argv) < 3:
    sys.exit("Kullanim: make_corner_variant.py <macro> [kolon] <ss|ff>")
MACRO = sys.argv[1]
# Kolon atlanabilir: <macro> <ss|ff> -> en kotu kolon netlistten gelir
if len(sys.argv) == 3:
    COL, CORNER = rom_paths.geometry(MACRO)["worst_col"], sys.argv[2]
else:
    COL, CORNER = sys.argv[2], sys.argv[3]
SRC = os.path.join(rom_paths.char_dir(MACRO),
                   f"col{COL}_worst_case_parasitic.sp")

PARAMS = {
    "ss": dict(vdd=1.6, temp=100, tag="SS_1p6V_100C"),
    "ff": dict(vdd=1.95, temp=-40, tag="FF_1p95V_n40C"),
}
p = PARAMS[CORNER]

text = open(SRC).read()
text = re.sub(r"(\.lib\s+\S+sky130\.lib\.spice)\s+tt", rf"\1 {CORNER}", text)
text = re.sub(r"\.param VDD=1\.8", f".param VDD={p['vdd']}", text)
if ".temp" not in text:
    text = text.replace(".param VDD=", f".temp {p['temp']}\n.param VDD=", 1)

OUT = SRC.replace(".sp", f"_{CORNER}.sp")
open(OUT, "w").write(text)
print(f"yazildi: {OUT}  (VDD={p['vdd']}, temp={p['temp']}C, lib={CORNER})")
