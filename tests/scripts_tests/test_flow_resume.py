#!/usr/bin/env python3
"""Exercise the CLI with isolated fake stages; never run real characterization."""

import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]


class ResumeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="flow-resume-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        shutil.copy2(REPO / "flow.py", self.root / "flow.py")
        self.scripts = self.root / "scripts" / "rom_char"
        self.scripts.mkdir(parents=True)
        (self.root / "tests").mkdir()
        self.macros = self.root / "macros"
        self.macros.mkdir()
        self.env = os.environ.copy()
        for key in ("ROM_MACROS_DIR", "ROM_OUT_DIR", "ROM_CORNERS", "JOBS",
                    "PIN_GAP_THRESH", "FAIL_STAGE"):
            self.env.pop(key, None)
        self.events = self.root / "events.jsonl"
        self.env.update(ROM_MACROS_DIR=str(self.macros), ROM_OUT_DIR=str(self.root / "output"),
                        EVENTS=str(self.events), PYTHONDONTWRITEBYTECODE="1",
                        NGSPICE_BIN=sys.executable, MAGIC_BIN=sys.executable,
                        IVERILOG_BIN=sys.executable, VVP_BIN=sys.executable)
        self.stub = self.root / "record.py"
        self.stub.write_text('''import json, os, pathlib, sys
name = sys.argv[1]
with open(os.environ["EVENTS"], "a") as f:
    f.write(json.dumps({"stage": name, "args": sys.argv[2:],
                       "gap": os.environ.get("PIN_GAP_THRESH"),
                       "jobs": os.environ.get("JOBS")}) + "\\n")
if os.environ.get("FAIL_STAGE") == name:
    print("injected failure: " + name, file=sys.stderr)
    sys.exit(9)
''')
        self.scripts.joinpath("rom_paths.py").write_text('''import os
from pathlib import Path
ROOT = str(Path(__file__).resolve().parents[2])
def macros_dir(explicit=None): return explicit or os.environ["ROM_MACROS_DIR"]
def out_dir(explicit=None): return explicit or os.environ["ROM_OUT_DIR"]
def split_macro(m, explicit=None):
    p = Path(m)
    return (p.name, str(p.resolve())) if p.is_dir() else (m, str(Path(macros_dir(explicit))/m))
def discover(explicit=None): return sorted(p.name for p in Path(macros_dir(explicit)).iterdir())
def cap_netlist(m, explicit=None): return str(Path(split_macro(m, explicit)[1])/(m+"_cap_only.spice"))
def char_dir(m, create=False): return str(Path(split_macro(m)[1])/"char")
def sky130_lib(): return __file__
if __name__ == "__main__":
    import subprocess, sys
    sys.exit(subprocess.call([sys.executable, str(Path(ROOT)/"record.py"), "preflight"]+sys.argv[1:]))
''')
        for name in ("cap_extract", "col_timing", "early_path", "backend_delay", "periphery_power",
                     "addr_setup", "col_power", "col_energy", "periphery_leak", "coldec_delay",
                     "pin_cap", "wl_slew", "hold_bisect", "addr2wl", "slew_sweep"):
            self.write_shell(self.scripts / f"run_{name}.sh", name.replace("_", "-"))
        self.write_shell(self.scripts / "regen_rom_libs.sh", "lib")
        self.write_shell(self.root / "tests" / "run_tests.sh", "tests")
        self.scripts.joinpath("gen_macro_behavioral_v.py").write_text(
            "import subprocess, sys\nsys.exit(subprocess.call([sys.executable, "
            + repr(str(self.stub)) + ", 'verilog']+sys.argv[1:]))\n")
        self.add_macro("demo")

    def write_shell(self, path, name):
        path.write_text("#!/bin/sh\nexec " + shlex.join([sys.executable, str(self.stub), name])
                        + ' "$@"\n')

    def add_macro(self, name):
        macro = self.macros / name
        (macro / "char").mkdir(parents=True)
        (macro / (name + "_cap_only.spice")).write_text("original extraction\n")
        (macro / (name + ".gds")).write_text("test-only layout placeholder\n")
        for prefix in ("cellgate", "wlslew"):
            for corner in ("tt", "ss", "ff"):
                (macro / "char" / f"{prefix}_{corner}.log").write_text("test input\n")

    def run_flow(self, *args, fail=None):
        env = dict(self.env)
        if fail:
            env["FAIL_STAGE"] = fail
        return subprocess.run([sys.executable, "-B", str(self.root / "flow.py"), *args],
                              cwd=self.root, env=env, capture_output=True, text=True)

    def records(self):
        return [json.loads(s) for s in self.events.read_text().splitlines()] if self.events.exists() else []

    def stages(self):
        return [r["stage"] for r in self.records()]

    def test_failure_then_retry_keeps_earlier_work_and_new_parameters(self):
        result = self.run_flow("demo", "--pin-cap-gap", "1", fail="pin-cap")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.stages()[-1], "pin-cap")
        self.assertNotIn("lib", self.stages())
        self.assertIn("--from-step pin-cap", result.stderr)
        before = len(self.records())
        cap = self.macros / "demo" / "demo_cap_only.spice"
        stamp = cap.stat().st_mtime_ns
        result = self.run_flow("demo", "--from-step", "pin-cap", "--pin-cap-gap", "2", "--jobs", "1")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        retry = self.records()[before:]
        self.assertEqual([r["stage"] for r in retry], ["pin-cap", "lib", "verilog", "tests"])
        self.assertTrue(all(r["gap"] == "2.0" and r["jobs"] == "1" for r in retry))
        self.assertEqual(cap.stat().st_mtime_ns, stamp)

    def test_numeric_phase_two_skips_preflight_and_existing_extraction(self):
        result = self.run_flow("demo", "--from-step", "2")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.stages()[0], "col-timing")
        self.assertNotIn("cap-extract", self.stages())
        self.assertNotIn("preflight", self.stages())
        self.assertEqual(self.stages()[-3:], ["lib", "verilog", "tests"])

    def test_late_restart_needs_no_simulator(self):
        self.env.update(NGSPICE_BIN="", PATH="/nonexistent")
        for step, expected in (("3", ["lib", "verilog", "tests"]),
                               ("4", ["verilog", "tests"]), ("5", ["tests"])):
            with self.subTest(step=step):
                self.events.unlink(missing_ok=True)
                result = self.run_flow("demo", "--from-step", step)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.stages(), expected)

    def test_full_restart_runs_remaining_full_stages(self):
        result = self.run_flow("demo", "--full", "--from-step", "hold-bisect")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.stages(), ["hold-bisect", "addr2wl", "slew-sweep", "lib", "verilog", "tests"])

    def test_rejects_conflicting_or_unknown_start_before_any_stage(self):
        cases = [("--from-step", "bad"), ("--from-step", "0"),
                 ("--from-step", "pin-cap", "--from-logs"),
                 ("--from-step", "2", "--check-only"),
                 ("--from-step", "pin-cap", "--with-extract"),
                 ("--from-step", "4", "--with-extract"),
                 ("--from-step", "hold-bisect")]
        for args in cases:
            with self.subTest(args=args):
                self.assertEqual(self.run_flow("demo", *args).returncode, 2)
                self.assertEqual(self.records(), [])

    def test_missing_extraction_does_not_restart_earlier_work(self):
        (self.macros / "demo" / "demo_cap_only.spice").unlink()
        result = self.run_flow("demo", "--from-step", "pin-cap")
        self.assertEqual(result.returncode, 1)
        self.assertIn("--from-step extract", result.stderr)
        self.assertEqual(self.records(), [])

    def test_missing_cellgate_and_wordline_inputs_fail_early(self):
        for prefix, step, flags in (("cellgate", "pin-cap", []),
                                    ("wlslew", "hold-bisect", ["--full"])):
            with self.subTest(prefix=prefix):
                path = self.macros / "demo" / "char" / f"{prefix}_tt.log"
                path.unlink()
                result = self.run_flow("demo", "--from-step", step, *flags)
                self.assertEqual(result.returncode, 1)
                self.assertIn(str(path), result.stderr)
                self.assertEqual(self.records(), [])
                path.write_text("restored test input\n")

    def test_list_does_not_need_macros_or_tools(self):
        self.env.update(ROM_MACROS_DIR="/nonexistent", PATH="/nonexistent")
        result = self.run_flow("--list-steps")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("pin-cap", result.stdout)
        self.assertIn("requires --full", result.stdout)
        self.assertEqual(self.records(), [])

    def test_existing_modes_and_standard_order(self):
        result = self.run_flow("demo")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.stages(), ["preflight", "col-timing", "early-path", "backend-delay",
            "periphery-power", "addr-setup", "col-power", "col-energy", "periphery-leak",
            "coldec-delay", "pin-cap", "lib", "verilog", "tests"])
        for flag, expected in (("--from-logs", ["preflight", "lib", "verilog", "tests"]),
                               ("--check-only", ["preflight"])):
            self.events.unlink()
            result = self.run_flow("demo", flag)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(self.stages(), expected)

    def test_extraction_runs_once_per_macro(self):
        self.add_macro("second")
        result = self.run_flow("demo", "second", "--from-step", "extract")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([(r["stage"], r["args"]) for r in self.records()[:2]],
                         [("cap-extract", ["demo"]), ("cap-extract", ["second"])])

    def test_late_failure_stops_and_suggests_correct_restart(self):
        for name, step in (("lib", "3"), ("verilog", "4"), ("tests", "5")):
            with self.subTest(name=name):
                self.events.unlink(missing_ok=True)
                result = self.run_flow("demo", "--from-step=3", fail=name)
                self.assertEqual(result.returncode, 1)
                self.assertEqual(self.stages()[-1], name)
                hint = result.stderr.split("continue with: ")[-1].split("\x1b")[0].strip()
                argv = shlex.split(hint)
                self.assertEqual(argv[-2:], ["--from-step", step])
                self.assertEqual(argv.count("--from-step"), 1)
                self.assertNotIn("--from-step=3", argv)

    def test_automatic_extraction_leaves_existing_macro_alone(self):
        self.add_macro("second")
        (self.macros / "second" / "second_cap_only.spice").unlink()
        (self.macros / "demo" / "demo.gds").unlink()
        result = self.run_flow("demo", "second", "--from-step", "2")
        self.assertEqual(result.returncode, 0, result.stderr)
        extraction = [r for r in self.records() if r["stage"] == "cap-extract"]
        self.assertEqual([r["args"] for r in extraction], [["second"]])

    def test_custom_corner_prerequisites(self):
        self.env["ROM_CORNERS"] = "tt:1.8:25:34.1"
        (self.macros / "demo" / "char" / "cellgate_ss.log").unlink()
        result = self.run_flow("demo", "--from-step", "pin-cap")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_retry_command_quotes_paths_and_preserves_options(self):
        self.add_macro("space macro")
        macro_path = str(self.macros / "space macro")
        output_path = str(self.root / "output path")
        result = self.run_flow(macro_path, "--full", "--out-dir", output_path,
                               "--from-step", "pin-cap", "--jobs", "2", fail="pin-cap")
        self.assertEqual(result.returncode, 1)
        hint = result.stderr.split("continue with: ")[-1].split("\x1b")[0].strip()
        argv = shlex.split(hint)
        self.assertIn(macro_path, argv)
        self.assertEqual(argv[argv.index("--out-dir") + 1], output_path)
        self.assertIn("--full", argv)
        self.assertEqual(argv[argv.index("--jobs") + 1], "2")
        retry = subprocess.run(argv, cwd=self.root, env=self.env, capture_output=True, text=True)
        self.assertEqual(retry.returncode, 0, retry.stdout + retry.stderr)


if __name__ == "__main__":
    unittest.main()
