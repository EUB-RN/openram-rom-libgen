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
# So a single gmin cannot serve every slice. This script generates the axis
# adaptively and reports, PER SLICE, the value where the answer stops moving
# for two consecutive intervals; a slice that reaches the safety floor without
# settling is printed as NOT CONVERGED and must not be used.
#
# Usage: scripts/rom_char/run_periphery_leak.sh [macro ...]
#        GMIN_START=1e-12 GMIN_FACTOR=1e-3 GMIN_FLOOR=1e-30 ...
# Output: <macro>/char/periph_leak_paired_<corner>.sp/.log (one parsed deck)
#         + periph_leak_cs<n>_<corner>_g<gmin>.log (marker-split results)
#         + periph_leak_cs<n>_<corner>.total       (nA, converged)

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
ng_reset          # clear the failure ledger for this run
GEN="$ROM_CHAR_DIR/gen_periphery_leak_tb.py"

# Adaptive axis: no fixed list. Each new point is the previous gmin times the
# factor. The run stops only after every slice agrees for STABLE_ROUNDS
# consecutive intervals, or fails at the configurable numerical safety floor.
GMIN_START="${GMIN_START:-1e-12}"
GMIN_FACTOR="${GMIN_FACTOR:-1e-3}"
GMIN_FLOOR="${GMIN_FLOOR:-1e-30}"
GMIN_STABLE_ROUNDS="${GMIN_STABLE_ROUNDS:-2}"
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
    # Generate and parse ONE deck per corner. The control block changes gmin
    # and Vcs in place, runs .op, and brackets every result with stable markers.
    # This grows the gmin axis until convergence while avoiding repeated parses.
    paired_sp="$G_CHAR/periph_leak_paired_${c}.sp"
    paired_lg="$G_CHAR/periph_leak_paired_${c}.log"
    counts=$(python3 "$GEN" "$m" --corner "$c" --vdd "$v" --temp "$t" \
                     --gmin "$GMIN_START" --paired \
                     --gmin-start "$GMIN_START" --gmin-factor "$GMIN_FACTOR" \
                     --gmin-floor "$GMIN_FLOOR" --stable-rounds "$GMIN_STABLE_ROUNDS" \
                     --settle-tol "$TOL" --zero-na "$ZERO" 2>/dev/null)
    run_ng "periphery-leak" "$paired_sp" "$paired_lg" \
           "$m $c paired cs0=0,1 gmin-sweep" || continue

    for cs in $CS_STATES; do
      cslog="$G_CHAR/periph_leak_cs${cs}_${c}_adaptive.log"
      awk -v cs="$cs" '$0 == "LEAK_CS_BEGIN=" cs, $0 == "LEAK_CS_END=" cs' \
          "$paired_lg" > "$cslog"
      if ! grep -q "^LEAK_CS_CONVERGED=$cs$" "$cslog"; then
        ng_fail "periphery-leak" "$m $c cs$cs adaptive-gmin" "$paired_sp" "$cslog" \
                "0 (adaptive gmin)" "gmin reached $GMIN_FLOOR without two stable intervals"
        continue
      fi
      gmins=$(awk '/^LEAK_ITER_BEGIN$/ {inside=1; next}
                   /^LEAK_ITER_END$/ {inside=0}
                   inside && $1=="g" && $2=="=" {
                     printf "%s%.0e", sep, $3; sep=" "
                   }' "$cslog")

      # Keep the legacy per-state/per-gmin LOGS so diagnostics and downstream
      # readers do not need to know that execution was paired. All of them
      # point at the one real paired deck in provenance; no duplicate .sp
      # files are generated.
      for g in $gmins; do
        lg="$G_CHAR/periph_leak_cs${cs}_${c}_g${g}.log"
        awk -v target="$g" '
          /^LEAK_ITER_BEGIN$/ { capture=1; block=$0 ORS; current=""; next }
          capture { block=block $0 ORS }
          capture && $1=="g" && $2=="=" { current=sprintf("%.0e", $3) }
          /^LEAK_ITER_END$/ {
            if (current==target) printf "%s", block
            capture=0
          }' "$cslog" > "$lg"
        prov_write "periphery-leak" "$paired_sp" "$lg" "$m $c cs$cs gmin=$g"
      done

      # per slice: the smallest gmin is the answer, the point above it
      # agreeing is the proof
      echo "== $m $c cs0=$cs =="
      printf "%-8s %-6s" slice count
      for g in $gmins; do printf " %12s" "$g"; done
      printf " %14s %s\n" "converged(nA)" "at"
      total=""
      for tag in $(echo "$counts" | awk '/^count /{print $2}'); do
        cnt=$(echo "$counts" | awk -v t="$tag" '$1=="count" && $2==t {print $3}')
        vals=""
        for g in $gmins; do
          lg="$G_CHAR/periph_leak_cs${cs}_${c}_g${g}.log"
          # .op prints the source branch current; into the source is negative
          i=$(awk -v n="v$tag#branch" '$1==n {
                x = ($2 == "=" ? $3 : $2); printf "%.6g", -x*1e9 }' "$lg")
          vals="$vals ${i:-NA}"
        done
        # The ANSWER is the smallest gmin on the axis; the point above it
        # agreeing is the PROOF that it converged (the same rule the column
        # deck uses). Also report the first gmin that already lands within
        # TOL of it -- that is the "1e-15 is enough for this slice" fact.
        conv=$(echo "$vals" | awk -v tol="$TOL" -v zero="$ZERO" '{
            if (NF < 3) { print "NOTCONV", 0; exit }
            last = $NF; prev = $(NF-1); prev2 = $(NF-2)
            if (last == "NA" || prev == "NA" || prev2 == "NA") { print "NOTCONV", 0; exit }
            a = (last < 0) ? -last : last
            ap = (prev < 0) ? -prev : prev
            ap2 = (prev2 < 0) ? -prev2 : prev2
            if (a < zero && ap < zero && ap2 < zero) { print last, -1; exit }
            d1 = (last == 0) ? 0 : (last - prev) / last * 100
            d2 = (prev == 0) ? 0 : (prev - prev2) / prev * 100
            if (d1 < 0) d1 = -d1
            if (d2 < 0) d2 = -d2
            if (d1 > tol || d2 > tol) { print "NOTCONV", 0; exit }
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
          printf " %14s %s\n" "NOT CONVERGED" "-- reached GMIN_FLOOR"
        else
          if [ "$cidx" = "-1" ]; then
            # under the ZERO floor: the slice passes nothing, and saying
            # "clean from gmin=..." about a 1e-19 A number would be a
            # convergence claim the sweep never made.
            printf " %14.6g %s\n" "$cval" "ZERO (under ${ZERO} nA floor)"
          else
          gsel=$(echo "$gmins" | cut -d' ' -f"$cidx")
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
