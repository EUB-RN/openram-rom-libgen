#!/bin/sh
# INPUT PIN CAPACITANCE -- the `capacitance` attribute of every input pin.
#
# WHY THIS EXISTS: until 2026-09-22 those numbers were not measured at all.
# gen_rom_lib.py carried
#     PIN_CAP = {"clk0": 0.0025, "cs0": 0.0030, "_default": 0.0060}
# i.e. an analytic estimate from gate widths, with ONE value covering all
# eleven address bits (README limitation 5). The extraction says that cannot
# be right on its face: the top-level wire C alone runs from 6 C elements on
# addr0[0] to 41 on addr0[10], so the address pins cannot all be the same.
#
# WHAT IS MEASURED: each pin is ramped 0 -> VDD on its own and the charge it
# has to supply is integrated, C = Q(VDD)/VDD -- the same reduction
# gen_cell_gate_tb.py uses for the cell gate, and the right one for Liberty,
# whose `capacitance` is a single scalar a driver's delay calculation
# multiplies. It captures the whole load, not just a gate: the pin's wire C,
# the gate C of the first stage it drives, and the Miller charge pushed back
# through that stage as it switches.
#
# BOTH EDGES. c_rise and c_fall are measured separately. They should agree; a
# pin where they do not is state dependent and no single Liberty number can
# represent it. The summary prints the gap and ships the LARGER of the two --
# a driver that is told to expect less capacitance than it finds is the unsafe
# direction.
#
# WHY IT KEEPS THE WHOLE PERIPHERY: addr0[0:2] go to the COLUMN decoder and
# addr0[3:] to the row decoder, while clk0 and cs0 go to the control logic, so
# every one of the three blocks has to be in the deck or some pin would be
# measured driving nothing. The cell array and the column mux are deleted but
# put back as load, because the decoders have to switch against what they
# really drive -- that switching is what feeds Miller charge back into the
# address pins.
#
# COST: one run per macro per corner (the deck measures every pin at once),
# about 7 minutes and ~2.6 GB each. Budget ~3 GB per job.
#
# Usage: scripts/rom_char/run_pin_cap.sh [macro ...]
#        PIN_TR=2n scripts/rom_char/run_pin_cap.sh wrom0   # ramp-time check

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
GENP="$ROM_CHAR_DIR/gen_periphery_power_tb.py"

# The charge over a full swing must NOT depend on how fast the pin is ramped;
# running two values and comparing is the same check the energy decks make
# against --tclk. 1 ns is the default and is also the deck's timestep.
PIN_TR="${PIN_TR:-1n}"

# THE GOLDEN REFERENCE. Every other cross-check on these numbers -- ramp
# independence, agreement across macros, insensitivity to a 2x change in the
# array load -- is a SELF-CONSISTENCY check. They bound how much the answer
# moves when a knob moves, and none of them can see an error that every
# variant shares. The only thing that can is a run with NOTHING deleted:
# --keep-all keeps the whole cell array, so no block is replaced by a lumped
# load and there is no reduction left to be wrong about.
#
# It is expensive -- the deck goes from ~2.8k to ~38k devices and from 19k to
# 168k capacitors, and it ran for hours at ~15 GB on wrom0 -- so it measures a
# FEW pins rather than all thirteen (the run time is set by the pin count,
# each pin getting its own slot). Off by default; set GOLDEN_PINS to run it.
#
#   GOLDEN_PINS="clk0,addr0[0],addr0[9]" scripts/rom_char/run_pin_cap.sh wrom0
#
# addr0[0] is worth including: it is the pin the settling check flags, the one
# that moves with the ramp time, and the one that moved -4.9% when the array
# load was doubled -- i.e. the pin where the reduction is most likely to show.
GOLDEN_PINS="${GOLDEN_PINS:-}"
# Deviation of the reduced deck from the golden reference, in percent, above
# which a WARNING is printed. It does NOT fail the run: this is a modelling
# cross-check, not a correctness gate, and a noisy gate that blocks the flow
# teaches people to ignore it.
#
# Why 10: the reduced deck reproduces itself to 0.45% across ramp times on
# eleven of thirteen pins, and to 4-5% on addr0[0] and addr0[6], so the band
# has to sit above 5% or it fires on behaviour that is already documented. A
# real reduction error is not a few percent -- the analytic estimate this work
# replaced was off by 58-96%. 10% sits between the two.
GOLDEN_BAND="${GOLDEN_BAND:-10}"

MACROS=$(macro_list "$@")

echo "== input pin capacitance: C = Q(VDD)/VDD per pin =="
echo "   ramp: $PIN_TR"
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
    sp="$G_CHAR/pincap_${c}.sp"
    lg="$G_CHAR/pincap_${c}.log"
    python3 "$GENP" "$m" 1 "$sp" --corner "$c" --vdd "$v" --temp "$t" \
            --gate-cap-ff "$cg" --pin-cap --pin-tr "$PIN_TR" >/dev/null
    ( $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true ) &
    n=$((n+1))
    [ $((n % JOBS)) -eq 0 ] && wait
  done
done
wait

# --- the golden reference, when asked for -------------------------------
if [ -n "$GOLDEN_PINS" ]; then
  echo
  echo "== golden reference (nothing deleted): $GOLDEN_PINS =="
  n=0
  for m in $MACROS; do
    load_geom "$m" || continue
    for ck in $CORNERS; do
      c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
      t=$(echo "$ck" | cut -d: -f3)
      sp="$G_CHAR/pincap_golden_${c}.sp"
      lg="$G_CHAR/pincap_golden_${c}.log"
      python3 "$GENP" "$m" 1 "$sp" --corner "$c" --vdd "$v" --temp "$t" \
              --pin-cap --pin-tr "$PIN_TR" --keep-all \
              --pin-only "$GOLDEN_PINS" >/dev/null
      ( $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true ) &
      n=$((n+1))
      [ $((n % JOBS)) -eq 0 ] && wait
    done
  done
  wait
fi

# --- Summary --------------------------------------------------------------
# The pin index -> name mapping is a *PINCAP marker the generator writes into
# the deck, so the table names real pins rather than indices.
echo
printf "%-7s %-6s %-11s %9s %9s %9s %8s\n" \
       macro corner pin c_cyc c_rise c_fall gap
rc=0
for m in $MACROS; do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    sp="$G_CHAR/pincap_${c}.sp"
    lg="$G_CHAR/pincap_${c}.log"
    if [ ! -f "$lg" ] || [ ! -f "$sp" ]; then
      printf "%-7s %-6s %-11s %9s\n" "$m" "$c" "-" "NO LOG"
      rc=1
      continue
    fi
    sed -n 's/^\*PINCAP \([0-9][0-9]*\) \(.*\)$/\1 \2/p' "$sp" | while read -r i p; do
      cy=$(meas "$lg" "c_cyc${i}_ff")
      cr=$(meas "$lg" "c_rise${i}_ff")
      cf=$(meas "$lg" "c_fall${i}_ff")
      if [ -z "$cy" ] || [ -z "$cr" ] || [ -z "$cf" ]; then
        printf "%-7s %-6s %-11s %9s\n" "$m" "$c" "$p" "FAILED"
        continue
      fi
      printf "%-7s %-6s %-11s %9.4f %9.4f %9.4f" "$m" "$c" "$p" "$cy" "$cr" "$cf"
      echo "$cr $cf" | awk '{ lo = $1 < $2 ? $1 : $2; hi = $1 > $2 ? $1 : $2
                              g = lo ? (hi-lo)/lo*100 : 0
                              printf " %7.1f%%%s\n", g, (g > 5 ? "  <-- NOT SETTLED" : "") }'
    done
    # the gate: a pin whose two edges disagree by more than 5%
    sed -n 's/^\*PINCAP \([0-9][0-9]*\) \(.*\)$/\1/p' "$sp" | while read -r i; do
      cr=$(meas "$lg" "c_rise${i}_ff"); cf=$(meas "$lg" "c_fall${i}_ff")
      [ -z "$cr" ] || [ -z "$cf" ] && continue
      echo "$cr $cf" | awk '{ lo = $1 < $2 ? $1 : $2; hi = $1 > $2 ? $1 : $2
                              if (lo && (hi-lo)/lo*100 > 5) exit 1 }' || echo unsettled
    done | grep -q unsettled && rc=1
  done
done

echo
echo "c_cyc is the number that ships: the charge for one full 0 -> VDD -> 0"
echo "round trip, over two swings. It is used INSTEAD of either edge because"
echo "the two edges trade charge across the window boundary when a pin has a"
echo "deep fanout -- on clk0 they swapped places between two ramp times while"
echo "their sum held to 0.2%. c_rise and c_fall are kept as the settling"
echo "proof: a gap over 5% means the tail has not died inside the window and"
echo "that pin's number carries a few percent of ramp-time sensitivity."
# --- reduced vs golden ----------------------------------------------------
gold_seen=0
for m in $MACROS; do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    gsp="$G_CHAR/pincap_golden_${c}.sp"
    glg="$G_CHAR/pincap_golden_${c}.log"
    rlg="$G_CHAR/pincap_${c}.log"
    [ -f "$gsp" ] && [ -f "$glg" ] && [ -f "$rlg" ] || continue
    if [ "$gold_seen" = 0 ]; then
      echo
      printf "%-7s %-6s %-11s %9s %9s %8s\n" \
             macro corner pin reduced golden dev
      gold_seen=1
    fi
    # the golden deck measures a SUBSET, so it has its own index numbering;
    # both files are matched by PIN NAME through their own *PINCAP markers.
    sed -n 's/^\*PINCAP \([0-9][0-9]*\) \(.*\)$/\1 \2/p' "$gsp" | while read -r gi p; do
      gv=$(meas "$glg" "c_cyc${gi}_ff")
      ri=$(sed -n "s/^\*PINCAP \([0-9][0-9]*\) $(echo "$p" | sed 's/[][]/\\&/g')\$/\1/p" \
             "$G_CHAR/pincap_${c}.sp")
      rv=""
      [ -n "$ri" ] && rv=$(meas "$rlg" "c_cyc${ri}_ff")
      if [ -z "$gv" ] || [ -z "$rv" ]; then
        printf "%-7s %-6s %-11s %9s\n" "$m" "$c" "$p" "NO PAIR"
        continue
      fi
      printf "%-7s %-6s %-11s %9.4f %9.4f" "$m" "$c" "$p" "$rv" "$gv"
      echo "$rv $gv $GOLDEN_BAND" \
        | awk '{ d = $2 ? ($1-$2)/$2*100 : 0
                 a = d < 0 ? -d : d
                 printf " %+7.2f%%%s\n", d,
                        (a > $3 ? "  <-- WARNING: outside the +-" $3 "% band" : "") }'
    done
  done
done
if [ "$gold_seen" = 0 ] && [ -n "$GOLDEN_PINS" ]; then
  echo
  echo "  golden reference asked for but no usable log pair was produced."
fi

echo
echo "RAMP INDEPENDENCE is the check this deck cannot make on its own -- the"
echo "charge over a full swing must not depend on --pin-tr. Run it twice:"
echo "  PIN_TR=1n scripts/rom_char/run_pin_cap.sh wrom0"
echo "  PIN_TR=2n scripts/rom_char/run_pin_cap.sh wrom0"
echo "On wrom0 at TT (2026-09-22) eleven of thirteen pins agreed to 0.45%;"
echo "clk0 and addr0[6] moved 4-5%, and those two are the ones the gap check"
echo "above also flags."
echo
echo "THE GOLDEN REFERENCE is the only check here that is not a"
echo "self-consistency check: GOLDEN_PINS runs the same measurement with"
echo "NOTHING deleted -- the whole cell array in the deck, no lumped load --"
echo "so it sees reduction error that every other cross-check is blind to."
echo "A deviation outside +-${GOLDEN_BAND}% is WARNED about and nothing more:"
echo "it is a modelling cross-check, not a correctness gate."

exit $rc
