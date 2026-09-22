#!/bin/sh
# COLUMN DECODE DELAY -- precharge -> column select.
#
# WHY THIS EXISTS: until 2026-09-22 `rom_column_decode` was the one block in
# the macro the flow never simulated. run_backend_delay.sh drives the eight
# column selects with ideal DC sources, so nothing proved they are where they
# have to be when the bitline data arrives. README "Known limitations" item 2
# called the margin large but unproven; this script is what proves it.
#
# WHAT THE NETLIST SAYS (top level of <macro>.sp):
#     Xrom_column_decoder  addr0[0] addr0[1] addr0[2]
#   +   word_sel_0 .. word_sel_7  precharge precharge  vccd1 vssd1
# Both its `clk` and its `precharge` port sit on the INTERNAL PRECHARGE NET --
# the same net t_dis_50 triggers off. So the column decoder does not sit in
# series with the bitline: the two start on the same edge and RACE.
#
#     access = t_clk2pre + max(t_dis_50, t_pre2sel) + t_bl2dout
#
# The column decoder enters access only if it ever wins that race. It does not
# -- but "it does not" is now a measurement rather than an estimate, and this
# script fails loudly if a future macro changes that.
#
# POLARITY (measured, not assumed): rom_column_decode_wordline_buffer inverts
# the precharged decode array, so ALL EIGHT selects are LOW during precharge
# (the mux is off, the 32 outputs float) and only the SELECTED one rises during
# evaluate. That is the opposite of the row decoder, where every wordline is
# high during precharge and the unselected ones fall. The seven unselected
# selects therefore report "failed" in the log, and that failure IS the
# evidence -- which is why every address is swept: across the eight runs each
# select must be the one that moves exactly once.
#
# THE LOAD IS REAL: rom_column_mux_array is deleted like every other block, but
# its gate load is put back by the same slice x count rule the cell array uses
# -- 32 pass transistors plus 44-79 fF of wire per select. A decoder measured
# into no load is not a measurement.
#
# COST, and MIND THE MEMORY. cs0=1 only (at cs0=0 the precharge net never
# rises and there is nothing to measure), so it is <corners> x <addresses>
# runs per macro, each about 6 minutes. Each ngspice holds ~2.6 GB: this deck
# keeps the row decoder as well, because the precharge edge the decoder sees is
# produced by the real precharge driver rather than a synthetic ramp. JOBS=12
# on a 31 GB machine drove it into swap and one batch had not finished in 22
# minutes (2026-09-22). Budget ~3 GB per job.
#
# The full 8 x 3 x 4 sweep is over 9 CPU-hours, and most of it is redundant:
# the eight selects differ only in wire load (44-79 fF on the examples,
# monotonic from sel_0 down to sel_7), so ONE address is the worst everywhere.
# The two-phase run below gets the same evidence in about half an hour:
#
#   # A) which select each address drives, and which one is slowest -- one
#   #    macro, one corner is enough to establish the pattern
#   ROM_CORNERS="tt:1.8:25:38.2" JOBS=6 \
#     scripts/rom_char/run_coldec_delay.sh wrom0
#   # B) that worst address everywhere -- these are the numbers the .lib uses
#   COLDEC_ADDRS="0" JOBS=6 scripts/rom_char/run_coldec_delay.sh
#
# regen_rom_libs.sh takes the WORST t_pre2sel over whatever coldec_a*_<corner>
# logs exist, so a partial sweep is honest -- it just has less to choose from.
#
# Usage: scripts/rom_char/run_coldec_delay.sh [macro ...]

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
GENP="$ROM_CHAR_DIR/gen_periphery_power_tb.py"

# The column decoder takes addr0[0:2]; each of the eight values selects one
# column select. Sweeping all eight is what turns the "failed" lines into
# evidence -- see the polarity note above.
ADDRS="${COLDEC_ADDRS:-0 1 2 3 4 5 6 7}"
# Timing run, not an energy run: the measured edge is cycle <CYCLES-2>, and the
# decoder settles long before the bitline does. 5 keeps the runtime sane; the
# energy decks keep their 8.
CYCLES="${COLDEC_CYCLES:-5}"

MACROS=$(macro_list "$@")

echo "== column decode delay: precharge -> column select =="
echo "   addresses: $ADDRS   cycles: $CYCLES"
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
    for a in $ADDRS; do
      sp="$G_CHAR/coldec_a${a}_${c}.sp"
      lg="$G_CHAR/coldec_a${a}_${c}.log"
      python3 "$GENP" "$m" 1 "$sp" --corner "$c" --vdd "$v" --temp "$t" \
              --gate-cap-ff "$cg" --with-coldec --addr "$a" \
              --cycles "$CYCLES" >/dev/null
      ( $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true ) &
      n=$((n+1))
      [ $((n % JOBS)) -eq 0 ] && wait
    done
  done
done
wait

# --- Summary --------------------------------------------------------------
# For each address: which select moved, how long it took, and what it has to
# beat. The margin column is the whole point of the measurement.
echo
printf "%-7s %-6s %5s %5s %12s %12s %10s\n" \
       macro corner addr sel "t_pre2sel" "t_dis_50" "margin"
rc=0
for m in $MACROS; do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    tdis=$(meas "$G_CHAR/col${G_WORST_COL}_worst_case_parasitic_${c}.log" t_dis_50)
    [ -z "$tdis" ] && tdis=$(meas \
        "$G_CHAR/col${G_WORST_COL}_worst_case_parasitic.log" t_dis_50)
    for a in $ADDRS; do
      lg="$G_CHAR/coldec_a${a}_${c}.log"
      if [ ! -f "$lg" ]; then
        printf "%-7s %-6s %5s %5s %12s\n" "$m" "$c" "$a" "-" "NO LOG"
        rc=1
        continue
      fi
      # the select that actually moved: the only t_pre2selK_rise that returned
      # a positive number (the other seven never cross VDD/2)
      line=$(awk '/^t_pre2sel[0-9]+_rise /{ if ($3+0 > 0) print $1, $3 }' "$lg" \
             | head -1)
      if [ -z "$line" ]; then
        printf "%-7s %-6s %5s %5s %12s\n" "$m" "$c" "$a" "-" "NO SELECT ROSE"
        rc=1
        continue
      fi
      k=$(echo "$line" | sed -E 's/^t_pre2sel([0-9]+)_rise.*/\1/')
      ts=$(echo "$line" | awk '{print $2}')
      nmoved=$(awk '/^t_pre2sel[0-9]+_rise /{ if ($3+0 > 0) n++ } END{print n+0}' "$lg")
      printf "%-7s %-6s %5s %5s %12.4f" "$m" "$c" "$a" "$k" \
             "$(echo "$ts" | awk '{print $1*1e9}')"
      if [ -z "$tdis" ]; then
        printf " %12s %10s\n" "?" "?"
        rc=1
      else
        printf " %12.4f" "$(echo "$tdis" | awk '{print $1*1e9}')"
        echo "$ts $tdis" | awk '{ if ($1 < $2) printf " %9.1fx\n", $2/$1
                                  else { printf " %10s\n", "LOSES RACE"; exit 3 } }' \
          || rc=1
      fi
      if [ "$nmoved" != "1" ]; then
        echo "    WARNING: $nmoved selects rose at address $a -- exactly one" \
             "should. The decoder is not one-hot in this run."
        rc=1
      fi
    done
  done
done

echo
if [ "$rc" = 0 ]; then
  echo "Every address drove exactly ONE select, and every one of them was"
  echo "ready before the bitline reached 50%. The column decoder is off the"
  echo "critical path by the margin above -- access stays"
  echo "  t_clk2pre + t_dis_50 + t_bl2dout."
else
  echo "SOMETHING ABOVE DID NOT HOLD. If a select LOSES RACE, the column"
  echo "decoder is now the middle term of access and gen_rom_lib.py must take"
  echo "max(t_dis_50, t_pre2sel) instead of t_dis_50 -- do not ship the .lib"
  echo "until that is done."
fi
exit $rc
