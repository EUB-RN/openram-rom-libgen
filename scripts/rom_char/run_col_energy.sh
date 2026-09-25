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
ng_reset          # clear the failure ledger for this run
GEN="$ROM_CHAR_DIR/gen_col_power_tb.py"

# Two totals are reported, and they answer different questions:
#   E_worst : every column discharging (n x E_col + 0 periphery here) -- the
#             peak-current case, and what the .lib used to carry.
#   E_avg   : the same sum at ~50% switching activity, which is what random
#             contents actually do (a column discharges only where the selected
#             row holds a zero). The .lib now carries the real per-row average
#             from gen_random_read_energy.py; this column is the quick estimate
#             that says whether that tool's answer is the right size.
# Neither includes the periphery -- run_periphery_power.sh measures that.
# One extracted column per deck, ~0.45 GB: bounded by cores, not memory.
JOBS=$(stage_jobs "$ROM_MEM_COLUMN")

# RUN PASS -- every macro x corner at once. These are the longest decks in
# the flow (six cycles at a 1 us precharge phase), which is exactly why
# running them one after another cost the most.
for m in $(macro_list "$@"); do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)
    sp="$G_CHAR/${G_COLTAG}_energy_${c}.sp"
    python3 "$GEN" "$m" "$G_WORST_COL" active "$sp" --corner "$c" --vdd "$v" --temp "$t" >/dev/null
    job_slot
    run_ng "col-energy" "$sp" "$G_CHAR/${G_COLTAG}_energy_${c}.log" "$m $c" & job_add $!
  done
done
job_drain

# REPORT PASS, in macro/corner order, reading back what the run pass wrote.
printf "%-7s %-6s %12s %12s %12s %10s %14s\n" \
       macro corner "E_col(pJ)" "E_worst(pJ)" "E_avg(pJ)" "c2/c3(%)" \
       "P@fmax(mW)"
for m in $(macro_list "$@"); do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3); f=$(echo "$ck" | cut -d: -f4)
    sp="$G_CHAR/${G_COLTAG}_energy_${c}.sp"
    lg="$G_CHAR/${G_COLTAG}_energy_${c}.log"
    q2=$(meas "$lg" q_c2)
    q3=$(meas "$lg" q_c3)
    if [ -z "$q3" ]; then
      printf "%-7s %-6s %12s\n" "$m" "$c" "FAILED"; continue
    fi
    # The c2/c3 gap is DATA, not a remark: check_settled decides on it below,
    # exactly as run_periphery_power.sh does with the same quantity. Two
    # decimals because at a 1% limit one cannot show which side of it a row
    # is on.
    gap=$(echo "$q2 $q3" | awk '
      { q2 = ($1 < 0 ? -$1 : $1); q3 = ($2 < 0 ? -$2 : $2);
        printf "%.2f", q3 ? (q2-q3 < 0 ? q3-q2 : q2-q3)/q3*100 : 0 }')
    echo "$q3" | awk -v m="$m" -v c="$c" -v v="$v" -v f="$f" -v n="$G_COLS" -v g="$gap" '
      { q3 = ($1 < 0 ? -$1 : $1);
        e     = q3*v*1e12;                # pJ per column per cycle
        eworst = e*n;                     # pJ per read, every column discharging
        eavg   = e*n*0.5;                 # pJ per read at ~50% switching
        pmw   = eworst*1e-12*f*1e6*1e3;   # pJ x MHz -> mW, the peak case
        printf "%-7s %-6s %12.4f %12.2f %12.2f %10.2f %14.3f\n",
               m, c, e, eworst, eavg, g, pmw }'
    check_settled "col-energy" "$lg" "$m $c" "$gap" "$sp" || true
  done
done
echo
echo "NOTE: these numbers cover the COLUMN ARRAY only. Decoder/buffer/mux/"
echo "      control (periphery) energy is separate -- run_periphery_power.sh."
echo "      E_avg here is a flat 50% estimate. The number that reaches the"
echo "      .lib is the average of 10 random reads with the discharging"
echo "      columns counted per row from the netlist --"
echo "      gen_random_read_energy.py <macro> --corner <c>."
echo "      P@fmax is quoted for E_worst, i.e. the peak-current case."

# Non-zero if any deck died. The numbers those decks would have produced
# are simply absent otherwise, and absent is indistinguishable from fine.
ng_summary
