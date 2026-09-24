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
#   prov_*      -- the stamp that says a log came from THIS flow
#
# WHY: the macro list, the worst-column table, the column count and the
# repository path are derived here once instead of being repeated in every
# script, so regenerating a ROM cannot leave one of them stale. See
# rom_paths.py.

# Normally derived from the calling script. Overridable so the helpers below
# can be exercised on their own -- tests/test_error_reporting.py sources this
# file directly, where $0 is the shell rather than a run_*.sh.
ROM_CHAR_DIR="${ROM_CHAR_DIR:-$(cd "$(dirname "$0")" && pwd)}"
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

# --------------------------------------------------------------------------
# PROVENANCE: WHICH FLOW PRODUCED THIS LOG
#
# Every number in a .lib is read back out of a log in <macro>/char. Those logs
# are ordinary files that survive anything: a netlist regenerated with a new
# .bin, a deck rebuilt with a fixed measurement, an ngspice run that died
# halfway, a tree copied from somewhere else. `meas` cannot tell any of that
# apart -- it finds a line, it returns a number, and the library generator
# writes it out as a measured value.
#
# So each log gets a stamp beside it, <log>.prov, written by run_ng the moment
# the deck comes back clean. It records:
#     deck + deck_sha   the exact deck that was simulated
#     log_sha           the log as it was when it was judged healthy
#     src + src_sha     the macro netlist that deck was built from ($G_SP)
# and, if the run is later found to be unusable (check_settled), an `invalid`
# line saying why.
#
# CONTENT HASHES, NOT TIMESTAMPS. mtimes are rewritten by a git checkout, a
# copy, a rsync -- they say when a file arrived, not what is in it. The deck
# embeds the netlist it was built from, so a re-extracted macro or a changed
# generator produces a different deck and a different hash; that is what makes
# "this log belongs to the current flow" a question with an answer.
#
# WHO CHECKS: regen_rom_libs.sh, before it reads a single value. An unstamped
# or mismatched log is NOT treated as a missing one -- the missing-log paths
# fall back to documented pessimistic defaults, and quietly taking that road
# with a stale log on disk is the failure this exists to prevent.
PROV_VERSION=1

# sha256 of a file; the macro netlist is hashed once per macro (it is MBs and
# every log in the tree names the same one).
rom_sha() {
  [ -f "$1" ] || { echo "-"; return 0; }
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    # No sha tool at all: cksum is weaker but still content-derived, which is
    # the property being relied on.
    cksum "$1" | awk '{print $1 "-" $2}'
  fi
}

src_sha() {
  if [ "${_SRC_F:-}" != "$1" ]; then _SRC_F="$1"; _SRC_V=$(rom_sha "$1"); fi
  echo "$_SRC_V"
}

prov_field() { awk -F'\t' -v k="$2" '$1 == k { print $2; exit }' "$1" 2>/dev/null; }

# prov_write <stage> <deck> <artifact> [context]
#   <deck> may be "-" for a file DERIVED from other logs (run_periphery_leak's
#   .total, run_hold_bisect's hold_<corner>.log): there is no single deck
#   behind it, so what is stamped is the artifact itself plus the netlist.
prov_write() {
  _src="${G_SP:--}"
  {
    printf '# rom_char provenance v%s -- written by the flow, read by regen_rom_libs.sh\n' "$PROV_VERSION"
    printf 'version\t%s\n' "$PROV_VERSION"
    printf 'stage\t%s\n'   "$1"
    printf 'context\t%s\n' "${4:-}"
    printf 'when\t%s\n'    "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'deck\t%s\n'    "$2"
    printf 'deck_sha\t%s\n' "$([ "$2" = "-" ] && echo - || rom_sha "$2")"
    printf 'log_sha\t%s\n' "$(rom_sha "$3")"
    printf 'src\t%s\n'     "$_src"
    printf 'src_sha\t%s\n' "$([ "$_src" = "-" ] && echo - || src_sha "$_src")"
  } > "$3.prov"
}

# prov_invalidate <artifact> <reason>
#   The run happened and the file is there, but its number must not be used.
#   Recorded rather than deleted so the reason survives to whoever asks.
prov_invalidate() {
  [ -f "$1.prov" ] || prov_write "unknown" "-" "$1" ""
  grep -v '^invalid	' "$1.prov" > "$1.prov.tmp" 2>/dev/null || :
  mv "$1.prov.tmp" "$1.prov"
  printf 'invalid\t%s\n' "$2" >> "$1.prov"
}

# prov_adopt <stage> <deck> <log> [context]
#   For a deck that a GENERATOR ran on its own (gen_col_tb_parasitic.py runs
#   the TT column deck itself). The log did not pass through run_ng, so it is
#   judged here by the same fatal signatures and then stamped -- or marked
#   invalid, which is what makes an unstamped generator run unusable instead
#   of unnoticed. Returns 1 if the log is not fit to use.
prov_adopt() {
  if [ ! -f "$3" ]; then
    echo "  $1: $(basename "$3") was never written -- the generator's ngspice run did not produce it" >&2
    return 1
  fi
  _why=$(grep -hE "$NG_FATAL" "$3" 2>/dev/null | head -1 |
         sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | cut -c1-160)
  if [ -n "$_why" ]; then
    prov_invalidate "$3" "$_why"
    echo "  $1: $(basename "$3") -- $_why" >&2
    return 1
  fi
  prov_write "$1" "$2" "$3" "${4:-}"
  return 0
}

# prov_check <artifact>
#   Silent and 0 when the file belongs to the current flow. Otherwise prints
#   ONE line saying what is wrong with it and returns 1.
prov_check() {
  _a="$1"; _p="$1.prov"
  [ -f "$_a" ] || { echo "the file does not exist"; return 1; }
  if [ ! -f "$_p" ]; then
    echo "not stamped -- nothing says this flow produced it"
    return 1
  fi
  _inv=$(prov_field "$_p" invalid)
  [ -n "$_inv" ] && { echo "the run was rejected: $_inv"; return 1; }
  # THE DECK, IF IT IS STILL THERE. Decks are gitignored (`**/char/*.sp`, 204
  # MB across the examples) and every gen_*_tb.py rebuilds one from the
  # netlist on demand, so a missing deck is the normal state of a clone and
  # says nothing about the log. A deck that IS there and no longer hashes to
  # what was simulated does: the measurement was fixed, or the circuit was,
  # and this log predates it.
  _d=$(prov_field "$_p" deck)
  if [ -n "$_d" ] && [ "$_d" != "-" ] && [ -f "$_d" ]; then
    [ "$(rom_sha "$_d")" = "$(prov_field "$_p" deck_sha)" ] || {
      echo "$(basename "$_d") has changed since this log was written -- the log is from an older deck"
      return 1; }
  fi
  [ "$(rom_sha "$_a")" = "$(prov_field "$_p" log_sha)" ] || {
    echo "the file has changed since it was stamped"; return 1; }
  _s=$(prov_field "$_p" src)
  if [ -n "$_s" ] && [ "$_s" != "-" ]; then
    [ -f "$_s" ] || { echo "the netlist it was built from is gone ($_s)"; return 1; }
    [ "$(src_sha "$_s")" = "$(prov_field "$_p" src_sha)" ] || {
      echo "$(basename "$_s") has changed since this log was written -- re-run the flow"
      return 1; }
  fi
  return 0
}

# --------------------------------------------------------------------------
# RUNNING NGSPICE WITHOUT SWALLOWING THE FAILURE
#
# Every deck used to be run as
#     $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true
# which throws away the exit status AND the diagnostics, in the background as
# often as not. A deck that died produced no log, no message and no non-zero
# exit -- it surfaced much later as a missing .measure, or not at all.
#
# THE EXIT CODE ALONE IS NOT ENOUGH, measured rather than assumed:
#     unknown subckt            -> exit 1, "Simulation interrupted due to error!"
#     .measure on a bad node    -> exit 0, "Error: no such vector as ..."
#     empty netlist             -> exit 1, "Error: incomplete or empty netlist"
# The middle case is the dangerous one: ngspice reports success while the
# measurement it was asked for never happened.
#
# So a run is judged by its status AND by its log. The fatal list below was
# chosen by scanning all 311 committed logs: every pattern in it appears in
# ZERO of them, while "Error: measure" and "failed!" appear in 93 and are
# EXPECTED -- an unselected wordline has no edge to measure, and that failure
# is evidence the flow relies on. So the list separates a dead run from a
# healthy one without a single false positive on the existing corpus.
#
# "no data saved / analysis not run / can't parse" were added after the fact:
# a deck whose .measure names a node that does not exist reports exactly
# those, and it was being caught only by its exit code -- so the report said
# "exited 1 with no recognised message" instead of naming the cause. They are
# in 0 of the 311 logs as well.
NG_FATAL='Simulation interrupted|unknown subckt|no such vector|incomplete or empty netlist|Timestep too small|singular|iteration limit|[Ff]atal|Out of memory|MODELNAME|no data saved|analysis not run|can.t parse'

# One ledger per shell, so a failure inside a BACKGROUNDED job still reaches
# the parent: a subshell cannot set a variable in it, but it can append a line.
NG_LEDGER="${TMPDIR:-/tmp}/rom_char_ng_fail.$$"

ng_reset() { : > "$NG_LEDGER"; }
[ -f "$NG_LEDGER" ] || ng_reset

# run_ng <stage> <deck.sp> <log> [context]
#   Runs one deck. On failure prints WHICH STAGE died and WHY, keeps the deck
#   and the log for inspection, records it in the ledger and returns 1.
run_ng() {
  _st="$1"; _sp="$2"; _lg="$3"; _cx="${4:-}"
  if [ ! -f "$_sp" ]; then
    ng_fail "$_st" "$_cx" "$_sp" "$_lg" "-" "the deck was never written (the generator failed before ngspice ran)"
    return 1
  fi
  _term="${_lg}.term"
  "$NG" -b -o "$_lg" "$_sp" > "$_term" 2>&1
  _rc=$?
  # The WHOLE matching line, not just the matched fragment: ngspice puts the
  # useful part around the keyword ("fatal error: can't open library file
  # /nonexistent/..."), and grep -o would throw exactly that away.
  _why=$(grep -hE "$NG_FATAL" "$_lg" "$_term" 2>/dev/null | head -1 |
         sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | cut -c1-160)
  if [ -z "$_why" ] && [ "$_rc" -ne 0 ]; then
    _why="ngspice exited $_rc with no recognised message -- see the log"
  fi
  if [ -n "$_why" ]; then
    # The fatal signature is the VERDICT, but it is often ngspice's last word
    # rather than its first ("fatal error in ngspice, exit(1)" after "Could
    # not find library file ..."). So the first real Error/ERROR line is
    # reported alongside it as the root cause, with .measure failures excluded
    # -- those are expected here and would otherwise always win the race.
    _root=$(grep -hE '^[[:space:]]*(Error|ERROR)' "$_lg" "$_term" 2>/dev/null |
            grep -viE 'measure' | head -1 |
            sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | cut -c1-160)
    ng_fail "$_st" "$_cx" "$_sp" "$_lg" "$_rc" "$_why" "$_root"
    return 1
  fi
  rm -f "$_term"
  # The deck came back clean: stamp the log with the deck and the netlist it
  # came from, so regen_rom_libs.sh can tell this run from one left over in
  # the tree. Nothing downstream may use an unstamped log.
  prov_write "$_st" "$_sp" "$_lg" "$_cx"
  return 0
}

# the report: stage first, because that is the question being asked
ng_fail() {
  printf "\n  !! FAILED stage=%s %s\n" "$1" "${2:+[$2]}" >&2
  printf "     reason : %s\n" "$6" >&2
  [ -n "${7:-}" ] && [ "${7:-}" != "$6" ] && printf "     cause  : %s\n" "$7" >&2
  printf "     exit   : %s\n" "$5" >&2
  printf "     deck   : %s\n" "$3" >&2
  printf "     log    : %s\n" "$4" >&2
  printf "%s\t%s\t%s\t%s\n" "$1" "$2" "${7:-$6}" "$4" >> "$NG_LEDGER"
  # A failed re-run leaves the PREVIOUS run's log on disk, stamp and all. That
  # stamp said the file was good, and it is now the output of nothing -- so
  # withdraw it here rather than let regen_rom_libs.sh read a number the flow
  # has just failed to reproduce.
  [ -f "$4" ] && prov_invalidate "$4" "${7:-$6}"
  return 0
}

# A deck that RAN but has NOT CONVERGED. ngspice is silent about this: the
# .measure lines all resolve, the exit code is 0, and the number is simply a
# startup transient rather than the steady state. The decks that can tell
# measure the same quantity on two consecutive cycles; if those disagree the
# answer must not be used. 1% is the same limit gen_col_tb_parasitic.py
# applies to t_dis_50 vs t_dis_50_prev, and the measured spread on the
# committed periphery logs is under 0.6%, so it is a loose ceiling rather
# than a tight one.
SETTLE_MAX_PCT="${SETTLE_MAX_PCT:-1.0}"

# check_settled <stage> <log> <context> <gap_pct> [deck]
#   Records an unsettled deck in the ledger exactly like a crash, so the run
#   exits non-zero. Returns 1 if it did.
check_settled() {
  _st="$1"; _lg="$2"; _cx="$3"; _gp="$4"; _sp="${5:--}"
  awk -v g="$_gp" -v m="$SETTLE_MAX_PCT" 'BEGIN{exit !(g+0 > m+0)}' || return 0
  ng_fail "$_st" "$_cx" "$_sp" "$_lg" "0 (the deck ran clean)" \
          "NOT SETTLED -- the last two cycles differ by ${_gp}% (limit ${SETTLE_MAX_PCT}%). ngspice reports nothing wrong; the number is a startup transient, not the steady state. Raise --cycles and re-run; do not ship this value."
  return 1
}

# Call at the end of a run_*.sh: prints what died and returns 1 if anything
# did, so the script exits non-zero and a caller (or CI) can act on it.
ng_summary() {
  [ -s "$NG_LEDGER" ] || return 0
  echo >&2
  echo "SIMULATION FAILURES -- do not use these numbers:" >&2
  awk -F'\t' '{printf "  %-22s %-22s %s\n", $1, $2, $3}' "$NG_LEDGER" >&2
  echo "  (each failing deck and log was kept; re-run one by hand to see more)" >&2
  return 1
}

# is ngspice available? (the generators work without it, the runs do not)
need_ngspice() {
  command -v "$NG" >/dev/null 2>&1 && return 0
  [ -x "$NG" ] && return 0
  echo "ERROR: ngspice not found ('$NG'). Set NGSPICE_BIN to its path." >&2
  exit 1
}
