#!/bin/sh
# PER-COLUMN switching ENERGY per cycle, three corners.
#
# WHY ENERGY: Liberty `internal_power` is ENERGY per switching event (pJ), not
# power. The power tool applies the frequency (P = E*f*activity), so we never
# need to know it. Verified: changing TCLK from 200n to 400n moved the
# per-cycle charge by only 3.3% (2026-09-05).
#
# The worst column and the column COUNT come from the netlist (rom_paths.py).
#
# Usage: scripts/rom_char/run_col_energy.sh [macro ...]

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
GEN="$ROM_CHAR_DIR/gen_col_power_tb.py"

printf "%-7s %-6s %12s %12s %10s %14s\n" \
       macro corner "E_col(pJ)" "E_total(pJ)" "c2/c3(%)" "P@fmax(mW)"
for m in $(macro_list "$@"); do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3); f=$(echo "$ck" | cut -d: -f4)
    sp="$G_CHAR/${G_COLTAG}_energy_${c}.sp"
    lg="$G_CHAR/${G_COLTAG}_energy_${c}.log"
    python3 "$GEN" "$m" "$G_WORST_COL" active "$sp" --corner "$c" --vdd "$v" --temp "$t" >/dev/null
    $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true
    q2=$(meas "$lg" q_c2)
    q3=$(meas "$lg" q_c3)
    if [ -z "$q3" ]; then
      printf "%-7s %-6s %12s\n" "$m" "$c" "FAILED"; continue
    fi
    echo "$q2 $q3" | awk -v m="$m" -v c="$c" -v v="$v" -v f="$f" -v n="$G_COLS" '
      { q2 = ($1 < 0 ? -$1 : $1); q3 = ($2 < 0 ? -$2 : $2);
        e    = q3*v*1e12;                 # pJ per column per cycle
        etot = e*n;                       # pJ per read (all columns)
        settle = q3 ? (q2-q3 < 0 ? q3-q2 : q2-q3)/q3*100 : 0;
        pmw  = etot*1e-12*f*1e6*1e3;      # pJ x MHz -> mW
        printf "%-7s %-6s %12.4f %12.2f %10.1f %14.3f\n", m, c, e, etot, settle, pmw }'
  done
done
echo
echo "NOTE: these numbers cover the COLUMN ARRAY only. Decoder/buffer/mux/"
echo "      control (periphery) energy is separate -- run_periphery_power.sh."
