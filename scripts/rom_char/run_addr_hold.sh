#!/bin/sh
# ADDRESS HOLD -- the one .lib constraint that was never measured.
#
# The library ships hold = access (17.33 ns at TT on wrom0) because the row
# decoder is clocked: an address that moves during evaluate drops a second
# wordline, that wordline cannot come back inside the cycle, and the cut chain
# stops the bitline wherever it happens to be. Safe, but never measured.
#
# This sweeps WHEN the address moves and asks whether the read still lands.
# For each point the chain is cut at the cell nearest the bitline (the worst
# place to cut) and the deck reports whether bl_b -- the bitline inverter's
# output, i.e. the read value -- still crosses VDD/2.
#
#   cut too early -> the bitline stalls above the trip point, bl_b never
#                    crosses, the ROM reads 1 where a 0 was stored: VIOLATION
#   cut late      -> the bitline is already past the trip point, the cut
#                    changes nothing, the read is correct: hold satisfied
#
# The smallest passing cut time IS the hold requirement.
#
# Usage: scripts/rom_char/run_addr_hold.sh [macro ...]
#        BREAKS="0 5 10 15 20" CORNERS=tt:1.8:25:0 JOBS=12 \
#          scripts/rom_char/run_addr_hold.sh wrom0
#
# Each point is a full three-cycle run with a 1 us precharge phase, ~1 min of
# CPU. The default sweep is 13 points per corner; run it with JOBS.

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
ng_reset          # clear the failure ledger for this run
GEN="$ROM_CHAR_DIR/gen_addr_hold_tb.py"

# ns after the evaluate edge. The default brackets t_dis_50 (14.85 ns at TT on
# wrom0) from both sides, close-spaced where the answer is expected.
BREAKS="${BREAKS:-0 2 4 6 8 10 12 13 14 15 16 18 22}"

MACROS=$(macro_list "$@")

# The wordline edge that cuts the chain. Measured by run_wl_slew.sh out of the
# periphery deck (real buffer, real row load); the 100 ps fallback is an ideal
# step, which is the PESSIMISTIC end -- a real edge keeps the chain partly
# conducting while it falls, so the bitline goes on discharging. Whatever it
# is, --break-ns names the wordline's 50% crossing, so the axis does not move.
wl_slew_for() {   # $1 = corner tag -> prints "<ns> <where it came from>"
  if [ -n "${WL_SLEW:-}" ]; then
    echo "$WL_SLEW WL_SLEW"
    return
  fi
  _s=$(meas "$G_CHAR/wlslew_${1}.log" t_wl1090_0 |
       awk '{printf "%.4f", $1*1e9/0.8}')
  if [ -n "$_s" ]; then
    echo "$_s measured"
  else
    echo "0.1 ideal-step-NOT-MEASURED"
  fi
}

echo "== address hold: when may addr0 move after clk0 rises? =="
echo "   cut points: $BREAKS ns"
echo "   the NUMBER comes from run_hold_bisect.sh; this sweep is the picture"
echo

n=0
for m in $MACROS; do
  load_geom "$m" || { echo "$m: cannot read geometry, skipped"; continue; }
  OUT="$G_CHAR/hold"
  mkdir -p "$OUT"
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    set -- $(wl_slew_for "$c"); slew="$1"; slewsrc="$2"
    echo "   $m $c: wordline fall $slew ns ($slewsrc)"
    # the reference: no cut at all -- it must reproduce the committed t_dis_50,
    # which is what proves the patched deck is still the same circuit.
    python3 "$GEN" "$m" "$OUT/ref_${c}.sp" --corner "$c" >/dev/null
    run_ng "addr-hold-ref" "$OUT/ref_${c}.sp" "$OUT/ref_${c}.log" "$m $c" &
    n=$((n+1)); [ $((n % JOBS)) -eq 0 ] && wait
    for b in $BREAKS; do
      tag=$(echo "$b" | tr '.' 'p')
      python3 "$GEN" "$m" "$OUT/cut${tag}_${c}.sp" --corner "$c" \
              --break-ns "$b" --wl-slew-ns "$slew" >/dev/null
      run_ng "addr-hold-sweep" "$OUT/cut${tag}_${c}.sp" \
             "$OUT/cut${tag}_${c}.log" "$m $c break=$b" &
      n=$((n+1)); [ $((n % JOBS)) -eq 0 ] && wait
    done
  done
done
wait

echo
for m in $MACROS; do
  load_geom "$m" || continue
  OUT="$G_CHAR/hold"
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    [ -f "$OUT/ref_${c}.log" ] || continue
    ref=$(meas "$OUT/ref_${c}.log" t_dis_50 | awk '{printf "%.4f", $1*1e9}')
    com=$(meas "$G_CHAR/${G_COLTAG}_worst_case_parasitic$( [ "$c" = tt ] || echo "_$c").log" \
          t_dis_50 | awk '{printf "%.4f", $1*1e9}')
    echo "-- $m $c --------------------------------------------------"
    echo "   reference run (no cut): t_dis_50 = ${ref:-FAILED} ns"
    echo "   committed column deck : t_dis_50 = ${com:-?} ns   <- must match"
    printf "   %8s  %12s  %12s  %s\n" "cut@ns" "t_read(ns)" "bl_end(V)" "read"
    hold=""
    for b in $BREAKS; do
      tag=$(echo "$b" | tr '.' 'p')
      lg="$OUT/cut${tag}_${c}.log"
      tr_=$(meas "$lg" t_read | awk '{printf "%.4f", $1*1e9}')
      be=$(meas "$lg" bl_end | awk '{printf "%.4f", $1}')
      if [ -n "$tr_" ]; then
        verdict="ok"
        [ -z "$hold" ] && hold="$b"
      else
        verdict="LOST"
      fi
      printf "   %8s  %12s  %12s  %s\n" "$b" "${tr_:---}" "${be:-?}" "$verdict"
    done
    if [ -n "$hold" ]; then
      echo "   -> smallest cut time the read survives: $hold ns"
      echo "      (the .lib currently declares hold = access)"
    else
      echo "   -> the read is lost at EVERY cut point in the sweep;"
      echo "         extend BREAKS upward."
    fi
    echo
  done
done

echo "look at it in ngspice -- the waveforms, with the address edge on them:"
echo "  python3 scripts/rom_char/gen_addr_hold_tb.py <macro> look.sp --sweep-ns 8,14,16,22"
echo "  ngspice look.sp"

# Non-zero if any deck died. The numbers those decks would have produced
# are simply absent otherwise, and absent is indistinguishable from fine.
ng_summary
