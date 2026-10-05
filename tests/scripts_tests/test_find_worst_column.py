#!/usr/bin/env python3
"""Unit, CLI, and integration tests for find_worst_column.py."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SCRIPTS_DIR = ROOT / "scripts" / "rom_char"
sys.path.insert(0, str(SCRIPTS_DIR))

import find_worst_column  # noqa: E402


class TestFindWorstColumn(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="test-fwc-")
        self.addCleanup(self.tmp.cleanup)
        self.tmp_path = Path(self.tmp.name)

    def write_sp(self, content: str) -> Path:
        p = self.tmp_path / "test_macro.sp"
        p.write_text(content)
        return p

    # --- 1. SPICE Netlist Structure & Data Edge Cases ---

    def test_basic_matrix(self):
        """Test a clean 3x3 ROM matrix with known 1 and 0 cell counts."""
        # Row 0: c0=1, c1=1, c2=1
        # Row 1: c0=1, c1=1, c2=0
        # Row 2: c0=1, c1=0, c2=0
        # Expected:
        # col 0: 3 one_cells (worst)
        # col 1: 2 one_cells
        # col 2: 1 one_cell  (best)
        sp_content = """
.SUBCKT test_macro_rom_base_array bl_0 bl_1 bl_2 wl_0 wl_1 wl_2 gnd
Xbit_r0_c0
+ bl_int_0_0 bl_0 wl_0 gnd
+ test_macro_rom_base_one_cell
Xbit_r0_c1
+ bl_int_0_1 bl_1 wl_0 gnd
+ test_macro_rom_base_one_cell
Xbit_r0_c2
+ bl_int_0_2 bl_2 wl_0 gnd
+ test_macro_rom_base_one_cell

Xbit_r1_c0
+ bl_int_1_0 bl_int_0_0 wl_1 gnd
+ test_macro_rom_base_one_cell
Xbit_r1_c1
+ bl_int_1_1 bl_int_0_1 wl_1 gnd
+ test_macro_rom_base_one_cell
Xbit_r1_c2
+ bl_2 wl_1 gnd
+ test_macro_rom_base_zero_cell

Xbit_r2_c0
+ bl_int_2_0 bl_int_1_0 wl_2 gnd
+ test_macro_rom_base_one_cell
Xbit_r2_c1
+ bl_int_1_1 wl_2 gnd
+ test_macro_rom_base_zero_cell
Xbit_r2_c2
+ bl_2 wl_2 gnd
+ test_macro_rom_base_zero_cell
.ENDS test_macro_rom_base_array
"""
        path = self.write_sp(sp_content)
        res = find_worst_column.analyse(str(path))
        self.assertIsNotNone(res)
        rows, cols, worst_col, chain, avg, mn, best_col = res

        self.assertEqual(rows, 3)
        self.assertEqual(cols, 3)
        self.assertEqual(worst_col, 0)
        self.assertEqual(chain, 3)
        self.assertEqual(best_col, 2)
        self.assertEqual(mn, 1)
        self.assertAlmostEqual(avg, (3 + 2 + 1) / 3.0)

    def test_all_zero_column_edge_case(self):
        """Columns with zero one_cells (all zeros / metal straps) must be included."""
        sp_content = """
.SUBCKT test_macro_rom_base_array bl_0 bl_1 wl_0 wl_1 gnd
* Col 0 has 2 one_cells
Xbit_r0_c0
+ bl_int_0_0 bl_0 wl_0 gnd
+ test_macro_rom_base_one_cell
Xbit_r1_c0
+ bl_int_1_0 bl_int_0_0 wl_1 gnd
+ test_macro_rom_base_one_cell

* Col 1 has 0 one_cells (all zeros)
Xbit_r0_c1
+ bl_1 wl_0 gnd
+ test_macro_rom_base_zero_cell
Xbit_r1_c1
+ bl_1 wl_1 gnd
+ test_macro_rom_base_zero_cell
.ENDS test_macro_rom_base_array
"""
        path = self.write_sp(sp_content)
        res = find_worst_column.analyse(str(path))
        self.assertIsNotNone(res)
        rows, cols, worst_col, chain, avg, mn, best_col = res

        self.assertEqual(cols, 2)
        self.assertEqual(worst_col, 0)
        self.assertEqual(chain, 2)
        self.assertEqual(best_col, 1)  # Must select col 1 as best
        self.assertEqual(mn, 0)        # Min count must be 0
        self.assertAlmostEqual(avg, (2 + 0) / 2.0)

    def test_tie_breaking_is_deterministic(self):
        """When multiple columns have identical counts, tie-breaking must be stable."""
        sp_content = """
.SUBCKT test_macro_rom_base_array bl_0 bl_1 wl_0 gnd
Xbit_r0_c0
+ bl_int_0_0 bl_0 wl_0 gnd
+ test_macro_rom_base_one_cell
Xbit_r0_c1
+ bl_int_0_1 bl_1 wl_0 gnd
+ test_macro_rom_base_one_cell
.ENDS test_macro_rom_base_array
"""
        path = self.write_sp(sp_content)
        res = find_worst_column.analyse(str(path))
        self.assertIsNotNone(res)
        rows, cols, worst_col, chain, avg, mn, best_col = res
        # Both columns have count 1; tie-breaking orders by column index
        self.assertEqual(worst_col, 0)
        self.assertEqual(best_col, 0)
        self.assertEqual(chain, 1)

    def test_scoping_ignores_decoder_arrays(self):
        """Instances in row/column decoders must not contaminate the counts."""
        sp_content = """
.SUBCKT test_macro_rom_row_decode_array bl_0 bl_1 wl_0 gnd
* Decoder has 3 one_cells on col 1
Xbit_r0_c1
+ bl_int_0_1 bl_1 wl_0 gnd
+ test_macro_rom_base_one_cell
Xbit_r1_c1
+ bl_int_1_1 bl_int_0_1 wl_1 gnd
+ test_macro_rom_base_one_cell
Xbit_r2_c1
+ bl_int_2_1 bl_int_1_1 wl_2 gnd
+ test_macro_rom_base_one_cell
.ENDS test_macro_rom_row_decode_array

.SUBCKT test_macro_rom_base_array bl_0 bl_1 wl_0 gnd
* Main array: col 0 has 2 one_cells, col 1 has 1 one_cell
Xbit_r0_c0
+ bl_int_0_0 bl_0 wl_0 gnd
+ test_macro_rom_base_one_cell
Xbit_r0_c1
+ bl_int_0_1 bl_1 wl_0 gnd
+ test_macro_rom_base_one_cell
Xbit_r1_c0
+ bl_int_1_0 bl_int_0_0 wl_1 gnd
+ test_macro_rom_base_one_cell
Xbit_r1_c1
+ bl_1 wl_1 gnd
+ test_macro_rom_base_zero_cell
.ENDS test_macro_rom_base_array

.SUBCKT test_macro_rom_column_decode_array bl_0 bl_1 wl_0 gnd
Xbit_r0_c1
+ bl_int_0_1 bl_1 wl_0 gnd
+ test_macro_rom_base_one_cell
.ENDS test_macro_rom_column_decode_array
"""
        path = self.write_sp(sp_content)
        res = find_worst_column.analyse(str(path))
        self.assertIsNotNone(res)
        rows, cols, worst_col, chain, avg, mn, best_col = res

        # Col 0 must be worst_col with 2 cells (if decoder weren't ignored, col 1 would have 4 cells)
        self.assertEqual(worst_col, 0)
        self.assertEqual(chain, 2)
        self.assertEqual(best_col, 1)
        self.assertEqual(mn, 1)

    def test_continuation_and_whitespace_formatting(self):
        """SPICE netlists can have arbitrary continuation lines and extra spaces."""
        sp_content = """
.SUBCKT test_macro_rom_base_array bl_0 bl_1
Xbit_r0_c0
+   bl_int_0_0   
+   bl_0   
+   wl_0   
+   gnd   
+   test_macro_rom_base_one_cell  
Xbit_r0_c1
+ bl_1 wl_0 gnd test_macro_rom_base_zero_cell
.ENDS test_macro_rom_base_array
"""
        path = self.write_sp(sp_content)
        res = find_worst_column.analyse(str(path))
        self.assertIsNotNone(res)
        rows, cols, worst_col, chain, avg, mn, best_col = res
        self.assertEqual(worst_col, 0)
        self.assertEqual(chain, 1)

    def test_non_matching_format_returns_none(self):
        """Netlists missing the base array or matching instance patterns return None."""
        # Case 1: Empty file
        p1 = self.write_sp("")
        self.assertIsNone(find_worst_column.analyse(str(p1)))

        # Case 2: No _rom_base_array subckt
        p2 = self.write_sp("""
.SUBCKT other_circuit
Xbit_r0_c0 bl_0 wl_0 gnd test_macro_rom_base_one_cell
.ENDS other_circuit
""")
        self.assertIsNone(find_worst_column.analyse(str(p2)))

        # Case 3: Different cell instance naming (e.g. Xcell_r0_c0)
        p3 = self.write_sp("""
.SUBCKT test_macro_rom_base_array
Xcell_r0_c0 bl_0 wl_0 gnd test_macro_rom_base_one_cell
.ENDS test_macro_rom_base_array
""")
        self.assertIsNone(find_worst_column.analyse(str(p3)))

    def test_row_zero_counts(self):
        """Test per-row zero cell counting across different rows."""
        sp_content = """
.SUBCKT test_macro_rom_base_array bl_0 bl_1 bl_2 wl_0 wl_1 gnd
* Row 0: 3 zero_cells
Xbit_r0_c0
+ bl_0 wl_0 gnd
+ test_zero_cell
Xbit_r0_c1
+ bl_1 wl_0 gnd
+ test_zero_cell
Xbit_r0_c2
+ bl_2 wl_0 gnd
+ test_zero_cell
* Row 1: 0 zero_cells (all one_cells)
Xbit_r1_c0
+ bl_int_0 bl_0 wl_1 gnd
+ test_one_cell
Xbit_r1_c1
+ bl_int_1 bl_1 wl_1 gnd
+ test_one_cell
Xbit_r1_c2
+ bl_int_2 bl_2 wl_1 gnd
+ test_one_cell
.ENDS test_macro_rom_base_array
"""
        path = self.write_sp(sp_content)
        res = find_worst_column.row_zero_counts(str(path))
        self.assertIsNotNone(res)
        rows, cols, z_counts = res
        self.assertEqual(rows, 2)
        self.assertEqual(cols, 3)
        self.assertEqual(z_counts[0], 3)
        self.assertEqual(z_counts[1], 0)

    # --- 2. CLI, Missing Files, and Integration Edge Cases ---

    def test_cli_execution_with_sp_flag(self):
        """CLI invocation via --sp must exit 0 and print column statistics."""
        sp_content = """
.SUBCKT test_cli_rom_base_array bl_0 bl_1 wl_0 gnd
Xbit_r0_c0
+ bl_int_0 bl_0 wl_0 gnd
+ test_one_cell
Xbit_r0_c1
+ bl_1 wl_0 gnd
+ test_zero_cell
.ENDS test_cli_rom_base_array
"""
        path = self.write_sp(sp_content)
        proc = subprocess.run(
            [sys.executable, str(SCRIPTS_DIR / "find_worst_column.py"), "--sp", str(path)],
            capture_output=True, text=True
        )
        self.assertEqual(proc.returncode, 0)
        self.assertIn("worst_column", proc.stdout)
        self.assertIn("series_NMOS", proc.stdout)
        self.assertIn("test_macro", proc.stdout)

    def test_cli_missing_file_handling(self):
        """Passing a non-existent macro netlist should report cleanly without crashing."""
        proc = subprocess.run(
            [sys.executable, str(SCRIPTS_DIR / "find_worst_column.py"), "--sp", "/non/existent/path.sp"],
            capture_output=True, text=True
        )
        self.assertEqual(proc.returncode, 0)
        self.assertIn("no netlist:", proc.stderr)

    def test_real_wrom0_regression(self):
        """Verify results against the known examples/wrom0 macro if present."""
        wrom0_sp = ROOT / "examples" / "wrom0" / "wrom0.sp"
        if not wrom0_sp.exists():
            self.skipTest("examples/wrom0/wrom0.sp not found")

        res = find_worst_column.analyse(str(wrom0_sp))
        self.assertIsNotNone(res)
        rows, cols, worst_col, chain, avg, mn, best_col = res
        self.assertEqual(rows, 134)
        self.assertEqual(cols, 256)
        self.assertEqual(worst_col, 236)
        self.assertEqual(chain, 82)
        self.assertEqual(best_col, 10)
        self.assertEqual(mn, 48)


if __name__ == "__main__":
    unittest.main()
