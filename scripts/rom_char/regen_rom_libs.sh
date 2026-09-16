#!/bin/sh
# Generate the .lib files for every ROM macro in the tree, three corners each,
# from MEASURED values.  Usage:
#     scripts/rom_char/regen_rom_libs.sh [macro ...]
#     ROM_MACROS_DIR=/path/to/macros scripts/rom_char/regen_rom_libs.sh
# Output: $ROM_OUT_DIR/lib (default <repo>/output/lib)
#
# TIMING (access = three terms, all measured):
#   1) front end   clk0 -> precharge : char/periph_active_<corner>.log t_clk2pre
#   2) bitline     precharge -> bl 50%: char/col<N>_worst_case_parasitic*.log
#   3) back end    bitline -> dout0  : char/backend_<corner>_<load>.log t_bl2dout
#   output slew                      : same file, t_dout_slew
# LEAKAGE: char/col<N>_leak_<corner>.log   (vvdd#branch from the .op table)
# ENERGY : column array <columns> x char/col<N>_energy_<corner>.log e_col_pj
#          + periphery              char/periph_active_<corner>.log  e_periph_pj
#   idle   (when "!cs0")            : char/periph_idle_<corner>.log  e_periph_pj
# SETUP  : char/periph_setup_<corner>.log  t_addr2dec* (worst of them)
#
# Terms 1 and 3, the periphery energy and the output slew were added on
# 2026-09-06; before that `access` covered only the MIDDLE term, the slew was
# a fixed guess, and because idle power was never written OpenSTA silently
# treated it as zero.
#
# EVERY NUMBER IS READ FROM A LOG -- nothing is copied by hand. An earlier
# version kept the macro names, the worst column/chain and the
# access/t_pre/leakage values in a TABLE inside this file; regenerating the
# ROM (new word_size / words_per_row / .bin) silently invalidated it. Now:
#   * macro list       <- <macro>/<macro>.sp directories in the tree
#   * worst column     <- netlist scan (rom_paths.py / find_worst_column)
#   * chain length     <- same scan
#   * column count     <- same scan (energy/leakage multiplier; was a literal 256)
#   * access / t_pre   <- col<N>_worst_case_parasitic*.log (t_dis_50/t_pre_99)
#   * leakage          <- col<N>_leak_<corner>.log
#
# t_pre uses t_pre_99, NOT t_pre_90: 90% recharge comes out ~0.5 ns and would
# write a min_pulse_width(fall) 20x too small.
#
# --measured IS REQUIRED: the values already belong to that corner, so the
# derating factors in the CORNERS table must NOT be applied on top (double
# counting would turn SS 38 ns into 70 ns).

set -e
. "$(dirname "$0")/common.sh"

GEN="$ROM_CHAR_DIR/gen_rom_lib.py"

# file-name tag of a .lib CELL_TABLE index_2 point (1.7225 -> 17225)
load_tags() { for cl in $LOADS; do echo "$cl" | tr -d '.'; done; }

# comma-separated list in ns: $1=char dir  $2=corner  $3=measurement name
be_list() {
  out=""
  for t in $(load_tags); do
    v=$(meas "$1/backend_${2}_${t}.log" "$3")
    [ -z "$v" ] && { echo ""; return; }
    out="${out:+$out,}$(echo "$v" | awk '{printf "%.4f", $1*1e9}')"
  done
  echo "$out"
}

for m in $(macro_list "$@"); do
  load_geom "$m" || { echo "$m: cannot read geometry, skipped"; continue; }
  col="$G_WORST_COL"
  LEF="$G_LEF"

  for ck in $CORNERS; do
    c=$(echo  "$ck" | cut -d: -f1)
    vdd=$(echo "$ck" | cut -d: -f2)
    corner=$(corner_lib_name "$c")
    # the TT file has no suffix, the others are _ss / _ff
    [ "$c" = tt ] && sfx="" || sfx="_$c"

    PAR="$G_CHAR/${G_COLTAG}_worst_case_parasitic${sfx}.log"
    PA="$G_CHAR/periph_active_${c}.log"
    PI="$G_CHAR/periph_idle_${c}.log"
    EC="$G_CHAR/${G_COLTAG}_energy_${c}.log"
    LK="$G_CHAR/${G_COLTAG}_leak_${c}.log"

    # 2) bitline term + precharge time (that corner's own run)
    acc=$(meas "$PAR" t_dis_50 | awk '{printf "%.4f", $1*1e9}')
    pre=$(meas "$PAR" t_pre_99 | awk '{printf "%.4f", $1*1e9}')

    # Leakage is not a .measure: it is the supply current in the .op table.
    # P = |I| x <column count> x VDD  -> mW
    leak=$(grep -m1 "vvdd#branch" "$LK" 2>/dev/null | awk -v n="$G_COLS" -v v="$vdd" \
             '{ i = $2 < 0 ? -$2 : $2; printf "%.7f", i*n*v*1e3 }')

    # 1) front end: clk0 -> precharge. The column measurement triggers off the
    #    internal precharge net, so this term was MISSING from access. (Cross-
    #    checked against the wordline path with t_clk2wl0: in all three
    #    corners the wordline is FASTER than the precharge path, so precharge
    #    is the critical one.)
    tf=$(meas "$PA" t_clk2pre | awk '{printf "%.4f", $1*1e9}')
    # 3) back end: bitline -> dout0 plus output slew, at three load points
    be=$(be_list "$G_CHAR" "$c" t_bl2dout)
    sl=$(be_list "$G_CHAR" "$c" t_dout_slew)
    # energy: column array (G_COLS columns) + periphery
    e_act=$(awk -v n="$G_COLS" -v ec="$(meas "$EC" e_col_pj)" \
                -v ep="$(meas "$PA" e_periph_pj)" \
                'BEGIN{ if (ec == "" || ep == "") exit 1; printf "%.4f", n*ec + ep }') || e_act=""
    e_idle=$(meas "$PI" e_periph_pj | awk '{printf "%.4f", $1}')

    # A missing measurement means a silently wrong .lib. Say which term it is.
    missing=""
    for pair in "acc:$acc" "pre:$pre" "leak:$leak" "tf:$tf" "be:$be" \
                "sl:$sl" "e_act:$e_act" "e_idle:$e_idle"; do
      if [ -z "${pair#*:}" ]; then
        missing="${missing:+$missing, }${pair%%:*}"
      fi
    done
    if [ -n "$missing" ]; then
      echo "$m $c: missing measurement ($missing) -- skipped"
      continue
    fi

    # setup: MEASURED DIRECTLY since 2026-09-08.
    # run_addr_setup.sh switches addr0 during the precharge phase and measures
    #   addr0 -> inv_array_mod/Z  (= the A input of the decoder NAND)
    # taking the WORST of the per-address-bit buffers. The decoder is a CLOCKED
    # NAND, so that net is exactly where the address has to be stable.
    #
    # It used to be an analytic upper bound of 3 x t_clk2pre (~4.93 ns at SS);
    # the measured value at SS is 0.053 ns, i.e. the bound was ~90x pessimistic.
    # With no measurement we FALL BACK to that pessimistic bound -- writing a
    # large number is the safe side, writing a small one silently is not.
    stl="$G_CHAR/periph_setup_${c}.log"
    stp=$(awk '/^t_addr2dec[0-9]+/ { if ($3 ~ /^[0-9.eE+-]+$/ && $3+0 > mx) mx = $3+0 }
               END { if (mx > 0) printf "%.4f", mx*1e9 }' "$stl" 2>/dev/null)
    if [ -z "$stp" ]; then
      stp=$(awk -v t="$tf" 'BEGIN{printf "%.4f", 3.0*t}')
      echo "  $m $c: no setup measurement -> using pessimistic bound $stp ns"
    fi

    SRC="real Magic parasitic C + that corner's OWN sky130 models; \
${G_ROWS}x${G_COLS} array, worst column ${col} (series NMOS ${G_CHAIN}); \
front end + periphery power char/periph_{active,idle}_${c}.log, \
bitline char/${G_COLTAG}_worst_case_parasitic${sfx}.log, \
back end + slew char/backend_${c}_*.log, \
leakage char/${G_COLTAG}_leak_${c}.log, \
column energy char/${G_COLTAG}_energy_${c}.log"

    python3 "$GEN" --lef "$LEF" --memory-type rom --measured \
      --outdir "$LIB_DIR" \
      --corner "$corner" --access "$acc" --hold "$acc" --t-pre "$pre" \
      --setup "$stp" \
      --leakage-mw "$leak" --energy-pj "$e_act" --energy-idle-pj "$e_idle" \
      --t-front "$tf" --backend-ns "$be" --out-slew-ns "$sl" \
      --chain-len "$G_CHAIN" --worst-col "$col" \
      --rows "$G_ROWS" --cols "$G_COLS" --char-source "$SRC" >/dev/null

    printf "%-7s %-4s access = %.4f + %s + %s = %.4f ns  E=%s pJ  E_idle=%s pJ\n" \
      "$m" "$c" "$tf" "$acc" "$(echo "$be" | cut -d, -f3)" \
      "$(awk -v a="$tf" -v b="$acc" -v d="$(echo "$be" | cut -d, -f3)" \
            'BEGIN{print a+b+d}')" "$e_act" "$e_idle"
  done
done
echo "Done -- .lib files written to $LIB_DIR with measured timing"
echo "(front end + bitline + back end), output slew, leakage and energy"
echo "(active + idle)."
