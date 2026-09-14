#!/bin/sh
# wrom0..wrom3 icin ARKA UC gecikmesi (bitline -> dout0), uc kose x uc yuk.
#
# NEDEN: .lib'deki `access` clk0 -> dout0 suresidir, ama olculen tek sey
# bitline'in bosalmasiydi (t_dis_50, TRIG'i ic `precharge` agindan alan).
# Aradaki uc kademe -- bitline eviricisi, 264:8 kolon mux'u ve cikis
# tamponu -- hic olculmemisti. Bitline cok yavas dustugu icin (wrom0 TT'de
# ~52 mV/ns) bu terim tahminle gecilemez.
#
# Ayrica bu kosum .lib CELL_TABLE'inin index_2 (cikis yuku) eksenini
# GERCEKTEN olcer; onceki dosyalarda uc yuk noktasi da ayni sayiyi
# tasiyordu.
#
# Toplam:  access = max(t_clk2wl, t_clk2pre)   [run_periphery_power.sh]
#                 + t_dis_50                   [col*_worst_case_parasitic]
#                 + t_bl2dout                  [BU betik]
#
# Kullanim: asic/scripts/rom_char/run_backend_delay.sh [makro ...]

set -e
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$REPO_ROOT"
NG="${NGSPICE_BIN:-/nix/store/4ssrcgdvyb8car0yxay8cwfa5wc89f1w-ngspice-45/bin/ngspice}"
GEN=asic/scripts/rom_char/gen_backend_delay_tb.py
JOBS="${JOBS:-4}"
LOADS="${LOADS:-1.7225 6.89 27.56}"     # .lib CELL_TABLE index_2

WANT="${*:-wrom0 wrom1 wrom2 wrom3}"
n=0
for row in "wrom0:236" "wrom1:214" "wrom2:236" "wrom3:10"; do
  m=${row%%:*}; col=${row##*:}
  echo " $WANT " | grep -q " $m " || continue
  for ck in "tt::1.8:25" "ss:_ss:1.6:100" "ff:_ff:1.95:-40"; do
    c=$(echo  "$ck" | cut -d: -f1); sfx=$(echo "$ck" | cut -d: -f2)
    v=$(echo  "$ck" | cut -d: -f3); t=$(echo   "$ck" | cut -d: -f4)
    src="asic/macros/$m/char/col${col}_worst_case_parasitic${sfx}.log"
    d50=$(grep -m1 "t_dis_50" "$src" | awk '{print $3}')
    d10=$(grep -m1 "t_dis_10" "$src" | awk '{print $3}')
    [ -z "$d50" ] && { echo "$m $c: t_dis_50 yok ($src)"; continue; }
    for cl in $LOADS; do
      tag=$(echo "$cl" | tr -d '.')
      sp="asic/macros/$m/char/backend_${c}_${tag}.sp"
      lg="asic/macros/$m/char/backend_${c}_${tag}.log"
      python3 $GEN "$m" "$col" "$sp" --t-dis-50 "$d50" --t-dis-10 "$d10" \
              --corner "$c" --vdd "$v" --temp "$t" --load-ff "$cl" >/dev/null
      ( $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true ) &
      n=$((n+1))
      [ $((n % JOBS)) -eq 0 ] && wait
    done
  done
done
wait

echo
printf "%-7s %-4s %10s %14s %14s\n" makro kose "yuk(fF)" "t_bl2dout(ns)" "dout_slew(ns)"
for row in "wrom0:236" "wrom1:214" "wrom2:236" "wrom3:10"; do
  m=${row%%:*}
  echo " $WANT " | grep -q " $m " || continue
  for c in tt ss ff; do
    for cl in $LOADS; do
      tag=$(echo "$cl" | tr -d '.')
      lg="asic/macros/$m/char/backend_${c}_${tag}.log"
      d=$(grep -m1 "t_bl2dout" "$lg" 2>/dev/null | awk '{print $3}')
      sl=$(grep -m1 "t_dout_slew" "$lg" 2>/dev/null | awk '{print $3}')
      if [ -z "$d" ]; then
        printf "%-7s %-4s %10s %14s\n" "$m" "$c" "$cl" "OLCULEMEDI"
      else
        # awk kullaniliyor: python -c icinde ic ice tirnak f-string'i bozuyor
        echo "$d $sl" | awk -v m="$m" -v c="$c" -v cl="$cl" \
          '{printf "%-7s %-4s %10s %14.4f %14.4f\n", m, c, cl, $1*1e9, $2*1e9}'
      fi
    done
  done
done
