#!/usr/bin/env python3
"""Her ROM makrosu icin GERCEK davranisini modelleyen `<makro>.v`'yi uretir.

NEDEN
-----
OpenRAM'in makro ile birlikte urettigi `<makro>.v` zamanlamayi YANLIS
modelliyor -- SRAM sablonundan geliyor:

    always @(posedge clk0) begin cs0_reg = cs0; addr0_reg = addr0; ... end
    always @(negedge clk0) if (cs0_reg) dout0 <= #(DELAY) mem[addr0_reg];
    // "All inputs are registers"  +  "FIXME: This delay is arbitrary"

Iki varsayimi da yanlis: (1) girisler registerli degil, (2) cikis registerli
degil. Makronun cikarilmis hucre envanterinde (`<makro>/*.ext`) tek bir
dff/latch/sense_amp/replica_column/delay_chain YOK; okuma elemani duz bir
inverter. Karsilastirma: ayni OpenRAM'in SRAM'i row_addr_dff / col_addr_dff /
data_dff / sense_amp / replica_column / delay_chain hepsini icerir -- SRAM
modelinin varsayimlari ORADA gercek, ROM'da degil.

Sonuc: OpenRAM modeliyle kosulan her simulasyon (GLS dahil) ROM'un dinamik
davranisini GORMEZ; ne adresin degerlendirme ortasinda degismesini, ne de
verinin clk0 dusunce silinmesini.

NE URETIYOR
-----------
Her makronun KENDI klasorunde, KENDI icerik dosyasi ve KENDI olculen
zamanlama degerleriyle bir `<makro>.v`. Degerler elle yazilmaz; makronun
kendi `.lib` dosyalarindan okunur:

    access   <- "TOPLAM (en kotu yuk)"        (lib basligi)
    t_pre    <- min_pulse_width fall_constraint
    setup    <- setup_rising ilk deger

Yani lib'ler yeniden uretildiginde bu betigi tekrar kosturmak yeter.

DIKKAT -- OpenRAM TUZAGI
------------------------
Makro her yeniden derlendiginde OpenRAM `<makro>.v`'yi SIFIRDAN yazar ve bu
modeli sessizce siler. Yeniden uretim sonrasi:

    python3 asic/scripts/rom_char/gen_macro_behavioral_v.py

Uretilen dosyanin basligindaki imza satiri, dosyanin bu betikten mi yoksa
OpenRAM'den mi geldigini ayirt etmeye yarar.

Kullanim:
    python3 gen_macro_behavioral_v.py                 # wrom0..wrom3
    python3 gen_macro_behavioral_v.py wrom0 wrom2     # secili
    python3 gen_macro_behavioral_v.py --corner TT_1p8V_25C
"""

import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
MACROS = os.path.join(REPO, "asic", "macros")

SIGNATURE = "GERCEK DAVRANIS MODELI -- gen_macro_behavioral_v.py"

# Varsayilan kose: en kotu (SS). Model kotumser tarafta kalsin.
DEFAULT_CORNER = "SS_1p6V_100C"


def read_lib_timing(lib_path):
    """(access, t_pre, setup) ns olarak dondurur; bulunamayan None."""
    if not os.path.exists(lib_path):
        return None, None, None
    txt = open(lib_path).read()

    access = None
    m = re.search(r"TOPLAM \(en kotu yuk\)\s*:\s*([\d.]+)\s*ns", txt)
    if m:
        access = float(m.group(1))

    t_pre = None
    m = re.search(r'timing_type\s*:\s*"min_pulse_width".*?'
                  r'fall_constraint\(scalar\)\s*\{\s*values\("([\d.]+)"\)',
                  txt, re.S)
    if m:
        t_pre = float(m.group(1))

    setup = None
    m = re.search(r"timing_type\s*:\s*setup_rising.*?values\(\"([\d.]+)", txt, re.S)
    if m:
        setup = float(m.group(1))

    return access, t_pre, setup


def read_geometry(macro_dir, macro):
    """(words, width, addr_bits, wpr).

    GEOMETRI LEF + .bin'DEN TURETILIR, `<makro>.v` basligindan DEGIL.
    Sebep: bu betik `<makro>.v`'nin uzerine yaziyor, dolayisiyla basliktan
    okumak kendi kendini kilitleyen bir dongu olurdu (bir kez calistiktan
    sonra ikinci kez okuyacak baslik kalmaz). LEF ve .bin ise OpenRAM
    ciktisi olarak degismeden duruyor.

        addr_bits, width <- LEF pin sayilari (PIN addr0[..], PIN dout0[..])
        words            <- .bin boyutu / (width/8)   -- tam sayi, kesin
        wpr              <- yalnizca yorum icin; .v basliginda varsa okunur
    """
    lef = os.path.join(macro_dir, macro + ".lef")
    addr_bits = data_bits = 0
    if os.path.exists(lef):
        lt = open(lef).read()
        addr_bits = len(re.findall(r"^\s*PIN addr0\[", lt, re.M))
        data_bits = len(re.findall(r"^\s*PIN dout0\[", lt, re.M))

    words = 0
    binf = os.path.join(macro_dir, "rom_configs", macro + ".bin")
    if data_bits and os.path.exists(binf):
        words = os.path.getsize(binf) // (data_bits // 8)

    # words_per_row = kolon sayisi / kelime genisligi. Kolon sayisi
    # netlistten sayilir (find_worst_column.py ile ayni kaynak), boylece
    # bu deger de `<makro>.v` basligina bagimli olmaktan cikar.
    wpr = 0
    try:
        from find_worst_column import analyse as _an
        _r = _an(os.path.join(macro_dir, macro + ".sp"))
        if _r and data_bits:
            wpr = _r[1] // data_bits
    except Exception:
        pass

    return words, data_bits, addr_bits, wpr


TEMPLATE = '''// OpenROM ROM model
// Words: {words}
// Word size: {width}
// Word per Row: {wpr}
// Data Type: bin
// Data File: rom_configs/{macro}.bin
//
// ^^^ YUKARIDAKI ALTI SATIR OpenRAM BICIMINDE BIRAKILDI -- SILMEYIN.
// Hem bu betigin kendisi (read_geometry) hem de simulasyon betiklerinin
// .bin donusturucusu (verification/system/gls/lib_gls.sh, run_gls.sh,
// verification/ai/ai_accelerator/run_wrom.sh) kelime genisligini
// "// Word size:" satirindan okuyor. Satir yoksa donusturucu 8 bite duser
// ve her kelimenin yalnizca alt 8 biti yuklenir -- ROM icerigi SESSIZCE
// yanlis olur.
// ---------------------------------------------------------------------------
// {macro} -- {sig}
//
// DIKKAT: OpenRAM makroyu her yeniden derlediginde BU DOSYAYI SIFIRDAN YAZAR
// ve asagidaki modeli siler. Yeniden uretim sonrasi geri uygulamak icin:
//     python3 asic/scripts/rom_char/gen_macro_behavioral_v.py {macro}
//
// NEDEN OpenRAM'in KENDI MODELI KULLANILMIYOR
// -------------------------------------------
// OpenRAM'in urettigi model SRAM sablonundan geliyor ve iki sey varsayiyor:
//     "All inputs are registers"                 -> adres iceride kilitlenir
//     always @(negedge clk0) dout0 <= mem[...]    -> veri cevrim boyunca durur
// IKISI DE YANLIS. Bu makronun cikarilmis hucre envanterinde ({macro}/*.ext)
// tek bir dff / latch / sense_amp / replica_column / delay_chain YOK; okuma
// elemani duz bir inverter (rom_bitline_inverter). Ayni OpenRAM'in SRAM'i ise
// row_addr_dff, col_addr_dff, data_dff, sense_amp, replica_column, delay_chain
// hepsini icerir -- o varsayimlar ORADA gecerli, burada degil.
//
// GERCEK DAVRANIS (degerler {macro}'in kendi .lib'inden, ngspice ile OLCULDU)
// ---------------------------------------------------------------------------
//   clk0 = 0 : ON-SARJ. Bitline'lar VDD'ye cekilir -> dout0 = tumu 1.
//              Bu faz en az T_PRE_NS surmeli.
//   clk0 = 1 : DEGERLENDIRME. Secili satirin "0" bitleri bitline'i {chain}
//              seri NMOS uzerinden bosaltir (en kotu kolon {wcol}).
//              dout0 yukselen kenardan ACCESS_NS sonra gecerli olur.
//   clk0 1->0: on-sarj yeniden baslar, VERI SILINIR.
//   cs0  = 0 : on-sarj SUREKLI acik; bitline'lar VDD'de durur, dout0 = tumu 1.
//              (Netlist: NAND(CS,clk) -> 7 kademeli inverter -> prechrg, ve
//              on-sarj PMOS gate'i dusukken iletir; yani prechrg = CS AND clk.
//              {macro}_rom_control_logic.ext merge zincirinden dogrulandi.)
//
//   GERI DONDURULEMEZ BOSALMA: dizideki her cihaz NMOS; makrodaki tek PMOS
//   on-sarj hucresinde. Bitline'in on-sarj disinda pull-up'i YOK. Evaluate
//   sirasinda adres degisirse eski satirin bosalttigi bitline'lar bosalmis
//   KALIR, yeni satir yalnizca ILAVE bitline bosaltabilir -- sonuc, evaluate
//   boyunca secilmis tum satirlarin bit-bazli AND'idir. 1'ler geri gelmez.
//
// GEOMETRI : {words} kelime x {width} bit, words_per_row {wpr}
//            adres {addr_bits} bit, {rows} satir x {cols} kolon
// ZAMANLAMA: {corner} kosesi (en kotu). Kaynak: {libname}
//
// SADECE SIMULASYON. Sentezlenmez; ASIC akisi {macro}_bbox.v (blackbox) okur.
// ---------------------------------------------------------------------------
`timescale 1ns / 1ps

module {macro} (
`ifdef USE_POWER_PINS
    inout  vccd1,
    inout  vssd1,
`endif
    input  wire        clk0,
    input  wire        cs0,
    input  wire [{amsb}:0] addr0,
    output wire [{dmsb}:0] dout0
  );

  parameter DEPTH     = {words};
  parameter WIDTH     = {width};
  parameter INIT_FILE = "rom_configs/{macro}.bin";

  // OLCULEN degerler -- {libname}
  parameter real ACCESS_NS = {access};   // clk0 yukselen -> dout0 gecerli
  parameter real T_PRE_NS  = {t_pre};   // clk0 dusuk fazi en az bu kadar
  parameter real SETUP_NS  = {setup};   // addr0/cs0, clk0 yukselmeden once

  // 1 = ihlalleri $error ile bildir. Bozulma her halukarda uygulanir --
  // silikonda olan budur; testin bozuk sonucu kendi yakalamasi beklenir.
  parameter REPORT = 1;

  reg [WIDTH-1:0] mem [0:DEPTH-1];

  initial begin
    if (INIT_FILE != "") $readmemb(INIT_FILE, mem);
  end

  // Bitline durumu: on-sarjda tumu 1, evaluate sirasinda yalnizca 1 -> 0.
  reg [WIDTH-1:0] bl;
  reg             evaluating;
  reg             ready;        // access suresi doldu mu
  time            t_eval, t_fall, t_addr_chg;

  initial begin
    bl         = {{WIDTH{{1'b1}}}};
    evaluating = 1'b0;
    ready      = 1'b0;
    t_eval     = 0;
    t_fall     = 0;
    t_addr_chg = 0;
  end

  always @(addr0) t_addr_chg = $time;

  // --- ON-SARJ: clk0 dusuk YA DA cs0 dusuk ---------------------------------
  always @(negedge clk0 or negedge cs0) begin
    // EVALUATE FAZI ACCESS'TEN KISAYSA veri hic gecerli olmaz ve dout0
    // on-sarj degerinde (tumu 1) kalir. Bu SESSIZ bir hatadir -- cikti
    // makul gorunur, sadece hep 0xFF'tir -- o yuzden acikca bildiriliyor.
    if (REPORT && evaluating && !ready)
      $display("HATA %0t %m: evaluate fazi ACCESS'ten KISA -- yuksek faz %0t, gereken %.3f ns. dout0 hic gecerli olmadi (on-sarj degerinde kaldi).",
               $time, $time - t_eval, ACCESS_NS);
    evaluating = 1'b0;
    ready      = 1'b0;
    bl         = {{WIDTH{{1'b1}}}};
    t_fall     = $time;
  end

  // --- DEGERLENDIRME -------------------------------------------------------
  always @(posedge clk0) begin
    if (cs0 === 1'b1) begin
      if (REPORT && t_fall > 0 && ($time - t_fall) < T_PRE_NS)
        $display("HATA %0t %m: on-sarj fazi KISA (%0t, gereken %.3f ns) -- bitline'lar tam dolmadi",
                 $time, $time - t_fall, T_PRE_NS);
      if (REPORT && t_addr_chg > 0 && ($time - t_addr_chg) < SETUP_NS)
        $display("HATA %0t %m: addr0 SETUP ihlali (adres %0t'de degisti, gereken %.3f ns) -- yanlis wordline acilabilir",
                 $time, t_addr_chg, SETUP_NS);

      t_eval     = $time;
      evaluating = 1'b1;
      bl         = bl & mem[addr0];

      // dout0 ancak access dolunca gecerli olur. Bu blok ACCESS_NS bekler;
      // periyot access'ten kisaysa bir sonraki kenar kacirilir -- o zaten
      // minimum_period ihlalidir ve yukarida bildirilir.
      #(ACCESS_NS);
      if (clk0 === 1'b1 && cs0 === 1'b1 && evaluating) ready = 1'b1;
    end
  end

  // --- EVALUATE SIRASINDA ADRES DEGISIRSE ----------------------------------
  always @(addr0) begin
    if (evaluating && cs0 === 1'b1 && clk0 === 1'b1) begin
      if (REPORT)
        $display("HATA %0t %m: addr0 evaluate SIRASINDA degisti (clk0 %0t'de yukselmisti) -- bitline'lar kalici bozuluyor, okuma satirlarin AND'i olacak",
                 $time, t_eval);
      bl = bl & mem[addr0];
    end
  end

  // --- CIKIS ---------------------------------------------------------------
  // On-sarjda ve access dolmadan once bitline'lar VDD'de -> tumu 1.
  assign dout0 = ready ? bl : {{WIDTH{{1'b1}}}};

endmodule
'''


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("macros", nargs="*", help="varsayilan: wrom0..wrom3")
    ap.add_argument("--corner", default=DEFAULT_CORNER,
                    help="zamanlama degerlerinin alinacagi kose (varsayilan: %s)" % DEFAULT_CORNER)
    args = ap.parse_args()

    names = args.macros or ["wrom%d" % k for k in range(4)]
    # find_worst_column.py ciktisiyla ayni kaynak: netlistten sayilir.
    sys.path.insert(0, HERE)
    try:
        from find_worst_column import analyse
    except Exception:
        analyse = None

    rc = 0
    for macro in names:
        mdir = os.path.join(MACROS, macro)
        if not os.path.isdir(mdir):
            print("%-7s dizin yok, atlandi" % macro, file=sys.stderr)
            rc = 1
            continue

        libname = "%s_%s.lib" % (macro, args.corner)
        access, t_pre, setup = read_lib_timing(os.path.join(mdir, libname))
        words, width, addr_bits, wpr = read_geometry(mdir, macro)

        missing = [n for n, v in (("access", access), ("t_pre", t_pre), ("setup", setup))
                   if v is None]
        if missing:
            print("%-7s UYARI: %s degeri %s'ten okunamadi -- lib henuz uretilmemis olabilir. ATLANDI."
                  % (macro, ",".join(missing), libname), file=sys.stderr)
            rc = 1
            continue
        if not (words and width and addr_bits):
            print("%-7s UYARI: geometri okunamadi (.v/.lef eksik). ATLANDI." % macro,
                  file=sys.stderr)
            rc = 1
            continue

        wcol = chain = rows = cols = "?"
        if analyse:
            r = analyse(os.path.join(mdir, macro + ".sp"))
            if r:
                rows, cols, wcol, chain = r[0], r[1], r[2], r[3]

        out = TEMPLATE.format(
            macro=macro, sig=SIGNATURE, corner=args.corner, libname=libname,
            words=words, width=width, wpr=wpr, addr_bits=addr_bits,
            rows=rows, cols=cols, wcol=wcol, chain=chain,
            amsb=addr_bits - 1, dmsb=width - 1,
            access="%.4f" % access, t_pre="%.4f" % t_pre, setup="%.4f" % setup)

        path = os.path.join(mdir, macro + ".v")
        open(path, "w").write(out)
        print("%-7s yazildi: %s  (access %.4f / t_pre %.4f / setup %.4f ns, %s)"
              % (macro, os.path.relpath(path, REPO), access, t_pre, setup, args.corner))

    return rc


if __name__ == "__main__":
    sys.exit(main())
