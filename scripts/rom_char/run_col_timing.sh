#!/bin/sh
# KOLON ZAMANLAMASI: en kotu kolonun bitline bosalma (t_dis_50/t_dis_10) ve
# on-sarj (t_pre_90/t_pre_99) sureleri, uc kosede.
#
# Bu adim akisin cekirdegi: .lib'deki access'in ORTA terimi ve t_pre
# dogrudan buradan gelir (regen_rom_libs.sh bu loglari okur).
#
# NE YAPAR
#   1) TT deck'ini uretir + kosar   (gen_col_tb_parasitic.py -- ayni zamanda
#      en kotu kolonu netlistten kendi bulur, graf yuruyusuyle)
#   2) SS/FF varyantlarini uretir   (make_corner_variant.py -- devre BIREBIR
#      ayni, yalnizca model/VDD/sicaklik degisir) ve kosar
#
# ON KOSUL: <makro>_cap_only.spice (run_cap_extract.sh)
#
# Kullanim: scripts/rom_char/run_col_timing.sh [makro ...]

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
export NGSPICE_BIN="$NG"

for m in $(macro_list "$@"); do
  load_geom "$m" || continue
  echo "== $m  (en kotu kolon $G_WORST_COL, seri NMOS $G_CHAIN) =="
  python3 "$ROM_CHAR_DIR/gen_col_tb_parasitic.py" "$m" "$G_WORST_COL"
  for c in ss ff; do
    python3 "$ROM_CHAR_DIR/make_corner_variant.py" "$m" "$G_WORST_COL" "$c" >/dev/null
    sp="$G_CHAR/${G_COLTAG}_worst_case_parasitic_${c}.sp"
    lg="$G_CHAR/${G_COLTAG}_worst_case_parasitic_${c}.log"
    $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true
    printf "%s %s t_dis_50 = %s   t_pre_99 = %s\n" "$m" "$c" \
      "$(meas "$lg" t_dis_50)" "$(meas "$lg" t_pre_99)"
  done
done
