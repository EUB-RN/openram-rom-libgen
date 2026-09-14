#!/bin/sh
# wrom0..wrom3 icin 3 kosenin .lib dosyalarini OLCULEN degerlerle uretir.
#
# ZAMANLAMA (access = uc terim, hepsi olculdu):
#   1) on uc   clk0 -> precharge : char/periph_active_<kose>.log  t_clk2pre
#   2) bitline precharge -> bl%50: char/col<N>_worst_case_parasitic*.log
#   3) arka uc bitline -> dout0  : char/backend_<kose>_<yuk>.log   t_bl2dout
#   cikis egimi                  : ayni dosya, t_dout_slew
# SIZINTI: char/col<N>_leak_<kose>.log   (.op, gmin=1e-15, 2026-09-05)
# ENERJI : kolon dizisi  264 x char/col<N>_energy_<kose>.log  e_col_pj
#          + cevre birimi char/periph_active_<kose>.log       e_periph_pj
#   bosta  (when "!cs0")         : char/periph_idle_<kose>.log   e_periph_pj
#
# 1, 3, cevre enerjisi ve cikis egimi 2026-09-06'da eklendi; oncesinde
# access yalnizca ORTA terimi kapsiyordu, egim sabit tahmindi ve bosta guc
# hic yazilmadigi icin OpenSTA onu sessizce 0 sayiyordu.
#
# Zamanlama/egim/cevre enerjisi log dosyalarindan OKUNUR -- elle kopyalanan
# tek sayi kalmasin diye. Yalnizca access/t_pre (2026-09-01 kosumu) ve
# sizinti (.op, tek satirlik olcum degil) asagida sabit duruyor.
#
# --measured SART: degerler zaten koseye ait, CORNERS tablosundaki dscale
# carpani UYGULANMAMALI (yoksa cift sayim -> SS 38 yerine 70 ns cikar).
#
# Kullanim: asic/scripts/rom_char/regen_rom_libs.sh

set -e
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$REPO_ROOT"
GEN=asic/scripts/rom_char/gen_rom_lib.py
LOADS="17225 689 2756"          # .lib CELL_TABLE index_2 (1.7225/6.89/27.56 fF)

# bir ngspice .measure satirindan degeri ceker
meas() { grep -m1 "^$2 " "$1" | awk '{print $3}'; }

# virgullu ns listesi: $1=makro $2=kose $3=olcum adi
be_list() {
  out=""
  for t in $LOADS; do
    v=$(meas "asic/macros/$1/char/backend_${2}_${t}.log" "$3")
    [ -z "$v" ] && { echo ""; return; }
    out="${out:+$out,}$(echo "$v" | awk '{printf "%.4f", $1*1e9}')"
  done
  echo "$out"
}

# macro:kolon:zincir:TT_acc:TT_pre:SS_acc:SS_pre:FF_acc:FF_pre  (ns)
# ardindan  :TT_leak:SS_leak:FF_leak (mW)
#
# 2026-09-08 -- makrolar word_size=4 (32 bit) / words_per_row=10 ile YENIDEN
# URETILDI. Onceki tablo 4256x8'lik makrolara aitti ve TAMAMEN gecersiz:
#   geometri  264 kolon x 129 satir  ->  320 kolon x 107 satir
#   en kotu zincir  85  ->  79/76/76/72   (find_worst_column.py ile sayildi)
#   en kotu kolon   155/67/83/116  ->  54/1/42/9
# Zincir kisaldigi icin bitline terimi SS'de %24-32 dustu.
#
# acc  = t_dis_50   (col<N>_worst_case_parasitic*.log)
# pre  = t_pre_99   (ayni log)  -- t_pre_90 DEGIL: o %90 geri sarj, ~0.5 ns
#        cikar ve min_pulse_width(fall) 20x kucuk yazilir.
# leak = P_256kol   (run_col_power.sh ciktisi, uW -> mW)
#
# 2026-09-08: words_per_row 10 -> 8 ile makro yeniden uretildi.
#   geometri  320 kolon x 106 satir  ->  256 kolon x 133 satir
#   1064 = 8 x 133 tam bolundugu icin kelime kaybi yok; 8 = 2^3 oldugu
#   icin adres bosluksuz (kelime indeksi = adres).
# Zincir uzadigi icin access buyudu (SS: 29.0 -> 39.4 .. 43.1 ns).
# Kolonlar da bu turda ILK KEZ dogru secildi: find_worst_column.py
# `.SUBCKT` kapsami yapmiyordu ve satir/kolon kod cozucu hucrelerini de
# sayiyordu, bu yuzden wrom1/wrom2 gercek en kotu kolondan karakterize
# EDILMEMISTI.
for row in \
  "wrom0:236:82:14.3346:12.1075:39.3750:13.6493:6.9559:9.4864:0.0001687:0.0002966:0.0000759" \
  "wrom1:214:88:15.1367:11.5232:41.5402:11.5465:7.3618:9.2593:0.0001687:0.0002944:0.0000759" \
  "wrom2:236:91:15.6778:11.7197:43.0865:12.0234:7.5827:9.4309:0.0001687:0.0002934:0.0000759" \
  "wrom3:10:77:14.0025:11.8543:38.6963:15.0009:6.7637:8.8687:0.0001687:0.0002983:0.0000759" \
; do
  m=$(echo  "$row" | cut -d: -f1);  col=$(echo "$row" | cut -d: -f2)
  chain=$(echo "$row" | cut -d: -f3)
  LEF="asic/macros/$m/$m.lef"
  SRC="gercek Magic parazitik C + o kosenin KENDI sky130 modeli; on uc+cevre gucu char/periph_{active,idle}_*.log (2026-09-06), bitline char/col${col}_worst_case_parasitic*.log (2026-09-01), arka uc+egim char/backend_*.log (2026-09-06), sizinti char/col${col}_leak_*.log (2026-09-05), kolon enerjisi char/col${col}_energy_*.log (2026-09-05)"

  for ck in "tt:TT_1p8V_25C:4:5:10" "ss:SS_1p6V_100C:6:7:11" "ff:FF_1p95V_n40C:8:9:12"; do
    c=$(echo "$ck" | cut -d: -f1); corner=$(echo "$ck" | cut -d: -f2)
    acc=$(echo "$row" | cut -d: -f"$(echo "$ck" | cut -d: -f3)")
    pre=$(echo "$row" | cut -d: -f"$(echo "$ck" | cut -d: -f4)")
    leak=$(echo "$row" | cut -d: -f"$(echo "$ck" | cut -d: -f5)")

    PA="asic/macros/$m/char/periph_active_${c}.log"
    PI="asic/macros/$m/char/periph_idle_${c}.log"
    EC="asic/macros/$m/char/col${col}_energy_${c}.log"

    # 1) on uc: clk0 -> precharge. Kolon olcumu TRIG'i ic precharge agindan
    #    aldigi icin bu terim access'te EKSIKTI. (wl yolu t_clk2wl0 ile
    #    capraz kontrol edildi: uc kosede de precharge yolundan HIZLI, yani
    #    kritik olan precharge.)
    tf=$(meas "$PA" t_clk2pre | awk '{printf "%.4f", $1*1e9}')
    # 3) arka uc: bitline -> dout0 + cikis egimi, uc yuk noktasinda
    be=$(be_list "$m" "$c" t_bl2dout)
    sl=$(be_list "$m" "$c" t_dout_slew)
    # enerji: kolon dizisi (264 kolon) + cevre birimi
    e_act=$(awk -v ec="$(meas "$EC" e_col_pj)" -v ep="$(meas "$PA" e_periph_pj)" \
                'BEGIN{printf "%.4f", 256*ec + ep}')
    e_idle=$(meas "$PI" e_periph_pj | awk '{printf "%.4f", $1}')

    if [ -z "$tf" ] || [ -z "$be" ] || [ -z "$sl" ] || [ -z "$e_idle" ]; then
      echo "$m $c: olcum eksik, atlandi"
      continue
    fi

    # setup: ARTIK DOGRUDAN OLCULUYOR (2026-09-08).
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
    stl="asic/macros/$m/char/periph_setup_${c}.log"
    stp=$(awk '/^t_addr2dec[0-9]+/ { if ($3 ~ /^[0-9.eE+-]+$/ && $3+0 > mx) mx = $3+0 }
               END { if (mx > 0) printf "%.4f", mx*1e9 }' "$stl" 2>/dev/null)
    if [ -z "$stp" ]; then
      stp=$(awk -v t="$tf" 'BEGIN{printf "%.4f", 3.0*t}')
      echo "  $m $c: setup olcumu yok -> kotumser sinir $stp ns kullanildi"
    fi

    python3 $GEN --lef "$LEF" --memory-type rom --measured \
      --corner "$corner" --access "$acc" --hold "$acc" --t-pre "$pre" \
      --setup "$stp" \
      --leakage-mw "$leak" --energy-pj "$e_act" --energy-idle-pj "$e_idle" \
      --t-front "$tf" --backend-ns "$be" --out-slew-ns "$sl" \
      --chain-len "$chain" --worst-col "$col" --char-source "$SRC" >/dev/null

    printf "%-7s %-4s access = %.4f + %s + %s = %.4f ns  E=%s pJ  E_bosta=%s pJ\n" \
      "$m" "$c" "$tf" "$acc" "$(echo "$be" | cut -d, -f3)" \
      "$(awk -v a="$tf" -v b="$acc" -v d="$(echo "$be" | cut -d, -f3)" \
            'BEGIN{print a+b+d}')" "$e_act" "$e_idle"
  done
done
echo "Tamam -- 12 .lib olculen zamanlama (on uc + bitline + arka uc), cikis"
echo "egimi, sizinti ve enerji (aktif + bosta) ile uretildi."
