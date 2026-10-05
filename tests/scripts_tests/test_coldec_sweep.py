#!/usr/bin/env python3
"""The one-transient coldec sweep must stay bounded, one-hot and settled."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
CHAR = ROOT / "scripts" / "rom_char"


class ColdecSweepTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="coldec-sweep-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def base_deck(self):
        lines = [
            ".param VDD=1.8", ".param TCLK=200n",
            "Vaddr0 addr0[0] 0 DC {0}", "Vaddr1 addr0[1] 0 DC {0}",
            "Vaddr2 addr0[2] 0 DC {0}", ".tran '200n/200' '5*TCLK' uic",
        ]
        for select in range(8):
            lines += [
                f".measure tran t_pre2sel{select}_rise TRIG v(pre) VAL='VDD/2' RISE=1 TD=6.9e-7",
                f"+ TARG v(sel{select}) VAL='VDD/2' RISE=1 TD=7.0e-7",
                f".measure tran t_pre2sel{select}_fall TRIG v(pre) VAL='VDD/2' FALL=1 TD=7.9e-7",
                f"+ TARG v(sel{select}) VAL='VDD/2' FALL=1 TD=8.0e-7",
            ]
        lines.append(".end")
        path = self.root / "base.sp"
        path.write_text("\n".join(lines) + "\n")
        return path

    def test_generator_builds_one_bounded_transient(self):
        output = self.root / "sweep.sp"
        result = subprocess.run(
            [sys.executable, str(CHAR / "gen_coldec_sweep_tb.py"),
             str(self.base_deck()), str(output)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        text = output.read_text()
        self.assertEqual(text.count(".tran "), 1)
        self.assertIn("8.000000000000e-06", text)
        self.assertEqual(text.count("_rise_prev TRIG"), 8)
        self.assertEqual(text.count("_rise TRIG"), 8)
        self.assertEqual(text.count(" FIND v(sel"), 64)
        self.assertIn("Vaddr0 addr0[0] 0 PWL(", text)
        self.assertNotIn("t_pre2sel0_rise", text)

    def write_log(self, unsettled=False, not_onehot=False):
        lines = ["Using KLU as Direct Linear Solver"]
        for address in range(8):
            rise = 0.5e-9 + address * 0.01e-9
            previous = rise * (0.98 if unsettled and address == 3 else 0.999)
            lines += [f"a{address}_rise = {rise}",
                      f"a{address}_rise_prev = {previous}",
                      f"a{address}_fall = {rise * 1.2}"]
            for select in range(8):
                high = select == address or (not_onehot and address == 4 and select == 5)
                lines.append(f"a{address}_sel{select} = {1.8 if high else 0.0}")
        path = self.root / "sweep.log"
        path.write_text("\n".join(lines) + "\n")
        return path

    def split(self, log):
        return subprocess.run(
            [sys.executable, str(CHAR / "split_coldec_sweep_log.py"),
             str(log), str(self.root / "out"), "tt", "--vdd", "1.8"],
            capture_output=True, text=True)

    def test_splitter_emits_eight_compatible_logs(self):
        result = self.split(self.write_log())
        self.assertEqual(result.returncode, 0, result.stderr)
        logs = sorted((self.root / "out").glob("coldec_a*_tt.log"))
        self.assertEqual(len(logs), 8)
        self.assertIn("t_pre2sel7_rise =", logs[7].read_text())
        self.assertIn("onehot=yes", result.stdout)

    def test_splitter_rejects_unsettled_or_non_onehot_results(self):
        for kwargs, message in (({"unsettled": True}, "not settled"),
                                ({"not_onehot": True}, "not one-hot")):
            with self.subTest(kwargs=kwargs):
                result = self.split(self.write_log(**kwargs))
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(message, result.stderr)

    def test_splitter_rejects_missing_or_nonpositive_delay_without_traceback(self):
        log = self.write_log()
        text = log.read_text()
        for replacement, message in (("", "missing sweep measurements"),
                                     ("a0_rise = 0", "non-positive delay")):
            with self.subTest(message=message):
                changed = self.root / ("bad-" + message.split()[0] + ".log")
                changed.write_text(text.replace("a0_rise = 5e-10", replacement))
                result = self.split(changed)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(message, result.stderr)
                self.assertNotIn("Traceback", result.stderr)


if __name__ == "__main__":
    unittest.main()
