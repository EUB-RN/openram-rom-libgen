#!/bin/sh
# COLUMN TIMING: bitline discharge (t_dis_50/t_dis_10) and precharge
# (t_pre_90/t_pre_99) of the worst column, three corners.
#
# This is the core of the flow: the MIDDLE term of `access` and t_pre in the
# .lib come straight from these logs (regen_rom_libs.sh reads them).
#
# WHAT IT DOES
#   1) builds and runs the TT deck   (gen_col_tb_parasitic.py -- which also
#      finds the worst column itself, by walking the netlist graph)
#   2) builds and runs the SS/FF variants (make_corner_variant.py -- exact same
#      circuit, only the models/VDD/temperature change)
#
# PREREQUISITE: <macro>_cap_only.spice (run_cap_extract.sh)
#
# Usage: scripts/rom_char/run_col_timing.sh [macro ...]

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
export NGSPICE_BIN="$NG"

for m in $(macro_list "$@"); do
  load_geom "$m" || continue
  echo "== $m  (worst column $G_WORST_COL, series NMOS $G_CHAIN) =="
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
