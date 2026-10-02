#!/usr/bin/env python3
"""Structural tests for the single-parse periphery leakage sweep."""

import os
import unittest


HERE = os.path.dirname(os.path.realpath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
CHAR = os.path.join(REPO, "scripts", "rom_char")


class TestPeripheryLeakPaired(unittest.TestCase):

    def test_generator_changes_cs_and_gmin_in_one_control_block(self):
        path = os.path.join(CHAR, "gen_periphery_leak_tb.py")
        with open(path) as source:
            body = source.read()
        self.assertIn('ap.add_argument("--paired"', body)
        self.assertIn('ap.add_argument("--gmin-factor"', body)
        self.assertIn('"  option gmin=$&g"', body)
        self.assertIn('"  alter Vcs=%s"', body)
        self.assertIn('"  op"', body)
        self.assertIn('LEAK_ITER_BEGIN', body)
        self.assertIn('LEAK_CS_CONVERGED=', body)

    def test_runner_uses_one_ngspice_call_per_corner(self):
        path = os.path.join(CHAR, "run_periphery_leak.sh")
        with open(path) as source:
            body = source.read()
        self.assertIn('--gmin-factor "$GMIN_FACTOR"', body)
        self.assertIn('GMIN_STABLE_ROUNDS', body)
        self.assertEqual(body.count('run_ng "periphery-leak"'), 1)
        self.assertIn('periph_leak_paired_${c}.sp', body)
        self.assertIn('periph_leak_paired_${c}.log', body)
        self.assertIn('prov_write "periphery-leak" "$paired_sp"', body)


if __name__ == "__main__":
    unittest.main()
