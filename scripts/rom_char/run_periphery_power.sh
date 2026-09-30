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
SETTLE_STEP="$ROM_CHAR_DIR/periph_settle_step.py"

MACROS=$(macro_list "$@")

# Settling threshold & adaptive convergence parameters (configurable externally)
SETTLE_MAX_PCT="${PERIPH_SETTLE_MAX_PCT:-${SETTLE_MAX_PCT:-1.0}}"
NOISE_FLOOR_PJ="${PERIPH_NOISE_FLOOR_PJ:-0.10}"
MAX_CYCLES="${PERIPH_MAX_CYCLES:-20}"
PERIPH_PAIRED="${PERIPH_PAIRED:-1}"
PREDICT_HARD_MAX="${PERIPH_PREDICT_MAX_CYCLES:-64}"

# Return the later of the active/idle settled markers for one corner.  A MAX
# marker is deliberately ignored: only observed convergence may train the
# cross-corner predictor.
corner_settled_cycles() {
  _corner="$1"
  _a=$(sed -n 's/^PERIPH_SETTLED_CYCLES=//p' "$G_CHAR/periph_active_${_corner}.log" 2>/dev/null | tail -1)
  _i=$(sed -n 's/^PERIPH_SETTLED_CYCLES=//p' "$G_CHAR/periph_idle_${_corner}.log" 2>/dev/null | tail -1)
  [ -n "$_a" ] && [ -n "$_i" ] || return 1
  [ "$_a" -ge "$_i" ] && echo "$_a" || echo "$_i"
}

# The characterized order is fast -> typical -> slow.  Once FF and TT have
# both settled, preserve their multiplicative slowdown when choosing the SS
# starting point.  Example: FF=14, TT=18 -> ceil_even(18*18/14) = 24.
ss_cycle_prediction() {
  _ff=$(corner_settled_cycles ff) || return 1
  _tt=$(corner_settled_cycles tt) || return 1
  python3 "$SETTLE_STEP" --predict-cycles "$_ff" "$_tt"
}

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

# Persistent adaptive worker: ngspice parses and starts the deck ONCE, pauses
# at cycle boundaries, and resumes the same transient state when it has not
# settled. Checking every two cycles costs only measurements; unlike the old
# retry loop it never recomputes the cycles it has already simulated.
run_periph_deck() {
  _m="$1"; _c="$2"; _v="$3"; _t="$4"; _cg="$5"; _cs="$6"
  _start_hint="${7:-}"; _max_cyc="${8:-$MAX_CYCLES}"
  _tag=$([ "$_cs" = 0 ] && echo idle || echo active)
  _sp="$G_CHAR/periph_${_tag}_${_c}.sp"
  _lg="$G_CHAR/periph_${_tag}_${_c}.log"

  # Larger row decoders take longer to settle. Avoid paying for an 8-cycle
  # run that is already known to be too short for 128-row-and-up macros.
  _default_start=8
  if [ "${G_ROWS:-0}" -ge 128 ]; then
    _default_start=12
  fi
  _cyc="${PERIPH_CYCLES_START:-${PERIPH_CYCLES:-${_start_hint:-$_default_start}}}"
  if [ "$_cyc" -gt "$_max_cyc" ] 2>/dev/null; then
    ng_fail "periphery-energy" "$_m $_c cs$_cs" "$_sp" "$_lg" \
            "-" "PERIPH_CYCLES_START ($_cyc) exceeds effective max cycles ($_max_cyc)"
    return 1
  fi

  python3 "$GENP" "$_m" "$_cs" "$_sp" --corner "$_c" --vdd "$_v" --temp "$_t" \
          --gate-cap-ff "$_cg" --cycles "$_cyc" \
          --settle-max-cycles "$_max_cyc" --settle-thresh "$SETTLE_MAX_PCT" \
          --noise-floor-pj "$NOISE_FLOOR_PJ" >/dev/null
  run_ng "periphery-energy" "$_sp" "$_lg" \
         "$_m $_c cs$_cs (persistent $_cyc..$MAX_CYCLES)" || return 1

  _final_cyc=$(sed -n 's/^PERIPH_\(SETTLED\|MAX\)_CYCLES=//p' "$_lg" | tail -1)
  if [ -z "$_final_cyc" ]; then
    ng_fail "periphery-energy" "$_m $_c cs$_cs" "$_sp" "$_lg" \
            "0 (persistent settling)" "ngspice log has no persistent-settling completion marker"
    return 1
  fi

  _eval_rc=0
  _eval=$(python3 "$SETTLE_STEP" "$_lg" \
          --vdd "$_v" --current-cycles "$_final_cyc" --max-cycles "$_max_cyc" \
          --thresh "$SETTLE_MAX_PCT" --noise-floor-pj "$NOISE_FLOOR_PJ") || _eval_rc=$?
  SETTLED=0; GAP_PCT=""; DELTA_E_PJ=""; NEXT_CYCLES=""; REASON=""
  eval "$_eval"
  if [ "$SETTLED" = "1" ]; then
    echo "  $_m $_c cs$_cs: persistent settling converged at $_final_cyc cycles: $REASON" >&2
  elif [ "$_eval_rc" -eq 2 ]; then
    echo "  $_m $_c cs$_cs: $REASON" >&2
  else
    ng_fail "periphery-energy" "$_m $_c cs$_cs" "$_sp" "$_lg" \
            "0 (settling evaluator)" "${REASON:-invalid settling evaluator response}"
    return 1
  fi
}

# Paired worker: ngspice parses the netlist ONCE per corner. It runs active
# (cs0=1), measures e_periph_pj and front-end timing, resets circuit state,
# alters Vcs=0, and runs idle (cs0=0) in the same KLU-only session.
# Reduces netlist parse overhead by 50% and speeds up large macro characterization.
run_periph_paired_deck() {
  _m="$1"; _c="$2"; _v="$3"; _t="$4"; _cg="$5"
  _start_hint="${6:-}"; _max_cyc="${7:-$MAX_CYCLES}"
  _sp="$G_CHAR/periph_paired_${_c}.sp"
  _lg="$G_CHAR/periph_paired_${_c}.log"
  _sp_act="$G_CHAR/periph_active_${_c}.sp"
  _lg_act="$G_CHAR/periph_active_${_c}.log"
  _sp_idle="$G_CHAR/periph_idle_${_c}.sp"
  _lg_idle="$G_CHAR/periph_idle_${_c}.log"

  _default_start=8
  if [ "${G_ROWS:-0}" -ge 128 ]; then
    _default_start=12
  fi
  _cyc="${PERIPH_CYCLES_START:-${PERIPH_CYCLES:-${_start_hint:-$_default_start}}}"

  echo "  --> [START] $_m $_c: paired active+idle deck (persistent ${_cyc}..${_max_cyc} cycles)..." >&2
  python3 "$GENP" "$_m" 1 "$_sp" --corner "$_c" --vdd "$_v" --temp "$_t" \
          --gate-cap-ff "$_cg" --cycles "$_cyc" \
          --settle-max-cycles "$_max_cyc" --settle-thresh "$SETTLE_MAX_PCT" \
          --noise-floor-pj "$NOISE_FLOOR_PJ" --paired >/dev/null
  cp "$_sp" "$_sp_act"
  cp "$_sp" "$_sp_idle"

  run_ng "periphery-energy" "$_sp" "$_lg" \
         "$_m $_c (paired persistent ${_cyc}..${_max_cyc})" || return 1

  # Split paired log into periph_active and periph_idle
  awk '/PAIRED_MODE_BEGIN=active/,/PAIRED_MODE_END=active/' "$_lg" > "$_lg_act"
  awk '/PAIRED_MODE_BEGIN=idle/,/PAIRED_MODE_END=idle/' "$_lg" > "$_lg_idle"

  # Write provenance stamps for active and idle logs
  prov_write "periphery-energy" "$_sp_act" "$_lg_act" "$_m $_c cs1"
  prov_write "periphery-energy" "$_sp_idle" "$_lg_idle" "$_m $_c cs0"

  for _cs in 1 0; do
    _tag=$([ "$_cs" = 0 ] && echo idle || echo active)
    _lg_sub="$G_CHAR/periph_${_tag}_${_c}.log"
    _final_cyc=$(sed -n 's/^PERIPH_\(SETTLED\|MAX\)_CYCLES=//p' "$_lg_sub" | tail -1)
    [ -z "$_final_cyc" ] && _final_cyc="$_cyc"
    _eval_rc=0
    _eval=$(python3 "$SETTLE_STEP" "$_lg_sub" \
            --vdd "$_v" --current-cycles "$_final_cyc" --max-cycles "$_max_cyc" \
            --thresh "$SETTLE_MAX_PCT" --noise-floor-pj "$NOISE_FLOOR_PJ") || _eval_rc=$?
    SETTLED=0; GAP_PCT=""; DELTA_E_PJ=""; NEXT_CYCLES=""; REASON=""
    eval "$_eval"
    if [ "$SETTLED" = "1" ]; then
      echo "  $_m $_c cs$_cs: paired settling converged at $_final_cyc cycles: $REASON" >&2
    elif [ "$_eval_rc" -eq 2 ]; then
      echo "  $_m $_c cs$_cs: $REASON" >&2
    else
      echo "  $_m $_c cs$_cs: paired settling warning: ${REASON:-check log}" >&2
    fi
  done
  echo "  ✓ [DONE] $_m $_c: paired active+idle finished" >&2
}

# --- Step 2: periphery energy --------------------------------------------
echo
if [ "$PERIPH_PAIRED" = "1" ]; then
  echo "== Step 2: periphery energy per cycle (paired active+idle single-parse) =="
else
  echo "== Step 2: periphery energy per cycle (persistent settling <= ${SETTLE_MAX_PCT}%) =="
fi
n=0
# Cross-corner prediction needs completed history, so run characterization in
# physical speed order and drain each phase before starting the next one.
# Jobs within a phase (different macros) still run in parallel.
RUN_CORNERS=""
for wanted in ff tt ss; do
  for ck in $CORNERS; do
    [ "$(echo "$ck" | cut -d: -f1)" = "$wanted" ] && RUN_CORNERS="$RUN_CORNERS $ck"
  done
done
for ck in $CORNERS; do
  case "$(echo "$ck" | cut -d: -f1)" in ff|tt|ss) ;; *) RUN_CORNERS="$RUN_CORNERS $ck" ;; esac
done

for ck in $RUN_CORNERS; do
  for m in $MACROS; do
    load_geom "$m" || continue
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)
    cg=$(meas "$G_CHAR/cellgate_${c}.log" c_one_ff)
    [ -z "$cg" ] && { echo "  $m $c: no C_eq, skipped"; continue; }

    _start_hint=""
    _effective_max="$MAX_CYCLES"
    _explicit_start="${PERIPH_CYCLES_START:-${PERIPH_CYCLES:-}}"
    if [ "$c" = ss ] && [ -z "$_explicit_start" ]; then
      _start_hint=$(ss_cycle_prediction 2>/dev/null || true)
      if [ -n "$_start_hint" ]; then
        if [ "$_start_hint" -gt "$PREDICT_HARD_MAX" ]; then
          echo "  $m ss: predicted $_start_hint cycles; clamped to safety ceiling $PREDICT_HARD_MAX" >&2
          _start_hint="$PREDICT_HARD_MAX"
        fi
        [ "$_start_hint" -gt "$_effective_max" ] && _effective_max="$_start_hint"
        echo "  $m ss: cross-corner prediction FF->TT gives ${_start_hint} cycles (effective max ${_effective_max})" >&2
      fi
    fi

    if [ "$PERIPH_PAIRED" = "1" ]; then
      job_slot
      run_periph_paired_deck "$m" "$c" "$v" "$t" "$cg" "$_start_hint" "$_effective_max" & job_add $!
      n=$((n+1))
    else
      for cs in 0 1; do
        job_slot
        run_periph_deck "$m" "$c" "$v" "$t" "$cg" "$cs" "$_start_hint" "$_effective_max" & job_add $!
        n=$((n+1))
      done
    fi
  done
  job_drain
done

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
      cyc=$(sed -n 's/^PERIPH_\(SETTLED\|MAX\)_CYCLES=//p' "$lg" 2>/dev/null | tail -1)
      [ -z "$cyc" ] && cyc=$(grep -oE '[0-9]+\*TCLK' "$sp" 2>/dev/null | head -1 | cut -d'*' -f1)
      [ -z "$cyc" ] && cyc="-"
      if [ -z "$q2" ] || [ -z "$q3" ]; then
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
      rows="${rows}$m $c cs$cs|$gap|$q2|$q3|$v|$cyc|$lg|$sp
"
    done
  done
done
echo
echo "NOTE: the c2/c3 gap shows whether the circuit has SETTLED. Limit is"
echo "      ${SETTLE_MAX_PCT}% (SETTLE_MAX_PCT to change it), or an absolute"
echo "      delta-E below ${NOISE_FLOOR_PJ} pJ. If un-settled, one persistent"
echo "      transient resumes by two cycles. FF->TT convergence predicts the SS"
echo "      start/ceiling (up to ${PREDICT_HARD_MAX}); prior cycles"
echo "      are never re-run. The energy should be"
echo "      frequency independent -- check with --tclk 400n."

printf '%s' "$rows" | while IFS='|' read -r cx gap q2 q3 v cyc lg sp; do
  [ -n "$cx" ] || continue
  _final_rc=0
  _final=$(python3 "$SETTLE_STEP" --q2="$q2" --q3="$q3" \
           --vdd "$v" --current-cycles "$cyc" --max-cycles "$MAX_CYCLES" \
           --thresh "$SETTLE_MAX_PCT" --noise-floor-pj "$NOISE_FLOOR_PJ") || _final_rc=$?
  SETTLED=0; GAP_PCT="$gap"; DELTA_E_PJ=""; REASON=""
  eval "$_final"
  if [ "$_final_rc" -gt 2 ] || [ -z "$GAP_PCT" ]; then
    ng_fail "periphery-energy" "$cx" "$sp" "$lg" \
            "0 (settling evaluator)" "${REASON:-invalid settling evaluator response}"
  elif [ "$SETTLED" = "1" ]; then
    echo "  $cx: $REASON"
  else
    # Keep the existing failure ledger/provenance path. This makes a maxed-out
    # dynamic run just as unusable as the former fixed-step run, while a
    # noise-floor convergence is accepted consistently here and in the loop.
    check_settled "periphery-energy" "$lg" "$cx" "$GAP_PCT" "$sp" || true
  fi
done

ng_summary
