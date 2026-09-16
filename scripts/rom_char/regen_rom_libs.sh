#!/bin/sh
# Agactaki TUM ROM makrolari icin 3 kosenin .lib dosyalarini OLCULEN
# degerlerle uretir.  Kullanim:
#     scripts/rom_char/regen_rom_libs.sh [makro ...]
#     ROM_MACROS_DIR=/yol/asic/macros scripts/rom_char/regen_rom_libs.sh
#
# ZAMANLAMA (access = uc terim, hepsi olculdu):
#   1) on uc   clk0 -> precharge : char/periph_active_<kose>.log  t_clk2pre
#   2) bitline precharge -> bl%50: char/col<N>_worst_case_parasitic*.log
#   3) arka uc bitline -> dout0  : char/backend_<kose>_<yuk>.log   t_bl2dout
#   cikis egimi                  : ayni dosya, t_dout_slew
# SIZINTI: char/col<N>_leak_<kose>.log   (.op tablosundaki vvdd#branch)
# ENERJI : kolon dizisi  <kolon_sayisi> x char/col<N>_energy_<kose>.log e_col_pj
#          + cevre birimi           char/periph_active_<kose>.log  e_periph_pj
#   bosta  (when "!cs0")           : char/periph_idle_<kose>.log   e_periph_pj
# SETUP  : char/periph_setup_<kose>.log  t_addr2dec* (en kotusu)
#
# 1, 3, cevre enerjisi ve cikis egimi 2026-09-06'da eklendi; oncesinde
# access yalnizca ORTA terimi kapsiyordu, egim sabit tahmindi ve bosta guc
# hic yazilmadigi icin OpenSTA onu sessizce 0 sayiyordu.
#
# TUM SAYILAR LOG DOSYALARINDAN OKUNUR -- elle kopyalanan tek sayi yok.
# Onceki surumde makro adlari, en kotu kolon/zincir ve access/t_pre/sizinti
# degerleri bu dosyada bir TABLO olarak duruyordu; ROM yeniden uretilince
# (word_size / words_per_row / .bin degisince) tablo sessizce gecersiz
# kaliyordu. Artik:
#   * makro listesi     <- agactaki <makro>/<makro>.sp dizinleri
#   * en kotu kolon     <- netlist taramasi (rom_paths.py / find_worst_column)
#   * zincir uzunlugu   <- ayni tarama
#   * kolon sayisi      <- ayni tarama (enerji/sizinti carpani; eskiden 256)
#   * access / t_pre    <- col<N>_worst_case_parasitic*.log (t_dis_50/t_pre_99)
#   * sizinti           <- col<N>_leak_<kose>.log
#
# t_pre icin t_pre_99 kullanilir, t_pre_90 DEGIL: %90 geri sarj ~0.5 ns
# cikar ve min_pulse_width(fall) 20x kucuk yazilir.
#
# --measured SART: degerler zaten koseye ait, CORNERS tablosundaki dscale
# carpani UYGULANMAMALI (yoksa cift sayim -> SS 38 yerine 70 ns cikar).

set -e
. "$(dirname "$0")/common.sh"

GEN="$ROM_CHAR_DIR/gen_rom_lib.py"

# .lib CELL_TABLE index_2 noktalarinin dosya adi etiketi (1.7225 -> 17225)
load_tags() { for cl in $LOADS; do echo "$cl" | tr -d '.'; done; }

# virgullu ns listesi: $1=char dizini $2=kose $3=olcum adi
be_list() {
  out=""
  for t in $(load_tags); do
    v=$(meas "$1/backend_${2}_${t}.log" "$3")
    [ -z "$v" ] && { echo ""; return; }
    out="${out:+$out,}$(echo "$v" | awk '{printf "%.4f", $1*1e9}')"
  done
  echo "$out"
}

for m in $(macro_list "$@"); do
  load_geom "$m" || { echo "$m: geometri okunamadi, atlandi"; continue; }
  col="$G_WORST_COL"
  LEF="$G_LEF"

  for ck in $CORNERS; do
    c=$(echo  "$ck" | cut -d: -f1)
    vdd=$(echo "$ck" | cut -d: -f2)
    corner=$(corner_lib_name "$c")
    # TT dosyasi soneksiz, digerleri _ss / _ff
    [ "$c" = tt ] && sfx="" || sfx="_$c"

    PAR="$G_CHAR/${G_COLTAG}_worst_case_parasitic${sfx}.log"
    PA="$G_CHAR/periph_active_${c}.log"
    PI="$G_CHAR/periph_idle_${c}.log"
    EC="$G_CHAR/${G_COLTAG}_energy_${c}.log"
    LK="$G_CHAR/${G_COLTAG}_leak_${c}.log"

    # 2) bitline terimi + on-sarj suresi (o kosenin kendi kosumu)
    acc=$(meas "$PAR" t_dis_50 | awk '{printf "%.4f", $1*1e9}')
    pre=$(meas "$PAR" t_pre_99 | awk '{printf "%.4f", $1*1e9}')

    # sizinti: .measure degil, .op tablosundaki besleme akimi.
    # P = |I| x <kolon sayisi> x VDD  -> mW
    leak=$(grep -m1 "vvdd#branch" "$LK" 2>/dev/null | awk -v n="$G_COLS" -v v="$vdd" \
             '{ i = $2 < 0 ? -$2 : $2; printf "%.7f", i*n*v*1e3 }')

    # 1) on uc: clk0 -> precharge. Kolon olcumu TRIG'i ic precharge agindan
    #    aldigi icin bu terim access'te EKSIKTI. (wl yolu t_clk2wl0 ile
    #    capraz kontrol edildi: uc kosede de precharge yolundan HIZLI, yani
    #    kritik olan precharge.)
    tf=$(meas "$PA" t_clk2pre | awk '{printf "%.4f", $1*1e9}')
    # 3) arka uc: bitline -> dout0 + cikis egimi, uc yuk noktasinda
    be=$(be_list "$G_CHAR" "$c" t_bl2dout)
    sl=$(be_list "$G_CHAR" "$c" t_dout_slew)
    # enerji: kolon dizisi (G_COLS kolon) + cevre birimi
    e_act=$(awk -v n="$G_COLS" -v ec="$(meas "$EC" e_col_pj)" \
                -v ep="$(meas "$PA" e_periph_pj)" \
                'BEGIN{ if (ec == "" || ep == "") exit 1; printf "%.4f", n*ec + ep }') || e_act=""
    e_idle=$(meas "$PI" e_periph_pj | awk '{printf "%.4f", $1}')

    # eksik olcum = sessiz yanlis .lib. Hangi terimin eksik oldugunu SOYLE.
    missing=""
    for pair in "acc:$acc" "pre:$pre" "leak:$leak" "tf:$tf" "be:$be" \
                "sl:$sl" "e_act:$e_act" "e_idle:$e_idle"; do
      if [ -z "${pair#*:}" ]; then
        missing="${missing:+$missing, }${pair%%:*}"
      fi
    done
    if [ -n "$missing" ]; then
      echo "$m $c: eksik olcum ($missing) -- atlandi"
      continue
    fi

    # setup: DOGRUDAN OLCULUYOR (2026-09-08).
    # run_addr_setup.sh, addr0'i on-sarj fazinda gecirip
    #   addr0 -> inv_array_mod/Z  (= kod cozucu NAND'inin A girisi)
    # gecikmesini olcer; adres bit basina tamponun EN KOTUSU alinir.
    # Kod cozucu SAATLI NAND oldugu icin adresin kararli olmasi gereken son
    # nokta tam olarak burasidir.
    #
    # Onceki hal 3 x t_clk2pre analitik ust siniriydi (SS'de ~4.93 ns);
    # olculen deger SS'de 0.053 ns cikti, yani sinir ~90x kotumserdi.
    # Olcum yoksa (log uretilmemisse) o kotumser sinira DUSULUR -- sessizce
    # kucuk bir sayi yazmaktansa buyuk yazmak guvenli taraftir.
    stl="$G_CHAR/periph_setup_${c}.log"
    stp=$(awk '/^t_addr2dec[0-9]+/ { if ($3 ~ /^[0-9.eE+-]+$/ && $3+0 > mx) mx = $3+0 }
               END { if (mx > 0) printf "%.4f", mx*1e9 }' "$stl" 2>/dev/null)
    if [ -z "$stp" ]; then
      stp=$(awk -v t="$tf" 'BEGIN{printf "%.4f", 3.0*t}')
      echo "  $m $c: setup olcumu yok -> kotumser sinir $stp ns kullanildi"
    fi

    SRC="gercek Magic parazitik C + o kosenin KENDI sky130 modeli; \
${G_ROWS}x${G_COLS} dizi, en kotu kolon ${col} (seri NMOS ${G_CHAIN}); \
on uc+cevre gucu char/periph_{active,idle}_${c}.log, \
bitline char/${G_COLTAG}_worst_case_parasitic${sfx}.log, \
arka uc+egim char/backend_${c}_*.log, \
sizinti char/${G_COLTAG}_leak_${c}.log, \
kolon enerjisi char/${G_COLTAG}_energy_${c}.log"

    python3 "$GEN" --lef "$LEF" --memory-type rom --measured \
      --corner "$corner" --access "$acc" --hold "$acc" --t-pre "$pre" \
      --setup "$stp" \
      --leakage-mw "$leak" --energy-pj "$e_act" --energy-idle-pj "$e_idle" \
      --t-front "$tf" --backend-ns "$be" --out-slew-ns "$sl" \
      --chain-len "$G_CHAIN" --worst-col "$col" --char-source "$SRC" >/dev/null

    printf "%-7s %-4s access = %.4f + %s + %s = %.4f ns  E=%s pJ  E_bosta=%s pJ\n" \
      "$m" "$c" "$tf" "$acc" "$(echo "$be" | cut -d, -f3)" \
      "$(awk -v a="$tf" -v b="$acc" -v d="$(echo "$be" | cut -d, -f3)" \
            'BEGIN{print a+b+d}')" "$e_act" "$e_idle"
  done
done
echo "Tamam -- .lib dosyalari olculen zamanlama (on uc + bitline + arka uc),"
echo "cikis egimi, sizinti ve enerji (aktif + bosta) ile uretildi."
