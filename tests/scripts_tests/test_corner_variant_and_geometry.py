#!/usr/bin/env python3
"""Edge cases for make_corner_variant.py, rom_paths.geometry and pin settling.

THE COMMON SHAPE
----------------
Each defect here is a step that reports success while having done less than
it says:

  * make_corner_variant derives the SS and FF column decks by rewriting three
    things in the TT one. `re.sub` returns its input unchanged when nothing
    matches, so a TT deck written even slightly differently (`.param VDD =
    1.8`) produced a deck still carrying the TT supply -- saved under an _ss
    name, while the script printed "VDD=1.6, temp=100C, lib=ss". That corner's
    whole column of the .lib would then come from a TT simulation.
  * rom_paths.geometry divided the .bin size by data_bits//8 without checking
    it: a traceback below 8 bits, and a silently floored word count above it.
  * pincap_settle_step printed the same "CONVERGED" token when it converged
    and when it merely ran out of iterations, so run_pin_cap.sh reported "all
    pins settled" for a capacitance that had not.
"""

from pathlib import Path
import os
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
CHAR = ROOT / "scripts" / "rom_char"
sys.path.insert(0, str(CHAR))

import rom_paths  # noqa: E402

TT_DECK = """* column deck
.lib /pdk/sky130A/libs.tech/ngspice/sky130.lib.spice tt
.param VDD=1.8
.param TCLK=10n
.tran 1p 100n
.end
"""


class CornerVariant(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="corner-variant-")
        self.addCleanup(self.tmp.cleanup)
        self.tree = Path(self.tmp.name)
        self.mdir = self.tree / "m"
        (self.mdir / "char").mkdir(parents=True)

    def write_deck(self, col, text):
        p = self.mdir / "char" / ("col%d_worst_case_parasitic.sp" % col)
        p.write_text(text)
        return p

    def run_variant(self, col, corner):
        env = dict(os.environ, ROM_MACROS_DIR=str(self.tree),
                   PYTHONDONTWRITEBYTECODE="1")
        return subprocess.run(
            [sys.executable, str(CHAR / "make_corner_variant.py"),
             "m", str(col), corner],
            capture_output=True, text=True, env=env, timeout=60)

    def out_deck(self, col, corner):
        return (self.mdir / "char"
                / ("col%d_worst_case_parasitic_%s.sp" % (col, corner))).read_text()

    def test_a_normal_tt_deck_converts(self):
        self.write_deck(1, TT_DECK)
        for corner, vdd, temp in (("ss", "1.6", "100"), ("ff", "1.95", "-40")):
            with self.subTest(corner=corner):
                r = self.run_variant(1, corner)
                self.assertEqual(r.returncode, 0, r.stderr)
                text = self.out_deck(1, corner)
                self.assertIn("sky130.lib.spice " + corner, text)
                self.assertIn(".param VDD=" + vdd, text)
                self.assertIn(".temp " + temp, text)
                self.assertNotIn("sky130.lib.spice tt", text)
                self.assertNotIn("VDD=1.8", text)

    def test_spaced_supply_is_handled_not_skipped(self):
        """`.param VDD = 1.8` used to leave the deck at the TT supply."""
        self.write_deck(2, TT_DECK.replace(".param VDD=1.8", ".param VDD = 1.8"))
        r = self.run_variant(2, "ss")
        self.assertEqual(r.returncode, 0, r.stderr)
        text = self.out_deck(2, "ss")
        self.assertIn(".param VDD=1.6", text)
        self.assertNotIn("1.8", text)

    def test_a_deck_with_no_supply_parameter_is_refused(self):
        self.write_deck(3, TT_DECK.replace(".param VDD=1.8", ".param SUP=1.8"))
        r = self.run_variant(3, "ss")
        self.assertNotEqual(r.returncode, 0,
                            "wrote an SS deck that still runs at the TT supply")
        self.assertIn("supply voltage", r.stdout + r.stderr)
        self.assertFalse((self.mdir / "char"
                          / "col3_worst_case_parasitic_ss.sp").exists(),
                         "a deck was written despite the refusal")

    def test_a_deck_whose_models_are_not_tt_is_refused(self):
        self.write_deck(4, TT_DECK.replace("sky130.lib.spice tt",
                                           "sky130.lib.spice ss"))
        r = self.run_variant(4, "ss")
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("model-library corner selector", r.stdout + r.stderr)

    def test_tt_is_not_a_target(self):
        self.write_deck(5, TT_DECK)
        r = self.run_variant(5, "tt")
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("unknown corner", r.stdout + r.stderr)
        self.assertNotIn("Traceback", r.stderr)

    def test_a_missing_tt_deck_is_reported_not_raised(self):
        r = self.run_variant(404, "ss")
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("no TT deck", r.stdout + r.stderr)
        self.assertNotIn("Traceback", r.stderr)


class GeometryWordCount(unittest.TestCase):
    """The .bin is byte-packed; the word count must not be guessed."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="geom-words-")
        self.addCleanup(self.tmp.cleanup)
        self.tree = Path(self.tmp.name)

    def build(self, name, data_bits, bin_bytes, rows=2, cols=8):
        mdir = self.tree / name
        (mdir / "rom_configs").mkdir(parents=True)
        lines = [".SUBCKT %s_rom_base_array bl wl gnd" % name]
        for r in range(rows):
            for c in range(cols):
                lines.append("Xbit_r%d_c%d n%d_%d bl wl gnd %s_rom_base_%s_cell"
                             % (r, c, r, c, name, "one" if c % 2 else "zero"))
        lines.append(".ENDS")
        (mdir / (name + ".sp")).write_text("\n".join(lines) + "\n")

        lef = ["MACRO %s" % name, "   SIZE 10 BY 10 ;"]
        for i in range(4):
            lef.append("   PIN addr0[%d]" % i)
        for i in range(data_bits):
            lef.append("   PIN dout0[%d]" % i)
        (mdir / (name + ".lef")).write_text("\n".join(lef) + "\n")
        (mdir / "rom_configs" / (name + ".bin")).write_bytes(b"\x00" * bin_bytes)
        return mdir

    def test_byte_aligned_width_counts_words(self):
        self.build("ok8", data_bits=16, bin_bytes=64)
        g = rom_paths.geometry("ok8", str(self.tree), use_cache=False, quiet=True)
        self.assertEqual(g["data_bits"], 16)
        self.assertEqual(g["words"], 32)

    def test_width_below_one_byte_is_refused_not_a_zero_division(self):
        self.build("narrow", data_bits=4, bin_bytes=16)
        with self.assertRaises(SystemExit) as cm:
            rom_paths.geometry("narrow", str(self.tree), use_cache=False,
                               quiet=True)
        self.assertIn("multiple of 8", str(cm.exception))

    def test_width_that_is_not_a_byte_multiple_is_refused(self):
        """12 bits used to floor to one byte per word and over-count by 4/3."""
        self.build("odd12", data_bits=12, bin_bytes=32)
        with self.assertRaises(SystemExit) as cm:
            rom_paths.geometry("odd12", str(self.tree), use_cache=False,
                               quiet=True)
        self.assertIn("multiple of 8", str(cm.exception))

    def test_a_bin_that_is_not_a_whole_number_of_words_is_refused(self):
        self.build("ragged", data_bits=16, bin_bytes=65)
        with self.assertRaises(SystemExit) as cm:
            rom_paths.geometry("ragged", str(self.tree), use_cache=False,
                               quiet=True)
        self.assertIn("whole number", str(cm.exception))

    def test_every_real_macro_still_resolves(self):
        checked = 0
        for tree in ("examples", "user", "smoke_test"):
            base = ROOT / tree
            if not base.is_dir():
                continue
            for name in rom_paths.discover(str(base)):
                with self.subTest(macro=name):
                    g = rom_paths.geometry(name, str(base), use_cache=False,
                                           quiet=True)
                    self.assertGreater(g["words"], 0)
                    self.assertEqual(g["data_bits"] % 8, 0)
                    checked += 1
        if checked == 0:
            self.skipTest("no macros in this checkout")


class WordsPerRowSource(unittest.TestCase):
    """`row = addr // words_per_row` decides which row each sampled read
    discharges, and the per-row zero_cell count IS the energy model.

    words_per_row used to come only from the OpenRAM config. A macro without
    one reported 0, and gen_random_read_energy fell back to 1 -- so every
    sampled read landed on row == address and the active energy was modelled
    against rows the access never touches. Silently: the number simply came
    out wrong. The array knows the answer (columns / word width), which is
    the same identity geometry() already cross-checks the config against.
    """

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="wpr-")
        self.addCleanup(self.tmp.cleanup)
        self.tree = Path(self.tmp.name)

    def build(self, name, cols=64, data_bits=8, rows=2, config=None):
        mdir = self.tree / name
        (mdir / "rom_configs").mkdir(parents=True)
        lines = [".SUBCKT %s_rom_base_array bl wl gnd" % name]
        for r in range(rows):
            for c in range(cols):
                lines.append("Xbit_r%d_c%d n%d_%d bl wl gnd %s_rom_base_%s_cell"
                             % (r, c, r, c, name, "one" if c % 3 else "zero"))
        lines.append(".ENDS")
        (mdir / (name + ".sp")).write_text("\n".join(lines) + "\n")
        lef = ["MACRO %s" % name, "   SIZE 10 BY 10 ;"]
        lef += ["   PIN addr0[%d]" % i for i in range(4)]
        lef += ["   PIN dout0[%d]" % i for i in range(data_bits)]
        (mdir / (name + ".lef")).write_text("\n".join(lef) + "\n")
        (mdir / "rom_configs" / (name + ".bin")).write_bytes(b"\x00" * 16)
        if config is not None:
            (mdir / "config").mkdir()
            (mdir / "config" / (name + ".py")).write_text(config)
        return mdir

    def test_the_config_still_wins_when_it_exists(self):
        self.build("withcfg", cols=64, data_bits=8,
                   config="word_size = 1\nwords_per_row = 8\n")
        g = rom_paths.geometry("withcfg", str(self.tree), use_cache=False,
                               quiet=True)
        self.assertEqual(g["words_per_row"], 8)
        self.assertEqual(g["words_per_row_source"], "config")

    def test_it_is_derived_from_the_array_without_a_config(self):
        self.build("nocfg", cols=64, data_bits=8)
        g = rom_paths.geometry("nocfg", str(self.tree), use_cache=False,
                               quiet=True)
        self.assertEqual(g["words_per_row"], 8, "64 columns / 8 data bits")
        self.assertEqual(g["words_per_row_source"], "netlist/LEF")

    def test_the_derived_value_matches_the_config_on_every_real_macro(self):
        """The two sources must agree where both exist, or deriving it when
        one is missing would not be sound."""
        checked = 0
        for tree in ("examples", "user", "smoke_test"):
            base = ROOT / tree
            if not base.is_dir():
                continue
            for name in rom_paths.discover(str(base)):
                g = rom_paths.geometry(name, str(base), use_cache=False,
                                       quiet=True)
                if g["words_per_row_source"] != "config" or not g["data_bits"]:
                    continue
                with self.subTest(macro=name):
                    self.assertEqual(g["words_per_row"],
                                     g["cols"] // g["data_bits"])
                    checked += 1
        if checked == 0:
            self.skipTest("no macros with a config in this checkout")

    def test_energy_model_refuses_an_unknown_words_per_row(self):
        src = (CHAR / "gen_random_read_energy.py").read_text()
        self.assertNotIn('geom["words_per_row"] or 1', src,
                         "the energy model still assumes one word per row "
                         "when nothing says otherwise")
        self.assertIn("words_per_row is unknown", src)


class RegenExitStatus(unittest.TestCase):
    """A corner that was skipped must fail the run.

    regen_rom_libs.sh says so itself, at its own exit: "A corner whose logs
    were refused is a failure of the run, not a remark: the .lib for it is
    either absent or left at whatever an earlier run wrote, and both of those
    are wrong to exit 0 on." The provenance refusal set RC; the
    missing-measurement skip, which has the identical consequence, did not.
    """

    def test_the_missing_measurement_skip_sets_rc(self):
        text = (CHAR / "regen_rom_libs.sh").read_text()
        idx = text.index("missing measurement ($missing) -- skipped")
        block = text[idx:idx + 500]
        self.assertIn("RC=1", block,
                      "a corner skipped for a missing measurement still "
                      "exits 0, so a stale .lib from an earlier run ships "
                      "as if it came from this one")
        self.assertIn("EARLIER run", block,
                      "the skip does not warn that output/lib may still hold "
                      "the previous run's file for this corner")


class PinSettlingSignal(unittest.TestCase):
    """Running out of iterations is not converging."""

    def test_the_step_script_distinguishes_the_two_stops(self):
        src = (CHAR / "pincap_settle_step.py").read_text()
        self.assertIn('sys.stdout.write("MAX_ITER\\n")', src,
                      "the iteration cap still reports the same token as a "
                      "real convergence")
        self.assertEqual(src.count('sys.stdout.write("CONVERGED\\n")'), 1,
                         "exactly one path may report CONVERGED: the one "
                         "where nothing is left unsettled")

    def test_the_caller_does_not_call_it_settled(self):
        src = (CHAR / "run_pin_cap.sh").read_text()
        self.assertIn('"$step_out" = "MAX_ITER"', src,
                      "run_pin_cap.sh does not separate the iteration cap "
                      "from convergence, so it reports 'all pins settled' "
                      "for a capacitance that never did")


if __name__ == "__main__":
    unittest.main()
