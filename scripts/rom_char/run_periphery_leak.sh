#!/bin/sh
# PERIPHERY leakage, three corners, WITH A GMIN SWEEP.
#
# `cell_leakage_power` covered the cell array only: one column measured with
# .op times the column count. The periphery -- clock driver, control NAND,
# precharge driver, address buffers, the row and column decode chains and
# their wordline drivers, and the read back end (bitline inverters, column
# mux, output buffers) -- leaks too, and was scored as zero.
#
# The read back end was missing from the first version of this deck as well.
# It is not a rounding term: one bitline inverter leaks 0.3655 nA at TT and
# there are 256 of them, which is about as much as the entire rest of the
# periphery put together.
#
# METHOD: one slice per block times a count from the netlist, every slice on
# its own supply source, one .op per state (gen_periphery_leak_tb.py). The
# state is clk0 = 0, the same idle state the array term is measured in, so
# the two can be added.
#
# WHY A SWEEP AND NOT ONE RUN. gmin is the artificial conductance ngspice
# puts on every node to converge, and it sits in PARALLEL with the leakage
# being measured: at the pA level it IS the answer. Measured on this deck
# (wrom0, TT, cs0=1):
#     slice     gmin=1e-12   1e-15      1e-18
#     ctl        14.33 nA    14.2232    14.2231     -> 1e-15 is enough
#     wlbuf       0.6925 nA   0.68895    0.68894    -> 1e-15 is enough
#     abuf        5.62 pA     0.2297     0.2241     -> 1e-12 is 96% artificial
#     dec        42.2 pA      0.0825     0.0353     -> 1e-15 still 2.3x high
# So a single gmin cannot serve every slice. This script runs the whole axis
# and reports, PER SLICE, the value where the answer stops moving; a slice
# that never settles is printed as NOT CONVERGED and must not be used.
#
# Usage: scripts/rom_char/run_periphery_leak.sh [macro ...]
#        GMINS="1e-12 1e-15 1e-18 1e-21" scripts/rom_char/run_periphery_leak.sh
# Output: <macro>/char/periph_leak_cs<n>_<corner>_g<gmin>.log
#         + <macro>/char/periph_leak_cs<n>_<corner>.total   (nA, converged)

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
ng_reset          # clear the failure ledger for this run
GEN="$ROM_CHAR_DIR/gen_periphery_leak_tb.py"

# The axis reaches two decades past the value the array deck settled on: the
# proof that a value is converged is the NEXT one down agreeing with it.
GMINS="${GMINS:-1e-12 1e-15 1e-18 1e-21}"
# cs0 gates the precharge path, so it changes the control logic's state.
CS_STATES="${CS_STATES:-0 1}"
# a slice is converged when two neighbouring gmin values agree this closely
TOL="${TOL:-1.0}"
# ... unless it is ZERO, where a RELATIVE tolerance means nothing. The column
# mux is the case: in the idle state both of its terminals sit at 0 V, so it
# passes ~1e-10 nA and the last two gmin points differ by whatever rounding
# ngspice did. A slice under this floor counts as a converged zero -- at 1e-6
# nA even the 256-wide mux array contributes under a pA to the total.
ZERO="${ZERO:-1e-6}"

for m in $(macro_list "$@"); do
  load_geom "$m" || { echo "$m: cannot read geometry, skipped"; continue; }
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)
    for cs in $CS_STATES; do
      # the generator prints "count <tag> <n>" -- the multipliers come from
      # the netlist, never from this file
      counts=$(python3 "$GEN" "$m" --cs0 "$cs" --corner "$c" --vdd "$v" \
                       --temp "$t" --gmin "$(echo "$GMINS" | cut -d' ' -f1)" \
                       2>/dev/null)
      n=0
      for g in $GMINS; do
        python3 "$GEN" "$m" --cs0 "$cs" --corner "$c" --vdd "$v" \
                --temp "$t" --gmin "$g" >/dev/null 2>&1
        sp="$G_CHAR/periph_leak_cs${cs}_${c}_g${g}.sp"
        lg="$G_CHAR/periph_leak_cs${cs}_${c}_g${g}.log"
        run_ng "periphery-leak" "$sp" "$lg" "$m $c cs$cs gmin=$g" &
        n=$((n + 1))
        [ "$((n % JOBS))" -eq 0 ] && wait
      done
      wait

      # per slice: the smallest gmin is the answer, the point above it
      # agreeing is the proof
      echo "== $m $c cs0=$cs =="
      printf "%-8s %-6s" slice count
      for g in $GMINS; do printf " %12s" "$g"; done
      printf " %14s %s\n" "converged(nA)" "at"
      total=""
      for tag in $(echo "$counts" | awk '/^count /{print $2}'); do
        cnt=$(echo "$counts" | awk -v t="$tag" '$1=="count" && $2==t {print $3}')
        vals=""
        for g in $GMINS; do
          lg="$G_CHAR/periph_leak_cs${cs}_${c}_g${g}.log"
          # .op prints the source branch current; into the source is negative
          i=$(awk -v n="v$tag#branch" '$1==n {printf "%.6g", -$2*1e9}' "$lg")
          vals="$vals ${i:-NA}"
        done
        # The ANSWER is the smallest gmin on the axis; the point above it
        # agreeing is the PROOF that it converged (the same rule the column
        # deck uses). Also report the first gmin that already lands within
        # TOL of it -- that is the "1e-15 is enough for this slice" fact.
        conv=$(echo "$vals" | awk -v tol="$TOL" -v zero="$ZERO" '{
            last = $NF; prev = $(NF-1)
            if (last == "NA" || prev == "NA") { print "NOTCONV", 0; exit }
            a = (last < 0) ? -last : last
            if (a < zero) { print last, -1; exit }
            d = (last == 0) ? 0 : (last - prev) / last * 100
            if (d < 0) d = -d
            if (d > tol) { print "NOTCONV", 0; exit }
            first = NF
            for (i = 1; i <= NF; i++) {
              if ($i == "NA") continue
              e = (last == 0) ? 0 : ($i - last) / last * 100
              if (e < 0) e = -e
              if (e <= tol) { first = i; break }
            }
            print last, first }')
        cval=$(echo "$conv" | awk '{print $1}')
        cidx=$(echo "$conv" | awk '{print $2}')
        printf "%-8s %-6s" "$tag" "$cnt"
        for x in $vals; do printf " %12s" "$x"; done
        if [ "$cval" = NOTCONV ]; then
          printf " %14s %s\n" "NOT CONVERGED" "-- widen GMINS"
        else
          if [ "$cidx" = "-1" ]; then
            # under the ZERO floor: the slice passes nothing, and saying
            # "clean from gmin=..." about a 1e-19 A number would be a
            # convergence claim the sweep never made.
            printf " %14.6g %s\n" "$cval" "ZERO (under ${ZERO} nA floor)"
          else
          gsel=$(echo "$GMINS" | cut -d' ' -f"$cidx")
          printf " %14.6g %s\n" "$cval" "clean from gmin=$gsel"
          fi
          total=$(awk -v s="${total:-0}" -v a="$cval" -v n="$cnt" \
                      'BEGIN{printf "%.6f", s + a*n}')
        fi
      done
      if [ -n "$total" ]; then
        echo "$total" > "$G_CHAR/periph_leak_cs${cs}_${c}.total"
        # The total is DERIVED from the gmin sweep above rather than written
        # by one deck, so it gets its stamp here (deck "-"). Without it
        # regen_rom_libs.sh cannot tell this sum from one left in the tree by
        # an older netlist, and the periphery leakage term is exactly the one
        # whose absence is silently survivable.
        prov_write "periphery-leak" "-" \
                   "$G_CHAR/periph_leak_cs${cs}_${c}.total" "$m $c cs$cs"
        printf "%-8s %-6s %s %.4f nA  (= %.6f uW at %s V)\n" TOTAL "" \
               "periphery leakage" "$total" \
               "$(awk -v i="$total" -v v="$v" 'BEGIN{print i*v/1000}')" "$v"
      fi
      echo
    done
  done
done

ng_summary
