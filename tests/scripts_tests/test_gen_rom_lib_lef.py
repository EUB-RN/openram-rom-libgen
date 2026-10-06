#!/usr/bin/env python3
"""LEF edge cases for gen_rom_lib.py.

WHY THIS FILE EXISTS
--------------------
The LEF is the only description of the macro's PINS the .lib generator has.
Every defect below produced a complete, well-formed Liberty file, and all but
one of them was accepted by `check_lib`, by `test_rom_lib` and by OpenSTA --
because the output is perfectly valid Liberty for a macro that does not exist.

  * a PIN with no DIRECTION defaulted to "input", so a `dout0` whose LEF left
    the line out became an INPUT: the cell was left with no output bus at all
    and every timing arc on the data vanished;
  * a bus with a gap (`dout0[0] [1] [3]`) was written as `dout0[2:0]` --
    one real pin dropped, one invented;
  * a bus starting above zero (`addr0[4:1]`) was written with the pin slice
    `[4:1]` under a type declaring `bit_from 3 / bit_to 0`;
  * a LEF with no `clk0` still got a `pin(clk0)`, because the generator writes
    one unconditionally -- every arc it emits is related to it;
  * `SIZE 0 BY 0` became `area : 0.0000`.

Each is now rejected at the source. The matching Liberty-side rules live in
`tests/lib_tests/fixtures/broken_bit_*`, `broken_bus_slice_range.lib` and
`broken_zero_area.lib`, so a .lib that arrives from anywhere else is caught
too.
"""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "rom_char" / "gen_rom_lib.py"


def lef(pins, name="probe", size="100 BY 100"):
    out = ["VERSION 5.4 ;", 'BUSBITCHARS "[]" ;', "MACRO %s" % name,
           "   CLASS BLOCK ;", "   SIZE %s ;" % size]
    for pname, direction in pins:
        out.append("   PIN %s" % pname)
        if direction:
            out.append("      DIRECTION %s ;" % direction)
        out += ["      PORT", "         LAYER met3 ;",
                "         RECT 0 0 1 1 ;", "      END", "   END %s" % pname]
    out += ["END %s" % name, "END LIBRARY"]
    return "\n".join(out) + "\n"


GOOD_PINS = ([("clk0", "INPUT"), ("cs0", "INPUT")]
             + [("addr0[%d]" % i, "INPUT") for i in range(4)]
             + [("dout0[%d]" % i, "OUTPUT") for i in range(4)])


class GenRomLibLefEdges(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="gen-rom-lib-lef-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def run_gen(self, text, outdir="out"):
        path = self.root / "probe.lef"
        path.write_text(text)
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--lef", str(path),
             "--corner", "TT_1p8V_25C", "--outdir", str(self.root / outdir)],
            capture_output=True, text=True, timeout=60)

    def assert_rejected(self, result, needle):
        self.assertNotEqual(result.returncode, 0,
                            "accepted a LEF it should have rejected:\n"
                            + result.stdout)
        self.assertNotIn("Traceback", result.stderr)
        self.assertIn(needle, result.stdout + result.stderr)

    # ------------------------------------------------------------- baseline
    def test_a_well_formed_lef_is_accepted(self):
        """The guard rails must not reject the shape they exist to protect."""
        result = self.run_gen(lef(GOOD_PINS))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("written", result.stdout)

    def test_the_outdir_is_created(self):
        """A missing --outdir used to be a FileNotFoundError traceback after
        the whole library had already been built."""
        result = self.run_gen(lef(GOOD_PINS), outdir="nested/deeper/out")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.root / "nested" / "deeper" / "out"
                         / "probe_TT_1p8V_25C.lib").exists())

    def test_every_example_lef_is_still_accepted(self):
        """The real inputs, through the real entry point."""
        lefs = sorted(ROOT.glob("examples/*/*.lef")) + \
            sorted(ROOT.glob("user/*/*.lef")) + \
            sorted(ROOT.glob("smoke_test/*/*.lef"))
        if not lefs:
            self.skipTest("no macro LEFs in this checkout")
        for path in lefs:
            with self.subTest(lef=path.name):
                result = subprocess.run(
                    [sys.executable, str(SCRIPT), "--lef", str(path),
                     "--corner", "TT_1p8V_25C",
                     "--outdir", str(self.root / "real")],
                    capture_output=True, text=True, timeout=60)
                self.assertEqual(result.returncode, 0, result.stderr)

    # ---------------------------------------------------------------- pins
    def test_pin_without_a_direction_is_rejected(self):
        pins = [p for p in GOOD_PINS if not p[0].startswith("dout0")]
        pins += [("dout0[%d]" % i, None) for i in range(4)]
        self.assert_rejected(self.run_gen(lef(pins)), "no DIRECTION")

    def test_missing_clock_pin_is_rejected(self):
        pins = [p for p in GOOD_PINS if p[0] != "clk0"]
        self.assert_rejected(self.run_gen(lef(pins)), "no PIN clk0")

    def test_missing_output_bus_is_rejected(self):
        pins = [p for p in GOOD_PINS if not p[0].startswith("dout0")]
        self.assert_rejected(self.run_gen(lef(pins)), "no output bus")

    # ---------------------------------------------------------------- buses
    def test_bus_with_a_gap_is_rejected(self):
        pins = [p for p in GOOD_PINS if not p[0].startswith("dout0")]
        pins += [("dout0[%d]" % i, "OUTPUT") for i in (0, 1, 3)]
        result = self.run_gen(lef(pins))
        self.assert_rejected(result, "missing [2]")

    def test_bus_not_starting_at_zero_is_rejected(self):
        pins = [p for p in GOOD_PINS if not p[0].startswith("addr0")]
        pins += [("addr0[%d]" % i, "INPUT") for i in range(1, 5)]
        result = self.run_gen(lef(pins))
        self.assert_rejected(result, "expected the dense range [3:0]")

    def test_a_gap_at_the_top_of_the_bus_is_rejected(self):
        """The quietest variant: indices 0,1,2,4 give the right pin slice
        [4:0] for the wrong width, which no downstream check can see as
        anything but an ordinary five-bit bus missing one arc."""
        pins = [p for p in GOOD_PINS if not p[0].startswith("dout0")]
        pins += [("dout0[%d]" % i, "OUTPUT") for i in (0, 1, 2, 4)]
        self.assert_rejected(self.run_gen(lef(pins)), "missing [3]")

    # ----------------------------------------------------------------- size
    def test_zero_area_is_rejected(self):
        self.assert_rejected(self.run_gen(lef(GOOD_PINS, size="0 BY 0")),
                             "zero area")

    def test_missing_size_is_rejected(self):
        text = lef(GOOD_PINS).replace("   SIZE 100 BY 100 ;\n", "")
        self.assert_rejected(self.run_gen(text), "no SIZE found")

    def test_missing_macro_header_is_rejected(self):
        text = lef(GOOD_PINS).replace("MACRO probe\n", "")
        self.assert_rejected(self.run_gen(text), "no MACRO found")


if __name__ == "__main__":
    unittest.main()
