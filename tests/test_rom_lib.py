#!/usr/bin/env python3
"""
ROM-specific checks on the generated .lib files.

tests/check_lib.py asks "is this a valid Liberty file?". This asks "does it say
what this macro actually does?" -- the questions a parser cannot answer, and
the ones that were silently wrong before. Each check names the failure mode it
exists to prevent.

Usage:
    python3 tests/test_rom_lib.py output/lib/*.lib
Exit status is 1 if anything failed.
"""

from __future__ import annotations

import os
import re
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from libparse import LibertyError, parse_file          # noqa: E402


# ---------------------------------------------------------------------------
# small helpers over the parse tree
# ---------------------------------------------------------------------------

def rows(table_group):
    """A table group -> list of list of float."""
    raw = table_group.complex_args("values") or []
    return [[float(x) for x in row.split(",") if x.strip()] for row in raw]


def arcs(pin):
    """timing_type -> the timing group, for one pin."""
    out = defaultdict(list)
    for t in pin.find("timing"):
        ttype = t.attr("timing_type")
        if ttype:
            out[ttype.strip('"')].append(t)
    return out


def bus_pin(cell, bus_name):
    """The pin(...) group inside bus(bus_name), or None."""
    for bus in cell.find("bus"):
        if bus.args and bus.args[0] == bus_name:
            pins = bus.find("pin")
            return pins[0] if pins else None
    return None


def scalar_pin(cell, name):
    for pin in cell.find("pin"):
        if pin.args and pin.args[0] == name:
            return pin
    return None


def bus_width(cell, bus_name):
    for bus in cell.find("bus"):
        if bus.args and bus.args[0] == bus_name:
            for pin in bus.find("pin"):
                m = re.search(r"\[(\d+):(\d+)\]", pin.args[0] if pin.args else "")
                if m:
                    return abs(int(m.group(1)) - int(m.group(2))) + 1
    return None


# ---------------------------------------------------------------------------
# the checks -- each returns a list of failure strings
# ---------------------------------------------------------------------------

def check_memory_group(cell):
    """The widths in memory() must match the actual buses.

    Prevents: a regenerated ROM (new word_size / words_per_row) whose .lib
    still advertises the old geometry. A tool trusts memory() over the pins.
    """
    bad = []
    mem = cell.first("memory")
    if mem is None:
        return ["no memory() group -- the macro will not be recognised as one"]
    if mem.attr("type") != "rom":
        bad.append("memory() type is %r, expected rom" % mem.attr("type"))
    for attr, bus in (("address_width", "addr0"), ("word_width", "dout0")):
        declared = mem.attr(attr)
        actual = bus_width(cell, bus)
        if declared is None:
            bad.append("memory() has no %s" % attr)
        elif actual is None:
            bad.append("cannot read the width of bus %s" % bus)
        elif int(declared) != actual:
            bad.append("memory() %s is %s but bus %s is %d bits wide"
                       % (attr, declared, bus, actual))
    return bad


def check_dout_arcs(cell):
    """dout0 must carry BOTH the rising_edge and the falling_edge arc.

    Prevents THE false pass this suite was written for: there is no output
    latch, so dout0 dies when clk0 falls. With only the rising arc, STA
    assumes the data holds until the next capture edge and reports a pass
    that the silicon does not honour.
    """
    bad = []
    pin = bus_pin(cell, "dout0")
    if pin is None:
        return ["no pin group inside bus(dout0)"]
    a = arcs(pin)

    if "rising_edge" not in a:
        bad.append("dout0 has no rising_edge arc (clk0 -> data valid)")
    if "falling_edge" not in a:
        bad.append("dout0 has no falling_edge arc -- nothing in the Liberty "
                   "data says the output dies when clk0 falls, so STA will "
                   "read this unlatched ROM as if it held its output")
    if bad:
        return bad

    rise = a["rising_edge"][0]
    fall = a["falling_edge"][0]
    for arc, name in ((rise, "rising_edge"), (fall, "falling_edge")):
        if arc.attr("related_pin", ).strip('"') != "clk0":
            bad.append("the %s arc on dout0 is related to %s, not clk0"
                       % (name, arc.attr("related_pin")))

    acc = rows(rise.first("cell_rise"))
    inv = rows(fall.first("cell_rise"))
    if not acc or not inv:
        return bad + ["one of the dout0 arcs has no cell_rise values"]

    flat_acc = [v for row in acc for v in row]
    flat_inv = [v for row in inv for v in row]

    if min(flat_inv) <= 0:
        bad.append("the falling_edge (invalidation) delay is %g ns -- it must "
                   "be positive" % min(flat_inv))
    if max(flat_inv) >= min(flat_acc):
        bad.append("the falling_edge delay (%g ns) is not earlier than the "
                   "access time (%g ns); an invalidation that lands after the "
                   "data is valid says nothing"
                   % (max(flat_inv), min(flat_acc)))
    if len(set(flat_inv)) != 1:
        bad.append("the falling_edge table is not flat (%g .. %g) -- it is "
                   "meant to be the earliest invalidation at every load"
                   % (min(flat_inv), max(flat_inv)))
    return bad


# The header sentence gen_rom_lib.py writes when it ships a flat index_1
# because run_slew_sweep.sh produced no log. Kept as one string in one place:
# if the generator's wording changes and this does not, _declares_flat_axis
# stops recognising the declaration and the standard-mode library FAILS the
# check -- loudly, and in the safe direction, rather than quietly accepting an
# axis nobody declared. gen_rom_lib.py carries a comment pointing back here.
FLAT_AXIS_DECLARATION = "the slew axis was NOT measured"

# Raw bytes of the file currently under check; main() sets it per file. Empty
# means "no text available", which makes _declares_flat_axis answer False --
# i.e. an undeclared axis, the failing direction.
_SOURCE_TEXT = ""


def _declares_flat_axis(lib):
    """Does the library's own header admit its index_1 is a fallback?"""
    return FLAT_AXIS_DECLARATION in _SOURCE_TEXT


def check_slew_axis(cell, lib):
    """index_1 must be measured, monotonic, and agree with max_transition.

    Prevents three things, all of which happened:
      * a flat axis -- three copies of one number, so the macro appears not to
        care how fast its clock arrives;
      * a delay that FALLS as the input edge slows. That is the signature of
        the measurement latching a glitch rather than the real transition: on
        a 1.5 ns clk0 ramp t_clk2pre came out below t_clk2int, which drives it
        through a NAND and cannot be faster;
      * an input declaring a max_transition beyond the axis it was
        characterised on -- the old library allowed 0.04 ns while every
        front-end measurement ran at 0.5 ns.
    """
    bad = []
    tpl = None
    for t in lib.find("lu_table_template"):
        if t.args and t.args[0] == "CELL_TABLE":
            tpl = t
    if tpl is None:
        return ["no CELL_TABLE template"]
    raw = tpl.complex_args("index_1")
    if not raw:
        return ["CELL_TABLE has no index_1"]
    axis = [float(x) for x in raw[0].split(",") if x.strip()]

    pin = bus_pin(cell, "dout0")
    rise = arcs(pin).get("rising_edge") if pin else None
    if rise:
        vals = rows(rise[0].first("cell_rise"))
        if len({tuple(r) for r in vals}) == 1:
            # A FLAT AXIS IS A DEFECT ONLY WHEN IT IS SILENT.
            #
            # `flow.py` without --full does not run run_slew_sweep.sh, so it
            # ships one number repeated three times -- on purpose, and the
            # generator says so in the header (and on stderr). What this check
            # was written to catch is the axis that is flat while the library
            # claims it was measured: then the macro "appears not to care how
            # fast its clock arrives" and a consumer has no way to tell.
            # A library that declares the fallback makes no such claim, so it
            # is reported as the known fallback rather than failed -- which
            # keeps `./flow.py <macro>` able to finish on its own output.
            if _declares_flat_axis(lib):
                print("  NOTE index_1 is the declared FALLBACK -- one number "
                      "repeated, the slew axis was not measured "
                      "(./flow.py <macro> --full measures it)")
            else:
                bad.append("cell_rise is flat along index_1 and the header "
                           "does not declare it -- the clk0 slew axis was "
                           "never measured (run_slew_sweep.sh, or --full)")
        else:
            # A NOISE TOLERANCE, with a number behind it. The front-end
            # term is measured in a transient whose timestep (TCLK/steps =
            # 1 ns) is coarser than the delay itself, and the step cannot be
            # refined: at --steps 4000 the periphery deck aborts with
            # "Timestep too small" because it runs with uic from an
            # inconsistent initial state. Re-running one point at --steps 400
            # moved t_clk2pre by 0.2% (0.7616 -> 0.7603 ns), so sub-percent
            # wiggle on this axis is measurement noise, not behaviour.
            #
            # 1% still catches what this check exists for: the 1.5 ns clk0
            # ramp that made t_clk2pre collapse by 81% (0.8118 -> 0.1527 ns)
            # when the measurement latched a glitch instead of the real
            # transition.
            TOL = 0.01
            for col in range(len(vals[0])):
                column = [r[col] for r in vals]
                drops = [(a - b) / a for a, b in zip(column, column[1:])
                         if b < a and a > 0]
                if drops and max(drops) > TOL:
                    bad.append("cell_rise falls %.1f%% as the input slew grows "
                               "at load point %d (%s) -- a slower clock edge "
                               "cannot make the macro faster"
                               % (max(drops) * 100, col + 1,
                                  ", ".join("%g" % v for v in column)))

    top = max(axis)
    for pin_name in ("clk0", "cs0"):
        p = scalar_pin(cell, pin_name)
        if p is None:
            continue
        mt = p.attr("max_transition")
        if mt is None:
            bad.append("%s has no max_transition" % pin_name)
        elif abs(float(mt) - top) > 1e-9:
            bad.append("%s declares max_transition %s but index_1 stops at %g "
                       "-- the library allows a slew it was never measured at"
                       % (pin_name, mt, top))
    return bad


def check_early_path(cell):
    """dout0 must carry retain_rise/retain_fall, and they must be early.

    Prevents the gap this check was written for: with only late data (worst
    column) the tool believes the previous cycle's value is held right up to
    the access time. A race that eats it before the capture flop takes it then
    passes silently -- a hold check has nothing to fail on.
    """
    bad = []
    pin = bus_pin(cell, "dout0")
    if pin is None:
        return ["no pin group inside bus(dout0)"]
    rise = arcs(pin).get("rising_edge")
    if not rise:
        return ["dout0 has no rising_edge arc"]
    arc = rise[0]

    for name in ("retain_rise", "retain_fall"):
        if arc.first(name) is None:
            bad.append("the rising_edge arc has no %s -- this file carries "
                       "LATE data only, so nothing bounds how soon dout0 can "
                       "move (run run_early_path.sh)" % name)
    # retain_* without retaining_* is ignored by most parsers
    for name in ("retaining_rise", "retaining_fall"):
        if arc.first(name) is None and arc.first("retain_rise") is not None:
            bad.append("retain_* is present but %s is not; the pair is "
                       "ignored without it" % name)
    if bad:
        return bad

    delay = [v for r in rows(arc.first("cell_rise")) for v in r]
    keep = [v for r in rows(arc.first("retain_rise")) for v in r]
    if min(keep) <= 0:
        bad.append("retain_rise is %g ns -- it must be positive" % min(keep))
    if max(keep) >= min(delay):
        bad.append("retain_rise (%g ns) is not earlier than the access time "
                   "(%g ns); an early bound at or after the late one says "
                   "nothing" % (max(keep), min(delay)))
    return bad


def check_load_monotonic(cell):
    """Delay and output slew must not fall as the load grows.

    Prevents: a back-end sweep whose three load points were written in the
    wrong order, which silently makes the heaviest load look fastest.
    """
    bad = []
    pin = bus_pin(cell, "dout0")
    if pin is None:
        return []
    rise = arcs(pin).get("rising_edge")
    if not rise:
        return []
    for tname in ("cell_rise", "rise_transition"):
        tbl = rise[0].first(tname)
        if tbl is None:
            continue
        for i, row in enumerate(rows(tbl)):
            if any(b < a for a, b in zip(row, row[1:])):
                bad.append("%s row %d falls as the load grows (%s)"
                           % (tname, i + 1, ", ".join("%g" % v for v in row)))
    return bad


def check_constraints(cell):
    """Every input must carry setup and hold against clk0.

    Prevents: an input the timing tool treats as unconstrained, i.e. free.
    """
    bad = []
    targets = [("addr0", bus_pin(cell, "addr0"))]
    for name in ("cs0",):
        targets.append((name, scalar_pin(cell, name)))
    for name, pin in targets:
        if pin is None:
            bad.append("no pin group for %s" % name)
            continue
        a = arcs(pin)
        for want in ("setup_rising", "hold_rising"):
            if want not in a:
                bad.append("%s has no %s constraint against clk0" % (name, want))
    return bad


def check_control_hold(cell):
    """cs0 must be held for the WHOLE access window, not the address's hold.

    Prevents the defect this check was written for: the hold experiment cuts
    the series chain, which is what a moving ADDRESS does to a clocked row
    decoder. cs0 is not on that path -- it gates the precharge
    (precharge = ~NAND(cs0, clk_int)), so losing it during evaluate turns the
    precharge PMOS back on and kills the read at any point in the cycle,
    including the late part where the address no longer matters. Copying the
    address's measured hold onto cs0 relaxes a constraint nothing measured.
    """
    bad = []
    pin = scalar_pin(cell, "cs0")
    dout = bus_pin(cell, "dout0")
    if pin is None or dout is None:
        return []
    rise = arcs(dout).get("rising_edge")
    if not rise:
        return []
    delay = rows(rise[0].first("cell_rise"))
    if not delay:
        return []
    access = max(v for r in delay for v in r)

    # cs0 must ALSO be pinned to the CLOCK'S PHASE, not to a duration. No
    # setup/hold number expresses "stable until clk0 falls": a hold reaches
    # forward from the rise, a setup reaches back from the fall, and a high
    # phase longer than their sum has a middle that neither covers -- while
    # the requirement itself grows with the clock period. (hold_falling does
    # not rescue it either: a hold bounds how EARLY a pin may change after a
    # PAST edge, so a cs0 dropped mid-phase is measured against the previous
    # falling edge and passes with room to spare.)
    #
    # cs0 gates the array's internal clock -- precharge = ~NAND(cs0, clk_int)
    # -- so the construct that fits is the clock-gating check, whose anchors
    # are the two EDGES: enable ready before the phase opens, held until it
    # closes.
    _a = arcs(pin)
    for _want in ("clock_gating_setup_rising", "clock_gating_hold_falling"):
        if _want not in _a:
            bad.append("cs0 has no %s against clk0. It gates the internal "
                       "clock, so the requirement is that it may only change "
                       "while clk0 is LOW -- a phase, not a duration. No "
                       "setup/hold number can state that, so without this "
                       "pair a cs0 pulled in mid-phase is a silent wrong "
                       "read that STA cannot see." % _want)

    hold = arcs(pin).get("hold_rising")
    if not hold:
        return []           # check_constraints already reports a missing arc
    for kind in ("rise_constraint", "fall_constraint"):
        tbl = hold[0].first(kind)
        if tbl is None:
            continue
        worst = min(v for r in rows(tbl) for v in r)
        if worst < access - 1e-6:
            bad.append("cs0 %s is %g ns, shorter than the access time "
                       "(%g ns). cs0 gates the precharge, so the read dies "
                       "the moment it goes away -- it has to be held for the "
                       "whole window. Only the ADDRESS hold may be shorter, "
                       "and only where run_hold_bisect.sh measured it."
                       % (kind, worst, access))
    return bad


def check_clock(cell):
    """clk0 must declare its pulse widths, its period, and BOTH power states.

    Prevents two things. A missing minimum_period lets the tool clock the
    macro faster than the bitline can precharge. A missing internal_power
    when-block is scored as ZERO by OpenSTA without any warning, so the
    idle power of the macro silently disappears from the report.
    """
    bad = []
    clk = scalar_pin(cell, "clk0")
    if clk is None:
        return ["no pin(clk0)"]
    if clk.attr("clock") != "true":
        bad.append("clk0 is not marked clock : true")

    a = arcs(clk)
    for want in ("min_pulse_width", "minimum_period"):
        if want not in a:
            bad.append("clk0 has no %s" % want)
    if "min_pulse_width" in a and "minimum_period" in a:
        pw = a["min_pulse_width"][0]
        per = a["minimum_period"][0]
        hi = rows(pw.first("rise_constraint"))[0][0]
        lo = rows(pw.first("fall_constraint"))[0][0]
        p = rows(per.first("rise_constraint"))[0][0]
        if p < hi + lo - 1e-9:
            bad.append("minimum_period %g ns is shorter than the two pulse "
                       "widths it has to contain (%g + %g = %g ns)"
                       % (p, hi, lo, hi + lo))

    states = set()
    for ip in clk.find("internal_power"):
        when = ip.attr("when")
        if when:
            states.add(when.strip('"').replace(" ", ""))
    if not states:
        bad.append("clk0 has no internal_power -- the macro will report zero "
                   "dynamic power")
    else:
        for want in ("cs0", "!cs0"):
            if want not in states:
                bad.append("clk0 has no internal_power for when %r; OpenSTA "
                           "scores a missing state as zero WITHOUT a warning"
                           % want)
    return bad


def check_macro_attrs(cell):
    """The macro must be fenced off from synthesis and carry its leakage."""
    bad = []
    for attr in ("dont_use", "dont_touch", "map_only"):
        if cell.attr(attr) != "true":
            bad.append("%s is not true -- synthesis may try to use or "
                       "restructure the macro" % attr)
    leak = cell.attr("cell_leakage_power")
    if leak is None:
        bad.append("no cell_leakage_power")
    elif float(leak) <= 0:
        bad.append("cell_leakage_power is %s; a 34k-transistor array does not "
                   "leak zero" % leak)
    # cell_leakage_power is what a tool reads when it ignores the per-state
    # groups, so it has to be the WORST of them -- a smaller number there
    # would silently under-report the state the groups describe.
    groups = [(lp.attr("when"), lp.attr("value")) for lp in
              cell.find("leakage_power")]
    vals = [(w, float(v)) for w, v in groups if v is not None]
    if leak is not None and vals:
        worst = max(v for _, v in vals)
        if float(leak) < worst - 1e-12:
            bad.append("cell_leakage_power is %s but a leakage_power group "
                       "carries %g -- the single number must be the worst "
                       "state, not the first one" % (leak, worst))
    if len(vals) > 1 and any(w is None for w, _ in vals):
        bad.append("several leakage_power groups and one of them has no "
                   "when condition -- a tool cannot tell which state it is")
    # EITHER one unconditional group, OR both cs0 states. A file that carries
    # a `when` group for one state and nothing for the other describes half a
    # macro: the header says both were measured, and a reader has no way to
    # tell that one of them went missing. This mirrors the rule check_clock
    # applies to internal_power, and it was added because deleting one of the
    # two groups passed every other check in this suite.
    conds = {w.strip('"').replace(" ", "") for w, _ in vals if w is not None}
    if conds and conds != {"cs0", "!cs0"}:
        bad.append("leakage_power carries the state(s) %s -- a conditional "
                   "leakage model has to give BOTH cs0 states or none at all, "
                   "otherwise the file describes one state and is silent "
                   "about the other" % ", ".join(sorted(conds)))

    kinds = {pg.attr("pg_type") for pg in cell.find("pg_pin")}
    for want in ("primary_power", "primary_ground"):
        if want not in kinds:
            bad.append("no pg_pin with pg_type %s" % want)
    return bad


def check_power_rails(cell):
    """Every signal pin and every power group must name its supply.

    check_lib.py already refuses a reference that does not resolve. This
    insists the references EXIST in the first place: the library used to
    declare voltage_map rails and pg_pins and then never point anything at
    them, which leaves a multi-voltage power tool with no way to walk from a
    pin to its supply. Nothing warns about it -- the analysis just comes out
    unattributed.
    """
    bad = []
    power = {pg.args[0] for pg in cell.find("pg_pin")
             if pg.args and "power" in (pg.attr("pg_type") or "")}
    ground = {pg.args[0] for pg in cell.find("pg_pin")
              if pg.args and "ground" in (pg.attr("pg_type") or "")}
    if not power or not ground:
        return ["the cell has no power and/or ground pg_pin"]

    signal_pins = [(p.args[0] if p.args else "?", p) for p in cell.find("pin")]
    for bus in cell.find("bus"):
        for p in bus.find("pin"):
            signal_pins.append((p.args[0] if p.args else "?", p))

    for label, pin in signal_pins:
        for attr in ("related_power_pin", "related_ground_pin"):
            if pin.attr(attr) is None:
                bad.append("%s has no %s" % (label, attr))

    for label, pin in signal_pins:
        for ip in pin.find("internal_power"):
            if ip.attr("related_pg_pin") is None:
                bad.append("%s: an internal_power group has no related_pg_pin, "
                           "so its energy is attributed to no supply" % label)

    for lp in cell.find("leakage_power"):
        if lp.attr("related_pg_pin") is None:
            bad.append("leakage_power has no related_pg_pin")

    return bad


CHECKS = (
    ("memory() matches the buses", check_memory_group),
    ("power/ground references", check_power_rails),
    ("dout0 rising + falling arcs", check_dout_arcs),
    ("dout0 early path (retain)", check_early_path),
    ("index_1 slew axis", check_slew_axis),
    ("delay/slew grow with load", check_load_monotonic),
    ("addr0 + cs0 constrained", check_constraints),
    ("cs0 held for the whole read", check_control_hold),
    ("clk0 widths, period, power", check_clock),
    ("macro attributes + leakage", check_macro_attrs),
)


# ---------------------------------------------------------------------------
# cross-corner check
# ---------------------------------------------------------------------------

CORNER_ORDER = {"FF": 0, "TT": 1, "SS": 2}


def check_corner_ordering(by_macro):
    """FF must be faster than TT, and TT faster than SS.

    Prevents: a corner run against the wrong model files, or a --measured run
    that accidentally got the derating factors applied on top. This is the
    cheapest possible detector for both and it needs no reference data.
    """
    bad = []
    for macro, entries in sorted(by_macro.items()):
        access = {}
        for corner, cell in entries:
            pin = bus_pin(cell, "dout0")
            if pin is None:
                continue
            rise = arcs(pin).get("rising_edge")
            if not rise:
                continue
            vals = rows(rise[0].first("cell_rise"))
            if vals:
                access[corner] = max(v for row in vals for v in row)
        ordered = sorted(access, key=lambda c: CORNER_ORDER.get(c, 9))
        for a, b in zip(ordered, ordered[1:]):
            if access[a] >= access[b]:
                bad.append("%s: %s access %g ns is not faster than %s %g ns"
                           % (macro, a, access[a], b, access[b]))
        # Only complain about a missing corner when a SET was handed in.
        # Checking one file on its own is a legitimate thing to do.
        if 1 < len(access) < 3:
            bad.append("%s: only %d of 3 corners present (%s)"
                       % (macro, len(access), ", ".join(sorted(access)) or "none"))
    return bad


# ---------------------------------------------------------------------------

def main(argv):
    paths = [a for a in argv[1:] if not a.startswith("-")]
    if not paths:
        sys.exit(__doc__.strip())

    failures = 0
    by_macro = defaultdict(list)

    for path in sorted(paths):
        base = os.path.basename(path)
        try:
            lib = parse_file(path)
            # The parser drops comments, and the header is a comment block --
            # but it is where the generator states which terms are fallbacks.
            # A check that has to ask "did this library declare it?" needs the
            # bytes. libparse.Group has __slots__, so they cannot ride on the
            # parsed object; they go in a module global set per file instead,
            # right next to the parse that produced it.
            global _SOURCE_TEXT
            _SOURCE_TEXT = open(path).read()
        except (LibertyError, OSError) as exc:
            print("  FAIL %s  cannot parse: %s" % (base, exc))
            failures += 1
            continue

        cells = lib.find("cell")
        if not cells:
            print("  FAIL %s  no cell group" % base)
            failures += 1
            continue
        cell = cells[0]

        m = re.match(r"(.+?)_(TT|SS|FF)_", base)
        if m:
            by_macro[m.group(1)].append((m.group(2), cell))

        for label, fn in CHECKS:
            try:
                # a few checks need library-level data (the table templates)
                problems = (fn(cell, lib) if fn.__code__.co_argcount == 2
                            else fn(cell))
            except Exception as exc:                    # a check itself broke
                problems = ["the check raised %s: %s" % (type(exc).__name__, exc)]
            for p in problems:
                print("  FAIL %s  [%s] %s" % (base, label, p))
                failures += 1

    for p in check_corner_ordering(by_macro):
        print("  FAIL [corner ordering] %s" % p)
        failures += 1

    if failures:
        print("test_rom_lib: %d failure(s) over %d file(s)" % (failures, len(paths)))
        return 1
    print("test_rom_lib: %d file(s) ok (%d checks each + corner ordering)"
          % (len(paths), len(CHECKS)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
