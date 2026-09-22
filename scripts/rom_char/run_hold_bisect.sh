#!/bin/sh
# ADDRESS HOLD, converged -- the number, not the picture.
#
# run_addr_hold.sh walks a fixed list of cut times. That is the right tool for
# LOOKING at the experiment, but its answer is only as tight as the coarsest
# gap in the list: a 13-point sweep over 22 ns brackets the limit to about a
# nanosecond and calls the first passing point the hold time, which overstates
# it by up to the width of that gap.
#
# This bisects instead. bl_b_end rises MONOTONICALLY with the cut time -- the
# later the chain is cut the further the bitline got, and the further the
# bitline got the harder the inverter drives -- so a threshold on it splits
# the axis cleanly and bisection is exact to whatever tolerance is asked for.
# 7 runs take the answer from "somewhere in 1.4 ns" to +/-0.05 ns.
#
# Monotone is NOT the same as a cliff. Near the limit the frozen bitline sits
# on the inverter's transfer curve and bl_b_end walks up it continuously; the
# threshold below is what turns that analog ramp into a yes/no, and choosing
# it too low is how the first version of this script returned a hold time
# 1.6 ns shorter than the circuit can actually deliver.
#
# THE TEST is bl_b_end, the read value one nanosecond before the phase ends,
# against a real LOGIC LEVEL: HOLD_VOH_FRAC * VDD, 0.9 by default.
#
# VDD/2 is the wrong threshold and was tried first. The cut FREEZES the
# bitline, and a frozen bitline near the inverter's trip point maps straight
# through its transfer curve: bl_b_end then moves CONTINUOUSLY with the cut
# time (0.77 V at 14.97 ns, 0.89 V at 15.05 ns, 0.96 V at 15.10 ns, 1.25 V at
# 15.31 ns on wrom0 at TT). Everything above VDD/2 in that list "passes" a
# half-rail test while being an analog level no downstream gate can read: no
# noise margin, and the inverter holds a DC path to ground for the rest of the
# phase because its input is sitting around a threshold voltage.
#
# The pass condition is therefore the level the REST OF THE FLOW assumes: the
# back-end delay and the output slew were both characterised with a bitline
# that swings the whole way, so the read only counts when bl_b lands within
# 10% of the rail. That is a stricter -- later, safer -- hold time than the
# trip-point crossing, and it is the honest one.
#
# The reported hold is the SMALLEST CUT TIME THAT PASSED, i.e. the upper end
# of the final bracket: never a value that was not itself simulated.
#
# THE WORDLINE EDGE IS REAL. --wl-slew-ns is taken from wlslew_<corner>.log
# (run_wl_slew.sh) unless WL_SLEW says otherwise, so the chain is cut at the
# rate the macro's own wordline buffer can drive its row. Falling back to the
# ideal 100 ps step is the pessimistic direction and is announced when it
# happens: a real edge keeps the chain partly conducting as it falls, so the
# bitline goes on discharging and the read survives an earlier address move.
#
# COST: ~1 min per point, ceil(log2((hi-lo)/tol)) points plus the two bracket
# checks. The corners run in parallel, one process each.
#
# Usage: scripts/rom_char/run_hold_bisect.sh [macro ...]
#        HOLD_TOL=0.02 scripts/rom_char/run_hold_bisect.sh wrom0
#        WL_SLEW=0.1 ROM_CORNERS="tt:1.8:25:34.1" \
#          scripts/rom_char/run_hold_bisect.sh wrom0     # the old ideal step
#
# Look at the converged answer:
#   scripts/rom_char/run_addr_hold.sh  -- or --
#   python3 scripts/rom_char/gen_addr_hold_tb.py <macro> look.sp \
#       --sweep-ns <lo>,<hold> --wl-slew-ns <tf> && ngspice look.sp

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
GEN="$ROM_CHAR_DIR/gen_addr_hold_tb.py"

TOL="${HOLD_TOL:-0.05}"          # ns; stop when the bracket is this narrow
VOH="${HOLD_VOH_FRAC:-0.9}"      # bl_b must reach this fraction of VDD
MAXGROW="${HOLD_MAXGROW:-4}"     # times the upper bound may be pushed out

MACROS=$(macro_list "$@")

# one point: writes the deck, runs it, prints "pass" or "fail"
# $1 break ns  $2 slew ns  $3 corner  $4 vdd  $5 macro  $6 outdir
try_point() {
  _b="$1"; _s="$2"; _c="$3"; _v="$4"; _m="$5"; _o="$6"
  _lim=$(awk -v v="$_v" -v f="$VOH" 'BEGIN{printf "%.6f", v*f}')
  _tag=$(printf "%08.4f_%06.4f" "$_b" "$_s" | tr '.' 'p')
  _sp="$_o/bis_${_tag}_${_c}.sp"
  _lg="$_o/bis_${_tag}_${_c}.log"
  python3 "$GEN" "$_m" "$_sp" --corner "$_c" --break-ns "$_b" \
          --wl-slew-ns "$_s" >/dev/null
  $NG -b -o "$_lg" "$_sp" >/dev/null 2>&1 || true
  _e=$(meas "$_lg" bl_b_end)
  printf "%s " "$_e" >> "$_o/level_${_c}.txt"
  # no measurement at all means the run itself died -- not a hold failure,
  # and silently folding it into "fail" would invent a hold time.
  [ -z "$_e" ] && { echo "ERROR"; return; }
  echo "$_e" | awk -v lim="$_lim" '{print ($1+0 >= lim) ? "pass" : "fail"}'
}

_level() {   # the bl_b_end of the most recent point, for the log line
  awk '{printf "%.4f", $NF}' "$1/level_${2}.txt" 2>/dev/null
}

bisect_corner() {
  _m="$1"; _c="$2"; _v="$3"; _o="$4"; _slew="$5"; _slewsrc="$6"; _hi0="$7"
  echo "-- $_m $_c ------------------------------------------------"
  echo "   wordline fall time: $_slew ns  ($_slewsrc)"
  echo "   the read counts when bl_b reaches $VOH x VDD = $(awk -v v="$_v" \
        -v f="$VOH" 'BEGIN{printf "%.3f", v*f}') V"
  : > "$_o/level_${_c}.txt"
  _lo="${HOLD_LO:-0}"
  _hi="$_hi0"

  # The bracket has to be proved, not assumed. If the low end already passes
  # there is no hold requirement to find; if the high end fails the limit is
  # outside the bracket and bisecting inside it would return a wrong number.
  _r=$(try_point "$_lo" "$_slew" "$_c" "$_v" "$_m" "$_o")
  printf "   %8s ns  %-4s  bl_b_end=%s V\n" "$_lo" "$_r" "$(_level "$_o" "$_c")"
  [ "$_r" = ERROR ] && { echo "   -> the run failed; nothing to report"; return; }
  if [ "$_r" = pass ]; then
    echo "   -> the read survives even at $_lo ns: no hold requirement here"
    return
  fi

  _g=0
  while : ; do
    _r=$(try_point "$_hi" "$_slew" "$_c" "$_v" "$_m" "$_o")
    printf "   %8s ns  %-4s  bl_b_end=%s V\n" "$_hi" "$_r" "$(_level "$_o" "$_c")"
    [ "$_r" = ERROR ] && { echo "   -> the run failed; nothing to report"; return; }
    [ "$_r" = pass ] && break
    _g=$((_g+1))
    if [ "$_g" -gt "$MAXGROW" ]; then
      echo "   -> the read is lost at every cut time up to $_hi ns;"
      echo "      raise HOLD_HI -- the cut may be landing outside the phase"
      return
    fi
    _lo="$_hi"
    _hi=$(awk -v h="$_hi" 'BEGIN{printf "%.4f", h*1.5}')
  done

  # invariant from here: lo FAILS, hi PASSES, and the answer is in between
  while awk -v l="$_lo" -v h="$_hi" -v t="$TOL" 'BEGIN{exit !(h-l > t)}'; do
    _mid=$(awk -v l="$_lo" -v h="$_hi" 'BEGIN{printf "%.4f", (l+h)/2}')
    _r=$(try_point "$_mid" "$_slew" "$_c" "$_v" "$_m" "$_o")
    printf "   %8s ns  %-4s  bl_b_end=%s V\n" "$_mid" "$_r" "$(_level "$_o" "$_c")"
    case "$_r" in
      pass)  _hi="$_mid" ;;
      fail)  _lo="$_mid" ;;
      *)     echo "   -> a run failed mid-bisection; bracket is $_lo .. $_hi ns"
             return ;;
    esac
  done

  _acc=$(meas "$G_CHAR/${G_COLTAG}_worst_case_parasitic$( [ "$_c" = tt ] || \
         echo "_$_c").log" t_dis_50 | awk '{printf "%.4f", $1*1e9}')
  # The number, where regen_rom_libs.sh looks for it. Seconds, laid out like
  # an ngspice .measure line so common.sh's `meas` reads it like every other
  # measured quantity in the flow -- nothing here is a special case.
  awk -v h="$_hi" -v l="$_lo" -v s="$_slew" -v f="$VOH" -v t="$TOL" 'BEGIN{
    printf "* address hold, scripts/rom_char/run_hold_bisect.sh\n"
    printf "* wordline fall %s ns, threshold %s x VDD, tolerance %s ns\n", s, f, t
    printf "* largest cut time that still FAILS: %.6e\n", l*1e-9
    printf "hold                =  %.6e\n", h*1e-9
  }' > "$G_CHAR/hold_${_c}.log"

  echo "   -> hold = $_hi ns   (simulated; $_lo ns does not reach the level,"
  echo "         tolerance $TOL ns, threshold $VOH x VDD)"
  echo "      written to char/hold_${_c}.log -- regen_rom_libs.sh picks it up"
  [ -n "$_acc" ] && echo "      t_dis_50 on the same column: $_acc ns"
  echo "      the .lib currently declares hold = access"
}

echo "== address hold by bisection (tolerance $TOL ns) =="
echo

for m in $MACROS; do
  load_geom "$m" || { echo "$m: cannot read geometry, skipped"; continue; }
  OUT="$G_CHAR/hold"
  mkdir -p "$OUT"
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)

    # the wordline edge: measured if it has been, pessimistic if it has not
    if [ -n "${WL_SLEW:-}" ]; then
      slew="$WL_SLEW"; slewsrc="WL_SLEW"
    else
      slew=$(meas "$G_CHAR/wlslew_${c}.log" t_wl1090_0 |
             awk '{printf "%.4f", $1*1e9/0.8}')
      if [ -n "$slew" ]; then
        slewsrc="measured: wlslew_${c}.log 90-10 / 0.8"
      else
        slew="0.1"
        slewsrc="NOT MEASURED -- ideal step, pessimistic; run run_wl_slew.sh"
      fi
    fi

    # the upper bracket: the committed discharge time with margin. Past
    # t_dis_50 the bitline is already through the trip point, so a cut there
    # cannot change the read -- it is a bound, not a guess.
    if [ -n "${HOLD_HI:-}" ]; then
      hi="$HOLD_HI"
    else
      hi=$(meas "$G_CHAR/${G_COLTAG}_worst_case_parasitic$( [ "$c" = tt ] || \
           echo "_$c").log" t_dis_50 | awk '{printf "%.4f", $1*1e9*1.5}')
      [ -z "$hi" ] && hi=22
    fi

    ( bisect_corner "$m" "$c" "$v" "$OUT" "$slew" "$slewsrc" "$hi" \
        > "$OUT/bisect_${c}.txt" 2>&1 ) &
  done
  wait
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    [ -f "$OUT/bisect_${c}.txt" ] && cat "$OUT/bisect_${c}.txt" && echo
  done
done
