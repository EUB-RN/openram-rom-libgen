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
# WHY: the macro list, the worst-column table, the column count (256) and the
# repository path used to be repeated by hand in every script; if they were
# not all updated together after a ROM was regenerated, the measurements went
# silently wrong. See rom_paths.py.

ROM_CHAR_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$ROM_CHAR_DIR/../.." && pwd)"
MACROS_DIR="$(python3 "$ROM_CHAR_DIR/rom_paths.py" --macros-dir-only)"
LIB_DIR="$(python3 "$ROM_CHAR_DIR/rom_paths.py" --lib-dir)"
VERILOG_DIR="$(python3 "$ROM_CHAR_DIR/rom_paths.py" --verilog-dir)"

NG="${NGSPICE_BIN:-ngspice}"
JOBS="${JOBS:-4}"

# tag:vdd:temperature:fmax(MHz) -- fmax only feeds the P=E*f summary column
CORNERS="${ROM_CORNERS:-tt:1.8:25:38.2 ss:1.6:100:19.1 ff:1.95:-40:60.7}"
# .lib CELL_TABLE index_2 points (output load, fF)
LOADS="${LOADS:-1.7225 6.89 27.56}"

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
