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

# Settling threshold & adaptive convergence parameters
SETTLE_MAX_PCT="${COL_SETTLE_MAX_PCT:-${SETTLE_MAX_PCT:-1.0}}"
CYCLES_START="${COL_CYCLES_START:-${COL_CYCLES:-6}}"
MAX_CYCLES="${COL_MAX_CYCLES:-16}"
CYCLE_STEP="${COL_CYCLE_STEP:-2}"

run_col_energy_deck() {
  _m="$1"; _c="$2"; _v="$3"; _t="$4"; _sp="$5"; _lg="$6"
  _cyc="$CYCLES_START"

  # Adaptive cycle period from timing characterization:
  # The column energy deck integrates charge to measure full C*V^2 switching energy.
  # If TCLK is too short, high-resistance series NMOS chains (notably in SS corner)
  # cannot fully discharge before precharge reactivates, causing severe energy
  # underestimation. We adaptively size TCLK from t_dis_10 and t_pre_99.
  _tclk="${COL_TCLK:-}"
  if [ -z "$_tclk" ]; then
    _sfx=$( [ "$_c" = "tt" ] && echo "" || echo "_$_c" )
    _tlog="$G_CHAR/${G_COLTAG}_worst_case_parasitic${_sfx}.log"
    [ ! -f "$_tlog" ] && _tlog="$G_CHAR/${G_COLTAG}_worst_case_parasitic_${_c}.log"

    _tdis10=$(meas "$_tlog" t_dis_10)
    _tpre99=$(meas "$_tlog" t_pre_99)

    if [ -n "$_tdis10" ]; then
      [ -z "$_tpre99" ] && _tpre99="20e-9"
      _tclk=$(awk -v d="$_tdis10" -v p="$_tpre99" 'BEGIN {
        teval = 1.25 * d;
        tpre  = 1.25 * p;
        tphase = (teval > tpre ? teval : tpre);
        tclk_ns = int((2.0 * tphase * 1e9 + 9) / 10) * 10;
        if (tclk_ns < 200) tclk_ns = 200;
        printf "%dns", tclk_ns;
      }')
    else
      _tclk="200n"
    fi
  fi

  while :; do
    python3 "$GEN" "$_m" "$G_WORST_COL" active "$_sp" --corner "$_c" --vdd "$_v" --temp "$_t" \
            --cycles "$_cyc" --tclk "$_tclk" ${MACROS_DIR:+--macros-dir "$MACROS_DIR"} >/dev/null
    run_ng "col-energy" "$_sp" "$_lg" "$_m $_c (cyc=$_cyc tclk=$_tclk)" || return 1
    _q2=$(meas "$_lg" q_c2)
    _q3=$(meas "$_lg" q_c3)
    [ -z "$_q3" ] && break
    _gap=$(echo "$_q2 $_q3" | awk '
      { q2 = ($1 < 0 ? -$1 : $1); q3 = ($2 < 0 ? -$2 : $2);
        printf "%.2f", q3 ? (q2-q3 < 0 ? q3-q2 : q2-q3)/q3*100 : 0 }')
    _ok=$(echo "$_gap $SETTLE_MAX_PCT" | awk '{print ($1+0 <= $2+0) ? 1 : 0}')
    if [ "$_ok" -eq 1 ]; then
      break
    fi
    if [ "$_cyc" -ge "$MAX_CYCLES" ]; then
      echo "  $_m $_c: reached max cycles ($_cyc) with gap ${_gap}% > ${SETTLE_MAX_PCT}%" >&2
      break
    fi
    _next_cyc=$((_cyc + CYCLE_STEP))
    echo "  $_m $_c: gap ${_gap}% > ${SETTLE_MAX_PCT}% -- adaptive settling: retrying with ${_next_cyc} cycles..." >&2
    _cyc="$_next_cyc"
  done
}

# RUN PASS -- every macro x corner at once.
for m in $(macro_list "$@"); do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)
    sp="$G_CHAR/${G_COLTAG}_energy_${c}.sp"
    lg="$G_CHAR/${G_COLTAG}_energy_${c}.log"
    job_slot
    run_col_energy_deck "$m" "$c" "$v" "$t" "$sp" "$lg" & job_add $!
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
