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

# --- Step 1: equivalent cell gate capacitance ----------------------------
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

# --- Step 2: periphery energy --------------------------------------------
echo
echo "== Step 2: periphery energy per cycle =="
n=0
for m in $MACROS; do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)
    cg=$(meas "$G_CHAR/cellgate_${c}.log" c_one_ff)
    [ -z "$cg" ] && { echo "  $m $c: no C_eq, skipped"; continue; }
    for cs in 0 1; do
      tag=$([ "$cs" = 0 ] && echo idle || echo active)
      sp="$G_CHAR/periph_${tag}_${c}.sp"
      lg="$G_CHAR/periph_${tag}_${c}.log"
      python3 "$GENP" "$m" "$cs" "$sp" --corner "$c" --vdd "$v" --temp "$t" \
              --gate-cap-ff "$cg" >/dev/null
      run_ng "periphery-energy" "$sp" "$lg" "$m $c cs$cs" &
      n=$((n+1))
      [ $((n % JOBS)) -eq 0 ] && wait
    done
  done
done
wait

# --- Summary --------------------------------------------------------------
echo
printf "%-7s %-6s %-4s %14s %10s %14s\n" macro corner cs0 "E_periph(pJ)" "c2/c3(%)" "P@fmax(mW)"
# Rows are collected here and judged AFTER the table, so one run still shows
# every macro and corner before it fails.
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
      if [ -z "$q3" ]; then
        printf "%-7s %-6s %-4s %14s\n" "$m" "$c" "$cs" "FAILED"; continue
      fi
      # The gap is computed separately from the row because it is now DATA --
      # check_settled decides on it. Printed to two decimals for the same
      # reason: at the 1% limit one decimal cannot show which side of it a
      # row is on.
      gap=$(echo "$q2 $q3" | awk '
        { q2 = ($1 < 0 ? -$1 : $1); q3 = ($2 < 0 ? -$2 : $2);
          printf "%.2f", q3 ? (q2-q3 < 0 ? q3-q2 : q2-q3)/q3*100 : 0 }')
      echo "$q3" | awk -v m="$m" -v c="$c" -v cs="$cs" -v v="$v" -v f="$f" -v g="$gap" '
        { q3 = ($1 < 0 ? -$1 : $1);
          e = q3*v*1e12;
          pmw = e*1e-12*f*1e6*1e3;
          printf "%-7s %-6s %-4s %14.4f %10.2f %14.4f\n", m, c, cs, e, g, pmw }'
      # EVERY row is collected, not just the ones that look bad here: the
      # limit lives in check_settled and must not be spelled a second time.
      rows="${rows}$m $c cs$cs|$gap|$lg|$sp
"
    done
  done
done
echo
echo "NOTE: the c2/c3 gap shows whether the circuit has SETTLED. Over"
echo "      ${SETTLE_MAX_PCT}% FAILS the run (SETTLE_MAX_PCT to change it): raise --cycles"
echo "      and re-run. The energy should be frequency independent -- check"
echo "      with --tclk 400n."

# Over the limit is a failure, not a remark. It is entered in the same ledger
# a crash uses, so ng_summary reports both together and the exit code covers
# both. Done after the table for the reason given at the top of it.
printf '%s' "$rows" | while IFS='|' read -r cx gap lg sp; do
  [ -n "$cx" ] || continue
  check_settled "periphery-energy" "$lg" "$cx" "$gap" "$sp" || true
done

# Non-zero if any deck died OR any of them never settled. In the first case
# the number is simply absent, and absent is indistinguishable from fine; in
# the second it is present and wrong, which is worse.
ng_summary
