#!/usr/bin/env python3
"""
OpenRAM ROM makrosu icin Liberty (.lib) zamanlama modeli uretir.

NEDEN: OpenRAM'in characterizer'i sadece SRAM icin .lib yaziyor. ROM
derleyicisi (rom_compiler) yalnizca .sp/.v/.lef/.gds uretir -- bkz.
macros/rom_17kbyte/rom_17kbyte.log ciktisindaki dosya listesi. Sentez ve
STA icin gereken .lib'i bu betik, LEF'ten cikarilan pin/alan bilgisi ve
asagidaki BASE tablosundaki zamanlama sayilariyla uretir.

DIKKAT -- zamanlama sayilari OLCUM DEGIL, analitik tahmindir:
  rom_17kbyte.sp icinde ne flip-flop ne latch var. Yapi klasik on-sarjli
  (precharged) NOR ROM:
      clk_out  = clock_driver(clk0)          (8 evirici, evirmez)
      prechrg  = ~NAND(cs0, clk_out) = cs0 & clk0
      precharge_cell = PMOS, gate = prechrg  -> prechrg=0 iken on-sarj
      adres tamponu: A_out = NAND(clk_out, ~A)  -> kod cozme yalnizca clk=1
      dout0 = 2 evirici (bitline_inverter + output_buffer), MANDAL YOK
  Sonuc:
      clk0 = 0 -> bitline'lar VDD'ye on-sarj edilir, dout0 tumu 1
      clk0 = 1 -> kod cozucu acilir, secili hucreler bitline'i bosaltir
      dout0 SADECE clk0 yuksek fazinda gecerlidir.
  BASE["access"] = clk0 yukselen kenardan dout0 gecerli olana kadar
  gecen sure (kod cozme + wordline + bitline bosaltma + tampon).

  Gercek olcumle degistirmek icin ngspice olan makinede rom_17kbyte.sp
  uzerinde en kotu adres icin transient kosun, sonra:
      python3 asic/scripts/rom_char/gen_rom_lib.py --access <olculen> --t-pre <olculen>

Kullanim:
    python3 asic/scripts/rom_char/gen_rom_lib.py                 # 3 kose uretir
    python3 asic/scripts/rom_char/gen_rom_lib.py --corner TT_1p8V_25C
    python3 asic/scripts/rom_char/gen_rom_lib.py --access 2.4 --hold 2.4
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from collections import OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
ASIC = os.path.dirname(os.path.dirname(HERE))
DEFAULT_LEF = os.path.join(ASIC, "macros", "rom_17kbyte", "rom_17kbyte.lef")

# ---------------------------------------------------------------------------
# Zamanlama knob'lari (ns / mW). TT temel, digerleri derating carpani.
# ---------------------------------------------------------------------------
# access  : clk0 yukselen kenar -> dout0 gecerli (en kucuk yukte)
# t_pre   : bitline on-sarj suresi -> clk0'in dusuk fazi en az bu kadar olmali
# setup   : addr0/cs0, clk0 yukselmeden once bu kadar kararli olmali
# hold    : addr0/cs0, clk0 yukseldikten sonra bu kadar kararli kalmali
#           (degerlendirme penceresi boyunca adres degisemez -> ~access)
BASE = {
    "access": 3.00,
    "t_pre": 2.80,
    "setup": 0.15,
    "hold": 3.00,
    "leakage_mw": 0.050,
}

# ad -> (proses, gerilim, sicaklik, gecikme carpani, kisit carpani)
CORNERS = OrderedDict([
    ("TT_1p8V_25C", (1.0, 1.80, 25, 1.00, 1.00)),
    ("SS_1p6V_100C", (1.0, 1.60, 100, 1.85, 1.50)),
    ("FF_1p95V_n40C", (1.0, 1.95, -40, 0.65, 0.70)),
])

# Yuk/egim tablolari -- OpenRAM'in SRAM lib'leriyle ayni index'ler (pF, ns)
CAP_INDEX = [0.0017224999999999999, 0.006889999999999999, 0.027559999999999998]
SLEW_INDEX = [0.00125, 0.005, 0.04]
# Cikis surucusu pinv_dec_4 (wp=5.0 wn=1.68); yuk duyarliligi OpenRAM'in
# ayni sinif surucu kullanan SRAM lib'inden alindi.
LOAD_DELTA = [0.000, 0.029, 0.145]
OUT_SLEW = [0.002, 0.005, 0.016]

# Giris pin kapasiteleri -- rom_17kbyte.sp'deki kapi genisliklerinden (pF)
#   clk0 -> clock_driver ilk evirici (pinv: wp=1.12 wn=0.36 um)
#   cs0  -> control_nand girisi      (wp=1.12 wn=0.74 um)
#   addr -> inv_array_mod girisi     (wp=3.00 wn=0.74 um)
PIN_CAP = {"clk0": 0.0025, "cs0": 0.0030, "_default": 0.0060}
MAX_CAP = 0.027559999999999998
MIN_CAP = 0.0017224999999999999
MAX_TRANSITION = 0.04


def parse_lef(path):
    """LEF'ten makro adi, boyut ve pin listesi (yon korunarak) cikarir."""
    with open(path) as fh:
        text = fh.read()

    m = re.search(r"^\s*MACRO\s+(\S+)", text, re.M)
    if not m:
        sys.exit("LEF icinde MACRO bulunamadi: %s" % path)
    name = m.group(1)

    m = re.search(r"^\s*SIZE\s+([\d.]+)\s+BY\s+([\d.]+)\s*;", text, re.M)
    if not m:
        sys.exit("LEF icinde SIZE bulunamadi: %s" % path)
    width, height = float(m.group(1)), float(m.group(2))

    pins = OrderedDict()
    pat = re.compile(r"^\s*PIN\s+(\S+)(.*?)^\s*END\s+\1\s*$", re.M | re.S)
    for pm in pat.finditer(text):
        pname, body = pm.group(1), pm.group(2)
        dm = re.search(r"DIRECTION\s+(\w+)", body)
        um = re.search(r"USE\s+(\w+)", body)
        pins[pname] = {
            "direction": dm.group(1).lower() if dm else "input",
            "use": um.group(1).lower() if um else None,
        }

    return name, width, height, pins


def group_buses(pins):
    """pin[3] seklindeki pinleri bus'lara toplar."""
    buses = OrderedDict()
    scalars = OrderedDict()
    for pname, info in pins.items():
        m = re.match(r"^(.*)\[(\d+)\]$", pname)
        if m:
            base, idx = m.group(1), int(m.group(2))
            b = buses.setdefault(base, {"direction": info["direction"],
                                        "bits": []})
            b["bits"].append(idx)
        else:
            scalars[pname] = info
    for b in buses.values():
        b["bits"].sort()
    return buses, scalars


def table(rows, pad):
    """3x3 lookup tablosunu Liberty values(...) govdesi olarak bicimler."""
    out = []
    for i, row in enumerate(rows):
        prefix = "" if i == 0 else pad
        out.append('%s"%s"' % (prefix, ", ".join("%.4f" % v for v in row)))
    return ",\\\n".join(out)


def constraint_block(setup_rows, hold_rows, indent):
    pad = " " * indent
    inner = pad + " " * 12
    lines = []
    for ttype, rows in (("setup_rising", setup_rows), ("hold_rising", hold_rows)):
        lines.append("%stiming() {" % pad)
        lines.append("%s    timing_type : %s;" % (pad, ttype))
        lines.append('%s    related_pin : "clk0";' % pad)
        for kind in ("rise_constraint", "fall_constraint"):
            lines.append("%s    %s(CONSTRAINT_TABLE) {" % (pad, kind))
            lines.append("%s    values(%s);" % (pad + "    ", table(rows, inner)))
            lines.append("%s    }" % pad)
        lines.append("%s}" % pad)
    return "\n".join(lines)


def gen_lib(name, area, buses, scalars, corner, args):
    proc, volt, temp, dscale, cscale = CORNERS[corner]
    # --measured: access/t_pre/hold ZATEN bu koseye ait (o kosenin kendi
    # sky130 modeliyle ngspice'te olculdu) -> tekrar olceklemek CIFT SAYIM.
    # SETUP: hala DOGRUDAN olculmedi, ama artik --measured modunda cagiran
    # taraf KOSE BASINA bir deger geciyor (regen_rom_libs.sh: olculen
    # t_clk2pre'nin 3 kati). t_clk2pre, clk0'dan on-sarj/wordline'a giden
    # OLCULMUS yoldur; adres yolu ayni wordline'a daha cok decode kati
    # uzerinden varir (adres tamponu -> predecode -> nand2_dec -> row_decode
    # -> wordline_driver), dolayisiyla 3x kotumser bir ust sinirdir.
    # Kose basina deger geldigi icin cscale ile TEKRAR olceklemek cift
    # sayim olurdu -> --measured'da sscale = 1. Marjlar (pw_high/pw_low
    # icindeki 0.5/0.2) analitik oldugu icin kose deratingi ile olceklenmeye
    # devam eder.
    mscale = 1.0 if args.measured else dscale   # olculen buyuklukler
    hscale = 1.0 if args.measured else cscale   # hold, olculen access'i izler
    sscale = 1.0 if args.measured else cscale   # setup, kose basina geliyor
    access = args.access * mscale
    t_pre = args.t_pre * mscale
    setup = args.setup * sscale
    hold = args.hold * hscale
    # --- access'in UC TERIMI --------------------------------------------
    # .lib'deki `access` clk0 yukselen kenarindan dout0 gecerli olana
    # kadardir. Kolon olcumu (t_dis_50) bunun yalnizca ORTA terimidir --
    # TRIG'i ic `precharge` agindan alir ve bitline'da biter:
    #   1) t_front : clk0 -> precharge / wordline
    #                (gen_periphery_power_tb.py: t_clk2pre / t_clk2wl)
    #   2) access  : precharge -> bitline %50  (col*_worst_case_parasitic)
    #   3) backend : bitline -> dout0          (gen_backend_delay_tb.py)
    #                bitline eviricisi + 264:8 kolon mux + cikis tamponu
    # 1 ve 3 gecilmezse eski (EKSIK) davranis korunur; .lib basliginda
    # bunun eksik oldugu ayrica yazilir.
    t_front = (args.t_front or 0.0) * (1.0 if args.measured else dscale)
    be = None
    if args.backend_ns:
        be = [float(x) for x in args.backend_ns.split(",")]
        if len(be) != 3:
            sys.exit("--backend-ns tam 3 deger ister (CELL_TABLE index_2)")
    sl = None
    if args.out_slew_ns:
        sl = [float(x) for x in args.out_slew_ns.split(",")]
        if len(sl) != 3:
            sys.exit("--out-slew-ns tam 3 deger ister")
    # pencereler ve hold en kotu cikis yukundeki TAM access'i kullanir --
    # veri o ana kadar gecerli degil.
    access_eff = (t_front + access + max(be)) if be else (access + max(LOAD_DELTA))

    # NOT: pencereler ve hold, access'in TAM halini (on uc + bitline + arka
    # uc, en kotu cikis yukunde) kullanir -- veri o ana kadar gecerli degil.
    pw_high = access_eff + 0.5 * dscale  # degerlendirme + pay (pay analitik)
    pw_low = t_pre + 0.2 * dscale        # on-sarj + pay (pay analitik)
    period = pw_high + pw_low
    leak = args.leakage_mw  # dogrudan olculen deger -- kose bazinda ARTIK
                             # ayri ayri geciliyor, tersine dscale ile
                             # olceklenmiyor (eski ters-dscale varsayimi
                             # SS/FF timing carpanlari gibi yanlis cikabilirdi)

    delay_rows = ([[t_front + access + b for b in be]] * 3 if be
                  else [[access + d for d in LOAD_DELTA]] * 3)
    slew_rows = [list(sl)] * 3 if sl else [list(OUT_SLEW)] * 3
    if be:
        # adres/cs0 degerlendirme penceresi boyunca kararli kalmali; pencere
        # artik TAM access kadar (on uc + bitline + arka uc).
        hold = access_eff
    setup_rows = [[setup] * 3] * 3
    hold_rows = [[hold] * 3] * 3

    addr_buses = [b for b, i in buses.items() if i["direction"] == "input"]
    data_buses = [b for b, i in buses.items() if i["direction"] == "output"]
    addr_bits = len(buses[addr_buses[0]]["bits"]) if addr_buses else 0
    data_bits = len(buses[data_buses[0]]["bits"]) if data_buses else 0

    o = []
    w = o.append
    w("/* -------------------------------------------------------------------")
    w(" * %s -- %s" % (name, corner))
    w(" * OTOMATIK URETILDI: asic/scripts/rom_char/gen_rom_lib.py  -- ELLE DUZENLEMEYIN")
    w(" *")
    w(" * OpenRAM ROM derleyicisi .lib yazmaz; bu dosya LEF pinleri +")
    w(" * %s.sp'den cikarilan devre yapisi uzerinden uretildi." % name)
    w(" *")
    w(" * Model: on-sarjli NAND-tipi (seri zincirli) ROM, cikista mandal YOK.")
    w(" *   clk0 = 0 -> bitline on-sarj (dout0 tumu 1)")
    w(" *   clk0 = 1 -> degerlendirme; secili 'bit=0' hucreler bitline'i")
    if args.chain_len:
        w(" *   en kotu durumda ~%d seri NMOS uzerinden bosaltir (kolon %s);"
          % (args.chain_len, args.worst_col if args.worst_col else "?"))
        w(" *   dout0 %.3f ns sonra gecerli" % access)
    else:
        w(" *   secili hucreler bitline'i seri zincir uzerinden bosaltir;")
        w(" *   dout0 %.3f ns sonra gecerli" % access)
    w(" *   clk0 dusunce dout0 GECERSIZLESIR. Tuketici ya clk0'in dusen")
    w(" *   kenarinda ornekler, ya da makro ters saatle surulur (clk0 = ~clk)")
    w(" *   ve veri sistem saatinin yukselen kenarinda yakalanir.")
    w(" *")
    w(" * KAYNAK: access/t_pre degerleri %s ngspice"
      % (args.char_source if args.char_source else "izole-kolon"))
    w(" * olcumunden geliyor -- BU kose (%s) kendi sky130 model" % corner)
    w(" * dosyasiyla (tt/ss/ff) AYRI AYRI simule edildi; sabit carpanla")
    w(" * olcekleme YAPILMADI. Olcum bunun gerekli oldugunu gosterdi: eski")
    w(" * SS x1.85 varsayimi gercekte olculen x2.76'ya gore %33 IYIMSERDI.")
    w(" * Yontem: docs/guides/rom_lib_uretimi.md. Bu betik --access/--t-pre")
    w(" * gecilmezse eski analitik varsayilan (yanlis NOR modeline dayanir)")
    w(" * kullanir -- imza icin HER ZAMAN olculen degerle cagirin.")
    w(" *")
    if be:
        w(" * ACCESS UC TERIMDEN OLUSUR (hepsi olculdu):")
        w(" *   clk0 -> precharge/wordline : %.4f ns" % t_front)
        w(" *   precharge -> bitline %%50   : %.4f ns" % access)
        w(" *   bitline -> dout0           : %.4f .. %.4f ns (cikis yukune gore)"
          % (min(be), max(be)))
        w(" *   TOPLAM (en kotu yuk)       : %.4f ns" % access_eff)
        w(" * Onceki surumlerde yalnizca ORTA terim vardi; on uc ve arka uc")
        w(" * (bitline eviricisi + 264:8 kolon mux + cikis tamponu) EKSIKTI.")
    else:
        w(" * UYARI: access yalnizca bitline terimini kapsiyor. clk0 ->")
        w(" * precharge/wordline ve bitline -> dout0 (evirici + mux + cikis")
        w(" * tamponu) EKSIK. --t-front / --backend-ns ile olculen degerleri")
        w(" * gecin (asic/scripts/rom_char/gen_backend_delay_tb.py).")
    if sl:
        w(" * Cikis gecis suresi OLCULDU: %.4f .. %.4f ns" % (min(sl), max(sl)))
    else:
        w(" * UYARI: rise/fall_transition OLCULMEDI (sabit tahmin) --")
        w(" * olcum bunun 30-300 kat dusuk oldugunu gosterdi.")
    if args.energy_pj or args.energy_idle_pj:
        w(" *")
        w(" * GUC MODELI: clk0 pininde internal_power = CEVRIM BASINA ENERJI")
        w(" * (pJ); frekansi guc araci uygular (P = E*f*aktivite).")
        if args.energy_pj:
            w(" *   when \"cs0\"  = %.4f pJ  (okuma: kolon dizisi + cevre birimi)"
              % args.energy_pj)
        if args.energy_idle_pj:
            w(" *   when \"!cs0\" = %.4f pJ  (BOSTA: cs0 yalnizca on-sarji"
              % args.energy_idle_pj)
            w(" *     kapatir; clk_int agaci + adres tamponlari + satir kod")
            w(" *     cozucu + 128 wordline secili olmasa da anahtarlanir.")
            w(" *     Bu blok eksik birakilirsa OpenSTA sessizce 0 sayar.)")
        else:
            w(" *   when \"!cs0\" = YAZILMADI -- bosta guc SIFIR sayilir, bu")
            w(" *     YANLIS. asic/scripts/rom_char/gen_periphery_power_tb.py ile olcup")
            w(" *     --energy-idle-pj ile gecin.")
    w(" * ----------------------------------------------------------------- */")
    w("library (%s_%s) {" % (name, corner))
    w('    delay_model : "table_lookup";')
    w('    time_unit : "1ns";')
    w('    voltage_unit : "1V";')
    w('    current_unit : "1mA";')
    w('    resistance_unit : "1kohm";')
    w("    capacitive_load_unit(1, pF);")
    w('    leakage_power_unit : "1mW";')
    w('    pulling_resistance_unit : "1kohm";')
    w("")
    w("    operating_conditions(OC) {")
    w("        process : %.1f;" % proc)
    w("        voltage : %.2f;" % volt)
    w("        temperature : %d;" % temp)
    w("    }")
    w("    default_operating_conditions : OC;")
    w("    nom_process : %.1f;" % proc)
    w("    nom_voltage : %.2f;" % volt)
    w("    nom_temperature : %d;" % temp)
    w("")
    w("    input_threshold_pct_fall       : 50.0;")
    w("    output_threshold_pct_fall      : 50.0;")
    w("    input_threshold_pct_rise       : 50.0;")
    w("    output_threshold_pct_rise      : 50.0;")
    w("    slew_lower_threshold_pct_fall  : 10.0;")
    w("    slew_upper_threshold_pct_fall  : 90.0;")
    w("    slew_lower_threshold_pct_rise  : 10.0;")
    w("    slew_upper_threshold_pct_rise  : 90.0;")
    w("")
    w("    default_cell_leakage_power    : 0.0;")
    w("    default_leakage_power_density : 0.0;")
    w("    default_input_pin_cap    : 1.0;")
    w("    default_inout_pin_cap    : 1.0;")
    w("    default_output_pin_cap   : 0.0;")
    # default_max_transition olculen cikis egimini KAPSAMALI: SS'de dout0
    # gecis suresi 5.35 ns'ye kadar cikiyor (bitline cok yavas dustugu icin),
    # eski sabit 0.5 ns kutuphaneyi KENDI ICINDE tutarsiz birakiyordu --
    # araclar makronun kendi cikisini max_transition ihlali sayardi.
    w("    default_max_transition   : %.4f;"
      % (max(sl) * 1.2 if sl else 0.5))
    w("    default_fanout_load      : 1.0;")
    w("    default_max_fanout       : 4.0;")
    w("    default_connection_class : universal;")
    w("")
    w("    voltage_map ( VCCD1, %.2f );" % volt)
    w("    voltage_map ( VSSD1, 0 );")
    w("")
    w("    lu_table_template(CELL_TABLE) {")
    w("        variable_1 : input_net_transition;")
    w("        variable_2 : total_output_net_capacitance;")
    w('        index_1("%s");' % ", ".join(str(x) for x in SLEW_INDEX))
    w('        index_2("%s");' % ", ".join(str(x) for x in CAP_INDEX))
    w("    }")
    w("")
    w("    lu_table_template(CONSTRAINT_TABLE) {")
    w("        variable_1 : related_pin_transition;")
    w("        variable_2 : constrained_pin_transition;")
    w('        index_1("%s");' % ", ".join(str(x) for x in SLEW_INDEX))
    w('        index_2("%s");' % ", ".join(str(x) for x in SLEW_INDEX))
    w("    }")
    w("")
    w("    type (rom_data) {")
    w("        base_type : array;")
    w("        data_type : bit;")
    w("        bit_width : %d;" % data_bits)
    w("        bit_from : %d;" % (data_bits - 1))
    w("        bit_to : 0;")
    w("    }")
    w("")
    w("    type (rom_addr) {")
    w("        base_type : array;")
    w("        data_type : bit;")
    w("        bit_width : %d;" % addr_bits)
    w("        bit_from : %d;" % (addr_bits - 1))
    w("        bit_to : 0;")
    w("    }")
    w("")
    w("cell (%s) {" % name)
    w("    memory() {")
    # Liberty "rom" tipini de tanir; bazi eski parser'lar sadece "ram"
    # kabul ettigi icin varsayilan ram (--memory-type rom ile degistirin).
    w("        type : %s;" % args.memory_type)
    w("        address_width : %d;" % addr_bits)
    w("        word_width : %d;" % data_bits)
    w("    }")
    w("    interface_timing : true;")
    w("    dont_use   : true;")
    w("    map_only   : true;")
    w("    dont_touch : true;")
    w("    area : %.4f;" % area)
    w("")
    w("    pg_pin(vccd1) {")
    w("        voltage_name : VCCD1;")
    w("        pg_type : primary_power;")
    w("    }")
    w("    pg_pin(vssd1) {")
    w("        voltage_name : VSSD1;")
    w("        pg_type : primary_ground;")
    w("    }")
    w("")
    w("    leakage_power () {")
    w("        value : %.6f;" % leak)
    w("    }")
    w("    cell_leakage_power : %.6f;" % leak)
    w("")

    pad20 = " " * 20
    for bname in data_buses:
        bits = buses[bname]["bits"]
        w("    bus(%s) {" % bname)
        w("        bus_type : rom_data;")
        w("        direction : output;")
        w("        max_capacitance : %s;" % MAX_CAP)
        w("        min_capacitance : %s;" % MIN_CAP)
        w("        memory_read() {")
        w("            address : %s;" % (addr_buses[0] if addr_buses else "addr0"))
        w("        }")
        w("        pin(%s[%d:%d]) {" % (bname, bits[-1], bits[0]))
        w("        timing() {")
        w("            timing_sense : non_unate;")
        w('            related_pin : "clk0";')
        # On-sarjli dizi clk YUKSELEN kenarda degerlendirmeye baslar.
        w("            timing_type : rising_edge;")
        for kind, rows in (("cell_rise", delay_rows), ("cell_fall", delay_rows),
                           ("rise_transition", slew_rows),
                           ("fall_transition", slew_rows)):
            w("            %s(CELL_TABLE) {" % kind)
            w("            values(%s);" % table(rows, pad20))
            w("            }")
        w("        }")
        w("        }")
        w("    }")
        w("")

    for bname in addr_buses:
        bits = buses[bname]["bits"]
        w("    bus(%s) {" % bname)
        w("        bus_type : rom_addr;")
        w("        direction : input;")
        w("        capacitance : %s;" % PIN_CAP["_default"])
        w("        max_transition : %s;" % MAX_TRANSITION)
        w("        pin(%s[%d:%d]) {" % (bname, bits[-1], bits[0]))
        w(constraint_block(setup_rows, hold_rows, indent=8))
        w("        }")
        w("    }")
        w("")

    for pname, info in scalars.items():
        if info["use"] in ("power", "ground") or pname == "clk0":
            continue
        w("    pin(%s) {" % pname)
        w("        direction : input;")
        w("        capacitance : %s;" % PIN_CAP.get(pname, PIN_CAP["_default"]))
        w("        max_transition : %s;" % MAX_TRANSITION)
        w(constraint_block(setup_rows, hold_rows, indent=8))
        w("    }")
        w("")

    w("    pin(clk0) {")
    w("        clock : true;")
    w("        direction : input;")
    w("        capacitance : %s;" % PIN_CAP["clk0"])
    w("        max_transition : %s;" % MAX_TRANSITION)
    w("        timing() {")
    w('            timing_type : "min_pulse_width";')
    w("            related_pin : clk0;")
    # rise = YUKSEK faz (degerlendirme), fall = DUSUK faz (on-sarj).
    w('            rise_constraint(scalar) { values("%.4f"); }' % pw_high)
    w('            fall_constraint(scalar) { values("%.4f"); }' % pw_low)
    w("        }")
    w("        timing() {")
    w('            timing_type : "minimum_period";')
    w("            related_pin : clk0;")
    w('            rise_constraint(scalar) { values("%.4f"); }' % period)
    w('            fall_constraint(scalar) { values("%.4f"); }' % period)
    w("        }")
    if args.energy_pj or args.energy_idle_pj:
        # internal_power = anahtarlama basina ENERJI (guc DEGIL!).
        # Liberty birimleri V*mA*ns = pJ. Frekansi guc araci kendi uygular:
        #     P_dinamik = E * f * aktivite
        # Bu yuzden karakterizasyonda frekans bilmeye gerek YOK. Olculen
        # buyukluk bir cevrimde VDD'den cekilen YUK integrali Q; E = Q*VDD.
        # Frekans bagimsizligi deneysel dogrulandi (2026-09-05, wrom0 kol.155):
        #     TCLK=200n -> q=2.342e-13 C ; TCLK=400n -> q=2.419e-13 C  (%3.3)
        # ROM her clk cevriminde TUM bitline'lari on-sarj edip
        # degerlendirdigi icin enerji clk0 pinine yazilir.
        # "when" SART: OpenSTA kosulsuz internal_power blogunu SAYMIYOR
        # (2026-09-05'te dogrulandi -- kosulsuz blokla Macro internal power
        # hic degismedi, report_power ornekte 0.000000e+00 gosterdi).
        # Calisan referans: sky130_sram_*.lib, pin(clk0) icinde
        #   internal_power(){ when : "!csb0 & !web0"; rise_power(scalar){...} }
        # ROM'da cs0 aktif-YUKSEK (control_nand(CS, clk_out)), okuma cs0=1'de.
        #
        # IKI DURUM DA YAZILIR. Eksik birakilan durum icin OpenSTA sessizce
        # 0 sayar -- uyari bile vermez, guc raporu oldugundan dusuk cikar.
        # Referans OpenRAM SRAM .lib'i de dort csb/web kombinasyonunu birden
        # yaziyor (sky130_sram_1kbyte_..._TT_1p8V_25C.lib:327-360).
        #
        # !cs0 NEDEN SIFIR DEGIL: cs0 yalnizca on-sarj yolunu kapatir.
        #     clk_int   = clock_driver(clk0)        -> cs0'dan BAGIMSIZ
        #     precharge = ~NAND(cs0, clk_int)       -> cs0=0 iken SABIT 0
        # Satir kod cozucu clk_int ile surulur (wrom0.sp: Xrom_row_decoder'in
        # clk portu clk_int'e bagli), yani makro secili DEGILKEN de her
        # cevrimde saat agaci + adres tamponlari + kod cozucu + 128 wordline
        # anahtarlanir. Bitline'lar VDD'de tutulur (ayak transistoru kapali)
        # -> onlarin payi yalnizca sizintidir, o da leakage_power'da sayili.
        # Olcum: asic/scripts/rom_char/gen_periphery_power_tb.py (cevre birimi izole,
        # hucre dizisi lump yukle temsil edilir -- kolon yonteminin aynisi).
        if args.energy_pj:
            w("        internal_power() {")
            w('            when : "cs0";')
            w('            rise_power(scalar) { values("%.4f"); }' % args.energy_pj)
            w('            fall_power(scalar) { values("%.4f"); }' % args.energy_pj)
            w("        }")
        if args.energy_idle_pj:
            w("        internal_power() {")
            w('            when : "!cs0";')
            w('            rise_power(scalar) { values("%.4f"); }'
              % args.energy_idle_pj)
            w('            fall_power(scalar) { values("%.4f"); }'
              % args.energy_idle_pj)
            w("        }")
    w("    }")
    w("")
    w("}")
    w("}")
    return "\n".join(o) + "\n"


def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--lef", default=DEFAULT_LEF)
    ap.add_argument("--outdir", default=None,
                    help="varsayilan: LEF ile ayni dizin")
    ap.add_argument("--corner", action="append", choices=list(CORNERS),
                    help="uretilecek kose (birden fazla verilebilir)")
    ap.add_argument("--memory-type", default="ram", choices=["ram", "rom"])
    ap.add_argument("--chain-len", type=int, default=None,
                    help="en kotu kolondaki seri NMOS sayisi (yalnizca .lib basligi icin)")
    ap.add_argument("--worst-col", type=int, default=None,
                    help="en kotu kolon numarasi (yalnizca .lib basligi icin)")
    ap.add_argument("--char-source", default=None,
                    help="olcum kaynagi aciklamasi (yalnizca .lib basligi icin)")
    ap.add_argument("--energy-pj", type=float, default=None,
                    help="bir okuma cevriminin ENERJISI (pJ, olculen). Verilirse "
                         "clk0 pinine internal_power blogu yazilir. Frekans "
                         "GEREKMEZ -- guc araci P=E*f*aktivite'yi kendi hesaplar.")
    ap.add_argument("--t-front", type=float, default=None,
                    help="clk0 -> precharge/wordline gecikmesi (ns, olculen). "
                         "Kolon olcumu TRIG'i ic precharge agindan aldigi icin "
                         "bu terim access'te EKSIKTI.")
    ap.add_argument("--backend-ns", default=None,
                    help="bitline -> dout0 gecikmesi, CELL_TABLE index_2'nin "
                         "UC yuk noktasi icin virgullu (ns, olculen): bitline "
                         "eviricisi + kolon mux + cikis tamponu. Verilmezse "
                         "eski (eksik) LOAD_DELTA tahmini kullanilir.")
    ap.add_argument("--out-slew-ns", default=None,
                    help="dout0 gecis suresi (%%10-%%90), uc yuk noktasi icin "
                         "virgullu (ns, olculen). Verilmezse eski sabit "
                         "OUT_SLEW tahmini kullanilir -- o tahmin olcumun "
                         "30-300 kati altinda cikti.")
    ap.add_argument("--energy-idle-pj", type=float, default=None,
                    help="makro SECILI DEGILKEN (cs0=0) bir clk0 cevriminin "
                         "ENERJISI (pJ, olculen). Verilirse clk0 pinine "
                         "when:\"!cs0\" internal_power blogu yazilir. cs0 "
                         "yalnizca on-sarji kapatir; saat agaci ve satir kod "
                         "cozucu bosta da calisir -- bu deger SIFIR DEGILDIR.")
    ap.add_argument("--measured", action="store_true",
                    help="gecilen access/t_pre ZATEN --corner ile verilen koseye ait "
                         "(o kosenin kendi ngspice olcumu); CORNERS tablosundaki "
                         "dscale/cscale carpanlari UYGULANMAZ. Uc kose de ayri "
                         "olculdugu icin imza akisinda DOGRU kullanim budur.")
    for key, val in BASE.items():
        ap.add_argument("--" + key.replace("_", "-"), dest=key, type=float,
                        default=val, help="varsayilan %s" % val)
    args = ap.parse_args()

    name, width, height, pins = parse_lef(args.lef)
    area = width * height
    buses, scalars = group_buses(pins)
    outdir = args.outdir or os.path.dirname(os.path.abspath(args.lef))
    corners = args.corner or list(CORNERS)

    print("makro   : %s" % name)
    print("boyut   : %.2f x %.2f um -> alan %.2f um2" % (width, height, area))
    print("bus     : %s" % ", ".join(
        "%s[%d:0] (%s)" % (b, len(i["bits"]) - 1, i["direction"])
        for b, i in buses.items()))
    print("skaler  : %s" % ", ".join(scalars))
    print("access  : %.3f ns (TT), hold %.3f ns, on-sarj %.3f ns"
          % (args.access, args.hold, args.t_pre))
    for corner in corners:
        text = gen_lib(name, area, buses, scalars, corner, args)
        path = os.path.join(outdir, "%s_%s.lib" % (name, corner))
        with open(path, "w") as fh:
            fh.write(text)
        print("yazildi : %s (%d satir)" % (path, text.count("\n")))


if __name__ == "__main__":
    main()
