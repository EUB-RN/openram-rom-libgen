// OpenROM ROM model
// Words: 1064
// Word size: 32
// Word per Row: 8
// Data Type: bin
// Data File: rom_configs/wrom2.bin
//
// ^^^ YUKARIDAKI ALTI SATIR OpenRAM BICIMINDE BIRAKILDI -- SILMEYIN.
// Hem bu betigin kendisi (read_geometry) hem de simulasyon betiklerinin
// .bin donusturucusu (verification/system/gls/lib_gls.sh, run_gls.sh,
// verification/ai/ai_accelerator/run_wrom.sh) kelime genisligini
// "// Word size:" satirindan okuyor. Satir yoksa donusturucu 8 bite duser
// ve her kelimenin yalnizca alt 8 biti yuklenir -- ROM icerigi SESSIZCE
// yanlis olur.
// ---------------------------------------------------------------------------
// wrom2 -- GERCEK DAVRANIS MODELI -- gen_macro_behavioral_v.py
//
// DIKKAT: OpenRAM makroyu her yeniden derlediginde BU DOSYAYI SIFIRDAN YAZAR
// ve asagidaki modeli siler. Yeniden uretim sonrasi geri uygulamak icin:
//     python3 asic/scripts/rom_char/gen_macro_behavioral_v.py wrom2
//
// NEDEN OpenRAM'in KENDI MODELI KULLANILMIYOR
// -------------------------------------------
// OpenRAM'in urettigi model SRAM sablonundan geliyor ve iki sey varsayiyor:
//     "All inputs are registers"                 -> adres iceride kilitlenir
//     always @(negedge clk0) dout0 <= mem[...]    -> veri cevrim boyunca durur
// IKISI DE YANLIS. Bu makronun cikarilmis hucre envanterinde (wrom2/*.ext)
// tek bir dff / latch / sense_amp / replica_column / delay_chain YOK; okuma
// elemani duz bir inverter (rom_bitline_inverter). Ayni OpenRAM'in SRAM'i ise
// row_addr_dff, col_addr_dff, data_dff, sense_amp, replica_column, delay_chain
// hepsini icerir -- o varsayimlar ORADA gecerli, burada degil.
//
// GERCEK DAVRANIS (degerler wrom2'in kendi .lib'inden, ngspice ile OLCULDU)
// ---------------------------------------------------------------------------
//   clk0 = 0 : ON-SARJ. Bitline'lar VDD'ye cekilir -> dout0 = tumu 1.
//              Bu faz en az T_PRE_NS surmeli.
//   clk0 = 1 : DEGERLENDIRME. Secili satirin "0" bitleri bitline'i 91
//              seri NMOS uzerinden bosaltir (en kotu kolon 236).
//              dout0 yukselen kenardan ACCESS_NS sonra gecerli olur.
//   clk0 1->0: on-sarj yeniden baslar, VERI SILINIR.
//   cs0  = 0 : on-sarj SUREKLI acik; bitline'lar VDD'de durur, dout0 = tumu 1.
//              (Netlist: NAND(CS,clk) -> 7 kademeli inverter -> prechrg, ve
//              on-sarj PMOS gate'i dusukken iletir; yani prechrg = CS AND clk.
//              wrom2_rom_control_logic.ext merge zincirinden dogrulandi.)
//
//   GERI DONDURULEMEZ BOSALMA: dizideki her cihaz NMOS; makrodaki tek PMOS
//   on-sarj hucresinde. Bitline'in on-sarj disinda pull-up'i YOK. Evaluate
//   sirasinda adres degisirse eski satirin bosalttigi bitline'lar bosalmis
//   KALIR, yeni satir yalnizca ILAVE bitline bosaltabilir -- sonuc, evaluate
//   boyunca secilmis tum satirlarin bit-bazli AND'idir. 1'ler geri gelmez.
//
// GEOMETRI : 1064 kelime x 32 bit, words_per_row 8
//            adres 11 bit, 134 satir x 256 kolon
// ZAMANLAMA: SS_1p6V_100C kosesi (en kotu). Kaynak: wrom2_SS_1p6V_100C.lib
//
// SADECE SIMULASYON. Sentezlenmez; ASIC akisi wrom2_bbox.v (blackbox) okur.
// ---------------------------------------------------------------------------
`timescale 1ns / 1ps

module wrom2 (
`ifdef USE_POWER_PINS
    inout  vccd1,
    inout  vssd1,
`endif
    input  wire        clk0,
    input  wire        cs0,
    input  wire [10:0] addr0,
    output wire [31:0] dout0
  );

  parameter DEPTH     = 1064;
  parameter WIDTH     = 32;
  parameter INIT_FILE = "rom_configs/wrom2.bin";

  // OLCULEN degerler -- wrom2_SS_1p6V_100C.lib
  parameter real ACCESS_NS = 46.4773;   // clk0 yukselen -> dout0 gecerli
  parameter real T_PRE_NS  = 12.3934;   // clk0 dusuk fazi en az bu kadar
  parameter real SETUP_NS  = 0.0519;   // addr0/cs0, clk0 yukselmeden once

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
    bl         = {WIDTH{1'b1}};
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
    bl         = {WIDTH{1'b1}};
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
  assign dout0 = ready ? bl : {WIDTH{1'b1}};

endmodule
