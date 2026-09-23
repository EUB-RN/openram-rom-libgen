#!/bin/sh
# BACK END delay (bitline -> dout0), three corners x three output loads.
#
# WHY: `access` in the .lib is clk0 -> dout0, while the column deck measures
# only the bitline discharge (t_dis_50, triggered off the internal `precharge`
# net). The three stages in between -- bitline inverter, column mux and output
# buffer -- are measured here. The bitline falls so slowly (~52 mV/ns for
# wrom0 at TT) that this term cannot be guessed.
#
# Running it once per load also makes the index_2 (output load) axis of the
# .lib CELL_TABLE a real measurement.
#
# Total:  access = t_clk2pre                  [run_periphery_power.sh]
#                                             (not max(t_clk2wl, t_clk2pre):
#                                              no wordline rises in evaluate,
#                                              the selected one FALLS and the
#                                              read-0 cell it gates is a
#                                              strap, so it is not in series)
#                + t_dis_50                   [col*_worst_case_parasitic]
#                + t_bl2dout                  [THIS script]
#
# The worst column comes from the netlist (rom_paths.py).
#
# Usage: scripts/rom_char/run_backend_delay.sh [macro ...]

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
ng_reset          # clear the failure ledger for this run
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
    [ -z "$d50" ] && { echo "$m $c: no t_dis_50 ($src)"; continue; }
    for cl in $LOADS; do
      tag=$(echo "$cl" | tr -d '.')
      sp="$G_CHAR/backend_${c}_${tag}.sp"
      lg="$G_CHAR/backend_${c}_${tag}.log"
      python3 "$GEN" "$m" "$G_WORST_COL" "$sp" --t-dis-50 "$d50" --t-dis-10 "$d10" \
              --corner "$c" --vdd "$v" --temp "$t" --load-ff "$cl" >/dev/null
      run_ng "backend-delay" "$sp" "$lg" "$m $c load=$tag" &
      n=$((n+1))
      [ $((n % JOBS)) -eq 0 ] && wait
    done
  done
done
wait

echo
printf "%-7s %-6s %10s %14s %14s\n" macro corner "load(fF)" "t_bl2dout(ns)" "dout_slew(ns)"
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
        printf "%-7s %-6s %10s %14s\n" "$m" "$c" "$cl" "FAILED"
      else
        # awk, not python -c: nested quotes inside an f-string break the here-doc
        echo "$d $sl" | awk -v m="$m" -v c="$c" -v cl="$cl" \
          '{printf "%-7s %-6s %10s %14.4f %14.4f\n", m, c, cl, $1*1e9, $2*1e9}'
      fi
    done
  done
done

# Non-zero if any deck died. The numbers those decks would have produced
# are simply absent otherwise, and absent is indistinguishable from fine.
ng_summary
