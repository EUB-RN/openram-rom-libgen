#!/usr/bin/env python3
"""
Unit tests for periph_settle_step.py (adaptive jumping & noise floor logic).
"""

import os
import sys
import unittest
import tempfile
import subprocess
import json
import shutil

HERE = os.path.dirname(os.path.realpath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
CHAR_DIR = os.path.join(REPO, "scripts", "rom_char")
sys.path.insert(0, CHAR_DIR)

from periph_settle_step import evaluate_settling, predict_next_corner_cycles


class TestPeriphSettle(unittest.TestCase):

    def test_cross_corner_ratio_prediction(self):
        """FF=14 and TT=18 predicts an even 24-cycle SS run."""
        self.assertEqual(predict_next_corner_cycles(14, 18), 24)

    def test_cross_corner_prediction_keeps_even_cadence(self):
        self.assertEqual(predict_next_corner_cycles(16, 18), 22)
        self.assertEqual(predict_next_corner_cycles(18, 18), 18)

    def test_cross_corner_prediction_rejects_invalid_history(self):
        with self.assertRaises(ValueError):
            predict_next_corner_cycles(0, 18)

    def test_production_flow_uses_persistent_settling(self):
        """Production must resume one transient and verify its final result.

        The helper checks the completed control run and the final provenance
        verdict. The generator owns stop/resume so the shell must not restore
        the former restart loop.
        """
        production = os.path.join(CHAR_DIR, "run_periphery_power.sh")
        with open(production) as f:
            body = f.read()

        self.assertIn('SETTLE_STEP="$ROM_CHAR_DIR/periph_settle_step.py"', body)
        self.assertGreaterEqual(body.count('python3 "$SETTLE_STEP"'), 2)
        self.assertGreaterEqual(body.count('if [ "$SETTLED" = "1" ]'), 2)
        self.assertIn('PERIPH_NOISE_FLOOR_PJ', body)
        self.assertIn('--settle-max-cycles "$_max_cyc"', body)
        self.assertIn('ss_cycle_prediction', body)
        self.assertIn('PERIPH_PREDICT_MAX_CYCLES', body)
        self.assertIn('PERIPH_\\(SETTLED\\|MAX\\)_CYCLES', body)
        self.assertNotIn('while :; do', body)
        self.assertNotIn('CYCLE_STEP=', body)

    @unittest.skipUnless(shutil.which("ngspice"), "ngspice is not installed")
    def test_ngspice_stop_resume_preserves_transient(self):
        """A batch control block can measure, resume, and emit final metrics."""
        deck = os.path.join(HERE, "fixtures", "ngspice_resume_probe.sp")
        res = subprocess.run(["ngspice", "-b", deck], capture_output=True,
                             text=True, timeout=10)
        output = res.stdout + res.stderr
        self.assertEqual(res.returncode, 0, output)
        self.assertIn("stop  when time = 8e-09", output)
        self.assertIn("stop  when time = 1.2e-08", output)
        self.assertRegex(output, r"(?m)^q_c2\s+=")
        self.assertRegex(output, r"(?m)^q_c3\s+=")
        self.assertRegex(output, r"(?m)^e_periph_pj\s+=")
        self.assertIn("PERIPH_SETTLED_CYCLES=12", output)

    def test_direct_convergence(self):
        """gap <= thresh should converge immediately."""
        # Q2 = -4.57414 pC, Q3 = -4.60657 pC (gap = 0.70%)
        settled, gap, delta_e, next_cyc, reason = evaluate_settling(
            q2=-4.57414e-12,
            q3=-4.60657e-12,
            vdd=1.6,
            current_cycles=8,
            thresh_pct=1.0
        )
        self.assertTrue(settled)
        self.assertAlmostEqual(gap, 0.7040, places=3)
        self.assertEqual(next_cyc, 8)
        self.assertIn("converged", reason)

    def test_noise_floor_convergence(self):
        """When energy difference is below noise floor (e.g. in idle mode), it should converge."""
        # Both Q2 and Q3 are tiny (idle/leakage regime):
        # Q2 = 0.040 pC, Q3 = 0.020 pC.
        # Relative gap = 100%, but delta_E = 0.020 pC * 1.8V = 0.036 pJ (< 0.1 pJ noise floor)
        settled, gap, delta_e, next_cyc, reason = evaluate_settling(
            q2=0.040e-12,
            q3=0.020e-12,
            vdd=1.8,
            current_cycles=8,
            thresh_pct=1.0,
            noise_floor_pj=0.1
        )
        self.assertTrue(settled)
        self.assertAlmostEqual(gap, 100.0, places=1)
        self.assertLess(delta_e, 0.1)
        self.assertIn("noise floor", reason)

    def test_large_gap_dynamic_jump(self):
        """gap >= 50% should jump +8 cycles directly (e.g. 8 -> 16)."""
        settled, gap, delta_e, next_cyc, reason = evaluate_settling(
            q2=-10.0e-12,
            q3=-5.0e-12,
            vdd=1.8,
            current_cycles=8,
            max_cycles=20,
            thresh_pct=1.0
        )
        self.assertFalse(settled)
        self.assertAlmostEqual(gap, 100.0, places=1)
        self.assertEqual(next_cyc, 16)  # 8 + 8 = 16
        self.assertIn("jumping +8 -> 16", reason)

    def test_moderate_gap_dynamic_jump(self):
        """gap between 20% and 50% should jump +6 cycles (e.g. 8 -> 14)."""
        settled, gap, delta_e, next_cyc, reason = evaluate_settling(
            q2=-6.5e-12,
            q3=-5.0e-12,
            vdd=1.8,
            current_cycles=8,
            max_cycles=20,
            thresh_pct=1.0
        )
        self.assertFalse(settled)
        self.assertAlmostEqual(gap, 30.0, places=1)
        self.assertEqual(next_cyc, 14)  # 8 + 6 = 14
        self.assertIn("jumping +6 -> 14", reason)

    def test_small_gap_jump(self):
        """gap between 5% and 20% should jump +4 cycles (e.g. 8 -> 12)."""
        settled, gap, delta_e, next_cyc, reason = evaluate_settling(
            q2=-5.5e-12,
            q3=-5.0e-12,
            vdd=1.8,
            current_cycles=8,
            max_cycles=20,
            thresh_pct=1.0
        )
        self.assertFalse(settled)
        self.assertAlmostEqual(gap, 10.0, places=1)
        self.assertEqual(next_cyc, 12)  # 8 + 4 = 12
        self.assertIn("jumping +4 -> 12", reason)

    def test_fine_tuning_jump(self):
        """gap < 5% should jump +2 cycles for fine-tuning (e.g. 12 -> 14)."""
        settled, gap, delta_e, next_cyc, reason = evaluate_settling(
            q2=-5.15e-12,
            q3=-5.0e-12,
            vdd=1.8,
            current_cycles=12,
            max_cycles=20,
            thresh_pct=1.0,
            noise_floor_pj=0.01  # small noise floor to test fine-tune
        )
        self.assertFalse(settled)
        self.assertAlmostEqual(gap, 3.0, places=1)
        self.assertEqual(next_cyc, 14)  # 12 + 2 = 14
        self.assertIn("jumping +2 -> 14", reason)

    def test_max_cycles_ceiling(self):
        """Should cap at max_cycles and not exceed it."""
        settled, gap, delta_e, next_cyc, reason = evaluate_settling(
            q2=-10.0e-12,
            q3=-5.0e-12,
            vdd=1.8,
            current_cycles=16,
            max_cycles=20,
            thresh_pct=1.0
        )
        self.assertFalse(settled)
        self.assertEqual(next_cyc, 20)  # min(16 + 8, 20) = 20

        # At max cycles:
        settled, gap, delta_e, next_cyc, reason = evaluate_settling(
            q2=-10.0e-12,
            q3=-5.0e-12,
            vdd=1.8,
            current_cycles=20,
            max_cycles=20,
            thresh_pct=1.0
        )
        self.assertFalse(settled)
        self.assertEqual(next_cyc, 20)
        self.assertIn("reached max cycles", reason)

    def test_cli_execution_with_log(self):
        """Test invoking periph_settle_step.py CLI with a simulated log file."""
        script = os.path.join(CHAR_DIR, "periph_settle_step.py")
        log_content = """
Circuit: * test
q_c2                =   -4.57414e-12 from=  1.00000e-06 to=  1.20000e-06
q_c3                =   -4.60657e-12 from=  1.20000e-06 to=  1.40000e-06
e_periph_pj         =  7.37051e+00
"""
        with tempfile.NamedTemporaryFile("w", suffix=".log", delete=False) as tf:
            tf.write(log_content)
            temp_path = tf.name

        try:
            # Test default shell output
            res = subprocess.run([sys.executable, script, temp_path, "--vdd", "1.6", "--thresh", "1.0"],
                                 capture_output=True, text=True)
            self.assertEqual(res.returncode, 0)
            self.assertIn("SETTLED=1", res.stdout)
            self.assertIn("GAP_PCT=0.70", res.stdout)

            # Test JSON output
            res_json = subprocess.run([sys.executable, script, temp_path, "--vdd", "1.6", "--thresh", "1.0", "--json"],
                                      capture_output=True, text=True)
            self.assertEqual(res_json.returncode, 0)
            data = json.loads(res_json.stdout)
            self.assertTrue(data["settled"])
            self.assertAlmostEqual(data["gap_pct"], 0.7040, places=3)
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)


if __name__ == "__main__":
    unittest.main()
