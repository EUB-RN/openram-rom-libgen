#!/bin/sh
# EARLY PATH: the fastest a bitline can discharge -- the .lib's retain times.
#
# WHY THIS EXISTS: every other number in the .lib comes from the WORST column
# (the longest series chain), which bounds setup but says nothing about how
# SOON dout0 can start moving. Without an early bound a hold check against the
# capture flop has nothing to fail on: the tool believes the previous cycle's
# data is held right up to the access time, and a race that eats the old value
# before it is captured passes silently.
#
# Liberty's construct for this is retain_rise/retain_fall inside the same
# timing() group as cell_rise/cell_fall -- the time the output RETAINS its
# previous value after the related-pin edge. That is the early bound, and it
# needs the BEST column, not the worst:
#
#   late  (cell_rise) : worst column, longest chain  -> run_col_timing.sh
#   early (retain_*)  : best column, shortest chain  -> THIS SCRIPT
#
# The deck is exactly the one run_col_timing.sh builds; only the column
# changes. It is written under --tag=best_case_parasitic so it cannot collide
# with a worst-case run: wrom3's worst column happens to be column 10, which
# is another macro's best, and a shared file name would have had one silently
# overwrite the other.
#
# PREREQUISITE: <macro>_cap_only.spice (run_cap_extract.sh)
# Set NO_RESISTANCE=1 to build the capacitance-only decks instead.
#
# Usage: scripts/rom_char/run_early_path.sh [macro ...]

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
ng_reset          # clear the failure ledger for this run
export NGSPICE_BIN="$NG"

TAG=best_case_parasitic
FAST=fastest_array

# The retain times use the FASTEST ARRAY, not the best programmed column.
# A stored 0 is a metal strap and leaves the series path; a stored 1 is a
# transistor in it. So the discharge speed is set by the CONTENTS, and the
# best column of this particular .bin is only the fastest array that happens
# to be programmed -- reprogram the same geometry and it gets faster. The
# early bound has to survive that, so gen_col_tb_parasitic.py --ones=0 builds
# the limit case: every data cell strapped out.
#
# Zero is legal. A column of all zeros reads 0 at every address -- useless,
# but electrically fine, because the FOOT TRANSISTOR (the last element of the
# walked path, gated by precharge rather than a wordline) stays in series
# whatever is stored. It is never converted; doing so ties the chain to
# ground for good and makes the column look 5x too fast.
#
# At that limit the bound is set by the fixed circuitry rather than by the
# array: on wrom0 at tt, 0 cells 0.5080 ns against 1 cell 0.5738 ns, but 47
# cells 10.0972 ns.

for m in $(macro_list "$@"); do
  load_geom "$m" || { echo "$m: cannot read geometry, skipped"; continue; }
  echo "== $m  (best column $G_BEST_COL, series NMOS $G_BEST_CHAIN;"
  echo "        worst is column $G_WORST_COL with $G_CHAIN) =="
  if [ "${NO_RESISTANCE:-0}" = 1 ]; then
    RFLAG=--no-resistance
  else
    RFLAG=""
    python3 "$ROM_CHAR_DIR/gen_resistance_model.py" "$m" >/dev/null || {
      echo "  $m: resistance model failed -- falling back to capacitance only"
      RFLAG=--no-resistance
    }
  fi
  # 1) the best PROGRAMMED column -- reported for comparison
  # 2) the fastest array this GEOMETRY can hold -- what retain_* uses
  python3 "$ROM_CHAR_DIR/gen_col_tb_parasitic.py" "$m" "$G_BEST_COL" \
          $RFLAG "--tag=$TAG"
  python3 "$ROM_CHAR_DIR/gen_col_tb_parasitic.py" "$m" "$G_BEST_COL" \
          $RFLAG "--tag=$FAST" --ones=0
  for c in ss ff; do
    for t in "$TAG" "$FAST"; do
      python3 "$ROM_CHAR_DIR/make_corner_variant.py" "$m" "$G_BEST_COL" "$c" \
              "--tag=$t" >/dev/null
      sp="$G_CHAR/${G_BESTTAG}_${t}_${c}.sp"
      lg="$G_CHAR/${G_BESTTAG}_${t}_${c}.log"
      run_ng "early-path" "$sp" "$lg" "$m $c" &
    done
  done
  wait

  printf "  %-4s %14s %14s %14s\n" corner "fastest array" "best column" "worst column"
  for c in tt ss ff; do
    [ "$c" = tt ] && sfx="" || sfx="_$c"
    f=$(meas "$G_CHAR/${G_BESTTAG}_${FAST}${sfx}.log" t_dis_50 \
        | awk '{printf "%.4f", $1*1e9}')
    e=$(meas "$G_CHAR/${G_BESTTAG}_${TAG}${sfx}.log" t_dis_50 \
        | awk '{printf "%.4f", $1*1e9}')
    l=$(meas "$G_CHAR/${G_COLTAG}_worst_case_parasitic${sfx}.log" t_dis_50 \
        | awk '{printf "%.4f", $1*1e9}')
    printf "  %-4s %14s %14s %14s\n" "$c" "${f:-FAILED}" "${e:-?}" "${l:-?}"
  done
done

echo
echo "fastest array < best column < worst column, always. The first is the"
echo "limit of the geometry (every data cell strapped out), the second is of"
echo "THIS .bin, the third is what access is measured on. If the ordering"
echo "the decks disagree about the resistance model or the foot transistor"
echo "was converted (see gen_col_tb_parasitic.py --ones)."

# Non-zero if any deck died. The numbers those decks would have produced
# are simply absent otherwise, and absent is indistinguishable from fine.
ng_summary
