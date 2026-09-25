#!/bin/sh
# BACK END delay (bitline -> dout0), three corners x three output loads.
#
# WHY: `access` in the .lib is clk0 -> dout0, while the column deck measures
# only the bitline discharge (t_dis_50, triggered off the internal `precharge`
# net). The three stages in between -- bitline inverter, column mux and output
# buffer -- are measured here. The bitline falls so slowly (~125 mV/ns through
# the trip point for wrom0 at TT) that this term cannot be guessed.
#
# The stimulus is not a model of that edge, it IS the edge: this script
# re-runs the column deck with its bitline kept (the measured run throws the
# waveform away, exactly as run_waveform_capture.sh does for the figures) and
# gen_backend_delay_tb.py replays those samples through a PWL source. What
# stood here before was a straight ramp through the measured 50% and 10%
# points; a discharge decelerates, so that secant was 3.3x flatter than the
# real curve at the inverter's trip point and t_bl2dout came out 48% high.
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

# capture_bl <column deck> <out.txt> -- the column deck again, waveform kept.
# wrdata lays one time column down per vector, so the file is
#   time  v(bitline)  time  v(precharge)
# and the precharge column is what lets the generator find the same settled
# discharge t_dis_50 was measured on, without either side counting cycles.
# Cached on mtime: this costs a full column run (~2 min a corner) and the
# waveform only changes when the deck does.
capture_bl() {
  _deck="$1"; _out="$2"
  [ -f "$_deck" ] || { echo "$m $c: no $(basename "$_deck") -- run run_col_timing.sh first" >&2; return 1; }
  [ -f "$_out" ] && [ "$_out" -nt "$_deck" ] && return 0
  # the bitline node is named after its instance and changes with the macro,
  # so it is read out of the deck rather than spelled here
  _bl=$(grep -i '^\.ic  *v(' "$_deck" | head -1 | sed 's/.*[vV](\([^)]*\)).*/\1/')
  [ -n "$_bl" ] || { echo "$m $c: no .ic bitline node in $(basename "$_deck")" >&2; return 1; }
  _tmp="${_out%.txt}.sp"
  awk -v sav=".save v($_bl) v(precharge)" \
      -v wr="wrdata $_out v($_bl) v(precharge)" '
    /^\.end$/ && !seen { print sav; print ".control"; print "run"; print wr;
                         print ".endc"; seen = 1 }
    { print }' "$_deck" > "$_tmp"
  echo "  $m $c: capturing the bitline waveform (v($_bl))"
  run_ng "bl-capture" "$_tmp" "${_out%.txt}.log" "$m $c" || return 1
  [ -s "$_out" ] || { echo "$m $c: ngspice wrote no samples to $_out" >&2; return 1; }
}

MACROS=$(macro_list "$@")
n=0
for m in $MACROS; do
  load_geom "$m" || continue
  WAVE="$G_CHAR/wave"; mkdir -p "$WAVE"
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    v=$(echo "$ck" | cut -d: -f2); t=$(echo "$ck" | cut -d: -f3)
    [ "$c" = tt ] && sfx="" || sfx="_$c"
    src="$G_CHAR/${G_COLTAG}_worst_case_parasitic${sfx}.log"
    [ -z "$(meas "$src" t_dis_50)" ] && { echo "$m $c: no t_dis_50 ($src)"; continue; }
    wave="$WAVE/bl_${c}.txt"
    capture_bl "$G_CHAR/${G_COLTAG}_worst_case_parasitic${sfx}.sp" "$wave" || continue
    for cl in $LOADS; do
      tag=$(echo "$cl" | tr -d '.')
      sp="$G_CHAR/backend_${c}_${tag}.sp"
      lg="$G_CHAR/backend_${c}_${tag}.log"
      python3 "$GEN" "$m" "$G_WORST_COL" "$sp" --bl-wave "$wave" \
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
