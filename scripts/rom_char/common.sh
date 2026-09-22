# shellcheck shell=sh
# Shared base for every run_*.sh -- `. "$(dirname "$0")/common.sh"`
#
# WHAT IT PROVIDES
#   ROOT, MACROS_DIR, LIB_DIR, VERILOG_DIR   (see ROM_MACROS_DIR / ROM_OUT_DIR)
#   NG / JOBS                                (NGSPICE_BIN, JOBS)
#   CORNERS "<tag>:<vdd>:<temperature>:<fmax_MHz>"
#   macro_list  -- every macro in the tree when no arguments are given
#   load_geom   -- sets G_COLS / G_WORST_COL / G_CHAIN / G_CHAR / ...
#   meas        -- pull a value out of an ngspice .measure line
#
# WHY: the macro list, the worst-column table, the column count and the
# repository path are derived here once instead of being repeated in every
# script, so regenerating a ROM cannot leave one of them stale. See
# rom_paths.py.

ROM_CHAR_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$ROM_CHAR_DIR/../.." && pwd)"
MACROS_DIR="$(python3 "$ROM_CHAR_DIR/rom_paths.py" --macros-dir-only)"
LIB_DIR="$(python3 "$ROM_CHAR_DIR/rom_paths.py" --lib-dir)"
VERILOG_DIR="$(python3 "$ROM_CHAR_DIR/rom_paths.py" --verilog-dir)"

NG="${NGSPICE_BIN:-ngspice}"
JOBS="${JOBS:-4}"

# tag:vdd:temperature:fmax(MHz) -- fmax only feeds the P=E*f summary column;
# nothing in the .lib is derived from it. The values are 1/minimum_period as
# the generated library declares it (wrom0: 29.35 / 54.75 / 20.74 ns), so the
# power column is quoted at the fastest clock the library actually allows.
# They are NOT a frequency bound in their own right -- min_pulse_width and
# minimum_period on clk0 are, and STA reads those.
CORNERS="${ROM_CORNERS:-tt:1.8:25:34.1 ss:1.6:100:18.3 ff:1.95:-40:48.2}"
# .lib CELL_TABLE index_2 points (output load, fF)
LOADS="${LOADS:-1.7225 6.89 27.56}"
# .lib CELL_TABLE index_1 points (clk0 input transition, ns).
#
# The axis spans what a real on-chip clock delivers into a 2.5 fF pin. Its top
# point becomes max_transition on clk0, so the library stays self-consistent.
#
# WHY IT STOPS AT 0.5 ns: above ~1 ns the front-end measurement breaks. On a
# slow ramp the precharge net bumps across VDD/2 before its real transition,
# and `.measure ... RISE=1 TD=` takes the first crossing after the window
# opens, so it latches the bump -- at 1.5 ns, tt, wrom0 that put t_clk2pre
# (0.1527 ns) ahead of t_clk2int (0.1544 ns), i.e. the precharge net crossing
# before the signal that drives it through a NAND. It is the same glitch class
# the front-end measurement comments document. 0.05-0.5 ns is clean and
# monotonic at all three corners. Raising the axis means making the
# measurement robust first, not just changing this line.
SLEWS="${SLEWS:-0.05 0.2 0.5}"

# corner tag -> .lib corner name
corner_lib_name() {
  case "$1" in
    tt) echo "TT_1p8V_25C" ;;
    ss) echo "SS_1p6V_100C" ;;
    ff) echo "FF_1p95V_n40C" ;;
    *)  echo "$1" ;;
  esac
}

# macros to process: the arguments, or everything in the tree
macro_list() {
  if [ "$#" -gt 0 ]; then
    echo "$@"
  else
    python3 "$ROM_CHAR_DIR/rom_paths.py" --list
  fi
}

# load the G_* geometry variables (derived from the netlist, cached)
load_geom() {
  _g=$(python3 "$ROM_CHAR_DIR/rom_paths.py" "$1" --sh) || return 1
  eval "$_g"
}

# value of an ngspice .measure line: meas <log> <measurement name>
meas() {
  [ -f "$1" ] || return 0
  grep -m1 "^$2 " "$1" | awk '{print $3}'
}

# is ngspice available? (the generators work without it, the runs do not)
need_ngspice() {
  command -v "$NG" >/dev/null 2>&1 && return 0
  [ -x "$NG" ] && return 0
  echo "ERROR: ngspice not found ('$NG'). Set NGSPICE_BIN to its path." >&2
  exit 1
}
