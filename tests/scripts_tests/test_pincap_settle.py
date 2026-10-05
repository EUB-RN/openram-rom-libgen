#!/usr/bin/env python3
"""Edge cases for adaptive pin-capacitance settling."""

from pathlib import Path
import json
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
CHAR = ROOT / "scripts" / "rom_char"
sys.path.insert(0, str(CHAR))

import pincap_settle_step as pincap  # noqa: E402


class PinCapSettleTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="pincap-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.deck = self.root / "pin.sp"
        self.log = self.root / "pin.log"
        self.deck.write_text("*PINCAP 0 clk0\n")

    def run_step(self, *args):
        return subprocess.run(
            [sys.executable, str(CHAR / "pincap_settle_step.py"),
             str(self.deck), str(self.log), *args],
            capture_output=True, text=True)

    def measurements(self, cyc=1.0, rise=1.0, fall=1.0):
        self.log.write_text(
            f"c_cyc0_ff = {cyc}\nc_rise0_ff = {rise}\nc_fall0_ff = {fall}\n")

    def test_time_parser_handles_supported_units_and_rejects_invalid_times(self):
        self.assertEqual(pincap.parse_time_ns("10ns"), 10.0)
        self.assertEqual(pincap.parse_time_ns("2u"), 2000.0)
        self.assertEqual(pincap.parse_time_ns("500ps"), 0.5)
        self.assertEqual(pincap.parse_time_ns("1e-9"), 1.0)
        for value in ("0", "-1n", "nan", "inf"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                pincap.parse_time_ns(value)

    def test_converged_pin_exits_zero_and_removes_state(self):
        self.measurements(rise=1.0, fall=1.005)
        state = Path(str(self.log) + ".pincap_state.json")
        state.write_text("{}")
        result = self.run_step("--thresh", "1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "CONVERGED")
        self.assertFalse(state.exists())

    def test_unsettled_pin_scales_only_that_pin(self):
        self.measurements(rise=1.0, fall=1.2)
        result = self.run_step("--current-map", "clk0:10n", "--step-th", "2")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout.strip(), "clk0:20.00n")
        self.assertIn("exceed", result.stderr)

    def test_missing_zero_and_nonfinite_measurements_fail_loudly(self):
        cases = ["c_cyc0_ff = 1\nc_rise0_ff = 1\n",
                 "c_cyc0_ff = 1\nc_rise0_ff = 0\nc_fall0_ff = 1\n",
                 "c_cyc0_ff = 1\nc_rise0_ff = nan\nc_fall0_ff = 1\n"]
        for content in cases:
            with self.subTest(content=content):
                self.log.write_text(content)
                result = self.run_step()
                self.assertEqual(result.returncode, 2)
                self.assertIn("Measurement failed", result.stderr)

    def test_partial_previous_state_does_not_crash_saturation_check(self):
        self.measurements(rise=1.0, fall=1.2)
        state = Path(str(self.log) + ".pincap_state.json")
        state.write_text(json.dumps({"clk0": {"gap": 20.0}}))
        result = self.run_step("--current-map", "clk0:20n")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("clk0:30.00n", result.stdout)

    def test_malformed_state_is_ignored(self):
        self.measurements(rise=1.0, fall=1.2)
        Path(str(self.log) + ".pincap_state.json").write_text("not json")
        result = self.run_step()
        self.assertEqual(result.returncode, 1, result.stderr)


if __name__ == "__main__":
    unittest.main()
