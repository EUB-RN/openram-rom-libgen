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


class TestToFloatSpiceSuffixEdges(unittest.TestCase):
    """The SPICE suffix grammar beyond the five suffixes originally handled.

    A netlist that is not OpenRAM's own output -- a user macro in `user/`, a
    hand-written stimulus, a third-party extractor -- is free to use any of
    these. Each case below used to raise, which at least was loud; the two
    that matter are 'meg' and the bare unit letter, because getting them
    wrong silently would be a 1e9 error in a device size.
    """

    def test_meg_is_mega_not_milli(self):
        """'m' is milli and 'meg' is mega. Confusing them is a 1e9 error."""
        self.assertAlmostEqual(to_float("1meg"), 1e6)
        self.assertAlmostEqual(to_float("1MEG"), 1e6)
        self.assertAlmostEqual(to_float("2.5Meg"), 2.5e6)
        self.assertAlmostEqual(to_float("1m"), 1e-3)

    def test_mil_is_thousandth_of_an_inch(self):
        self.assertAlmostEqual(to_float("1mil"), 25.4e-6)
        self.assertAlmostEqual(to_float("2MIL"), 50.8e-6)

    def test_extended_scale_suffixes(self):
        self.assertAlmostEqual(to_float("1a"), 1e-18)
        self.assertAlmostEqual(to_float("3g"), 3e9)
        self.assertAlmostEqual(to_float("1T"), 1e12)

    def test_trailing_unit_name_is_ignored(self):
        """'1.5pF' is 1.5e-12, exactly as SPICE reads it."""
        self.assertAlmostEqual(to_float("1.5pF"), 1.5e-12)
        self.assertAlmostEqual(to_float("2.5V"), 2.5)
        self.assertAlmostEqual(to_float("50ohm"), 50.0)
        self.assertAlmostEqual(to_float("10ns"), 10e-9)
        self.assertAlmostEqual(to_float("2e3Hz"), 2000.0)

    def test_scale_prefix_wins_over_unit_name_on_the_same_letter(self):
        """'1f' is a femto-unit, NOT one farad; '1m' is milli, not one metre.

        Both letters are also unit names. Reading them as units would turn a
        1 fF parasitic into 1 F -- fifteen orders of magnitude, and the
        simulation would still run.
        """
        self.assertAlmostEqual(to_float("1f"), 1e-15)
        self.assertAlmostEqual(to_float("1m"), 1e-3)
        self.assertAlmostEqual(to_float("1.5e-12f"), 1.5e-27)

    def test_unknown_trailing_word_still_raises(self):
        """Tolerating units must not become tolerating typos."""
        for tok in ("1.5pZ", "1e", "10xyz", "5q"):
            with self.assertRaises(ValueError, msg=tok):
                to_float(tok)

    def test_malformed_numbers_raise(self):
        for tok in (".", "+-1", "", "e-9", "1.2.3"):
            with self.assertRaises(ValueError, msg=tok):
                to_float(tok)


class TestFixUnitsCaseEdges(unittest.TestCase):
    """Attribute names must be matched case-insensitively.

    This is the one defect in this module that could not have been caught
    downstream: `W=1E-6` left unscaled is read by ngspice as 1e-6 MICRONS --
    a picometre-wide transistor. The deck simulates, converges, and produces
    a number that goes straight into a .lib.
    """

    def test_uppercase_attributes_are_scaled(self):
        out = fix_units("M1 d g s b nfet W=1E-6 L=0.15E-6")
        self.assertIn("W=1", out)
        self.assertIn("L=0.15", out)
        self.assertNotIn("1E-6", out)

    def test_mixed_case_area_and_perimeter(self):
        out = fix_units("M1 d g s b nfet AD=2e-13 As=2e-13 PD=3e-6 ps=3e-6")
        self.assertIn("AD=0.2u", out)
        self.assertIn("As=0.2u", out)
        self.assertIn("PD=3", out)
        self.assertIn("ps=3", out)

    def test_suffixed_values_are_scaled(self):
        out = fix_units("M1 d g s b nfet w=0.42u l=0.15u")
        self.assertIn("w=0.42", out)
        self.assertIn("l=0.15", out)

    def test_embedded_attribute_names_untouched(self):
        """`nw=` is not `w=`; a word-boundary slip would corrupt the device."""
        line = "X1 a b sub nw=5e-6 sl=1e-6"
        self.assertEqual(fix_units(line), line)


class TestBlocksStructuralDefects(unittest.TestCase):
    """Structural defects must raise, not silently return a smaller netlist.

    Each case below used to parse "successfully" into something that was not
    the file's contents. A generator fed the result would have emitted a deck
    for a circuit that does not exist, and every check after that point --
    Liberty structure, ROM semantics, OpenSTA -- would have passed on it.
    """

    def test_leading_whitespace_is_not_significant(self):
        """An indented netlist used to parse to {} -- no error, no content."""
        text = """
          .subckt foo a b
            M1 a b 0 0 nfet w=1e-6 l=0.15e-6
          +   m=2
          .ends
        """
        got = blocks_from_lines(text.splitlines())
        self.assertEqual(list(got), ["foo"])
        self.assertEqual(len(got["foo"]), 2)
        self.assertIn("m=2", got["foo"][1])

    def test_duplicate_subckt_name_raises(self):
        """Two definitions used to be MERGED into one impossible circuit."""
        text = ".subckt dup a\nR1 a 0 1k\n.ends\n.subckt dup a\nR2 a 0 2k\n.ends\n"
        with self.assertRaises(ValueError) as cm:
            blocks_from_lines(text.splitlines())
        self.assertIn("duplicate", str(cm.exception).lower())
        self.assertIn(":4:", str(cm.exception))

    def test_unnamed_subckt_raises(self):
        """'.subckt' with no name used to swallow its whole body."""
        text = ".subckt good a\nR1 a 0 1k\n.ends\n.subckt\nR2 c d 2k\n.ends\n"
        with self.assertRaises(ValueError) as cm:
            blocks_from_lines(text.splitlines())
        self.assertIn("no name", str(cm.exception))

    def test_nested_subckt_raises(self):
        text = ".subckt outer a\n.subckt inner b\nR1 b 0 1k\n.ends\n.ends\n"
        with self.assertRaises(ValueError) as cm:
            blocks_from_lines(text.splitlines())
        self.assertIn("nested", str(cm.exception).lower())

    def test_orphan_continuation_raises(self):
        text = "+ nothing to continue\n.subckt s1 a\nR1 a 0 1k\n.ends\n"
        with self.assertRaises(ValueError) as cm:
            blocks_from_lines(text.splitlines())
        self.assertIn("continuation", str(cm.exception).lower())

    def test_ends_outside_subckt_raises(self):
        with self.assertRaises(ValueError) as cm:
            blocks_from_lines(["R1 a 0 1k", ".ends"])
        self.assertIn(".ends outside", str(cm.exception))

    def test_unterminated_subckt_raises(self):
        with self.assertRaises(ValueError) as cm:
            blocks_from_lines([".subckt s1 a", "R1 a 0 1k"])
        self.assertIn("never closed", str(cm.exception))

    def test_error_message_names_the_source_and_line(self):
        """A parse failure on a 237k-line extracted netlist is useless
        without a line number."""
        with tempfile.NamedTemporaryFile("w", suffix=".sp", delete=False) as fh:
            fh.write(".subckt a x\n.ends\n.subckt a x\n.ends\n")
            path = fh.name
        try:
            with self.assertRaises(ValueError) as cm:
                blocks(path)
            self.assertIn(path, str(cm.exception))
            self.assertIn(":3:", str(cm.exception))
        finally:
            os.remove(path)

    def test_top_level_cards_outside_any_subckt_are_dropped(self):
        """Documented behaviour: only subcircuits are collected."""
        text = ".include models.sp\n.param vdd=1.8\n.subckt s1 a\nR1 a 0 1k\n.ends\n"
        got = blocks_from_lines(text.splitlines())
        self.assertEqual(list(got), ["s1"])

    def test_real_repository_netlists_still_parse(self):
        """The strictness must not reject what the flow actually consumes.

        Every netlist and extracted parasitic file in the repository goes
        through the parser here, so a future tightening that would have
        broken the real inputs fails in this suite rather than in a run.
        """
        import glob
        files = sorted(
            glob.glob(os.path.join(REPO, "examples", "*", "*.sp"))
            + glob.glob(os.path.join(REPO, "examples", "*", "*.spice"))
            + glob.glob(os.path.join(REPO, "smoke_test", "*", "*.sp"))
            + glob.glob(os.path.join(REPO, "smoke_test", "*", "*.spice"))
        )
        if not files:
            self.skipTest("no example netlists in this checkout")
        for path in files:
            with self.subTest(netlist=os.path.basename(path)):
                got = blocks(path)
                self.assertGreater(len(got), 0, "parsed to nothing")


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
