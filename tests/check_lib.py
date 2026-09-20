#!/usr/bin/env python3
"""
Structural validation of a Liberty file.

This is the generic half of the test suite: everything here is true of ANY
.lib, not just this ROM. The ROM-specific expectations live in
tests/test_rom_lib.py.

What it catches -- all of it previously invisible until some downstream tool
choked on the file:

  * syntax errors, with a line number
  * a table whose shape does not match the lu_table_template it names
    (3 rows against a 3-entry index_1, 3 columns against index_2) -- the
    single easiest mistake to make when hand-editing gen_rom_lib.py, and one
    that different parsers react to differently: some interpolate garbage
  * a non-monotonic index_1/index_2 (interpolation then reads backwards)
  * a timing() group with no timing_type, or an unknown one
  * a delay arc missing one of its four tables, or a constraint arc missing
    its constraints
  * related_pin naming a pin that does not exist in the cell
  * a bus whose declared type width disagrees with its pin slice
  * duplicate (timing_type, related_pin) arcs on one pin
  * values that are not numbers, or negative delays
  * a broken power/ground chain: a voltage_map rail no pg_pin uses, a pg_pin
    whose voltage_name has no voltage_map entry, or a related_power_pin /
    related_ground_pin / related_pg_pin naming something that is not a pg_pin
    of the right kind. Declaring the rails and never referencing them is what
    this library used to do, and it fails silently.

Usage:
    python3 tests/check_lib.py output/lib/*.lib
Exit status is 1 if anything failed.
"""

from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from libparse import LibertyError, parse_file          # noqa: E402

# The four tables a delay arc must carry, and the two a constraint arc must.
DELAY_TABLES = ("cell_rise", "cell_fall", "rise_transition", "fall_transition")
CONSTRAINT_TABLES = ("rise_constraint", "fall_constraint")

DELAY_TYPES = {
    "combinational", "combinational_rise", "combinational_fall",
    "three_state_disable", "three_state_enable",
    "rising_edge", "falling_edge", "preset", "clear",
}
CONSTRAINT_TYPES = {
    "setup_rising", "setup_falling", "hold_rising", "hold_falling",
    "recovery_rising", "recovery_falling", "removal_rising", "removal_falling",
    "min_pulse_width", "minimum_period", "max_clock_tree_path",
    "min_clock_tree_path", "non_seq_setup_rising", "non_seq_hold_rising",
    "skew_rising", "skew_falling", "nochange_high_high", "nochange_low_low",
}

REQUIRED_LIBRARY_ATTRS = (
    "delay_model", "time_unit", "voltage_unit", "current_unit",
    "leakage_power_unit",
)


class Report:
    """Collected problems for one file."""

    def __init__(self, path):
        self.path = path
        self.errors = []
        self.warnings = []

    def error(self, line, msg):
        self.errors.append((line, msg))

    def warn(self, line, msg):
        self.warnings.append((line, msg))

    @property
    def ok(self):
        return not self.errors

    def print(self, verbose=False):
        base = os.path.basename(self.path)
        for line, msg in sorted(self.errors):
            print("  FAIL %s:%d  %s" % (base, line, msg))
        for line, msg in sorted(self.warnings):
            print("  warn %s:%d  %s" % (base, line, msg))
        if self.ok and not self.warnings and verbose:
            print("  ok   %s" % base)


def _numbers(text, report, line, what):
    """Split a Liberty value string into floats, complaining about junk."""
    out = []
    for piece in text.split(","):
        piece = piece.strip()
        if not piece:
            continue
        try:
            out.append(float(piece))
        except ValueError:
            report.error(line, "%s: %r is not a number" % (what, piece))
    return out


def collect_templates(lib, report):
    """name -> (rows, cols) from every lu_table_template in the library."""
    templates = {"scalar": (1, 1)}
    for tpl in lib.find("lu_table_template"):
        if not tpl.args:
            report.error(tpl.line, "lu_table_template with no name")
            continue
        name = tpl.args[0]
        dims = []
        for axis in ("index_1", "index_2"):
            raw = tpl.complex_args(axis)
            if raw is None:
                break
            vals = _numbers(raw[0], report, tpl.attr_line(axis),
                            "%s %s" % (name, axis))
            if not vals:
                report.error(tpl.attr_line(axis),
                             "%s: %s is empty" % (name, axis))
                break
            if any(b <= a for a, b in zip(vals, vals[1:])):
                # interpolation walks this axis in order; out-of-order or
                # duplicated breakpoints make the lookup meaningless
                report.error(tpl.attr_line(axis),
                             "%s: %s is not strictly increasing (%s)"
                             % (name, axis, ", ".join("%g" % v for v in vals)))
            dims.append(len(vals))
        if not dims:
            report.error(tpl.line, "%s: no index_1" % name)
            continue
        templates[name] = (dims[0], dims[1] if len(dims) > 1 else 1)
    return templates


def check_table(group, templates, report, context, allow_negative=False):
    """One cell_rise/rise_constraint/... group: shape and contents."""
    tpl_name = group.args[0] if group.args else None
    if tpl_name is None:
        report.error(group.line, "%s: %s names no template"
                     % (context, group.name))
        return
    if tpl_name not in templates:
        report.error(group.line, "%s: %s names template %r, which is not "
                     "declared in this library"
                     % (context, group.name, tpl_name))
        return
    want_rows, want_cols = templates[tpl_name]

    rows = group.complex_args("values")
    if rows is None:
        report.error(group.line, "%s: %s has no values()" % (context, group.name))
        return
    line = group.attr_line("values")
    if len(rows) != want_rows:
        report.error(line, "%s: %s(%s) has %d row(s), template index_1 has %d"
                     % (context, group.name, tpl_name, len(rows), want_rows))
    for i, row in enumerate(rows):
        vals = _numbers(row, report, line, "%s %s" % (context, group.name))
        if len(vals) != want_cols:
            report.error(line, "%s: %s(%s) row %d has %d value(s), template "
                         "index_2 has %d"
                         % (context, group.name, tpl_name, i + 1,
                            len(vals), want_cols))
        if not allow_negative:
            for v in vals:
                if v < 0:
                    report.error(line, "%s: %s has a negative value (%g)"
                                 % (context, group.name, v))


def pin_names(cell):
    """Every pin name the cell exposes, bus base names included."""
    names = set()
    for p in cell.find("pin"):
        if p.args:
            names.add(p.args[0])
    for b in cell.find("bus"):
        if b.args:
            names.add(b.args[0])
        for p in b.find("pin"):
            if p.args:
                names.add(p.args[0].split("[")[0])
                names.add(p.args[0])
    for pg in cell.find("pg_pin"):
        if pg.args:
            names.add(pg.args[0])
    return names


def check_timing(tgroup, templates, report, context, known_pins):
    ttype = tgroup.attr("timing_type")
    if ttype is None:
        report.error(tgroup.line, "%s: timing() with no timing_type" % context)
        return None
    ttype = ttype.strip('"')
    if ttype not in DELAY_TYPES and ttype not in CONSTRAINT_TYPES:
        report.error(tgroup.attr_line("timing_type"),
                     "%s: unknown timing_type %r" % (context, ttype))

    related = tgroup.attr("related_pin")
    if related is None:
        report.error(tgroup.line, "%s: timing(%s) with no related_pin"
                     % (context, ttype))
    else:
        related = related.strip('"')
        if known_pins and related not in known_pins:
            report.error(tgroup.attr_line("related_pin"),
                         "%s: related_pin %r is not a pin of this cell"
                         % (context, related))

    present = {g.name for g in tgroup.groups}
    if ttype in CONSTRAINT_TYPES:
        wanted = CONSTRAINT_TABLES
        # a constraint may legitimately be negative (hold, skew)
        allow_neg = True
    else:
        wanted = DELAY_TABLES
        allow_neg = False
    for name in wanted:
        if name not in present:
            report.error(tgroup.line, "%s: timing(%s) has no %s"
                         % (context, ttype, name))
    for g in tgroup.groups:
        if g.name in DELAY_TABLES or g.name in CONSTRAINT_TABLES:
            check_table(g, templates, report,
                        "%s timing(%s)" % (context, ttype),
                        allow_negative=allow_neg)

    return (ttype, related)


def check_pin(pin, templates, report, cell_name, known_pins, is_bus_member,
              power=frozenset(), ground=frozenset(), bus_width=None):
    label = pin.args[0] if pin.args else "<unnamed>"
    context = "%s/%s" % (cell_name, label)

    check_pg_refs(pin, power, ground, report, context)
    if power and ground:
        for attr in ("related_power_pin", "related_ground_pin"):
            if pin.attr(attr) is None:
                report.warn(pin.line, "%s: no %s -- a multi-voltage power "
                            "tool cannot tell which supply this pin belongs to"
                            % (context, attr))

    if not pin.args:
        report.error(pin.line, "%s: pin with no name" % cell_name)

    direction = pin.attr("direction")
    if direction is None and not is_bus_member:
        report.error(pin.line, "%s: no direction" % context)
    elif direction is not None and direction not in ("input", "output",
                                                     "inout", "internal"):
        report.error(pin.attr_line("direction"),
                     "%s: direction %r is not input/output/inout"
                     % (context, direction))

    seen = {}
    for t in pin.find("timing"):
        key = check_timing(t, templates, report, context, known_pins)
        if key is None:
            continue
        if key in seen:
            report.error(t.line, "%s: a second timing(%s) against %s -- the "
                         "first one is at line %d and one of them will be "
                         "ignored" % (context, key[0], key[1], seen[key]))
        else:
            seen[key] = t.line

    for ip in pin.find("internal_power"):
        check_pg_refs(ip, power, ground, report, "%s internal_power" % context)
        if power and ip.attr("related_pg_pin") is None:
            report.warn(ip.line, "%s: internal_power with no related_pg_pin -- "
                        "the energy is not attributed to any supply" % context)
        for g in ip.groups:
            if g.name in ("rise_power", "fall_power", "power"):
                check_table(g, templates, report, "%s internal_power" % context,
                            allow_negative=True)


def collect_rails(lib, cell, report):
    """The power/ground wiring: voltage_map -> pg_pin -> related_*_pin.

    All three links have to exist. Declaring voltage_map rails and then never
    referencing them -- which is what this library used to do -- leaves a
    multi-voltage power tool with no way to walk from a signal pin to its
    supply, and it does that silently.

    Returns (power_pin_names, ground_pin_names).
    """
    rails = set()
    for aname, args, line, kind in lib.attrs:
        if aname == "voltage_map" and kind == "complex":
            if not args:
                report.error(line, "voltage_map with no arguments")
            else:
                rails.add(args[0])

    power, ground = set(), set()
    used_rails = set()
    for pg in cell.find("pg_pin"):
        pgname = pg.args[0] if pg.args else None
        if pgname is None:
            report.error(pg.line, "pg_pin with no name")
            continue
        pgtype = pg.attr("pg_type")
        if pgtype is None:
            report.error(pg.line, "pg_pin(%s): no pg_type" % pgname)
        elif "power" in pgtype:
            power.add(pgname)
        elif "ground" in pgtype:
            ground.add(pgname)
        else:
            report.error(pg.attr_line("pg_type"),
                         "pg_pin(%s): unknown pg_type %r" % (pgname, pgtype))

        vname = pg.attr("voltage_name")
        if vname is None:
            report.error(pg.line, "pg_pin(%s): no voltage_name" % pgname)
        elif rails and vname not in rails:
            report.error(pg.attr_line("voltage_name"),
                         "pg_pin(%s): voltage_name %r has no voltage_map entry"
                         % (pgname, vname))
        else:
            used_rails.add(vname)

    for orphan in sorted(rails - used_rails):
        report.error(lib.line, "voltage_map declares rail %r but no pg_pin "
                     "uses it -- the rail is dead weight and nothing can be "
                     "attributed to it" % orphan)

    if not power:
        report.error(cell.line, "no pg_pin of a power type")
    if not ground:
        report.error(cell.line, "no pg_pin of a ground type")
    return power, ground


def check_pg_refs(group, power, ground, report, context):
    """related_power_pin / related_ground_pin / related_pg_pin must resolve."""
    for attr, allowed, what in (("related_power_pin", power, "power"),
                                ("related_ground_pin", ground, "ground"),
                                ("related_pg_pin", power | ground, "supply")):
        val = group.attr(attr)
        if val is None:
            continue
        val = val.strip('"')
        if val not in allowed:
            report.error(group.attr_line(attr),
                         "%s: %s names %r, which is not a %s pg_pin of this "
                         "cell" % (context, attr, val, what))


def check_cell(cell, templates, report, lib):
    name = cell.args[0] if cell.args else "<unnamed>"
    known = pin_names(cell)
    power, ground = collect_rails(lib, cell, report)

    if cell.attr("area") is None:
        report.warn(cell.line, "%s: no area" % name)

    # declared bus types, for the width cross-check below
    types = {}
    for t in lib.find("type") + cell.find("type"):
        if t.args:
            try:
                types[t.args[0]] = int(t.attr("bit_width"))
            except (TypeError, ValueError):
                report.error(t.line, "type %s: bit_width is missing or not an "
                             "integer" % t.args[0])

    for lp in cell.find("leakage_power"):
        check_pg_refs(lp, power, ground, report, "%s leakage_power" % name)

    for pin in cell.find("pin"):
        check_pin(pin, templates, report, name, known, is_bus_member=False,
                  power=power, ground=ground)

    for bus in cell.find("bus"):
        bname = bus.args[0] if bus.args else "<unnamed>"
        btype = bus.attr("bus_type")
        width = None
        if btype is None:
            report.error(bus.line, "%s/%s: no bus_type" % (name, bname))
        elif btype not in types:
            report.error(bus.attr_line("bus_type"),
                         "%s/%s: bus_type %r is not declared"
                         % (name, bname, btype))
        else:
            width = types[btype]

        direction = bus.attr("direction")
        if direction == "output":
            lo, hi = bus.attr("min_capacitance"), bus.attr("max_capacitance")
            if lo is not None and hi is not None:
                try:
                    if float(lo) > float(hi):
                        report.error(bus.attr_line("max_capacitance"),
                                     "%s/%s: min_capacitance %s > "
                                     "max_capacitance %s" % (name, bname, lo, hi))
                except ValueError:
                    report.error(bus.line, "%s/%s: capacitance is not a number"
                                 % (name, bname))

        for pin in bus.find("pin"):
            label = pin.args[0] if pin.args else ""
            if width is not None and "[" in label and ":" in label:
                slice_ = label[label.index("[") + 1:label.rindex("]")]
                try:
                    a, b = (int(x) for x in slice_.split(":"))
                    if abs(a - b) + 1 != width:
                        report.error(pin.line,
                                     "%s/%s: pin slice [%d:%d] is %d bits but "
                                     "type %s declares %d"
                                     % (name, bname, a, b, abs(a - b) + 1,
                                        btype, width))
                except ValueError:
                    report.error(pin.line, "%s/%s: cannot read the bus slice %r"
                                 % (name, bname, label))
            check_pin(pin, templates, report, name, known, is_bus_member=True,
                      power=power, ground=ground, bus_width=width)


def check_file(path):
    report = Report(path)
    try:
        lib = parse_file(path)
    except LibertyError as exc:
        report.error(exc.line, exc.msg)
        return report
    except OSError as exc:
        report.error(0, str(exc))
        return report

    for attr in REQUIRED_LIBRARY_ATTRS:
        if lib.attr(attr) is None:
            report.error(lib.line, "library has no %s" % attr)

    templates = collect_templates(lib, report)

    cells = lib.find("cell")
    if not cells:
        report.error(lib.line, "library contains no cell")
    for cell in cells:
        check_cell(cell, templates, report, lib)

    return report


def main(argv):
    paths = [a for a in argv[1:] if not a.startswith("-")]
    verbose = "-v" in argv or "--verbose" in argv
    if not paths:
        sys.exit(__doc__.strip())

    failed = 0
    for path in paths:
        report = check_file(path)
        report.print(verbose=verbose)
        if not report.ok:
            failed += 1

    if failed:
        print("check_lib: %d of %d file(s) FAILED" % (failed, len(paths)))
        return 1
    print("check_lib: %d file(s) ok" % len(paths))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
