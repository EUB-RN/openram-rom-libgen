#!/bin/sh
# ARKA UC gecikmesi (bitline -> dout0), uc kose x uc yuk.
#
# NEDEN: .lib'deki `access` clk0 -> dout0 suresidir, ama olculen tek sey
# bitline'in bosalmasiydi (t_dis_50, TRIG'i ic `precharge` agindan alan).
# Aradaki uc kademe -- bitline eviricisi, <kolon>:<kelime> mux'u ve cikis
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
# En kotu kolon netlistten turetilir (rom_paths.py); eskiden bu dosyada
# "wrom0:236" tablosu olarak sabitti.
#
# Kullanim: scripts/rom_char/run_backend_delay.sh [makro ...]

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
GEN="$ROM_CHAR_DIR/gen_backend_delay_tb.py"

MACROS=$(macro_list "$@")
n=0
for m in $MACROS; do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    v=$(echo "$ck" | cut -d: -f2); t=$(echo "$ck" | cut -d: -f3)
    [ "$c" = tt ] && sfx="" || sfx="_$c"
    src="$G_CHAR/${G_COLTAG}_worst_case_parasitic${sfx}.log"
    d50=$(meas "$src" t_dis_50)
    d10=$(meas "$src" t_dis_10)
    [ -z "$d50" ] && { echo "$m $c: t_dis_50 yok ($src)"; continue; }
    for cl in $LOADS; do
      tag=$(echo "$cl" | tr -d '.')
      sp="$G_CHAR/backend_${c}_${tag}.sp"
      lg="$G_CHAR/backend_${c}_${tag}.log"
      python3 "$GEN" "$m" "$G_WORST_COL" "$sp" --t-dis-50 "$d50" --t-dis-10 "$d10" \
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
for m in $MACROS; do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    for cl in $LOADS; do
      tag=$(echo "$cl" | tr -d '.')
      lg="$G_CHAR/backend_${c}_${tag}.log"
      d=$(meas "$lg" t_bl2dout)
      sl=$(meas "$lg" t_dout_slew)
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
