#!/usr/bin/env python3
"""ROM makrosunun IZOLE KOLON'u uzerinden sizinti ve cevrim enerjisi olcer.

NEDEN KOLON, NEDEN TAM MAKRO DEGIL:
  Tam makro (~34k transistor) ngspice'te 28+ dk surup 7.3 GB RAM yiyor ve
  24 kosum (4 makro x 3 kose x 2 mod) gerekiyor -- pratik degil.
  Bu on-sarjli mimaride hem sizinti hem dinamik enerji KOLON BASINA
  ayrilabilir, cunku kolonlarin hepsi her cevrimde ayni isi yapiyor:
    sizinti  = N x (kapali ayak transistorunun alt-esik sizintisi) + cevre
    enerji   = N x (bir bitline'in sarj/desarj enerjisi)           + cevre
  (N = kolon sayisi; netlistten sayilir, bkz. rom_paths.py)
  Kolon netlisti PARAZITIK C icerir (gen_col_tb_parasitic.py ciktisi), yani
  dinamik enerji icin gereken gercek kapasiteler dahildir.

NEDEN ENERJI, NEDEN GUC DEGIL:
  Liberty `internal_power` = anahtarlama basina ENERJI (pJ), guc degil.
  Frekansi guc araci uygular: P = E * f * aktivite. Bu yuzden yuk
  integrali (Coulomb) olcup E = Q*VDD yaziyoruz -> frekanstan BAGIMSIZ.

Modlar:
  idle    -- precharge=0 sabit (on-sarj fazi, ayak KAPALI): DC sizinti (.op).
             gmin=1e-15 sart -- 1e-12 sonucu %79 sisiriyordu (bkz. idle blogu).
  active  -- precharge anahtarlanir: bir TAM cevrimin yuk integrali -> enerji.

Kullanim:
  gen_col_power_tb.py <macro> <kolon> <idle|active> <out.sp>
      [--corner tt|ss|ff] [--vdd 1.8] [--temp 25] [--tclk 200n]
"""
import sys, re, argparse, os

import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rom_paths

ap = argparse.ArgumentParser()
ap.add_argument("macro")
ap.add_argument("col", type=int)
ap.add_argument("mode", choices=["idle", "active"])
ap.add_argument("out")
ap.add_argument("--corner", default="tt", choices=["tt", "ss", "ff"])
ap.add_argument("--vdd", default="1.8")
ap.add_argument("--temp", default="25")
ap.add_argument("--tclk", default="200n",
                help="active modda cevrim periyodu; ENERJI buna bagimsiz olmali "
                     "-- iki farkli deger ile kosup dogrulanabilir")
ap.add_argument("--macros-dir", default=None,
                help="makro agaci (varsayilan: ROM_MACROS_DIR / <depo>/examples)")
args = ap.parse_args()

SRC = os.path.join(rom_paths.char_dir(args.macro, args.macros_dir),
                   f"col{args.col}_worst_case_parasitic.sp")
# Kolon sayisi netlistten gelir -- deck basligindaki "toplam = N x bu
# deger" ifadesi eskiden 264 diye SABIT yaziliydi ve makro yeniden
# uretilince yaniltiyordu.
NCOL = rom_paths.geometry(args.macro, args.macros_dir)["cols"]
if not os.path.exists(SRC):
    sys.exit(f"HATA: {SRC} yok -- once gen_col_tb_parasitic.py calistirin")

# Mevcut (dogrulanmis) kolon testbench'ini oku; devre govdesini aynen kullan,
# sadece uyaranlari ve olcumleri degistir. Boylece timing ile AYNI devre.
body, in_defs = [], False
for line in open(SRC):
    s = line.rstrip("\n")
    ls = s.lstrip().lower()
    # atlanacaklar: baslik/uyaran/analiz -- devre ve subckt tanimlari KALIR
    # DIKKAT: ".ends" da ".end" ile basliyor -- alt-devre kapanislari
    # SILINMEMELI, yoksa "Mismatch of .subckt ... .ends" hatasi alinir.
    first = ls.split()[0] if ls.split() else ""
    if first in (".lib", ".temp", ".param", ".tran", ".measure", ".ic", ".end"):
        continue
    if s.startswith("+") and body and body[-1] == "":   # .measure devam satiri
        continue
    if re.match(r"^V(vdd|precharge|wl\d+|gndgnd_uq\d+)\b", s):
        continue
    body.append(s)

circuit = "\n".join(l for l in body if l.strip())

# devrede gecen wordline ve turetilmis toprak dugumlerini bul
wl_nodes = sorted(set(re.findall(r"\bwl_0_\d+\b", circuit)),
                  key=lambda s: int(s.split("_")[-1]))
gnd_extra = sorted(set(re.findall(r"\bgnd_uq\d+\b", circuit)))

wl_src = "\n".join(f"Vwl{i} {n} 0 DC {{VDD}}" for i, n in enumerate(wl_nodes))
gnd_src = "\n".join(f"Vg{n} {n} 0 DC 0" for n in gnd_extra)

HEAD = f""".lib {rom_paths.sky130_lib()} {args.corner}
.temp {args.temp}
.param VDD={args.vdd}

Vvdd vdd 0 DC {{VDD}}
{gnd_src}
{wl_src}"""

if args.mode == "idle":
    tb = f"""* {args.macro} kolon {args.col} -- IDLE SIZINTI (kolon basina)
* precharge=0: on-sarj fazi, ayak transistoru KAPALI, bitline VDD'de.
* Baskin sizinti yolu: VDD -> prechg PMOS(acik) -> zincir(acik) -> ayak(KAPALI) -> gnd
* Toplam makro sizintisi ~ {NCOL} x (bu deger) + cevre birimi.
{HEAD}
Vprecharge precharge 0 DC 0

{circuit}

* gmin: ngspice'in yakinsama icin HER DUGUME ekledigi yapay iletkenlik.
* Cok buyuk secilirse sizinti olcumune KARISIR. 2026-09-05 taramasi:
*   gmin=1e-12 -> 0.656 nA   (%79 yapay!)
*   gmin=1e-15 -> 0.366 nA
*   gmin=1e-18 -> 0.366 nA   (ayni -> yakinsadi)
* 1e-15 yeterli ve guvenli.
.options gmin=1e-15 abstol=1e-15 reltol=1e-3 itl1=500
* .op KULLANILIYOR (transient DEGIL): "uic"li transient'te tum dugumler
* 0'dan baslayip 85 transistorluk direncli zincirden yavasca doluyor;
* 600 ns'de bile oturmuyordu (65->19->8.7 nA hala azaliyordu) ve sarj
* akimi sizinti sanilarak ~100x YUKSEK olculuyordu. .op bu kolonda
* (136 cihaz) yakinsiyor -- tam makroda (34k) yakinsamiyordu.
* Sonuc log'da "vvdd#branch" satirindan okunur (.measure op ngspice'te
* sayisal cikti uretmiyor).
.op
.end
"""
else:
    tb = f"""* {args.macro} kolon {args.col} -- AKTIF CEVRIM ENERJISI (kolon basina)
* Bir tam cevrimde VDD'den cekilen YUK integrali -> E = Q*VDD.
* Enerji FREKANSTAN BAGIMSIZ; --tclk degistirilerek dogrulanabilir.
* Toplam makro enerjisi ~ {NCOL} x (bu deger) + cevre birimi.
{HEAD}
.param TCLK={args.tclk}
Vprecharge precharge 0 PULSE(0 {{VDD}} {{TCLK/2}} 100p 100p {{TCLK/2-100p}} {{TCLK}})

{circuit}

.tran '{args.tclk}/400' '4*TCLK' uic
* 2. VE 3. cevrim ayri olculur: esit cikmalari devrenin OTURDUGUNU gosterir
* (uic ile tum dugumler 0'dan basliyor, zincir yavas doluyor).
* 3. cevrim daha oturmus oldugu icin .lib'e O yazilir.
* FREKANS BAGIMSIZLIGI DOGRULANDI (2026-09-05, wrom0 kolon 155, TT):
*   TCLK=200n -> q_c3 = 2.342e-13 C
*   TCLK=400n -> q_c3 = 2.419e-13 C   (periyot 2x, yuk %3.3 farkli)
.measure tran q_c2 integ i(Vvdd) from='TCLK' to='2*TCLK'
.measure tran q_c3 integ i(Vvdd) from='2*TCLK' to='3*TCLK'
.measure tran e_col_pj param='abs(q_c3)*VDD*1e12'
.end
"""

open(args.out, "w").write(tb)
print(f"yazildi: {args.out}  ({args.macro} kolon {args.col}, {args.mode}, "
      f"kose={args.corner}, {len(wl_nodes)} wordline)")
