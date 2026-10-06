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



class TestNetlistFormatEdges(unittest.TestCase):
    """Formatting a netlist is allowed to vary; the answer is not.

    `analyse` picks the single column every timing number in the .lib is
    measured on. Anything that makes it silently count a different set of
    cells -- a lowercase keyword, an indent, nodes written on the instance
    line -- moves every number in the library without an error anywhere.
    """

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="test-fwc-fmt-")
        self.addCleanup(self.tmp.cleanup)
        self.tmp_path = Path(self.tmp.name)

    def write_sp(self, content: str, name: str = "m.sp") -> Path:
        p = self.tmp_path / name
        p.write_text(content)
        return p

    # One column of 2 one_cells (c1) and one of 1 (c0), written four ways.
    EXPECTED = (2, 2, 1, 2)   # rows, cols, worst_col, chain

    def check(self, path):
        res = find_worst_column.analyse(str(path))
        self.assertIsNotNone(res, "netlist parsed to nothing")
        rows, cols, worst_col, chain = res[0], res[1], res[2], res[3]
        self.assertEqual((rows, cols, worst_col, chain), self.EXPECTED)

    def test_uppercase_keywords(self):
        self.check(self.write_sp("""
.SUBCKT m_rom_base_array bl wl gnd
Xbit_r0_c0
+ n0 bl wl gnd
+ m_rom_base_one_cell
Xbit_r0_c1
+ n1 bl wl gnd
+ m_rom_base_one_cell
Xbit_r1_c1
+ n2 bl wl gnd
+ m_rom_base_one_cell
Xbit_r1_c0
+ n3 bl wl gnd
+ m_rom_base_zero_cell
.ENDS m_rom_base_array
"""))

    def test_lowercase_keywords(self):
        """ngspice and most non-OpenRAM writers emit lowercase.

        The scope test used to match '.SUBCKT ' literally: a lowercase
        netlist left the scope unset, every instance was skipped, and the
        result was 'no Xbit_r*_c* instances -- different netlist format?'
        on a file that is entirely well formed.
        """
        self.check(self.write_sp("""
.subckt m_rom_base_array bl wl gnd
Xbit_r0_c0
+ n0 bl wl gnd
+ m_rom_base_one_cell
Xbit_r0_c1
+ n1 bl wl gnd
+ m_rom_base_one_cell
Xbit_r1_c1
+ n2 bl wl gnd
+ m_rom_base_one_cell
Xbit_r1_c0
+ n3 bl wl gnd
+ m_rom_base_zero_cell
.ends m_rom_base_array
"""))

    def test_indented_netlist(self):
        self.check(self.write_sp("""
   .subckt m_rom_base_array bl wl gnd
     Xbit_r0_c0
     + n0 bl wl gnd
     + m_rom_base_one_cell
     Xbit_r0_c1
     + n1 bl wl gnd
     + m_rom_base_one_cell
     Xbit_r1_c1
     + n2 bl wl gnd
     + m_rom_base_one_cell
     Xbit_r1_c0
     + n3 bl wl gnd
     + m_rom_base_zero_cell
   .ends
"""))

    def test_nodes_on_the_instance_line(self):
        """OpenRAM wraps; a hand-written or re-flowed netlist need not."""
        self.check(self.write_sp("""
.subckt m_rom_base_array bl wl gnd
Xbit_r0_c0 n0 bl wl gnd m_rom_base_one_cell
Xbit_r0_c1 n1 bl wl gnd m_rom_base_one_cell
Xbit_r1_c1 n2 bl wl gnd m_rom_base_one_cell
Xbit_r1_c0 n3 bl wl gnd m_rom_base_zero_cell
.ends
"""))

    def test_ends_closes_the_array_scope(self):
        """Cells after the array's .ends must not be attributed to it.

        The scope used to persist until the NEXT .subckt line, so instances
        sitting at the top level after the array -- or inside a sub-circuit
        whose header the old uppercase-only test did not recognise -- were
        counted as array cells.
        """
        path = self.write_sp("""
.subckt m_rom_base_array bl wl gnd
Xbit_r0_c0 n0 bl wl gnd m_rom_base_one_cell
.ends
Xbit_r0_c5 n5 bl wl gnd m_rom_base_one_cell
Xbit_r9_c9 n9 bl wl gnd m_rom_base_one_cell
""")
        rows, cols, worst_col, chain = find_worst_column.analyse(str(path))[:4]
        self.assertEqual((rows, cols, worst_col, chain), (1, 1, 0, 1))

    def test_instance_without_a_cell_type_is_counted_as_a_column(self):
        """A column exists even when its cell type cannot be resolved; it
        must not be silently dropped from the column count, because the
        column count scales energy and leakage."""
        path = self.write_sp("""
.subckt m_rom_base_array bl wl gnd
Xbit_r0_c0
Xbit_r0_c1 n1 bl wl gnd m_rom_base_one_cell
.ends
""")
        rows, cols, worst_col, chain = find_worst_column.analyse(str(path))[:4]
        self.assertEqual((cols, worst_col, chain), (2, 1, 1))

    def test_missing_file_raises(self):
        with self.assertRaises(OSError):
            find_worst_column.analyse(str(self.tmp_path / "absent.sp"))


class TestTieBreakIsIndexOrdered(unittest.TestCase):
    """A tie must resolve on the column index, not on file order.

    `Counter.most_common()` returns insertion order for equal counts, so the
    worst column depended on the order the array happened to be emitted in.
    Two netlists describing the SAME ROM, written in different order, chose
    different columns -- and since every access/setup number in the .lib
    comes from that one column, the whole library moved. `smoke_test/rom_256b`
    has a five-way tie at the maximum, so this is not a hypothetical.
    """

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="test-fwc-tie-")
        self.addCleanup(self.tmp.cleanup)
        self.tmp_path = Path(self.tmp.name)

    def build(self, columns, name):
        lines = [".subckt m_rom_base_array bl wl gnd"]
        for col in columns:
            lines.append(
                "Xbit_r0_c%d n%d bl wl gnd m_rom_base_one_cell" % (col, col))
        lines.append(".ends")
        p = self.tmp_path / name
        p.write_text("\n".join(lines) + "\n")
        return p

    def test_file_order_does_not_change_the_answer(self):
        forward = self.build([0, 1, 2, 3], "fwd.sp")
        reverse = self.build([3, 2, 1, 0], "rev.sp")
        a = find_worst_column.analyse(str(forward))
        b = find_worst_column.analyse(str(reverse))
        self.assertEqual(a, b)
        self.assertEqual(a[2], 0, "worst column must be the lowest tied index")
        self.assertEqual(a[6], 0, "best column must be the lowest tied index")

    def test_rom_256b_five_way_tie_is_stable(self):
        """The real netlist that exercises this. 167/181/240/247/248 all
        carry 9 one_cells; the answer must be 167 every time."""
        sp = ROOT / "smoke_test" / "rom_256b" / "rom_256b.sp"
        if not sp.exists():
            self.skipTest("smoke_test/rom_256b/rom_256b.sp not found")
        res = find_worst_column.analyse(str(sp))
        self.assertEqual(res[2], 167)
        self.assertEqual(res[3], 9)
        self.assertEqual(res[6], 31)


class TestRealMacroRegression(unittest.TestCase):
    """Every example macro's answer, pinned.

    These seven numbers per macro are the entire geometric input to the
    flow. A parser change that moves any of them silently re-characterizes
    the macro, so they are asserted rather than recomputed.
    """

    EXPECTED = {
        "examples/wrom0/wrom0.sp": (134, 256, 236, 82, 48, 10),
        "examples/wrom1/wrom1.sp": (134, 256, 214, 88, 52, 50),
        "examples/wrom2/wrom2.sp": (134, 256, 236, 91, 46, 79),
        "examples/wrom3/wrom3.sp": (134, 256, 10, 77, 43, 81),
        "smoke_test/rom_256b/rom_256b.sp": (9, 256, 167, 9, 2, 31),
    }

    def test_every_example_macro(self):
        checked = 0
        for rel, exp in sorted(self.EXPECTED.items()):
            path = ROOT / rel
            if not path.exists():
                continue
            with self.subTest(macro=rel):
                rows, cols, worst, chain, _avg, mn, best = \
                    find_worst_column.analyse(str(path))
                self.assertEqual((rows, cols, worst, chain, mn, best), exp)
                checked += 1
        if checked == 0:
            self.skipTest("no example macros in this checkout")

    def test_row_zero_counts_agrees_with_the_column_scan(self):
        """Both scans walk the same array, so their totals must match:
        every cell is either a one_cell or a zero_cell."""
        path = ROOT / "smoke_test" / "rom_256b" / "rom_256b.sp"
        if not path.exists():
            self.skipTest("smoke_test/rom_256b/rom_256b.sp not found")
        rows, cols, zero_by_row = find_worst_column.row_zero_counts(str(path))
        a_rows, a_cols, _w, _c, avg, _mn, _b = \
            find_worst_column.analyse(str(path))
        self.assertEqual((rows, cols), (a_rows, a_cols))
        total_cells = rows * cols
        total_one = avg * cols
        self.assertEqual(sum(zero_by_row.values()) + round(total_one),
                         total_cells)


if __name__ == "__main__":
    unittest.main()
