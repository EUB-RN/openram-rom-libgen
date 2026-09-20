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

HERE = os.path.dirname(os.path.abspath(__file__))
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
