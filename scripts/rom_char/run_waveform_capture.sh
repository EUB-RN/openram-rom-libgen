#!/bin/sh
# Draw the README's waveform figures -- with ngspice, from the decks that were
# already measured.
#
#     scripts/rom_char/run_waveform_capture.sh [macro ...]
#
# Nothing new is measured and nothing is re-plotted by another tool. The
# characterisation decks only ask for `.measure` results, so ngspice throws
# the waveform away; this script copies each deck, inserts a `.save` of the
# handful of nodes the figure needs plus a `.control` block that writes a raw
# file, and runs it again. A second ngspice pass loads those raw files and
# ngspice's OWN `hardcopy` writes the figure:
#
#     set hcopydevtype=svg      -- vector output, renders in the README
#     set color0=white ...      -- white paper instead of the screen's black
#     hardcopy <file> <vectors> -- the same picture the plot window shows
#
# So every curve in docs/img is ngspice's own drawing of its own simulation.
#
# Output: docs/img/05-col-discharge.svg   bitline + precharge, three corners
#         docs/img/06-front-end.svg       clk0 -> internal clock, wl, precharge
#         docs/img/07-backend-loads.svg   dout0 at the three .lib output loads
# Working files (raw, decks, logs): <macro>/char/wave/  -- git-ignored.
#
# The node names are read out of each deck's OWN .measure lines rather than
# spelled here: the extracted netlist names nodes after instances
# (wrom0_rom_row_decode_0/wl_0), so they change with the macro.
#
# Cost: the column deck is ~2 min per corner, the periphery deck longer. The
# figures are only worth redrawing after a re-characterisation.

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
ng_reset          # clear the failure ledger for this run
IMG="$ROOT/docs/img"

# node a .measure statement triggers on / targets: meas_node <deck> <name> TRIG|TARG
meas_node() {
  awk -v n="$2" -v w="$3" '
    $1 == ".measure" && $3 == n { inm = 1 }
    inm {
      for (i = 1; i <= NF; i++)
        if ($i == w && $(i+1) ~ /^v\(/) {
          s = $(i+1); sub(/^v\(/, "", s); sub(/\).*$/, "", s); print s; exit
        }
      if ($0 !~ /^\+/ && inm > 1) exit
      inm++
    }' "$1"
}

# param <deck> <name> -- the value of a .param line, in SI units
param() {
  grep -i "^\.param  *$2 *=" "$1" | head -1 | sed "s/.*= *//" | awk '{
    v = $1; u = v; sub(/^[0-9.e+-]*/, "", u); sub(/[a-zA-Z]*$/, "", v)
    m = 1
    if (u ~ /^[uU]/) m = 1e-6; else if (u ~ /^[nN]/) m = 1e-9
    else if (u ~ /^[pP]/) m = 1e-12; else if (u ~ /^[mM][eE][gG]/) m = 1e6
    else if (u ~ /^[mM]/) m = 1e-3; else if (u ~ /^[kK]/) m = 1e3
    printf "%.12g", v * m }'
}

# run_raw <deck> <out.raw> <node>...   -- re-run a measured deck, keep the wave
run_raw() {
  deck="$1"; raw="$2"; shift 2
  [ -f "$deck" ] || { echo "   missing $(basename "$deck") -- run its own run_*.sh first"; return 1; }
  vec=""
  for n in "$@"; do [ -n "$n" ] && vec="$vec \"v($n)\""; done
  [ -n "$vec" ] || { echo "   no usable nodes in $(basename "$deck")"; return 1; }
  [ -f "$raw" ] && [ "$raw" -nt "$deck" ] && { echo "   $(basename "$raw") is up to date"; return 0; }
  tmp="${raw%.raw}.sp"
  awk -v sav=".save$vec" -v wr="write $raw$vec" '
    /^\.end$/ && !done { print sav; print ".control"; print "run"; print wr;
                         print ".endc"; done = 1 }
    { print }' "$deck" > "$tmp"
  echo "   $(basename "$raw") <- $(basename "$deck")"
  # Reports stage, context and ngspice's own reason; the caller decides
  # whether a missing waveform stops the figure or only that one panel.
  run_ng "raw-capture-$(basename "$raw" .raw)" "$tmp" "${raw%.raw}.log" "$m" \
    || return 1
}

# hardcopy_svg <out.svg> <title> <xlabel> <raw list> <vector list> [t0 t1]
hardcopy_svg() {
  out="$1"; title="$2"; xlab="$3"; raws="$4"; vecs="$5"
  xlim=""; [ -n "$6" ] && xlim="xlimit $6 $7"
  for r in $raws; do [ -f "$r" ] || { echo "   $(basename "$out") skipped -- no $(basename "$r")"; return 0; } done
  tmp="$OUT/$(basename "${out%.svg}").plot.sp"
  {
    echo "* ngspice draws this figure itself -- see run_waveform_capture.sh"
    echo ".control"
    echo "load $raws"
    echo "set hcopydevtype=svg"
    echo "set hcopypscolor=1"
    echo "set color0=white"      # paper
    echo "set color1=black"      # axes, grid and text
    echo "hardcopy $out $vecs xlabel '$xlab' title '$title' $xlim"
    echo ".endc"
    echo ".end"
  } > "$tmp"
  # A figure that silently does not appear is the same class of bug as a
  # measurement that silently does not happen, so this reports too. It does
  # NOT stop the script: a missing figure costs documentation, not a number.
  run_ng "figure-$(basename "$out" .svg)" "$tmp" "${tmp%.sp}.log" "$m" || true
  if [ -f "$out" ]; then
    echo "   wrote docs/img/$(basename "$out")"
  else
    echo "   NO FIGURE: ngspice ran but wrote no hardcopy -- see ${tmp%.sp}.log" >&2
  fi
}

for m in $(macro_list "$@"); do
  load_geom "$m" || { echo "$m: cannot read geometry, skipped"; continue; }
  OUT="$G_CHAR/wave"
  mkdir -p "$OUT"
  echo "== $m: re-running measured decks with the waveform kept =="

  # ---- 05: the bitline, three corners on one pair of axes ------------------
  raws=""; vecs=""; i=0
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    if [ "$c" = tt ]; then d="$G_CHAR/${G_COLTAG}_worst_case_parasitic.sp"
    else d="$G_CHAR/${G_COLTAG}_worst_case_parasitic_${c}.sp"; fi
    bl=$(meas_node "$d" t_dis_50 TARG 2>/dev/null)
    if run_raw "$d" "$OUT/col_${c}.raw" precharge "$bl"; then
      i=$((i + 1)); raws="$raws $OUT/col_${c}.raw"
      vecs="$vecs \"tran$i.v($bl)\""
      [ "$c" = tt ] && vecs="$vecs \"tran$i.v(precharge)\""
    fi
  done
  tclk=$(param "$G_CHAR/${G_COLTAG}_worst_case_parasitic.sp" TCLK)
  ev=$(awk -v t="$tclk" 'BEGIN{printf "%.12g", 2.5*t}')     # evaluate edge
  pc=$(awk -v t="$tclk" 'BEGIN{printf "%.12g", 3.0*t}')     # precharge edge
  w=$(awk -v t="$tclk" 'BEGIN{printf "%.12g", (t/20 > 2e-7) ? 2e-7 : t/20}')
  hardcopy_svg "$IMG/05-col-discharge.svg" \
    "$m evaluate: the bitline discharges through ${G_CHAIN} series cells -- SS / TT / FF" \
    "time" "$raws" "$vecs" \
    "$(awk -v a="$ev" -v w="$w" 'BEGIN{printf "%.12g", a-w/20}')" \
    "$(awk -v a="$ev" -v w="$w" 'BEGIN{printf "%.12g", a+w}')"
  hardcopy_svg "$IMG/05b-col-precharge.svg" \
    "$m precharge: the same column pulled back to VDD -- SS / TT / FF" \
    "time" "$raws" "$vecs" \
    "$(awk -v a="$pc" -v w="$w" 'BEGIN{printf "%.12g", a-w/20}')" \
    "$(awk -v a="$pc" -v w="$w" 'BEGIN{printf "%.12g", a+w}')"

  # ---- 06: the front end ---------------------------------------------------
  d="$G_CHAR/periph_active_tt.sp"
  ci=$(meas_node "$d" t_clk2int TARG 2>/dev/null)
  cp=$(meas_node "$d" t_clk2pre TARG 2>/dev/null)
  # the wordline node, taken from the measure that actually resolves it: the
  # FALL. There is no clk0 -> wordline RISE arc in this circuit (see
  # gen_periphery_power_tb.py), and the t_clk2wl0 this line used to read has
  # been removed.
  cw=$(meas_node "$d" t_wlfall0 TARG 2>/dev/null)
  if run_raw "$d" "$OUT/front_tt.raw" clk0 "$ci" "$cp" "$cw"; then
    ptclk=$(param "$d" TCLK)
    # clk0 RISES at TCLK/2 + k*TCLK, so cycle 6's rising edge is at 6.5*TCLK.
    # This used to say 6*TCLK, which is where clk0 FALLS -- the figure was
    # drawn on the precharge edge while its own title said the opposite.
    pev=$(awk -v t="$ptclk" 'BEGIN{printf "%.12g", 6.5*t}')
    hardcopy_svg "$IMG/06-front-end.svg" \
      "$m front end at TT -- clk0 rises, the selected wordline FALLS" \
      "time" "$OUT/front_tt.raw" \
      "\"tran1.v(clk0)\" \"tran1.v($ci)\" \"tran1.v($cp)\" \"tran1.v($cw)\"" \
      "$(awk -v a="$pev" 'BEGIN{printf "%.12g", a-1e-9}')" \
      "$(awk -v a="$pev" 'BEGIN{printf "%.12g", a+1.5e-8}')"
  fi

  # ---- 07: the back end at each .lib output load ---------------------------
  raws=""; vecs=""; i=0
  for cl in $LOADS; do
    t=$(echo "$cl" | tr -d '.')
    d="$G_CHAR/backend_tt_${t}.sp"
    bl=$(meas_node "$d" t_bl2dout TRIG 2>/dev/null)
    do_=$(meas_node "$d" t_bl2dout TARG 2>/dev/null)
    if run_raw "$d" "$OUT/backend_${t}.raw" "$bl" "$do_"; then
      i=$((i + 1)); raws="$raws $OUT/backend_${t}.raw"
      vecs="$vecs \"tran$i.v($do_)\""
      [ "$i" = 1 ] && vecs="$vecs \"tran1.v($bl)\""
    fi
  done
  hardcopy_svg "$IMG/07-backend-loads.svg" \
    "$m back end at TT -- dout0 at $(echo $LOADS | tr ' ' '/') fF, and the bitline driving it" \
    "time" "$raws" "$vecs"
done

ng_summary
