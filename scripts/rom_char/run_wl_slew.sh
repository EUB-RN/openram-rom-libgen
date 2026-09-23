#!/bin/sh
# HOW FAST DOES A WORDLINE ACTUALLY FALL?
#
# WHY THIS EXISTS: gen_addr_hold_tb.py cuts the series chain by dropping a
# wordline, and until 2026-09-22 it did so with a fixed 100 ps edge -- a
# number nobody had measured. The column deck cannot answer the question: it
# holds every wordline at DC VDD through an ideal source, and in a
# single-column deck the wordline node drives exactly ONE cell gate, with the
# row-wide wire and the other <cols>-1 gates cut away by the extraction.
#
# The periphery deck can. It keeps the real rom_row_decode -- address buffers,
# decode array and the wordline buffers -- and puts the deleted array's load
# back by the same slice x count rule the rest of the flow uses: one cell gate
# per column (m=<cols>) plus the array's own parasitic wire C, ~174 fF per
# wordline on the examples. So the edge measured here is the edge the macro
# produces, driver and load both real.
#
# WHAT IT REPORTS, per corner:
#   t_wlfall0    clk0 50% -> wordline 50%     (delay -- already existed)
#   t_wlslew0    80% -> 20% fall              (the sky130 Liberty convention)
#   t_wl1090_0   90% -> 10% fall
#   tf           t_wl1090_0 / 0.8             <- the number to feed a PULSE/PWL
#
# tf is what --wl-slew-ns wants: a SPICE ramp is linear, so its full 100%->0%
# transition is the 90-10 measurement divided by 0.8. run_hold_bisect.sh picks
# it up from wlslew_<corner>.log automatically.
#
# COST: one periphery run per corner, ~6 min and ~3 GB each. The decks are
# written under their own wlslew_<corner> name so a committed
# periph_active_<corner>.log is never overwritten.
#
# Usage: scripts/rom_char/run_wl_slew.sh [macro ...]

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
ng_reset          # clear the failure ledger for this run
GENP="$ROM_CHAR_DIR/gen_periphery_power_tb.py"

MACROS=$(macro_list "$@")

echo "== wordline fall time, real driver into the real row load =="
echo

n=0
for m in $MACROS; do
  load_geom "$m" || { echo "$m: cannot read geometry, skipped"; continue; }
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)
    cg=$(meas "$G_CHAR/cellgate_${c}.log" c_one_ff)
    if [ -z "$cg" ]; then
      echo "  $m $c: no cellgate log -- run run_periphery_power.sh first, skipped"
      continue
    fi
    sp="$G_CHAR/wlslew_${c}.sp"
    python3 "$GENP" "$m" 1 "$sp" --corner "$c" --vdd "$v" --temp "$t" \
            --gate-cap-ff "$cg" >/dev/null
    run_ng "wordline-slew" "$sp" "$G_CHAR/wlslew_${c}.log" "$m $c" &
    n=$((n+1)); [ $((n % JOBS)) -eq 0 ] && wait
  done
done
wait

echo
for m in $MACROS; do
  load_geom "$m" || continue
  echo "-- $m ($G_COLS columns on the wordline) ------------------------"
  printf "   %-6s %12s %12s %12s %12s\n" \
         corner "t_wlfall" "80-20" "90-10" "tf (--wl-slew-ns)"
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    lg="$G_CHAR/wlslew_${c}.log"
    [ -f "$lg" ] || continue
    d=$(meas "$lg" t_wlfall0   | awk '{printf "%.4f", $1*1e9}')
    s8=$(meas "$lg" t_wlslew0  | awk '{printf "%.4f", $1*1e9}')
    s9=$(meas "$lg" t_wl1090_0 | awk '{printf "%.4f", $1*1e9}')
    tf=$(meas "$lg" t_wl1090_0 | awk '{printf "%.4f", $1*1e9/0.8}')
    printf "   %-6s %10s ns %10s ns %10s ns %10s ns\n" \
           "$c" "${d:---}" "${s8:---}" "${s9:---}" "${tf:---}"
  done
  echo
done

echo "feed it to the hold experiment:"
echo "  scripts/rom_char/run_hold_bisect.sh <macro>        (picks tf up itself)"
echo "  ... --wl-slew-ns <tf>                              (by hand)"

# Non-zero if any deck died. The numbers those decks would have produced
# are simply absent otherwise, and absent is indistinguishable from fine.
ng_summary
