#!/usr/bin/env python3
"""Numerical and malformed-input edge cases for resistance extraction helpers."""

from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
CHAR = ROOT / "scripts" / "rom_char"
sys.path.insert(0, str(CHAR))

import gen_resistance_model as resistance  # noqa: E402


class ResistanceModelTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="resistance-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def test_missing_tech_file_uses_documented_nominal_fallback(self):
        values = resistance.sheet_resistances(str(self.root / "missing.tech"))
        self.assertEqual(values["allm1"], 0.125)
        self.assertEqual(values["allpolynonres"], 48.2)

    def test_tech_parser_selects_requested_variant_and_converts_milliohms(self):
        tech = self.root / "sky130.tech"
        tech.write_text("""
variants (si)
resist (allm1)/metal1 125
resist (allpolynonres)/poly 48200
variants (high)
resist (allm1)/metal1 999
""")
        values = resistance.sheet_resistances(str(tech), "si")
        self.assertEqual(values["allm1"], 0.125)
        self.assertEqual(values["plane:metal1"], 0.125)
        self.assertEqual(values["allpolynonres"], 48.2)

    def test_two_point_series_parallel_disconnected_and_floating_island(self):
        self.assertAlmostEqual(
            resistance.two_point_resistance([("A", "x", 2), ("x", "B", 3)], "A", "B"), 5.0)
        parallel = [("A", "B", 10), ("A", "B", 10)]
        self.assertAlmostEqual(resistance.two_point_resistance(parallel, "A", "B"), 5.0)
        self.assertIsNone(resistance.two_point_resistance([("A", "x", 1)], "A", "B"))
        with_island = [("A", "B", 4), ("u", "v", 1)]
        self.assertAlmostEqual(resistance.two_point_resistance(with_island, "A", "B"), 4.0)

    def test_zero_or_negative_resistor_is_bounded_not_divided_by_zero(self):
        value = resistance.two_point_resistance([("A", "B", 0)], "A", "B")
        self.assertGreaterEqual(value, 0.0)
        self.assertLess(value, 1e-6)

    def test_parse_res_spice_handles_no_resistors_no_device_and_both_ports(self):
        self.assertEqual(resistance.parse_res_spice("X0 D G S B nfet"),
                         (0.0, "no R elements (nothing in series with the channel)"))
        value, note = resistance.parse_res_spice("R1 A B 2")
        self.assertIsNone(value)
        self.assertIn("no device", note)

        value, note = resistance.parse_res_spice("""
R1 S s_int 2
R2 D d_int 3
X0 d_int G s_int B nfet
""")
        self.assertAlmostEqual(value, 5.0)
        self.assertIn("S->channel", note)
        self.assertIn("D->channel", note)

    def test_mag_parser_and_analytic_strap_success_and_missing_labels(self):
        mag = self.root / "cell.mag"
        mag.write_text("""
magic
<< metal1 >>
rect 0 0 10 100
rlabel metal1 0 0 0 10 10 0 S
rlabel metal1 0 0 90 10 100 0 D
<< end >>
""")
        layers, labels = resistance.read_mag(mag)
        self.assertEqual(layers["metal1"], [(0, 0, 10, 100)])
        self.assertIn("S", labels)
        value, note = resistance.analytic_strap_ohms(mag, {"allm1": 0.125})
        self.assertAlmostEqual(value, 1.0)
        self.assertIn("8.00 squares", note)

        missing = self.root / "missing-label.mag"
        missing.write_text("<< metal1 >>\nrect 0 0 10 100\n")
        value, note = resistance.analytic_strap_ohms(missing, {"allm1": 0.125})
        self.assertIsNone(value)
        self.assertIn("no S/D", note)

    def test_poly_model_handles_absent_geometry_and_missing_sheet_value(self):
        mag = self.root / "poly.mag"
        mag.write_text("<< metal1 >>\nrect 0 0 1 1\n")
        self.assertIsNone(resistance.analytic_poly_per_pitch(mag, {}, 10))
        mag.write_text("<< poly >>\nrect 0 0 100 2\n")
        self.assertIsNone(resistance.analytic_poly_per_pitch(mag, {}, 10))
        self.assertAlmostEqual(
            resistance.analytic_poly_per_pitch(mag, {"allpolynonres": 48.2}, 10), 241.0)


if __name__ == "__main__":
    unittest.main()
