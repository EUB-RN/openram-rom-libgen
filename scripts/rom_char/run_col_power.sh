#!/bin/sh
# PER-COLUMN leakage (.op), three corners.
# Result: <macro>/char/col<N>_leak_<corner>.log  +  a summary table.
#
# METHOD NOTE: this uses .op, NOT a transient. In a transient with "uic" the
# nodes start at 0 and charge slowly through a resistive chain of dozens of
# transistors; even at 600 ns it has not settled (65 -> 19 -> 8.7 nA) and the
# charging current was being mistaken for leakage, ~100x too high (confirmed
# 2026-09-05).
#
# The worst column and the column COUNT come from the netlist (rom_paths.py),
# so regenerating the ROM cannot leave them stale.
#
# Usage: scripts/rom_char/run_col_power.sh [macro ...]

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
ng_reset          # clear the failure ledger for this run
GEN="$ROM_CHAR_DIR/gen_col_power_tb.py"

printf "%-7s %-6s %14s %14s %14s\n" macro corner "I_column(nA)" "I_total(uA)" "P_total(uW)"
for m in $(macro_list "$@"); do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)
    sp="$G_CHAR/${G_COLTAG}_leak_${c}.sp"
    lg="$G_CHAR/${G_COLTAG}_leak_${c}.log"
    python3 "$GEN" "$m" "$G_WORST_COL" idle "$sp" --corner "$c" --vdd "$v" --temp "$t" >/dev/null
    run_ng "col-leakage" "$sp" "$lg" "$m $c" || continue
    # `.measure op` produces no numeric output -> read the current from the .op table
    i=$(grep -m1 "vvdd#branch" "$lg" | awk '{print $2}')
    if [ -z "$i" ]; then
      printf "%-7s %-6s %14s\n" "$m" "$c" "FAILED"
      continue
    fi
    echo "$i" | awk -v m="$m" -v c="$c" -v n="$G_COLS" -v v="$v" \
      '{ i = $1 < 0 ? -$1 : $1;
         printf "%-7s %-6s %14.4f %14.4f %14.4f\n", m, c, i*1e9, i*n*1e6, i*n*v*1e6 }'
  done
done
echo
echo "NOTE: I_total/P_total = per-column value x column count (from the netlist)."
echo "      Periphery leakage is NOT included."

# Non-zero if any deck died. The numbers those decks would have produced
# are simply absent otherwise, and absent is indistinguishable from fine.
ng_summary
