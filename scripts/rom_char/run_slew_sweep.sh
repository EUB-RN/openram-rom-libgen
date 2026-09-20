#!/bin/sh
# FRONT-END DELAY vs clk0 INPUT SLEW -- the .lib's index_1 axis.
#
# WHY THIS EXISTS: the CELL_TABLE has two axes and only one of them was ever
# measured. index_2 (output load) came from run_backend_delay.sh; index_1
# (input_net_transition) was three copies of the same number, so every timing
# tool saw a macro whose delay does not care how fast its clock arrives.
#
# WHICH TERM ACTUALLY DEPENDS ON IT: access is the sum of three terms and only
# the FIRST one is driven by clk0.
#   1) t_clk2pre  clk0 -> precharge          <- depends on the clk0 edge
#   2) t_dis_50   precharge -> bitline 50%   <- triggers off the precharge net
#   3) t_bl2dout  bitline -> dout0           <- driven by the bitline edge
# So this sweeps term 1 and nothing else. Terms 2 and 3 are measured once and
# reused across the axis, which is not a shortcut: neither of them can see
# clk0. The same argument is why the OUTPUT SLEW table stays flat over index_1
# -- dout0's edge is set by the bitline and the output buffer, not by clk0.
#
# COST: <corners> x <slews> runs per macro, cs0=1 only (t_clk2pre means
# nothing at cs0=0 -- the precharge never rises). ~6 min each, JOBS parallel.
#
# Usage: scripts/rom_char/run_slew_sweep.sh [macro ...]
#        SLEWS="0.05 0.5 1.5" JOBS=4 scripts/rom_char/run_slew_sweep.sh wrom0

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
GENP="$ROM_CHAR_DIR/gen_periphery_power_tb.py"

MACROS=$(macro_list "$@")

echo "== front-end delay vs clk0 input slew =="
echo "   axis: $SLEWS ns"
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
    i=0
    for sl in $SLEWS; do
      sp="$G_CHAR/periph_slew${i}_${c}.sp"
      lg="$G_CHAR/periph_slew${i}_${c}.log"
      python3 "$GENP" "$m" 1 "$sp" --corner "$c" --vdd "$v" --temp "$t" \
              --gate-cap-ff "$cg" --clk-slew "${sl}n" >/dev/null
      ( $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true ) &
      n=$((n+1))
      i=$((i+1))
      [ $((n % JOBS)) -eq 0 ] && wait
    done
  done
done
wait

# --- Summary --------------------------------------------------------------
echo
printf "%-7s %-6s" macro corner
for sl in $SLEWS; do printf " %14s" "${sl}ns"; done
printf " %10s\n" "spread"
for m in $MACROS; do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    printf "%-7s %-6s" "$m" "$c"
    vals=""
    i=0
    for _sl in $SLEWS; do
      tf=$(meas "$G_CHAR/periph_slew${i}_${c}.log" t_clk2pre \
           | awk '{printf "%.4f", $1*1e9}')
      if [ -z "$tf" ]; then
        printf " %14s" "FAILED"
      else
        printf " %14s" "$tf"
        vals="$vals $tf"
      fi
      i=$((i+1))
    done
    echo "$vals" | awk '{ if (NF < 2) { printf " %10s\n", "-"; exit }
                          lo = hi = $1
                          for (k = 2; k <= NF; k++) {
                            if ($k < lo) lo = $k; if ($k > hi) hi = $k }
                          printf " %9.1f%%\n", lo ? (hi-lo)/lo*100 : 0 }'
  done
done
echo
echo "The middle point of the default axis is 0.5 ns, the edge every earlier"
echo "measurement used -- it must reproduce the committed t_clk2pre. A spread"
echo "near 0% would mean the front end does not care about its clock edge,"
echo "which would be worth understanding before trusting the axis."
