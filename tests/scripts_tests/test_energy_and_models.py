#!/usr/bin/env python3
"""Edge cases for energy sampling and generated timing/model helpers."""

from contextlib import redirect_stderr
from io import StringIO
from pathlib import Path
from unittest import mock
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
CHAR = ROOT / "scripts" / "rom_char"
sys.path.insert(0, str(CHAR))

import gen_macro_behavioral_v as behavioral  # noqa: E402
import gen_random_read_energy as energy  # noqa: E402


class EnergyTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="energy-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def test_measurement_parser_handles_missing_malformed_and_scientific_values(self):
        self.assertIsNone(energy.meas(self.root / "missing.log", "e"))
        log = self.root / "x.log"
        log.write_text("e = nope\ne = 1.25e-3\n")
        self.assertIsNone(energy.meas(log, "e"), "first malformed measurement must not be skipped")
        log.write_text("prefix_e = 9\ne = 1.25e-3\n")
        self.assertAlmostEqual(energy.meas(log, "e"), 1.25e-3)

    def test_address_space_prefers_exact_bin_word_count_and_has_array_fallback(self):
        self.assertEqual(energy.address_space({"words_per_row": 8, "words": 13}, 2),
                         (13, 8, True))
        self.assertEqual(energy.address_space({"words_per_row": 0, "words": 0}, 3),
                         (3, 1, False))

    def test_sampling_is_reproducible_and_uses_row_activity(self):
        char = self.root / "char"
        char.mkdir()
        (char / "col1_energy_tt.log").write_text("e_col_pj = 2.0\n")
        (char / "periph_active_tt.log").write_text("e_periph_pj = 1.0\n")
        geom = {"macro": "demo", "sp": "demo.sp", "char": str(char),
                "worst_col": 1, "words_per_row": 2, "words": 4}
        with mock.patch.object(energy.rom_paths, "geometry", return_value=geom), \
             mock.patch.object(energy.find_worst_column, "row_zero_counts",
                               return_value=(2, 4, {0: 1, 1: 3})):
            first = energy.sample("demo", "tt", 20, 7)
            second = energy.sample("demo", "tt", 20, 7)
        self.assertEqual(first["table"], second["table"])
        self.assertEqual({row for _addr, row, _n, _e in first["table"]}, {0, 1})
        for _addr, row, n_dis, e_read in first["table"]:
            self.assertEqual(n_dis, {0: 1, 1: 3}[row])
            self.assertEqual(e_read, n_dis * 2.0 + 1.0)

    def test_sampling_reports_every_missing_measurement(self):
        char = self.root / "char"
        char.mkdir()
        geom = {"macro": "demo", "sp": "demo.sp", "char": str(char),
                "worst_col": 0, "words_per_row": 1, "words": 1}
        with mock.patch.object(energy.rom_paths, "geometry", return_value=geom), \
             mock.patch.object(energy.find_worst_column, "row_zero_counts",
                               return_value=(1, 1, {0: 1})):
            with self.assertRaises(SystemExit) as ctx:
                energy.sample("demo", "tt", 1, 0)
        msg = str(ctx.exception)
        self.assertIn("e_col_pj", msg)
        self.assertIn("e_periph_pj", msg)

    def test_sampling_uses_only_requested_corner_and_worst_column_logs(self):
        char = self.root / "char"
        char.mkdir()
        (char / "col3_energy_ss.log").write_text("e_col_pj = 2.0\n")
        (char / "periph_active_ss.log").write_text("e_periph_pj = 5.0\n")
        # Decoys: a wrong corner or neighbouring column must never win merely
        # because the file exists or sorts first.
        (char / "col3_energy_tt.log").write_text("e_col_pj = 200.0\n")
        (char / "col2_energy_ss.log").write_text("e_col_pj = 300.0\n")
        geom = {"macro": "demo", "sp": "demo.sp", "char": str(char),
                "worst_col": 3, "words_per_row": 1, "words": 1}
        with mock.patch.object(energy.rom_paths, "geometry", return_value=geom), \
             mock.patch.object(energy.find_worst_column, "row_zero_counts",
                               return_value=(1, 4, {0: 1})):
            result = energy.sample("demo", "ss", 1, 0)
        self.assertEqual(result["e_col"], 2.0)
        self.assertEqual(result["e_periph"], 5.0)
        self.assertEqual(result["e_avg"], 7.0)

    def test_cli_rejects_zero_reads_and_bad_seed(self):
        for args, text in ((["demo", "--reads", "0"], "at least 1"),
                           (["demo", "--seed", "abc"], "integer or 'random'")):
            with self.subTest(args=args), self.assertRaises(SystemExit) as ctx, \
                 redirect_stderr(StringIO()) as err:
                energy.main(args)
            self.assertEqual(ctx.exception.code, 2)
            self.assertIn(text, err.getvalue())


class BehavioralTimingTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="timing-model-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def test_corner_aliases_are_case_insensitive_and_custom_corner_survives(self):
        self.assertEqual(behavioral.resolve_corner(None), behavioral.DEFAULT_CORNER)
        self.assertEqual(behavioral.resolve_corner(" TT "), "TT_1p8V_25C")
        self.assertEqual(behavioral.resolve_corner("custom"), "custom")

    def test_cell_rise_uses_only_requested_edge_and_largest_table_value(self):
        text = """
        timing() {
          timing_type : rising_edge;
          cell_rise(t) { values(\"1.0, 2.5e0\", \\"0.5, 2.0\"); }
        }
        timing() {
          timing_type : falling_edge;
          cell_rise(t) { values(\"9.0, 10.0\"); }
        }
        """
        self.assertEqual(behavioral._cell_rise_max(text), 2.5)
        self.assertEqual(behavioral._cell_rise_max(text, "falling_edge"), 10.0)
        self.assertIsNone(behavioral._cell_rise_max("no timing arcs"))

    def test_cell_rise_does_not_borrow_a_table_from_the_next_timing_group(self):
        text = """
        timing() {
          timing_type : rising_edge;
          cell_fall(t) { values(\"1.0\"); }
        }
        timing() {
          timing_type : falling_edge;
          cell_rise(t) { values(\"9.0\"); }
        }
        """
        self.assertIsNone(behavioral._cell_rise_max(text, "rising_edge"))
        self.assertEqual(behavioral._cell_rise_max(text, "falling_edge"), 9.0)

    def test_read_lib_timing_does_not_borrow_hold_from_later_pin_group(self):
        lib = self.root / "x.lib"
        lib.write_text("""
        bus(addr0) { timing() { timing_type : setup_rising; values(\"0.1\"); } }
        pin(cs0) { timing() { timing_type : hold_rising; values(\"7.0\"); } }
        """)
        timing = behavioral.read_lib_timing(lib)
        self.assertIsNone(timing["hold"])
        self.assertEqual(timing["hold_cs"], 7.0)

    def test_read_lib_timing_does_not_borrow_setup_from_cs0(self):
        lib = self.root / "x.lib"
        lib.write_text("""
        bus(addr0) { timing() { timing_type : hold_rising; values(\"0.1\"); } }
        pin(cs0) { timing() { timing_type : setup_rising; values(\"7.0\"); } }
        """)
        timing = behavioral.read_lib_timing(lib)
        self.assertIsNone(timing["setup"])

    def test_constraints_do_not_borrow_values_from_the_next_timing_arc(self):
        lib = self.root / "x.lib"
        lib.write_text("""
        bus(addr0) {
          timing() { timing_type : setup_rising; rise_constraint(t) { } }
          timing() { timing_type : hold_rising; values(\"7.0\"); }
        }
        pin(clk0) {
          timing() {
            timing_type : "min_pulse_width";
            rise_constraint(scalar) { values(\"2.0\"); }
          }
          timing() {
            timing_type : "minimum_period";
            fall_constraint(scalar) { values(\"9.0\"); }
          }
        }
        """)
        timing = behavioral.read_lib_timing(lib)
        self.assertIsNone(timing["setup"])
        self.assertIsNone(timing["t_pre"])
        self.assertEqual(timing["mpw_high"], 2.0)

    def test_banner_is_fallback_but_table_wins_with_warning(self):
        lib = self.root / "x.lib"
        lib.write_text("""
        /* TOTAL (worst load): 9.0 ns */
        timing() {
          timing_type : rising_edge;
          cell_rise(t) { values(\"1.0, 2.0\"); }
        }
        """)
        err = StringIO()
        with redirect_stderr(err):
            timing = behavioral.read_lib_timing(lib)
        self.assertEqual(timing["access"], 2.0)
        self.assertIn("using the table", err.getvalue())

    def test_missing_library_returns_all_known_keys_as_none(self):
        timing = behavioral.read_lib_timing(self.root / "missing.lib")
        self.assertTrue(timing)
        self.assertTrue(all(value is None for value in timing.values()))

    def test_generated_liberty_values_round_trip_to_the_behavioral_model(self):
        lef = self.root / "sentinel.lef"
        lef.write_text("""
MACRO sentinel
  SIZE 10 BY 2 ;
  PIN addr0[0]
    DIRECTION INPUT ;
  END addr0[0]
  PIN dout0[0]
    DIRECTION OUTPUT ;
  END dout0[0]
  PIN clk0
    DIRECTION INPUT ;
  END clk0
  PIN cs0
    DIRECTION INPUT ;
  END cs0
  PIN vccd1
    DIRECTION INOUT ;
    USE POWER ;
  END vccd1
  PIN vssd1
    DIRECTION INOUT ;
    USE GROUND ;
  END vssd1
END sentinel
""")
        cmd = [
            sys.executable, str(CHAR / "gen_rom_lib.py"),
            "--lef", str(lef), "--outdir", str(self.root),
            "--corner", "TT_1p8V_25C", "--memory-type", "rom", "--measured",
            "--access", "1.1", "--t-front", "0.5",
            "--backend-ns", "0.1,0.2,0.3",
            "--out-slew-ns", "0.01,0.02,0.03",
            "--t-pre", "2.2", "--setup", "3.3",
            "--hold", "1.1", "--hold-measured", "4.4",
            "--t-invalid", "0.7",
        ]
        generated = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        self.assertEqual(generated.returncode, 0, generated.stderr)
        timing = behavioral.read_lib_timing(
            self.root / "sentinel_TT_1p8V_25C.lib")
        self.assertEqual(timing["access"], 1.9)  # front + array + worst backend
        self.assertEqual(timing["t_pre"], 2.4)  # measured precharge + 0.2 ns margin
        self.assertEqual(timing["setup"], 3.3)
        self.assertEqual(timing["hold"], 4.4)
        self.assertEqual(timing["hold_cs"], 1.9)
        self.assertEqual(timing["t_fall"], 0.7)


if __name__ == "__main__":
    unittest.main()
