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
#      IN PARALLEL: the column decoder, char/coldec_a<addr>_<corner>.log
#      t_pre2sel* -- it hangs off the SAME precharge net, so the middle term
#      is max(bitline, column decode) and not their sum.
#   3) back end    bitline -> dout0  : char/backend_<corner>_<load>.log t_bl2dout
#   output slew                      : same file, t_dout_slew
# INVALIDATION (falling_edge arc on dout0, clk0 falls -> data gone):
#   t_clk2pre + t_pre_50 + the SMALLEST-load t_bl2dout -- the earliest the
#   output can leave its valid level. Without it STA assumes dout0 holds to
#   the next capture edge, which is a false pass on an unlatched ROM.
# LEAKAGE: array     char/col<N>_leak_<corner>.log  (vvdd#branch, x columns)
#          periphery char/periph_leak_cs<n>_<corner>.total  (run_periphery_leak.sh:
#          one slice per block x a count, gmin-swept). Both are taken in the
#          SAME state (clk0 low) so that they can be added. Without the
#          periphery files the .lib says ARRAY ONLY and warns.
# ENERGY : active (when "cs0") is the AVERAGE OF 10 RANDOM READS, not the
#          worst case. Per read, E = <discharging columns in the selected row>
#          x char/col<N>_energy_<corner>.log e_col_pj
#          + char/periph_active_<corner>.log e_periph_pj. The column count
#          comes from the netlist's own cell types (a zero_cell discharges,
#          a one_cell in the selected row does not), so only the ACTIVITY is
#          counted here -- both energy terms are still measured.
#          gen_random_read_energy.py --log writes the per-read table to
#          char/random_energy_<corner>.log. Set ROM_ENERGY_READS to change
#          the sample size.
#   idle   (when "!cs0")            : char/periph_idle_<corner>.log  e_periph_pj
# SETUP  : char/periph_setup_<corner>.log  t_addr2dec* (worst of them)
#
# EVERY NUMBER IS READ FROM A LOG -- nothing is copied by hand, so
# regenerating the ROM (new word_size / words_per_row / .bin) cannot leave a
# stale value behind:
#   * macro list       <- <macro>/<macro>.sp directories in the tree
#   * worst column     <- netlist scan (rom_paths.py / find_worst_column)
#   * chain length     <- same scan
#   * column count     <- same scan (energy/leakage multiplier)
#   * access / t_pre   <- col<N>_worst_case_parasitic*.log (t_dis_50/t_pre_99)
#   * leakage          <- col<N>_leak_<corner>.log
#
# t_pre uses t_pre_99, NOT t_pre_90: 90% recharge comes out ~0.5 ns and would
# write a min_pulse_width(fall) 20x too small. The falling_edge arc is the
# opposite case: it wants the EARLIEST crossing, so it uses t_pre_50.
#
# --measured IS REQUIRED: the values already belong to that corner, so the
# derating factors in the CORNERS table must NOT be applied on top (double
# counting would turn SS 38 ns into 70 ns).

set -e
. "$(dirname "$0")/common.sh"

GEN="$ROM_CHAR_DIR/gen_rom_lib.py"

# --------------------------------------------------------------------------
# ONLY THIS FLOW'S LOGS
#
# Every number below is read back out of a file in <macro>/char. Those files
# outlive everything: re-extract the macro, fix a measurement and rebuild a
# deck, have an ngspice run die halfway, copy the tree from another machine --
# the old log is still sitting there with a plausible number in it, and `meas`
# returns it without a word.
#
# So a log is read only if the flow STAMPED it (common.sh: <log>.prov, written
# by run_ng when the deck came back clean) and that stamp still describes what
# is on disk: same deck, same log, same netlist, and no later verdict against
# it (a failed re-run or check_settled marks it invalid, which is item 2c of
# docs/STATUS.md -- an unsettled periphery log used to be read back with no
# re-check at all).
#
# A stale log is NOT treated as a missing one. Missing has documented
# fallbacks -- hold = access, a flat index_1, ARRAY-ONLY leakage, an analytic
# setup bound -- all of them safe and all of them stated in the .lib header.
# Quietly taking one of those roads while a rejected log sits next to it would
# hide exactly what this check is for, so a rejected file FAILS that corner:
# nothing is written for it and the script exits non-zero. Re-run the stage it
# names.
STALE_LEDGER="${TMPDIR:-/tmp}/rom_char_stale.$$"
RC=0
WROTE=0
trap 'rm -f "$STALE_LEDGER"' EXIT

# which run_*.sh writes a given file -- so the report says what to re-run
# instead of leaving that to be looked up. Keyed on the name the flow itself
# builds, so a renamed stage shows up here as "unknown" rather than as a wrong
# instruction.
stage_of() {
  case "$1" in
    *_worst_case_parasitic*)        echo run_col_timing.sh ;;
    *_fastest_array*|*_best_case_parasitic*) echo run_early_path.sh ;;
    *_leak_*.log)                   echo run_col_power.sh ;;
    *_energy_*.log)                 echo run_col_energy.sh ;;
    periph_leak_cs*.total)          echo run_periphery_leak.sh ;;
    periph_active_*|periph_idle_*)  echo run_periphery_power.sh ;;
    periph_setup_*)                 echo run_addr_setup.sh ;;
    periph_slew*)                   echo run_slew_sweep.sh ;;
    backend_*)                      echo run_backend_delay.sh ;;
    coldec_a*)                      echo run_coldec_delay.sh ;;
    pincap_*)                       echo run_pin_cap.sh ;;
    hold_*)                         echo run_hold_bisect.sh ;;
    addr2wl_*)                      echo run_addr2wl.sh ;;
    *)                              echo "unknown stage" ;;
  esac
}

# every file this script may read for one macro and corner ($1 corner, $2 sfx)
corner_inputs() {
  echo "$G_CHAR/${G_COLTAG}_worst_case_parasitic${2}.log"
  echo "$G_CHAR/${G_COLTAG}_leak_${1}.log"
  echo "$G_CHAR/${G_COLTAG}_energy_${1}.log"
  echo "$G_CHAR/${G_BESTTAG}_fastest_array${2}.log"
  echo "$G_CHAR/${G_BESTTAG}_best_case_parasitic${2}.log"
  echo "$G_CHAR/periph_active_${1}.log"
  echo "$G_CHAR/periph_idle_${1}.log"
  echo "$G_CHAR/periph_setup_${1}.log"
  echo "$G_CHAR/periph_leak_cs0_${1}.total"
  echo "$G_CHAR/periph_leak_cs1_${1}.total"
  echo "$G_CHAR/pincap_${1}.log"
  echo "$G_CHAR/hold_${1}.log"
  echo "$G_CHAR/addr2wl_${1}.log"
  for _t in $(load_tags); do echo "$G_CHAR/backend_${1}_${_t}.log"; done
  _i=0
  for _s in $SLEWS; do echo "$G_CHAR/periph_slew${_i}_${1}.log"; _i=$((_i+1)); done
  for _a in 0 1 2 3 4 5 6 7; do echo "$G_CHAR/coldec_a${_a}_${1}.log"; done
}

# How many random reads the active-energy average is taken over.
ROM_ENERGY_READS="${ROM_ENERGY_READS:-10}"

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

    # Refuse anything that is not this flow's output before a single value
    # is read (see ONLY THIS FLOW'S LOGS above).
    : > "$STALE_LEDGER"
    present=0
    for f in $(corner_inputs "$c" "$sfx"); do
      [ -f "$f" ] || continue
      present=$((present+1))
      why=$(prov_check "$f") || printf '%s\t%s\t%s\n' \
           "$(stage_of "$(basename "$f")")" "$(basename "$f")" "$why" \
           >> "$STALE_LEDGER"
    done
    if [ -s "$STALE_LEDGER" ]; then
      bad=$(wc -l < "$STALE_LEDGER")
      echo "$m $c: NOT REGENERATED -- $bad of the $present files it would read"
      echo "        are not output of the current flow."
      if [ "$bad" = "$present" ]; then
        # Not a stale file here and there: nothing in this corner was produced
        # by the flow as it stands. Listing 28 identical lines buries that.
        echo "        NONE of them is stamped -- this characterisation"
        echo "        predates the check, or the netlist has changed since."
        echo "        Re-run the flow for $m (docs/flow.md), then this script."
      else
        # Grouped by stage: that is the unit you re-run, and one dead stage
        # usually accounts for several files.
        sort "$STALE_LEDGER" | awk -F'\t' '
          { if ($1 != prev) { printf "          %s\n", $1; prev = $1 }
            printf "            %-38s %s\n", $2, $3 }'
      fi
      # The .lib for this corner is NOT rewritten, so whatever an earlier run
      # left in output/lib is still there -- and it is exactly the file
      # somebody would ship believing it came from this run.
      [ -f "$LIB_DIR/${m}_${corner}.lib" ] && \
        echo "        $LIB_DIR/${m}_${corner}.lib is from an EARLIER run -- do not ship it"
      RC=1
      continue
    fi

    PAR="$G_CHAR/${G_COLTAG}_worst_case_parasitic${sfx}.log"
    PA="$G_CHAR/periph_active_${c}.log"
    PI="$G_CHAR/periph_idle_${c}.log"
    LK="$G_CHAR/${G_COLTAG}_leak_${c}.log"

    # 2) bitline term + precharge time (that corner's own run)
    acc=$(meas "$PAR" t_dis_50 | awk '{printf "%.4f", $1*1e9}')
    pre=$(meas "$PAR" t_pre_99 | awk '{printf "%.4f", $1*1e9}')

    # Leakage is not a .measure: it is the supply current in the .op table.
    # P = |I| x <column count> x VDD  -> mW.  That is the ARRAY term.
    leak_arr=$(grep -m1 "vvdd#branch" "$LK" 2>/dev/null | awk -v n="$G_COLS" -v v="$vdd" \
             '{ i = $2 < 0 ? -$2 : $2; printf "%.7f", i*n*v*1e3 }')

    # The PERIPHERY term: run_periphery_leak.sh writes the converged total in
    # nA, one file per cs0 state. cs0 gates the precharge path only, so the
    # two states differ in the periphery and not in the array; both are
    # written to the .lib and cell_leakage_power is the worse of them.
    # Without these files the .lib falls back to the array alone, which
    # scores the whole periphery as ZERO -- so say so rather than let it pass.
    leak=""
    leak_idle=""
    pl1="$G_CHAR/periph_leak_cs1_${c}.total"
    pl0="$G_CHAR/periph_leak_cs0_${c}.total"
    if [ -n "$leak_arr" ] && [ -f "$pl1" ] && [ -f "$pl0" ]; then
      leak=$(awk -v a="$leak_arr" -v v="$vdd" '{printf "%.7f", a + $1*1e-9*v*1e3}' "$pl1")
      leak_idle=$(awk -v a="$leak_arr" -v v="$vdd" '{printf "%.7f", a + $1*1e-9*v*1e3}' "$pl0")
    elif [ -n "$leak_arr" ]; then
      echo "  $m $c: no periphery leakage log -> cell_leakage_power covers the"
      echo "        ARRAY ONLY; the clock tree, address buffers, decoders and"
      echo "        wordline drivers are scored as zero (run"
      echo "        run_periphery_leak.sh)"
      leak="$leak_arr"
    fi

    # 1) front end: clk0 -> precharge. The column measurement triggers off the
    #    internal precharge net, so this term was MISSING from access.
    #
    #    It is NOT raced against a wordline delay. This comment used to claim
    #    a cross-check "against the wordline path with t_clk2wl0: the wordline
    #    is FASTER than the precharge path" -- that rested on a broken
    #    measurement (a TARG window opened half a cycle early, so t_clk2wl0
    #    read -99 ns in every log, and the negative sign was mistaken for
    #    speed; fixed 2026-09-23). No wordline RISES during evaluate at all:
    #    the selected one FALLS, t_wlfall0 = 1.5692 ns at TT against
    #    t_clk2pre = 0.7642, i.e. the wordline moves 0.8 ns LATER than the
    #    precharge edge, not earlier.
    #
    #    That does not change this term, and the reason is the array rather
    #    than a race. For the read of 0 the deck characterises, the selected
    #    row's cell is a metal strap: the chain conducts whether its gate has
    #    fallen or not, so the discharge starts on the precharge edge and the
    #    wordline is not in series with it.
    tf=$(meas "$PA" t_clk2pre | awk '{printf "%.4f", $1*1e9}')
    # index_1 (clk0 slew): the front-end term at each point of the axis.
    # run_slew_sweep.sh writes periph_slew<i>_<corner>.log. Without them the
    # axis stays flat, which is what every earlier run produced -- say so
    # rather than silently writing three copies of one number.
    tf_list=""
    i=0
    for _sl in $SLEWS; do
      v=$(meas "$G_CHAR/periph_slew${i}_${c}.log" t_clk2pre \
          | awk '{printf "%.4f", $1*1e9}')
      [ -z "$v" ] && { tf_list=""; break; }
      tf_list="${tf_list:+$tf_list,}$v"
      i=$((i+1))
    done
    if [ -z "$tf_list" ]; then
      echo "  $m $c: no slew sweep -> index_1 stays FLAT (run run_slew_sweep.sh)"
      tf_list="$tf"
      slew_arg=""
    else
      slew_arg="--slew-index $(echo "$SLEWS" | tr ' ' ',')"
    fi
    # 2b) the column decoder, which RACES the bitline instead of adding to it
    #     (its clk and its precharge port are both on the internal precharge
    #     net -- the same net t_dis_50 triggers off). run_coldec_delay.sh
    #     writes one log per column address; the WORST of them is what the
    #     library has to survive. Absent logs are reported, not silently
    #     skipped: the .lib then says the block was never simulated.
    cd_ns=""
    for a in 0 1 2 3 4 5 6 7; do
      v=$(awk '/^t_pre2sel[0-9]+_rise /{ if ($3+0 > 0) print $3 }' \
            "$G_CHAR/coldec_a${a}_${c}.log" 2>/dev/null | head -1)
      [ -z "$v" ] && continue
      cd_ns=$(awk -v old="$cd_ns" -v new="$v" \
                'BEGIN{ n = new*1e9; if (old == "" || n > old) printf "%.4f", n
                        else printf "%s", old }')
    done
    if [ -n "$cd_ns" ]; then
      coldec_arg="--t-coldec $cd_ns"
    else
      echo "  $m $c: no column-decode logs -> the .lib will say the column" \
           "decoder was never simulated (run run_coldec_delay.sh)"
      coldec_arg=""
    fi

    # INPUT PIN CAPACITANCES. run_pin_cap.sh writes pincap_<corner>.log, and
    # the pin index -> name mapping lives in the deck header it was built from
    # (the generator writes it there, so the names are the netlist's own). For
    # each pin what ships is c_cyc: the charge for one full 0 -> VDD -> 0
    # round trip over two swings. Neither edge on its own is safe to use --
    # on a pin with a deep fanout they trade charge across the window
    # boundary (on clk0 the two swapped places between two ramp times while
    # their SUM held to 0.2%). run_pin_cap.sh compares the edges as the
    # settling proof and flags any pin where they disagree by over 5%.
    # Absent logs are reported, not skipped -- the .lib then says outright
    # that these numbers are analytic.
    PCS="$G_CHAR/pincap_${c}.sp"
    PCL="$G_CHAR/pincap_${c}.log"
    pc_arg=""
    if [ -f "$PCL" ] && [ -f "$PCS" ]; then
      pc_list=$(sed -n 's/^\*PINCAP \([0-9][0-9]*\) \(.*\)$/\1 \2/p' "$PCS" \
        | while read -r i p; do
            cy=$(meas "$PCL" "c_cyc${i}_ff")
            [ -z "$cy" ] && continue
            echo "$p $cy" | awk '{printf "%s=%.4f,", $1, $2}'
          done)
      pc_list=${pc_list%,}
      if [ -n "$pc_list" ]; then
        pc_arg="--pin-cap $pc_list"
      fi
    fi
    if [ -z "$pc_arg" ]; then
      echo "  $m $c: no pin-cap log -> input capacitances stay ANALYTIC" \
           "(run run_pin_cap.sh)"
    fi

    # 3) back end: bitline -> dout0 plus output slew, at three load points
    be=$(be_list "$G_CHAR" "$c" t_bl2dout)
    sl=$(be_list "$G_CHAR" "$c" t_dout_slew)
    # falling_edge arc: clk0 falls -> dout0 leaves its valid level. Same path
    # as access but in reverse and with the MINIMUM of every term, because
    # what has to be proven is that the consumer captured BEFORE the data went
    # away (see gen_rom_lib.py --t-invalid).
    #   t_clk2pre + t_pre_50 + t_bl2dout at the SMALLEST load
    # t_pre_50 comes from the column deck; logs written before it was added do
    # not have it. Dropping that term makes the arc EARLIER, which is the safe
    # direction, so the fallback is a warning and not a skip.
    # EARLY PATH: how soon dout0 can leave the previous value. Same three
    # terms as access but each at its fastest: the front end at that slew
    # point, the fastest discharge, and the back end at the smallest load.
    #
    # The discharge term is the FASTEST ARRAY, not the best column of this
    # .bin. A stored 0 is a metal strap and leaves the series path; a stored 1
    # is a transistor in it, so the discharge speed is set by the CONTENTS.
    # The best programmed column is only the fastest array that happens to be
    # loaded -- reprogram the same geometry and it gets faster, and a retain
    # time that assumed otherwise would be too late. run_early_path.sh
    # measures the limit case (one data cell) as <best col>_fastest_array.
    FAST="$G_CHAR/${G_BESTTAG}_fastest_array${sfx}.log"
    EARLY="$G_CHAR/${G_BESTTAG}_best_case_parasitic${sfx}.log"
    e_dis=$(meas "$FAST" t_dis_50 | awk '{printf "%.4f", $1*1e9}')
    e_prog=$(meas "$EARLY" t_dis_50 | awk '{printf "%.4f", $1*1e9}')
    if [ -z "$e_dis" ] && [ -n "$e_prog" ]; then
      echo "  $m $c: no fastest-array log -> retain_* falls back to this"
      echo "        .bin's best column ($e_prog ns). Valid only while the"
      echo "        contents do not change; run run_early_path.sh."
      e_dis="$e_prog"
    fi
    # ADDRESS HOLD, measured rather than declared equal to access. Without
    # the log the .lib keeps hold = access, which is safe and says so in its
    # own header -- the same rule every other optional measurement follows.
    hold_meas=$(meas "$G_CHAR/hold_${c}.log" hold |
                awk '{printf "%.4f", $1*1e9}')
    hold_arg=""
    if [ -n "$hold_meas" ]; then
      hold_arg="--hold-measured $hold_meas"
    else
      echo "  $m $c: no hold log -> hold = access (pessimistic in STA);"
      echo "        run run_wl_slew.sh then run_hold_bisect.sh to measure it"
    fi
    # THE FRAME CONVERSION for that hold. run_hold_bisect.sh answers in the
    # column deck's frame -- that deck has no clk0 in it, so its cut time is
    # counted from the internal evaluate edge -- while Liberty's hold_rising
    # is referenced to the clk0 PIN. addr0 -> the wordline it drops is the
    # missing term (run_addr2wl.sh, measured during evaluate when the clocked
    # decoder is transparent); gen_rom_lib.py does the arithmetic. Exactly one
    # probed wordline falls, so the worst of whatever resolved is the answer.
    a2w=""
    if [ -f "$G_CHAR/addr2wl_${c}.log" ]; then
      a2w=$(awk '/^t_addr2wl[0-9]+ /{ if ($3 ~ /^[0-9.eE+-]+$/ && $3+0 > mx) mx = $3+0 }
                 END { if (mx > 0) printf "%.4f", mx*1e9 }' \
                "$G_CHAR/addr2wl_${c}.log" 2>/dev/null || true)
    fi
    a2w_arg=""
    if [ -n "$a2w" ]; then
      a2w_arg="--t-addr2wl $a2w"
    elif [ -n "$hold_meas" ]; then
      echo "  $m $c: no addr2wl log -> the hold stays in the COLUMN DECK'S"
      echo "        frame and the .lib says so (run run_addr2wl.sh)"
    fi
    # SETUP is a path delay; the gate it feeds is clocked by clk_int, so what
    # the address really has to beat is the CLOCK to the same gate. Passing
    # t_clk2int lets the header state that race -- and it is what bounds cs0,
    # whose own path has no stage to measure (it goes straight to the control
    # NAND's gate and the extraction keeps it as one node).
    ci=$(meas "$PA" t_clk2int | awk '{printf "%.4f", $1*1e9}')
    ci_arg=""
    [ -n "$ci" ] && ci_arg="--t-clk2int $ci"

    retain_arg=""
    if [ -z "$e_dis" ]; then
      echo "  $m $c: no early-path log -> NO retain_* in the .lib; a hold"
      echo "        check has nothing to fail on (run run_early_path.sh)"
    else
      retain_list=""
      for v in $(echo "$tf_list" | tr ',' ' '); do
        r=$(awk -v a="$v" -v d="$e_dis" -v b="$(echo "$be" | cut -d, -f1)" \
                'BEGIN{printf "%.4f", a+d+b}')
        retain_list="${retain_list:+$retain_list,}$r"
      done
      retain_arg="--retain-ns $retain_list"
    fi

    # The falling arc wants the EARLIEST bitline trip point, so take the
    # smaller of whichever columns have been measured. The best-column deck
    # (run_early_path.sh) carries t_pre_50 as a by-product.
    tp50=$(for f in "$PAR" "$EARLY"; do
             meas "$f" t_pre_50 | awk '{printf "%.4f\n", $1*1e9}'
           done | sort -n | head -1)
    be_min=$(echo "$be" | cut -d, -f1)
    if [ -z "$tp50" ]; then
      echo "  $m $c: no t_pre_50 in $(basename "$PAR") -> falling-edge arc drops"
      echo "        the bitline recharge term (earlier = safe). Re-run"
      echo "        run_col_timing.sh to measure it."
      tinv=$(awk -v a="$tf" -v b="$be_min" 'BEGIN{printf "%.4f", a+b}')
    else
      tinv=$(awk -v a="$tf" -v p="$tp50" -v b="$be_min" \
                 'BEGIN{printf "%.4f", a+p+b}')
    fi
    # ACTIVE ENERGY: the average of ROM_ENERGY_READS random reads, not the
    # worst case. A column discharges only when the SELECTED ROW holds a zero
    # there (a one_cell is an NMOS whose gate has just fallen, so it opens the
    # series chain and that bitline stays at VDD), and the array is about half
    # zeros -- `n*ec + ep` with n = every column was ~1.95x the real average on
    # wrom0. gen_random_read_energy.py samples the address space, counts the
    # discharging columns per read from the netlist's own cell types, and
    # averages E_i = N_discharge(row_i)*e_col + e_periph. Both energy terms are
    # still MEASURED (char/col<N>_energy_<corner>.log and $PA); only the
    # ACTIVITY is counted here.
    #
    # Its seed is derived from the macro name ALONE, so regenerating from
    # unchanged inputs cannot move the number AND all three corners sample the
    # same ten addresses -- which columns discharge is set by the contents, not
    # by the corner, so a per-corner draw would put sampling noise straight
    # into the corner ratios (it was worth ~7% on wrom0 before this was fixed).
    # --log leaves the per-read table in char/random_energy_<corner>.log,
    # which is what the .lib cites.
    e_act=$(python3 "$ROM_CHAR_DIR/gen_random_read_energy.py" "$m" \
              --corner "$c" --reads "$ROM_ENERGY_READS" --energy-only --log \
              --macros-dir "$MACROS_DIR") || e_act=""
    # The worst case is not dropped, only demoted: the .lib header quotes it
    # next to the average so a peak-current budget still has a number. It is
    # read back from the log the call above just wrote.
    e_worst=$(meas "$G_CHAR/random_energy_${c}.log" e_read_worst_pj |
              awk '{printf "%.4f", $1}')
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

    # setup: MEASURED DIRECTLY.
    # run_addr_setup.sh switches addr0 during the precharge phase and measures
    #   addr0 -> inv_array_mod/Z  (= the A input of the decoder NAND)
    # taking the WORST of the per-address-bit buffers. The decoder is a CLOCKED
    # NAND, so that net is exactly where the address has to be stable.
    #
    # With no measurement we FALL BACK to an analytic upper bound of
    # 3 x t_clk2pre (~4.93 ns at SS against 0.053 ns measured, i.e. ~90x
    # pessimistic) -- writing a large number is the safe side, writing a
    # small one silently is not.
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
leakage char/${G_COLTAG}_leak_${c}.log${leak_idle:+ + char/periph_leak_cs*_${c}.total}, \
column energy char/${G_COLTAG}_energy_${c}.log, \
active energy = mean of ${ROM_ENERGY_READS} random reads \
char/random_energy_${c}.log\
${hold_meas:+, address hold char/hold_${c}.log}"

    python3 "$GEN" --lef "$LEF" --memory-type rom --measured \
      --outdir "$LIB_DIR" \
      --corner "$corner" --access "$acc" --hold "$acc" $hold_arg --t-pre "$pre" \
      --setup "$stp" \
      --leakage-mw "$leak" ${leak_idle:+--leakage-idle-mw "$leak_idle"} \
      --energy-pj "$e_act" --energy-idle-pj "$e_idle" \
      --energy-reads "$ROM_ENERGY_READS" \
      ${e_worst:+--energy-worst-pj "$e_worst"} \
      --t-front "$tf_list" $slew_arg $retain_arg $coldec_arg $pc_arg \
      $a2w_arg $ci_arg \
      --backend-ns "$be" --out-slew-ns "$sl" \
      --t-invalid "$tinv" \
      --chain-len "$G_CHAIN" --worst-col "$col" \
      --rows "$G_ROWS" --cols "$G_COLS" --char-source "$SRC" >/dev/null
    WROTE=$((WROTE+1))

    printf "%-7s %-4s access = %.4f + %s + %s = %.4f ns  E=%s pJ (%s-read avg%s)  E_idle=%s pJ\n" \
      "$m" "$c" "$tf" "$acc" "$(echo "$be" | cut -d, -f3)" \
      "$(awk -v a="$tf" -v b="$acc" -v d="$(echo "$be" | cut -d, -f3)" \
            'BEGIN{print a+b+d}')" "$e_act" "$ROM_ENERGY_READS" \
      "${e_worst:+, worst $e_worst}" "$e_idle"
  done
done
if [ "$WROTE" = 0 ]; then
  # Saying "Done -- .lib files written" over a run that wrote nothing is how a
  # stale library gets shipped, so the banner below is not printed at all, and
  # neither is the structural check run: it would be reading the PREVIOUS
  # run's files and reporting them green.
  echo
  echo "NOTHING WAS WRITTEN -- no corner had a complete set of current logs." >&2
  echo "Any .lib in $LIB_DIR is from an earlier run." >&2
  exit 1
fi

echo "Done -- .lib files written to $LIB_DIR with measured timing"
echo "(front end + bitline + back end), output slew, leakage and energy"
echo "(active + idle). Active energy is the average of $ROM_ENERGY_READS random"
echo "reads, not the all-columns-discharging worst case; the per-read tables"
echo "are in <macro>/char/random_energy_<corner>.log."

# Never hand out a file that was never read back. This is the cheap structural
# pass (syntax, table shapes, arc completeness); tests/run_tests.sh adds the
# ROM semantics and, where it is installed, OpenSTA's own reader.
CHECK="$(cd "$(dirname "$0")/../.." && pwd)/tests/check_lib.py"
if [ -f "$CHECK" ]; then
  echo
  if ! python3 "$CHECK" "$LIB_DIR"/*.lib; then
    echo "The generated .lib files did NOT pass validation -- see above." >&2
    echo "Run tests/run_tests.sh for the full report." >&2
    exit 1
  fi
fi

# A corner whose logs were refused is a failure of the run, not a remark: the
# .lib for it is either absent or left at whatever an earlier run wrote, and
# both of those are wrong to exit 0 on.
exit $RC
