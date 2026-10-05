#!/usr/bin/env python3
"""Edge-case tests for the path and geometry source of truth."""

from contextlib import redirect_stderr
from io import StringIO
from pathlib import Path
from unittest import mock
import json
import os
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
CHAR = ROOT / "scripts" / "rom_char"
sys.path.insert(0, str(CHAR))

import rom_paths  # noqa: E402


ARRAY = """\
.SUBCKT demo_rom_base_array bl_0 bl_1 wl_0 wl_1 gnd
Xbit_r0_c0
+ a b wl_0 gnd demo_rom_base_one_cell
Xbit_r0_c1
+ a b wl_0 gnd demo_rom_base_zero_cell
Xbit_r1_c0
+ a b wl_1 gnd demo_rom_base_one_cell
Xbit_r1_c1
+ a b wl_1 gnd demo_rom_base_one_cell
.ENDS demo_rom_base_array
"""


class RomPathsTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="rom-paths-test-")
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)

    def macro(self, name="demo"):
        md = self.base / name
        md.mkdir(parents=True, exist_ok=True)
        (md / f"{name}.sp").write_text(ARRAY.replace("demo", name))
        return md

    def test_split_macro_accepts_name_directory_netlist_and_trailing_slash(self):
        md = self.macro()
        expected = str(md.resolve())
        self.assertEqual(rom_paths.split_macro("demo", str(self.base)), ("demo", expected))
        self.assertEqual(rom_paths.split_macro(str(md) + "/"), ("demo", expected))
        self.assertEqual(rom_paths.split_macro(str(md / "demo.sp")), ("demo", expected))

    def test_discover_is_sorted_and_requires_matching_netlist_name(self):
        self.macro("zeta")
        self.macro("alpha")
        wrong = self.base / "wrong"
        wrong.mkdir()
        (wrong / "other.sp").write_text(ARRAY)
        (self.base / "plain-file").write_text("not a directory")
        self.assertEqual(rom_paths.discover(str(self.base)), ["alpha", "zeta"])

    def test_macros_dir_precedence_is_explicit_then_environment(self):
        env_dir = self.base / "env"
        explicit = self.base / "explicit"
        with mock.patch.dict(os.environ, {"ROM_MACROS_DIR": str(env_dir)}):
            self.assertEqual(rom_paths.macros_dir(), str(env_dir.resolve()))
            self.assertEqual(rom_paths.macros_dir(str(explicit)), str(explicit.resolve()))

    def test_output_directory_can_be_queried_without_creation(self):
        target = self.base / "does-not-exist"
        result = rom_paths.out_dir("lib", create=False, explicit=str(target))
        self.assertEqual(result, str(target / "lib"))
        self.assertFalse(target.exists())

    def test_geometry_derives_sizes_and_refreshes_corrupt_cache(self):
        md = self.macro()
        (md / "demo.lef").write_text(
            "MACRO demo\nSIZE 1 BY 2 ;\n"
            + "\n".join(f"PIN addr0[{i}]" for i in range(2)) + "\n"
            + "\n".join(f"PIN dout0[{i}]" for i in range(8)) + "\n")
        (md / "demo.py").write_text("word_size = 1\nwords_per_row = 2\n")
        cfg = md / "rom_configs"
        cfg.mkdir()
        (cfg / "demo.bin").write_bytes(b"\x00\x01\x02")

        g = rom_paths.geometry("demo", str(self.base), quiet=True)
        self.assertEqual((g["rows"], g["cols"]), (2, 2))
        self.assertEqual((g["worst_col"], g["best_col"]), (0, 1))
        self.assertEqual((g["addr_bits"], g["data_bits"], g["words"]), (2, 8, 3))

        cache = md / "char" / ".geometry.json"
        cache.write_text("{broken json")
        refreshed = rom_paths.geometry("demo", str(self.base), quiet=True)
        self.assertEqual(refreshed["cols"], 2)
        self.assertEqual(json.loads(cache.read_text())["macro"], "demo")

    def test_geometry_rejects_missing_or_non_rom_netlist(self):
        with self.assertRaisesRegex(SystemExit, "no netlist"):
            rom_paths.geometry("missing", str(self.base))

        md = self.base / "empty"
        md.mkdir()
        (md / "empty.sp").write_text(".subckt unrelated a b\n.ends\n")
        with self.assertRaisesRegex(SystemExit, "no Xbit"):
            rom_paths.geometry("empty", str(self.base), use_cache=False)

    def test_geometry_warns_on_config_mismatch_and_non_power_of_two_wpr(self):
        md = self.macro()
        (md / "demo.py").write_text("word_size = 1\nwords_per_row = 3\n")
        err = StringIO()
        with redirect_stderr(err):
            rom_paths.geometry("demo", str(self.base), use_cache=False)
        self.assertIn("config says", err.getvalue())
        self.assertIn("not a power of two", err.getvalue())

    def test_main_rejects_missing_macros_dir_argument(self):
        # argparse is not used here; a missing value must still be a clean error,
        # not an IndexError traceback.
        err = StringIO()
        with redirect_stderr(err):
            rc = rom_paths.main(["rom_paths.py", "--macros-dir"])
        self.assertEqual(rc, 1)
        self.assertIn("requires a directory", err.getvalue())


if __name__ == "__main__":
    unittest.main()
