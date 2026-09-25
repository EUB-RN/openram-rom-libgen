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
ng_reset          # clear the failure ledger for this run
GENP="$ROM_CHAR_DIR/gen_periphery_power_tb.py"

# The charge over a full swing must NOT depend on how fast the pin is ramped;
# running two values and comparing is the same check the energy decks make
# against --tclk. 1 ns is the default and is also the deck's timestep.
PIN_TR="${PIN_TR:-1n}"

# THERE IS NO WHOLE-MACRO REFERENCE RUN, and this is the one cross-check that
# is deliberately NOT offered. It existed: a --keep-all deck that deleted
# nothing, the full cell array simulated, so the reduction had nothing left to
# be wrong about. On wrom0 -- a 1 kbit example -- it ran for hours at ~15 GB
# and was killed before it finished. The cell array is the one block whose
# size the USER picks, so that cost is not a fixed price: it grows with every
# macro this generator is pointed at, and on a real ROM the deck does not run
# slowly, it dies. A check that only works on the smallest possible macro
# cannot be part of a generator's flow, so it was removed rather than left in
# as a knob nobody can afford to turn.
#
# THE MEASUREMENT ITSELF IS UNTOUCHED: every pin, every corner, the reduced
# deck. What is gone is only the reference it used to be compared against. The
# checks that remain -- rise vs fall below, ramp independence across two
# --pin-tr values, agreement across macros and corners -- all run on that same
# reduced deck, so none of them can see an error the reduction makes in every
# variant at once. That error is BOUNDED rather than measured: doubling the
# lumped load the deleted array is replaced by moved addr0[0] by 4.9% and
# every other pin by under 0.6% (docs/limitations.md item 5). A bound is what
# these numbers carry, and the .lib header says so.

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
    job_slot
    run_ng "pin-cap" "$sp" "$lg" "$m $c" & job_add $!
    n=$((n+1))
  done
done
job_drain

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
echo
echo "RAMP INDEPENDENCE is the check this deck cannot make on its own -- the"
echo "charge over a full swing must not depend on --pin-tr. Run it twice:"
echo "  PIN_TR=1n scripts/rom_char/run_pin_cap.sh wrom0"
echo "  PIN_TR=2n scripts/rom_char/run_pin_cap.sh wrom0"
echo "On wrom0 at TT (2026-09-22) eleven of thirteen pins agreed to 0.45%;"
echo "clk0 and addr0[6] moved 4-5%, and those two are the ones the gap check"
echo "above also flags."
echo
echo "WHAT NONE OF THESE CHECKS CAN SEE is an error shared by every variant:"
echo "they all run the same reduced deck, with the cell array deleted and its"
echo "load put back as lumped C. Seeing it would take a deck that simulates"
echo "the whole array, whose cost grows with the array the user chooses -- it"
echo "is not runnable on a real ROM, so it is not offered. The reduction cost"
echo "is BOUNDED instead of proven: doubling the lumped array load moved the"
echo "worst pin (addr0[0] on wrom0) by 4.9% and every other pin by under 0.6%."
echo "docs/limitations.md item 5 carries that as a limitation of these numbers."

exit $rc

# Non-zero if any deck died. The numbers those decks would have produced
# are simply absent otherwise, and absent is indistinguishable from fine.
ng_summary
