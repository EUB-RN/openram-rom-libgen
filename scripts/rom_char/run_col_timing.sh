#!/bin/sh
# COLUMN TIMING: bitline discharge (t_dis_50/t_dis_10) and precharge
# (t_pre_90/t_pre_99) of the worst column, three corners.
#
# This is the core of the flow: the MIDDLE term of `access` and t_pre in the
# .lib come straight from these logs (regen_rom_libs.sh reads them).
#
# WHAT IT DOES
#   0) builds the per-cell wire resistance model (gen_resistance_model.py --
#      Magic on a single cell, analytic where Magic segfaults). The column deck
#      needs it: wire resistance is included by default and moves the bitline
#      term by +15% (tt) / +6.6% (ss) / +28% (ff).
#   1) builds and runs the TT deck   (gen_col_tb_parasitic.py -- which also
#      finds the worst column itself, by walking the netlist graph)
#   2) builds and runs the SS/FF variants (make_corner_variant.py -- exact same
#      circuit, only the models/VDD/temperature change)
#
# PREREQUISITE: <macro>_cap_only.spice (run_cap_extract.sh)
# Set NO_RESISTANCE=1 to build the capacitance-only decks instead.
#
# Usage: scripts/rom_char/run_col_timing.sh [macro ...]

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
ng_reset          # clear the failure ledger for this run
export NGSPICE_BIN="$NG"

# The bitline term has its own settling proof: the deck measures t_dis_50 on
# the last cycle and t_dis_50_prev on the one before, and they must agree.
# gen_col_tb_parasitic.py printed a WARNING about it and nothing acted on the
# warning; worse, it only ran for TT, because the SS/FF decks are built by
# make_corner_variant.py and run straight from here. This turns both halves
# into the same failure every other unsettled deck gets.
col_settled() {
  _d=$(meas "$3" t_dis_50); _p=$(meas "$3" t_dis_50_prev)
  [ -n "$_d" ] && [ -n "$_p" ] || return 0
  _g=$(awk -v a="$_d" -v b="$_p" 'BEGIN{ d=(a-b); if (d<0) d=-d;
         printf "%.2f", a ? d/a*100 : 0 }')
  check_settled "col-timing" "$3" "$1 $2" "$_g" "$4" || true
}

for m in $(macro_list "$@"); do
  load_geom "$m" || continue
  echo "== $m  (worst column $G_WORST_COL, series NMOS $G_CHAIN) =="
  if [ "${NO_RESISTANCE:-0}" = 1 ]; then
    RFLAG=--no-resistance
  else
    RFLAG=""
    python3 "$ROM_CHAR_DIR/gen_resistance_model.py" "$m" || {
      echo "  $m: resistance model failed -- falling back to capacitance only"
      RFLAG=--no-resistance
    }
  fi
  python3 "$ROM_CHAR_DIR/gen_col_tb_parasitic.py" "$m" "$G_WORST_COL" $RFLAG
  # The TT deck is built AND RUN by the generator, so its log never passes
  # through run_ng and would carry no provenance stamp -- which downstream
  # means "not from this flow" and is refused. Judge and stamp it here by the
  # same rules run_ng applies to the SS/FF decks below.
  prov_adopt "col-timing" "$G_CHAR/${G_COLTAG}_worst_case_parasitic.sp" \
             "$G_CHAR/${G_COLTAG}_worst_case_parasitic.log" "$m tt" || true
  for c in ss ff; do
    python3 "$ROM_CHAR_DIR/make_corner_variant.py" "$m" "$G_WORST_COL" "$c" >/dev/null
    sp="$G_CHAR/${G_COLTAG}_worst_case_parasitic_${c}.sp"
    lg="$G_CHAR/${G_COLTAG}_worst_case_parasitic_${c}.log"
    run_ng "col-timing" "$sp" "$lg" "$m $c" || continue
    printf "%s %s t_dis_50 = %s   t_pre_99 = %s\n" "$m" "$c" \
      "$(meas "$lg" t_dis_50)" "$(meas "$lg" t_pre_99)"
    col_settled "$m" "$c" "$lg" "$sp"
  done
  # The TT deck is run by the generator above, which prints its own settling
  # verdict but only WARNS. Gate it here with the same rule the corner decks
  # get, so all three are judged alike -- SS is the corner most at risk, being
  # 2.4x slower, and it was the one with no check at all.
  col_settled "$m" "tt" "$G_CHAR/${G_COLTAG}_worst_case_parasitic.log" \
                        "$G_CHAR/${G_COLTAG}_worst_case_parasitic.sp"
done

# Non-zero if any deck died. The numbers those decks would have produced
# are simply absent otherwise, and absent is indistinguishable from fine.
ng_summary
