#!/bin/sh
# addr0 -> decoder SETUP measurement, every macro x three corners.
#
# WHAT IS MEASURED
# ----------------
# `setup_rising` in the .lib: how long addr0/cs0 must be stable BEFORE clk0
# rises. In this macro it has an exact physical counterpart:
#
#     rom_address_control_buf structure (from the netlist):
#         addr0 -> inv_array_mod/Z -> nand2_dec(A=inv/Z, clk) -> A_out
#
# i.e. the address goes from the buffer STRAIGHT into a clocked NAND; there is
# no separate predecode stage in between. The last point at which the address
# must be stable is inv_array_mod's Z, and what we measure is the addr0 -> that
# net delay.
#
# WHY IT MATTERS: the decoder is PRECHARGED. During precharge every wordline
# rises; during evaluate the UNSELECTED ones fall. If the address has not
# settled when evaluate begins, the WRONG wordline falls -- and, like a
# bitline, a decoder node does not come back until the next precharge. So a
# setup violation is not metastability: it is a silent, persistent misread.
#
# WHY A SEPARATE DECK: an address transition costs extra switching energy; put
# into the periph_active/idle decks it would inflate the per-cycle energy
# measurement. This script calls the same generator with --addr-alt and runs a
# SEPARATE deck, leaving the power flow untouched.
#
# WORST-CASE ADDRESS: 0 -> all address bits high (derived from the number of
# addr0[] pins in the LEF). Every buffer switches at once, supply droop
# included. This used to be a literal 2047 (11 bits), which silently became a
# weaker stimulus whenever the address width changed.
#
# Usage: scripts/rom_char/run_addr_setup.sh [macro ...]
# Output: <macro>/char/periph_setup_<corner>.log plus a summary table;
#         regen_rom_libs.sh feeds it to --setup.

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
GENP="$ROM_CHAR_DIR/gen_periphery_power_tb.py"
JOBS="${JOBS:-6}"

MACROS=$(macro_list "$@")
n=0
for m in $MACROS; do
  load_geom "$m" || continue
  ADDR=0
  ADDR_ALT=$(awk -v b="$G_ADDR_BITS" 'BEGIN{printf "%d", 2^b - 1}')
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)

    # equivalent cell gate capacitance -- same input as the periph deck
    cgl="$G_CHAR/cellgate_${c}.log"
    if [ ! -f "$cgl" ]; then
      echo "  $m $c: no cellgate log (run run_periphery_power.sh first), skipped"
      continue
    fi
    cg=$(meas "$cgl" c_one_ff)
    [ -z "$cg" ] && { echo "  $m $c: no C_eq, skipped"; continue; }

    sp="$G_CHAR/periph_setup_${c}.sp"
    lg="$G_CHAR/periph_setup_${c}.log"
    python3 "$GENP" "$m" 1 "$sp" --corner "$c" --vdd "$v" --temp "$t" \
            --gate-cap-ff "$cg" --addr "$ADDR" --addr-alt "$ADDR_ALT" >/dev/null
    ( $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true ) &
    n=$((n+1))
    [ $((n % JOBS)) -eq 0 ] && wait
  done
done
wait

echo ""
echo "macro   corner  measured setup (ns)   [addr0 -> decoder NAND input]"
for m in $MACROS; do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    lg="$G_CHAR/periph_setup_${c}.log"
    [ -f "$lg" ] || continue
    # the WORST of all the buffer measurements
    w=$(grep -E "^t_addr2dec[0-9]+" "$lg" 2>/dev/null \
        | awk '{ if ($3 ~ /^[0-9.eE+-]+$/ && $3+0 > mx) mx = $3+0 } END { if (mx>0) printf "%.4f", mx*1e9 }')
    cnt=$(grep -cE "^t_addr2dec[0-9]+" "$lg" 2>/dev/null || echo 0)
    printf "%-7s %-6s  %-8s   (%s measurements)\n" "$m" "$c" "${w:-NONE}" "$cnt"
  done
done
