#!/usr/bin/env python3
"""
Tests for the checker itself.

A validator nobody validates is worse than no validator: it turns every run
green and everyone stops looking. tests/fixtures/ holds one hand-written
VALID Liberty file plus a copy of it per defect, each carrying exactly one.
This asserts that the valid one passes and that each broken one is rejected
for the RIGHT reason -- matched on a substring of the message, so a check that
starts firing for some unrelated reason still counts as a failure here.

Usage:
    python3 tests/test_checker.py
"""

from __future__ import annotations

import os
import sys

HERE = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, HERE)
from check_lib import check_file                       # noqa: E402

FIXTURES = os.path.join(HERE, "fixtures")

# fixture -> a substring the failure message must contain
EXPECTED = {
    "broken_syntax.lib":            "never closed",
    "broken_table_shape.lib":       "row(s), template index_1 has 3",
    "broken_row_width.lib":         "value(s), template index_2 has 3",
    "broken_no_timing_type.lib":    "no timing_type",
    "broken_related_pin.lib":       "is not a pin of this cell",
    "broken_index_order.lib":       "not strictly increasing",
    "broken_missing_table.lib":     "has no fall_transition",
    "broken_bus_width.lib":         "but type word declares 8",
    "broken_unknown_template.lib":  "is not declared in this library",
    "broken_negative_delay.lib":    "negative value",
    "broken_not_a_number.lib":      "is not a number",
    # the power/ground chain: voltage_map -> pg_pin -> related_*_pin
    "broken_orphan_rail.lib":       "but no pg_pin uses it",
    "broken_rail_undeclared.lib":   "has no voltage_map entry",
    "broken_related_power_pin.lib": "is not a power pg_pin",
    "broken_related_pg_pin.lib":    "is not a supply pg_pin",

    # the declaration layer: a library/template/type header that is itself
    # wrong. These fail EARLY, and everything downstream of them then fails
    # for a second, misleading reason -- so each is matched on the first
    # message, the one that names the actual defect.
    "broken_library_no_delay_model.lib": "library has no delay_model",
    "broken_library_no_cell.lib":        "library contains no cell",
    "broken_template_no_name.lib":       "lu_table_template with no name",
    "broken_template_no_index1.lib":     "T: no index_1",
    "broken_bit_width_not_int.lib":      "bit_width is missing or not an integer",

    # the pin layer
    "broken_pin_no_direction.lib":       "no direction",
    "broken_pin_bad_direction.lib":      "is not input/output/inout",
    "broken_bus_no_type.lib":            "no bus_type",
    "broken_max_cap_not_a_number.lib":   "capacitance is not a number",

    # the power/ground chain, continued: a pg_pin that is itself incomplete,
    # and a cell left with no power rail at all
    "broken_pg_no_type.lib":             "no pg_type",
    "broken_pg_no_voltage_name.lib":     "no voltage_name",
    "broken_no_power_pg_pin.lib":        "no pg_pin of a power type",

    # the timing layer
    "broken_timing_no_related_pin.lib":  "with no related_pin",
    "broken_table_no_values.lib":        "has no values()",
    # A duplicate arc is the one defect here that a reader would not see: the
    # file is valid Liberty, every table is well formed, and the parser takes
    # whichever of the two it meets last. Half the macro's timing can be
    # replaced this way without a single syntax complaint.
    "broken_duplicate_timing_arc.lib":   "a second timing(rising_edge) against clk",

    # the bus GEOMETRY: a type whose width, range and pin slice must all agree.
    # Each of these came out of a malformed LEF, and all three used to reach a
    # .lib that check_lib accepted -- the width-only slice check passes when
    # the count is right and the range is not.
    "broken_bit_width_zero.lib":         "a bus needs at least one bit",
    "broken_bit_range_span.lib":         "but bit_width says",
    "broken_bus_slice_range.lib":        "does not match type word",
    "broken_zero_area.lib":              "cannot occupy zero or negative area",
    "broken_area_not_a_number.lib":      "is not a number",
}


def main():
    failures = 0

    good = os.path.join(FIXTURES, "good.lib")
    report = check_file(good)
    if not report.ok:
        print("  FAIL good.lib is valid Liberty but the checker rejected it:")
        for line, msg in report.errors:
            print("       line %d: %s" % (line, msg))
        failures += 1

    on_disk = {f for f in os.listdir(FIXTURES) if f.startswith("broken_")}
    for missing in sorted(on_disk - set(EXPECTED)):
        print("  FAIL %s has no entry in EXPECTED -- an untested fixture is a "
              "check nobody is watching" % missing)
        failures += 1

    for fixture, needle in sorted(EXPECTED.items()):
        path = os.path.join(FIXTURES, fixture)
        if not os.path.exists(path):
            print("  FAIL %s is listed in EXPECTED but does not exist" % fixture)
            failures += 1
            continue
        report = check_file(path)
        if report.ok:
            print("  FAIL %s slipped through the checker" % fixture)
            failures += 1
            continue
        msgs = [m for _l, m in report.errors]
        if not any(needle in m for m in msgs):
            print("  FAIL %s was rejected, but not for the expected reason." % fixture)
            print("       wanted a message containing: %r" % needle)
            for m in msgs:
                print("       got: %s" % m)
            failures += 1

    if failures:
        print("test_checker: %d failure(s)" % failures)
        return 1
    print("test_checker: good.lib passes, %d defect(s) each caught for the "
          "right reason" % len(EXPECTED))
    return 0


if __name__ == "__main__":
    sys.exit(main())
