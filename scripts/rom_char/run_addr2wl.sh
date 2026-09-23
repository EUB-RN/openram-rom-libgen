#!/bin/sh
# addr0 -> WORDLINE FALL, every macro x three corners.
#
# WHY THIS EXISTS: hold is measured in the wrong time frame without it.
#
# run_hold_bisect.sh answers the physical question -- how late may the series
# chain be cut and still leave a readable bitline -- but it answers it in the
# COLUMN deck's frame. That deck is driven by a synthetic `precharge` source
# and contains no clk0 at all, so its cut time is counted from the INTERNAL
# evaluate edge. Liberty's `hold_rising` is referenced to the clk0 PIN. Two
# delays separate the two frames:
#
#     hold(clk0 frame) = t_clk2pre  +  cut  -  t_addr2wl
#                        \_______/            \_________/
#                    pin -> array edge      pin -> the wordline it drops
#
# Shipping the raw cut time is the same as asserting that those two cancel.
# On wrom0 at TT they nearly do -- which is luck, not design, and is exactly
# the kind of coincidence that stops holding on the next macro.
#
# WHAT IS MEASURED. The address is switched in the MIDDLE OF EVALUATE, when
# the clocked decoder is transparent, so the newly selected row's wordline
# actually falls. The trigger is the address pin, the target is that fall:
# the delay a moving address needs to reach the array.
#
# WHICH BIT IS SWITCHED. addr0[0 .. log2(words_per_row)-1] drive the COLUMN
# mux, not the rows -- toggling one of those changes which column is read and
# no wordline moves at all. The first ROW bit is therefore
# log2(G_WORDS_PER_ROW) (3 on the example macros, derived here rather than
# fixed), and switching address 0 -> 2^that moves the selection from row 0 to
# row 1, whose wordline is in the probed set.
#
# Output: <macro>/char/addr2wl_<corner>.log, which regen_rom_libs.sh reads to
# convert the hold. Without it the .lib says outright that the hold it carries
# is in the deck's frame rather than clk0's.
#
# Usage: scripts/rom_char/run_addr2wl.sh [macro ...]

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
ng_reset          # clear the failure ledger for this run
GENP="$ROM_CHAR_DIR/gen_periphery_power_tb.py"
JOBS="${JOBS:-3}"

MACROS=$(macro_list "$@")
n=0
for m in $MACROS; do
  load_geom "$m" || continue
  # first ROW address bit = log2(words_per_row); the bits below it are the
  # column select and moving one of those drops no wordline.
  ROWBIT=$(awk -v w="$G_WORDS_PER_ROW" 'BEGIN{
             b = 0; while ((2 ^ b) < w) b++; print b }')
  ALT=$(awk -v b="$ROWBIT" 'BEGIN{printf "%d", 2 ^ b}')
  echo "== $m: switching addr0[$ROWBIT] (0 -> $ALT), row 0 -> row 1 =="
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)

    cgl="$G_CHAR/cellgate_${c}.log"
    if [ ! -f "$cgl" ]; then
      echo "  $m $c: no cellgate log (run run_periphery_power.sh first), skipped"
      continue
    fi
    cg=$(meas "$cgl" c_one_ff)
    [ -z "$cg" ] && { echo "  $m $c: no C_eq, skipped"; continue; }

    sp="$G_CHAR/addr2wl_${c}.sp"
    lg="$G_CHAR/addr2wl_${c}.log"
    python3 "$GENP" "$m" 1 "$sp" --corner "$c" --vdd "$v" --temp "$t" \
            --gate-cap-ff "$cg" --addr 0 --addr-alt "$ALT" \
            --addr-sw-eval >/dev/null
    run_ng "addr-to-wordline" "$sp" "$lg" "$m $c" &
    n=$((n+1))
    [ $((n % JOBS)) -eq 0 ] && wait
  done
done
wait

echo ""
printf "%-7s %-6s %12s %12s %12s   %s\n" \
       macro corner "t_addr2wl" "t_clk2pre" "cut(hold)" "hold(clk0 frame)"
for m in $MACROS; do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    lg="$G_CHAR/addr2wl_${c}.log"
    [ -f "$lg" ] || continue
    # exactly one probed wordline falls -- the row the new address selects.
    # The others report "failed", which is the evidence that nothing else
    # moved, so the WORST (largest) of whatever resolved is the honest pick.
    d=$(awk '/^t_addr2wl[0-9]+ /{ if ($3 ~ /^[0-9.eE+-]+$/ && $3+0 > mx) mx = $3+0 }
             END { if (mx > 0) printf "%.4f", mx*1e9 }' "$lg")
    tf=$(meas "$G_CHAR/periph_active_${c}.log" t_clk2pre |
         awk '{printf "%.4f", $1*1e9}')
    cut=$(meas "$G_CHAR/hold_${c}.log" hold | awk '{printf "%.4f", $1*1e9}')
    if [ -z "$d" ]; then
      printf "%-7s %-6s %12s\n" "$m" "$c" "NO FALL"
      continue
    fi
    if [ -n "$tf" ] && [ -n "$cut" ]; then
      h=$(awk -v a="$tf" -v b="$cut" -v d="$d" 'BEGIN{printf "%.4f", a+b-d}')
    else
      h="(needs hold_${c}.log)"
    fi
    printf "%-7s %-6s %12s %12s %12s   %s\n" \
           "$m" "$c" "$d" "${tf:--}" "${cut:--}" "$h"
  done
done

echo
echo "hold(clk0 frame) = t_clk2pre + cut - t_addr2wl. regen_rom_libs.sh applies"
echo "this conversion itself; the column here is so the two frames can be"
echo "compared by eye. A conversion that comes out NEGATIVE means the address"
echo "reaches the array later than the read is decided, i.e. there is no hold"
echo "requirement left at the pin -- report it, do not ship a negative hold."

# Non-zero if any deck died. The numbers those decks would have produced
# are simply absent otherwise, and absent is indistinguishable from fine.
ng_summary
