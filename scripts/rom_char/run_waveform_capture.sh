#!/bin/sh
# Re-run three decks that have already been measured, this time KEEPING the
# waveform, so that the README figures can show what the numbers in the .lib
# actually refer to.
#
#     scripts/rom_char/run_waveform_capture.sh [macro ...]
#     CORNERS=tt:1.8:25:0 scripts/rom_char/run_waveform_capture.sh wrom0
#
# Nothing new is measured here. The characterisation decks only ask for
# `.measure` results, so ngspice throws the waveform away; this script copies
# each deck, inserts a `.save` of the handful of nodes the figure needs plus a
# `.control` block that writes them out, and runs it again. The .measure
# results still land in the log, so the run also double-checks that the deck
# reproduces the committed number.
#
# Output: <macro>/char/wave/*.csv  (ignored by git -- regenerate, don't commit)
# Then:   python3 docs/img/make_figures.py        # draws 05/06/07 from them
#
# The node names are read out of each deck's OWN .measure lines rather than
# spelled here: the extracted netlist names nodes after instances
# (wrom0_rom_row_decode_0/wl_0), so they change with the macro.
#
# Cost: the column deck is ~90 s per corner, the periphery deck a few minutes.

set -e
. "$(dirname "$0")/common.sh"
need_ngspice

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

# capture <deck> <out.csv> <node> [node ...]
capture() {
  deck="$1"; csv="$2"; shift 2
  [ -f "$deck" ] || { echo "   missing $(basename "$deck") -- run its own run_*.sh first"; return 0; }
  sav=""; wr=""
  for n in "$@"; do
    [ -n "$n" ] || continue
    sav="$sav v($n)"; wr="$wr v($n)"
  done
  [ -n "$sav" ] || { echo "   no usable nodes in $(basename "$deck")"; return 0; }
  tmp="${csv%.csv}.sp"
  awk -v sav=".save$sav" -v wr="wrdata $csv$wr" '
    /^\.end$/ && !done { print sav; print ".control"; print "run"; print wr;
                         print ".endc"; done = 1 }
    { print }' "$deck" > "$tmp"
  echo "   $(basename "$csv") <- $(basename "$deck")"
  $NG -b -o "${csv%.csv}.log" "$tmp" >/dev/null 2>&1 || echo "   ngspice failed on $(basename "$deck")"
}

for m in $(macro_list "$@"); do
  load_geom "$m" || { echo "$m: cannot read geometry, skipped"; continue; }
  OUT="$G_CHAR/wave"
  mkdir -p "$OUT"
  echo "== $m: keeping the waveform of decks that were only measured =="

  # 05 -- bitline discharge and precharge, one file per corner
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    if [ "$c" = tt ]; then d="$G_CHAR/${G_COLTAG}_worst_case_parasitic.sp"
    else d="$G_CHAR/${G_COLTAG}_worst_case_parasitic_${c}.sp"; fi
    bl=$(meas_node "$d" t_dis_50 TARG 2>/dev/null)
    capture "$d" "$OUT/col_${c}.csv" precharge "$bl"
  done

  # 06 -- the front end: clk0 -> internal clock, wordline, precharge
  d="$G_CHAR/periph_active_tt.sp"
  capture "$d" "$OUT/front_tt.csv" clk0 \
          "$(meas_node "$d" t_clk2int TARG 2>/dev/null)" \
          "$(meas_node "$d" t_clk2pre TARG 2>/dev/null)" \
          "$(meas_node "$d" t_clk2wl0 TARG 2>/dev/null)"

  # 07 -- the back end at each output load of the .lib CELL_TABLE
  for cl in $LOADS; do
    t=$(echo "$cl" | tr -d '.')
    d="$G_CHAR/backend_tt_${t}.sp"
    capture "$d" "$OUT/backend_${t}.csv" \
            "$(meas_node "$d" t_bl2dout TRIG 2>/dev/null)" \
            "$(meas_node "$d" t_bl2dout TARG 2>/dev/null)"
  done
done

echo
echo "now draw them:  python3 docs/img/make_figures.py"
