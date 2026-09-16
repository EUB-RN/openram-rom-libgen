#!/usr/bin/env python3
"""Bir ROM makrosunun TAM devresi (tek kolon degil -- tum dizi + decoder +
tamponlar) icin guc/enerji testbench'i uretir.

NEDEN ENERJI, NEDEN GUC DEGIL:
  Liberty'nin `internal_power` alani -- adina ragmen -- GUC degil, anahtarlama
  basina ENERJI tutar (V*mA*ns birimleriyle => pJ). Frekansi guc analiz araci
  sonradan uygular:  P_dinamik = E_cevrim * f * aktivite.
  Bu yuzden burada bir cevrimde VDD'den cekilen TOPLAM YUKU (integral)
  olcup enerjiye ceviriyoruz -- sonuc frekanstan BAGIMSIZ olur.
  (Eski surum `avg i(Vvdd)` olcuyordu; o deger secilen TCLK'ya bagliydi,
  yani frekans verilmeden anlamsizdi.)

Modlar:
  idle    -- cs0=0, clk0=0 sabit; .op ile VDD'den cekilen SIZINTI akimi
             (leakage_power icin; frekanstan zaten bagimsiz).
             Kapasiteler .op'ta acik devre oldugu icin sematik netlist yeterli.
  active  -- cs0=1, clk0 anahtarlanir; .tran ile BIR cevrimde cekilen yuk
             integrali -> enerji (internal_power icin).
             Dinamik enerji ~ C*V^2 oldugundan PARAZITIK netlist kullanilmali.

Kullanim: gen_power_tb.py <macro> <idle|active> <out.sp> [--tclk 200n]
          [--corner tt|ss|ff] [--vdd 1.8] [--temp 25] [--netlist <path>]
"""
import sys, re, argparse

import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rom_paths

ap = argparse.ArgumentParser()
ap.add_argument("macro")
ap.add_argument("mode", choices=["idle", "active"])
ap.add_argument("out")
ap.add_argument("--tclk", default="200n",
                help="active modda cevrim periyodu; enerji buna BAGIMSIZ olmali "
                     "(iki farkli deger ile kosup dogrulanabilir)")
ap.add_argument("--corner", default="tt", choices=["tt", "ss", "ff"])
ap.add_argument("--vdd", default="1.8")
ap.add_argument("--temp", default="25")
ap.add_argument("--netlist", default=None,
                help="varsayilan: idle->sematik .sp, active->_cap_only.spice "
                     "(gercek parazitik C)")
ap.add_argument("--macros-dir", default=None,
                help="makro agaci (varsayilan: ROM_MACROS_DIR / <depo>/examples)")
args = ap.parse_args()

MACRO, MODE, OUT = args.macro, args.mode, args.out
SCHEM = rom_paths.netlist(MACRO, args.macros_dir)
# active: parazitikli netlist (dinamik enerji kapasiteye baglidir)
DEFAULT_NL = SCHEM if MODE == "idle" else os.path.join(
    rom_paths.macro_dir(MACRO, args.macros_dir), MACRO + "_cap_only_fixed.spice")
NL = args.netlist or DEFAULT_NL


def logical_lines(path):
    """SPICE '+' devam satirlarini mantiksal satira birlestir."""
    cur = None
    for line in open(path):
        s = line.rstrip("\n")
        if s.startswith("+"):
            cur = (cur or "") + " " + s[1:].strip(); continue
        if cur is not None:
            yield cur
        cur = s
    if cur is not None:
        yield cur


# top subckt port sirasini netlistten oku (elle yazmiyoruz -- kaynaktan gelir)
ports = None
for l in logical_lines(NL):
    toks = l.split()
    if len(toks) >= 2 and toks[0].lower() == ".subckt" and toks[1] == MACRO:
        ports = toks[2:]
        break
if ports is None:
    sys.exit(f"HATA: {NL} icinde .subckt {MACRO} port satiri bulunamadi")


def port_signal(p):
    if p == "clk0": return "clk"
    if p == "cs0": return "cs"
    if p.startswith("addr0["): return "0"          # adres sabit 0
    if p.startswith("dout0["): return f"d{p[6:-1]}"
    if p in ("vccd1", "vdd"): return "vdd"
    if p in ("vssd1", "gnd"): return "0"
    return p


conn = " ".join(port_signal(p) for p in ports)
# Magic cikisi tekillestirilmis toprak dugumleri uretebilir (gnd_uqN)
gnd_extra = sorted(set(re.findall(r"gnd_uq\d+", conn)))
gnd_src = "\n".join(f"Vgnd{n} {n} 0 DC 0" for n in gnd_extra)

HEAD = f""".lib {rom_paths.sky130_lib()} {args.corner}
.temp {args.temp}
.param VDD={args.vdd}
.include {NL}

Vvdd vdd 0 DC {{VDD}}
{gnd_src}"""

if MODE == "idle":
    # NOT: .op (DC cozum) bu boyutta (~34k transistor) YAKINSAMIYOR --
    # 2026-09-05'te 10 dk'da tek satir cikti uretmeden zaman asimina ugradi.
    # Cozum: girisleri sabit tutup KISA bir transient kosmak ve devre
    # oturduktan sonra akimi olcmek (buyuk devrelerde standart yontem).
    # Sizinti yine frekanstan bagimsizdir; transient sadece cozucu yardimi.
    tb = f"""* {MACRO} -- TUM MAKRO, IDLE (cs0=0) SIZINTI olcumu
* Sizinti frekanstan bagimsizdir; dogrudan mW olarak .lib'e yazilir.
* .op yerine transient-oturma (bkz. betikteki not).
{HEAD}
Vclk clk 0 DC 0
Vcs  cs  0 DC 0

Xdut {conn} {MACRO}

.options gmin=1e-12 abstol=1e-13 reltol=1e-3 itl1=1000 itl2=1000
.tran 1n 200n uic
* son 50 ns: devre oturmus kabul edilir
.measure tran i_leak avg i(Vvdd) from=150n to=200n
.measure tran p_leak_mw param='abs(i_leak)*VDD*1000'
.end
"""
else:
    # Bir TAM cevrimde cekilen yuk integrali -> enerji. 1. cevrim baslangic
    # gecicisi icin atlanir; 2. cevrim (TCLK..2*TCLK) olculur.
    tb = f"""* {MACRO} -- TUM MAKRO, AKTIF: bir okuma cevriminin ENERJISI
* Olculen buyukluk yuk integrali (Coulomb) -> E = Q*VDD (Joule) -> pJ.
* Enerji FREKANSTAN BAGIMSIZ; --tclk degistirilip dogrulanabilir.
{HEAD}
.param TCLK={args.tclk}
Vclk clk 0 PULSE(0 {{VDD}} {{TCLK/2}} 100p 100p {{TCLK/2-100p}} {{TCLK}})
Vcs  cs  0 DC {{VDD}}

Xdut {conn} {MACRO}

.tran '{args.tclk}/200' '3*TCLK'
* 2. cevrim: baslangic gecicisi disarida
.measure tran q_cycle integ i(Vvdd) from='TCLK' to='2*TCLK'
.measure tran e_cycle_pj param='abs(q_cycle)*VDD*1e12'
* karsilastirma icin ortalama akim (FREKANSA BAGLI -- .lib'e YAZILMAZ)
.measure tran i_avg avg i(Vvdd) from='TCLK' to='2*TCLK'
.end
"""

open(OUT, "w").write(tb)
print(f"yazildi: {OUT}  (mod={MODE}, kose={args.corner}, netlist={NL.split('/')[-1]})")
