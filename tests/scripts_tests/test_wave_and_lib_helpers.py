#!/usr/bin/env python3
"""Boundary tests for waveform memory conversion and Liberty helpers."""

from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
CHAR = ROOT / "scripts" / "rom_char"
sys.path.insert(0, str(CHAR))

import gen_rom_lib  # noqa: E402
import gen_wave_tb  # noqa: E402


class WaveHelpersTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="wave-helper-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def test_write_mem_honours_endianness_and_depth_limit(self):
        raw = self.root / "rom.bin"
        raw.write_bytes(bytes([0x01, 0x02, 0x03, 0x04, 0x05, 0x06]))
        little = self.root / "little.mem"
        big = self.root / "big.mem"
        self.assertEqual(gen_wave_tb.write_mem(raw, little, 16, 2, "little"), 2)
        self.assertEqual(gen_wave_tb.write_mem(raw, big, 16, 1, "big"), 1)
        self.assertEqual(little.read_text().splitlines()[-2:],
                         ["0000001000000001", "0000010000000011"])
        self.assertEqual(big.read_text().splitlines()[-1], "0000000100000010")

    def test_write_mem_rejects_non_byte_width_and_truncated_word(self):
        raw = self.root / "rom.bin"
        raw.write_bytes(b"\x01\x02\x03")
        with self.assertRaisesRegex(ValueError, "multiple of 8"):
            gen_wave_tb.write_mem(raw, self.root / "bad.mem", 7, 1, "little")
        with self.assertRaisesRegex(ValueError, "whole number of words"):
            gen_wave_tb.write_mem(raw, self.root / "short.mem", 16, 2, "little")

    def test_read_model_reports_all_missing_required_fields(self):
        model = self.root / "demo.sv"
        model.write_text("parameter real ACCESS_NS = 1.0;\n")
        info, missing = gen_wave_tb.read_model(model)
        self.assertIsNone(info)
        self.assertIn("depth", missing)
        self.assertIn("width", missing)
        self.assertIn("addr_bits", missing)
        self.assertNotIn("access", missing)


class LibertyHelpersTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="lib-helper-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def test_parse_lef_preserves_pin_directions_and_area(self):
        lef = self.root / "demo.lef"
        lef.write_text("""
MACRO demo
  SIZE 10.5 BY 2 ;
  PIN addr0[1]
    DIRECTION INPUT ;
  END addr0[1]
  PIN dout0[0]
    DIRECTION OUTPUT ;
  END dout0[0]
  PIN vdd
    DIRECTION INOUT ;
  END vdd
END demo
""")
        name, width, height, pins = gen_rom_lib.parse_lef(lef)
        self.assertEqual(name, "demo")
        self.assertEqual(width * height, 21.0)
        self.assertEqual(pins["addr0[1]"]["direction"], "input")
        self.assertEqual(pins["dout0[0]"]["direction"], "output")
        self.assertEqual(pins["vdd"]["direction"], "inout")

    def test_parse_lef_fails_loudly_without_macro_or_size(self):
        lef = self.root / "bad.lef"
        lef.write_text("SIZE 1 BY 2 ;\n")
        with self.assertRaisesRegex(SystemExit, "no MACRO"):
            gen_rom_lib.parse_lef(lef)
        lef.write_text("MACRO demo\n")
        with self.assertRaisesRegex(SystemExit, "no SIZE"):
            gen_rom_lib.parse_lef(lef)

    def test_group_buses_sorts_indices_and_keeps_scalars(self):
        pins = {"addr0[10]": {"direction": "input"},
                "addr0[2]": {"direction": "input"},
                "addr0[1]": {"direction": "input"},
                "clk0": {"direction": "input"},
                "dout0[0]": {"direction": "output"}}
        buses, scalars = gen_rom_lib.group_buses(pins)
        self.assertEqual(buses["addr0"], {"direction": "input", "bits": [1, 2, 10]})
        self.assertEqual(buses["dout0"], {"direction": "output", "bits": [0]})
        self.assertEqual(scalars, {"clk0": {"direction": "input"}})

    def test_three_requires_exactly_three_values_or_expands_scalar(self):
        self.assertEqual(gen_rom_lib._three("1.0", "--x"), [1.0, 1.0, 1.0])
        self.assertEqual(gen_rom_lib._three("1.0,2.0,3.0", "--x"), [1.0, 2.0, 3.0])
        with self.assertRaisesRegex(SystemExit, "1 or 3"):
            gen_rom_lib._three("1.0,2.0", "--x")

    def test_constraint_block_is_balanced(self):
        rows = [[1.0, 1.0, 1.0]] * 3
        block = gen_rom_lib.constraint_block(rows, rows, 8)
        self.assertEqual(block.count("{"), block.count("}"))
        self.assertEqual(block.count("timing()"), 2)
        for arc in ("setup_rising", "hold_rising"):
            self.assertEqual(block.count("timing_type : " + arc), 1)


if __name__ == "__main__":
    unittest.main()
