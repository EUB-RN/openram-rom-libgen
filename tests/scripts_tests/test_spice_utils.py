#!/usr/bin/env python3
"""Unit tests for scripts/rom_char/spice_utils.py and deck generator parsing.

Validates:
1. to_float(): SI suffix parsing, engineering notation, error handling
2. fix_units(): Regex unit normalization for ngspice (w, l, pd, ps, ad, as)
3. blocks_from_lines() / blocks(): SPICE subcircuit parsing, '+' continuation line
   joining, comment stripping, case-insensitivity
4. CLI / Script body execution test: Proves how top-level deck generation scripts
   can be tested end-to-end via CLI arguments.
"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.realpath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
CHAR_DIR = os.path.join(REPO, "scripts", "rom_char")
sys.path.insert(0, CHAR_DIR)

from spice_utils import blocks, blocks_from_lines, fix_units, to_float  # noqa: E402


class TestToFloat(unittest.TestCase):
    """Test numeric parsing with SPICE / SI suffixes."""

    def test_standard_suffixes(self):
        cases = [
            ("10f", 10e-15),
            ("1.5f", 1.5e-15),
            ("100p", 100e-12),
            ("2.5p", 2.5e-12),
            ("1n", 1e-9),
            ("200n", 200e-9),
            ("0.5n", 0.5e-9),
            ("1u", 1e-6),
            ("20u", 20e-6),
            ("5m", 5e-3),
            ("10k", 10e3),
        ]
        for tok, expected in cases:
            with self.subTest(token=tok):
                self.assertAlmostEqual(to_float(tok), expected, delta=abs(expected * 1e-6))

    def test_case_insensitivity(self):
        self.assertAlmostEqual(to_float("1.8N"), 1.8e-9)
        self.assertAlmostEqual(to_float("100P"), 100e-12)
        self.assertAlmostEqual(to_float("2.5U"), 2.5e-6)

    def test_numbers_without_suffix(self):
        self.assertAlmostEqual(to_float("1.8"), 1.8)
        self.assertAlmostEqual(to_float("0"), 0.0)
        self.assertAlmostEqual(to_float("-0.75"), -0.75)
        self.assertAlmostEqual(to_float("100"), 100.0)

    def test_scientific_notation(self):
        self.assertAlmostEqual(to_float("1e-6"), 1e-6)
        self.assertAlmostEqual(to_float("2.5E-3"), 2.5e-3)
        self.assertAlmostEqual(to_float("-1.2e-4"), -1.2e-4)

    def test_whitespace_tolerance(self):
        self.assertAlmostEqual(to_float("  1.5n  "), 1.5e-9)
        self.assertAlmostEqual(to_float("\t20u\n"), 20e-6)

    def test_invalid_tokens_raise_value_error(self):
        invalid_tokens = ["", "abc", "1.2.3", "10x", "None", "--5n"]
        for tok in invalid_tokens:
            with self.subTest(invalid=tok):
                with self.assertRaises(ValueError):
                    to_float(tok)


class TestFixUnits(unittest.TestCase):
    """Test regex unit normalization for ngspice."""

    def test_single_transistor_line(self):
        # Raw SPICE from Magic: w=0.36u l=0.15u ad=0.108p pd=1.32u as=0.216p ps=2.64u
        raw = "X0 S G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108p pd=1.32u as=0.216p ps=2.64u w=0.36u l=0.15u"
        fixed = fix_units(raw)

        # Expected: w, l, pd, ps scaled by 1e6 (0.36, 0.15, 1.32, 2.64)
        # ad, as scaled by 1e12 with 'u' suffix (0.108u, 0.216u)
        self.assertIn("w=0.36", fixed)
        self.assertIn("l=0.15", fixed)
        self.assertIn("pd=1.32", fixed)
        self.assertIn("ps=2.64", fixed)
        self.assertIn("ad=0.108u", fixed)
        self.assertIn("as=0.216u", fixed)

    def test_non_matching_line_untouched(self):
        line = "C0 net1 net2 0.05763f"
        self.assertEqual(fix_units(line), line)

    def test_word_boundaries_respected(self):
        # Tokens like 'show=10' or 'flow=5' should not match 'w='
        line = "X1 a b show=10 flow=5 w=1u"
        fixed = fix_units(line)
        self.assertIn("show=10", fixed)
        self.assertIn("flow=5", fixed)
        self.assertIn("w=1", fixed)


class TestBlocksParser(unittest.TestCase):
    """Test SPICE subcircuit block extraction and line continuation handling."""

    def test_multiline_continuation_joined(self):
        sample = [
            "* SPICE sample",
            ".subckt rom_precharge_array",
            "+ bl_out_0 bl_out_1",
            "+ bl_out_2 bl_out_3",
            "X0 bl_out_0 vdd sky130_pfet",
            "+ w=0.42u l=0.15u",
            "C0 bl_out_0 gnd 0.5f",
            ".ends",
        ]
        b = blocks_from_lines(sample)
        self.assertIn("rom_precharge_array", b)
        lines = b["rom_precharge_array"]

        # First line is header, continuations joined
        header = lines[0]
        self.assertTrue(header.startswith(".subckt rom_precharge_array"))
        self.assertIn("bl_out_0 bl_out_1 bl_out_2 bl_out_3", header)
        self.assertFalse(any(l.startswith("+") for l in lines))

        # Device line continuations joined
        dev_line = lines[1]
        self.assertTrue(dev_line.startswith("X0 bl_out_0"))
        self.assertIn("w=0.42u l=0.15u", dev_line)

        # Total logical lines: header + X0 + C0 = 3
        self.assertEqual(len(lines), 3)

    def test_comments_and_blank_lines_ignored(self):
        sample = [
            "* Comment at top",
            "",
            "   ",
            ".subckt cell_a in out",
            "* Internal comment",
            "X0 in out gnd sky130_nfet",
            "",
            ".ends",
        ]
        b = blocks_from_lines(sample)
        self.assertIn("cell_a", b)
        self.assertEqual(len(b["cell_a"]), 2)  # header + X0
        for l in b["cell_a"]:
            self.assertFalse(l.startswith("*"))

    def test_multiple_subcircuits(self):
        sample = [
            ".subckt cell_zero a b",
            "X0 a b gnd nfet",
            ".ends",
            ".subckt cell_one a b c",
            "X1 a b c gnd nfet",
            ".ends",
        ]
        b = blocks_from_lines(sample)
        self.assertEqual(list(b.keys()), ["cell_zero", "cell_one"])

    def test_case_insensitivity_subckt_ends(self):
        sample = [
            ".SUBCKT TEST_BLOCK port1 port2",
            "X0 port1 port2 gnd nfet",
            ".ENDS",
        ]
        b = blocks_from_lines(sample)
        self.assertIn("TEST_BLOCK", b)
        self.assertEqual(len(b["TEST_BLOCK"]), 2)

    def test_blocks_from_file_matches_from_lines(self):
        content = (
            ".subckt sample_cell a b\n"
            "+ c d\n"
            "X0 a b c d gnd nfet\n"
            ".ends\n"
        )
        with tempfile.NamedTemporaryFile("w+", suffix=".spice", delete=False) as tmp:
            tmp.write(content)
            tmp_path = tmp.name

        try:
            b_file = blocks(tmp_path)
            b_lines = blocks_from_lines(content.splitlines())
            self.assertEqual(b_file, b_lines)
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)


class TestScriptBodyCliExecution(unittest.TestCase):
    """Demonstrates and verifies testing scripts whose logic lives in the top-level script body.

    Executes gen_periphery_power_tb.py via subprocess with synthetic/controlled
    arguments to verify end-to-end exit status, argument validation, and output.
    """

    def test_gen_periphery_power_help_flag(self):
        script = os.path.join(CHAR_DIR, "gen_periphery_power_tb.py")
        res = subprocess.run([sys.executable, script, "--help"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0)
        self.assertIn("usage: gen_periphery_power_tb.py", res.stdout)
        self.assertIn("--corner", res.stdout)

    def test_gen_periphery_power_missing_args(self):
        script = os.path.join(CHAR_DIR, "gen_periphery_power_tb.py")
        res = subprocess.run([sys.executable, script], capture_output=True, text=True)
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("usage:", res.stderr.lower())

    def test_gen_periphery_power_nonexistent_macro(self):
        script = os.path.join(CHAR_DIR, "gen_periphery_power_tb.py")
        res = subprocess.run(
            [sys.executable, script, "nonexistent_macro_xyz", "0", "/tmp/dummy.sp"],
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(res.returncode, 0)
        self.assertIn("does not exist", res.stderr + res.stdout)


if __name__ == "__main__":
    unittest.main()
