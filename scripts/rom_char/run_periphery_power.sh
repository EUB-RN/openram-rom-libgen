#!/bin/sh
# PERIPHERY switching energy per cycle, three corners.
#
# WHY: the clk0 internal_power blocks in the .lib need a `when : "!cs0"`
# value as well. cs0 only gates the precharge path (precharge = ~NAND(cs0, clk_int)); the
# clock driver and the row decoder run off clk_int, INDEPENDENT of cs0. So even
# when the macro is deselected, every cycle still switches the clock tree, the
# address buffers, the decoder and all the wordlines. A missing block produces
# no error or warning in OpenSTA -- it silently scores that state as zero.
#
# METHOD: the same "one slice x a count" trick as gen_col_power_tb.py. The cell
# array (tens of thousands of transistors) is NOT simulated; it is deleted and
# its load (one cell gate per column on each wordline + the array's own wire C)
# is put back as a lump. Cell counts and gate capacitance come from the netlist.
#   Step 1: equivalent gate capacitance per cell (single device, seconds)
#   Step 2: periphery energy per cycle (cs0=0 and cs0=1)
#
# cs0=0 -> the `when : "!cs0"` value; goes straight to --energy-idle-pj.
# cs0=1 -> the PERIPHERY share of an active cycle. The `when : "cs0"` value is
#          <column count> x E_column (run_col_energy.sh) + this; regen_rom_libs.sh
#          does that sum itself.
#
# ~6 min per run (almost all of it parsing the netlist); JOBS run in parallel.
#
# Usage: scripts/rom_char/run_periphery_power.sh [macro ...]
#        JOBS=4 scripts/rom_char/run_periphery_power.sh wrom0

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
ng_reset          # clear the failure ledger for this run
GENP="$ROM_CHAR_DIR/gen_periphery_power_tb.py"
GENC="$ROM_CHAR_DIR/gen_cell_gate_tb.py"

MACROS=$(macro_list "$@")

# Settling threshold & adaptive convergence parameters (configurable externally)
SETTLE_MAX_PCT="${PERIPH_SETTLE_MAX_PCT:-${SETTLE_MAX_PCT:-1.0}}"
CYCLES_START="${PERIPH_CYCLES_START:-${PERIPH_CYCLES:-8}}"
MAX_CYCLES="${PERIPH_MAX_CYCLES:-20}"
CYCLE_STEP="${PERIPH_CYCLE_STEP:-2}"

# --- Step 1: equivalent cell gate capacitance ----------------------------
if [ "${SKIP_STEP1:-0}" != "1" ]; then
  echo "== Step 1: equivalent cell gate capacitance (C = Q(VDD)/VDD) =="
  for m in $MACROS; do
    load_geom "$m" || continue
    for ck in $CORNERS; do
      c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
      t=$(echo "$ck" | cut -d: -f3)
      sp="$G_CHAR/cellgate_${c}.sp"
      lg="$G_CHAR/cellgate_${c}.log"
      python3 "$GENC" "$m" "$sp" --corner "$c" --vdd "$v" --temp "$t" >/dev/null
      run_ng "cell-gate-cap" "$sp" "$lg" "$m $c" || continue
      cg=$(meas "$lg" c_one_ff)
      printf "  %-7s %-6s C_eq = %s fF/cell\n" "$m" "$c" "${cg:-FAILED}"
    done
  done
fi

# Adaptive worker: runs deck and increases cycles until c2/c3 gap <= SETTLE_MAX_PCT
run_periph_deck() {
  _m="$1"; _c="$2"; _v="$3"; _t="$4"; _cg="$5"; _cs="$6"
  _tag=$([ "$_cs" = 0 ] && echo idle || echo active)
  _sp="$G_CHAR/periph_${_tag}_${_c}.sp"
  _lg="$G_CHAR/periph_${_tag}_${_c}.log"
  _cyc="$CYCLES_START"

  while :; do
    python3 "$GENP" "$_m" "$_cs" "$_sp" --corner "$_c" --vdd "$_v" --temp "$_t" \
            --gate-cap-ff "$_cg" --cycles "$_cyc" >/dev/null
    run_ng "periphery-energy" "$_sp" "$_lg" "$_m $_c cs$_cs (cyc=$_cyc)" || return 1
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
      echo "  $_m $_c cs$_cs: reached max cycles ($_cyc) with gap ${_gap}% > ${SETTLE_MAX_PCT}%" >&2
      break
    fi
    _next_cyc=$((_cyc + CYCLE_STEP))
    echo "  $_m $_c cs$_cs: gap ${_gap}% > ${SETTLE_MAX_PCT}% -- adaptive settling: retrying with ${_next_cyc} cycles..." >&2
    _cyc="$_next_cyc"
  done
}

# --- Step 2: periphery energy --------------------------------------------
echo
echo "== Step 2: periphery energy per cycle (adaptive settling <= ${SETTLE_MAX_PCT}%) =="
n=0
for m in $MACROS; do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)
    cg=$(meas "$G_CHAR/cellgate_${c}.log" c_one_ff)
    [ -z "$cg" ] && { echo "  $m $c: no C_eq, skipped"; continue; }
    for cs in 0 1; do
      job_slot
      run_periph_deck "$m" "$c" "$v" "$t" "$cg" "$cs" & job_add $!
      n=$((n+1))
    done
  done
done
job_drain

# --- Summary --------------------------------------------------------------
echo
printf "%-7s %-6s %-4s %6s %14s %10s %14s\n" macro corner cs0 "cycles" "E_periph(pJ)" "c2/c3(%)" "P@fmax(mW)"
rows=""
for m in $MACROS; do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    f=$(echo "$ck" | cut -d: -f4)
    for cs in 0 1; do
      tag=$([ "$cs" = 0 ] && echo idle || echo active)
      sp="$G_CHAR/periph_${tag}_${c}.sp"
      lg="$G_CHAR/periph_${tag}_${c}.log"
      q2=$(meas "$lg" q_c2)
      q3=$(meas "$lg" q_c3)
      cyc=$(grep -oE '[0-9]+\*TCLK' "$sp" 2>/dev/null | head -1 | cut -d'*' -f1)
      [ -z "$cyc" ] && cyc="-"
      if [ -z "$q3" ]; then
        printf "%-7s %-6s %-4s %6s %14s\n" "$m" "$c" "$cs" "$cyc" "FAILED"; continue
      fi
      gap=$(echo "$q2 $q3" | awk '
        { q2 = ($1 < 0 ? -$1 : $1); q3 = ($2 < 0 ? -$2 : $2);
          printf "%.2f", q3 ? (q2-q3 < 0 ? q3-q2 : q2-q3)/q3*100 : 0 }')
      echo "$q3" | awk -v m="$m" -v c="$c" -v cs="$cs" -v cyc="$cyc" -v v="$v" -v f="$f" -v g="$gap" '
        { q3 = ($1 < 0 ? -$1 : $1);
          e = q3*v*1e12;
          pmw = e*1e-12*f*1e6*1e3;
          printf "%-7s %-6s %-4s %6s %14.4f %10.2f %14.4f\n", m, c, cs, cyc, e, g, pmw }'
      rows="${rows}$m $c cs$cs|$gap|$lg|$sp
"
    done
  done
done
echo
echo "NOTE: the c2/c3 gap shows whether the circuit has SETTLED. Limit is"
echo "      ${SETTLE_MAX_PCT}% (SETTLE_MAX_PCT to change it). If un-settled, runs"
echo "      adaptively increase up to ${MAX_CYCLES} cycles. The energy should be"
echo "      frequency independent -- check with --tclk 400n."

printf '%s' "$rows" | while IFS='|' read -r cx gap lg sp; do
  [ -n "$cx" ] || continue
  check_settled "periphery-energy" "$lg" "$cx" "$gap" "$sp" || true
done

ng_summary
