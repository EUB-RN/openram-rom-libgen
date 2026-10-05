#!/usr/bin/env python3
"""One explicit failure/edge contract for every active characterization script.

The manifest is intentional: adding a new script without assigning it an
edge-case test fails this suite instead of silently reducing coverage.
"""

from pathlib import Path
import os
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
CHAR = ROOT / "scripts" / "rom_char"

# Each active entry point must be named here. More detailed behavior is tested
# in the focused test modules; this file closes the "forgotten script" gap.
EDGE_CASES = {
    "common.sh": "invalid memory budget and missing measurements",
    "find_worst_column.py": "missing netlist and malformed arrays",
    "gen_addr_hold_tb.py": "mutually exclusive experiments and missing deck",
    "gen_backend_delay_tb.py": "missing extracted netlist/waveform",
    "gen_cell_gate_tb.py": "missing extracted netlist",
    "gen_col_power_tb.py": "missing characterized column deck",
    "gen_col_tb_parasitic.py": "missing args, negative synthetic chain, missing extraction",
    "gen_coldec_sweep_tb.py": "malformed base deck and unsupported SPICE suffix",
    "gen_macro_behavioral_v.py": "missing fields and pin-group timing scope",
    "gen_periphery_leak_tb.py": "invalid gmin sweep controls",
    "gen_periphery_power_tb.py": "invalid cycle and persistent-settling combinations",
    "gen_random_read_energy.py": "invalid reads/seed and missing measurements",
    "gen_resistance_model.py": "disconnected/degenerate networks and missing geometry",
    "gen_rom_lib.py": "malformed LEF/table axes/value cardinality",
    "gen_wave_tb.py": "invalid width/depth/endian and truncated binary",
    "make_corner_variant.py": "missing arguments",
    "periph_settle_step.py": "missing, zero, threshold and max-cycle measurements",
    "pincap_settle_step.py": "missing/zero/nonfinite measurements and corrupt state",
    "rom_explore.py": "empty/non-ROM netlist",
    "rom_paths.py": "missing/malformed macro, cache and CLI paths",
    "spice_utils.py": "invalid units and malformed continuation blocks",
    "split_coldec_sweep_log.py": "missing/nonpositive/unsettled/non-one-hot measurements",
    "regen_rom_libs.sh": "empty macro tree",
    "run_addr2wl.sh": "missing macro",
    "run_addr_setup.sh": "missing macro",
    "run_backend_delay.sh": "missing macro",
    "run_cap_extract.sh": "missing macro and extractor",
    "run_col_energy.sh": "missing macro",
    "run_col_power.sh": "missing macro",
    "run_col_timing.sh": "missing macro",
    "run_coldec_delay.sh": "missing macro",
    "run_early_path.sh": "missing macro",
    "run_hold_bisect.sh": "missing macro",
    "run_periphery_leak.sh": "missing macro",
    "run_periphery_power.sh": "missing macro",
    "run_pin_cap.sh": "missing macro",
    "run_slew_sweep.sh": "missing macro",
    "run_wl_slew.sh": "missing macro",
}


class AllEntrypointEdges(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="all-entrypoints-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.macros = self.root / "macros"
        self.macros.mkdir()
        self.out = self.root / "out"
        self.env = dict(os.environ,
                        ROM_MACROS_DIR=str(self.macros),
                        ROM_OUT_DIR=str(self.out),
                        ROM_CORNERS="tt:1.8:25:1",
                        JOBS="1",
                        NGSPICE_BIN="/bin/false",
                        MAGIC_BIN="/bin/false",
                        PYTHONDONTWRITEBYTECODE="1")

    def run_script(self, script, *args):
        path = CHAR / script
        cmd = ([sys.executable, str(path)] if path.suffix == ".py"
               else ["bash", str(path)])
        return subprocess.run(cmd + list(args), capture_output=True, text=True,
                              env=self.env, timeout=10)

    def assert_clean_failure(self, result, message=None):
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("Traceback", result.stderr)
        if message:
            self.assertIn(message, result.stdout + result.stderr)

    def test_manifest_covers_every_active_script(self):
        actual = {p.name for p in CHAR.iterdir()
                  if p.is_file() and p.suffix in (".py", ".sh")}
        self.assertEqual(set(EDGE_CASES), actual,
                         "every new/removed script must update the edge-case manifest")

    def test_python_generators_reject_invalid_inputs_cleanly(self):
        cases = [
            ("gen_addr_hold_tb.py", ("missing", str(self.root / "x.sp"),
                                     "--retention-us", "1", "--sweep-ns", "1,2"),
             "different experiments"),
            ("gen_backend_delay_tb.py", ("missing", "0", str(self.root / "x.sp"),
                                          "--bl-wave", str(self.root / "none"),
                                          "--macros-dir", str(self.macros)), "does not exist"),
            ("gen_cell_gate_tb.py", ("missing", str(self.root / "x.sp"),
                                      "--macros-dir", str(self.macros)), "does not exist"),
            ("gen_col_power_tb.py", ("missing", "0", "idle", str(self.root / "x.sp"),
                                      "--macros-dir", str(self.macros)), "no netlist"),
            ("gen_col_tb_parasitic.py", (), "usage:"),
            ("gen_periphery_leak_tb.py", ("missing", "--gmin-factor", "1"),
             "between 0 and 1"),
            ("gen_periphery_power_tb.py", ("missing", "1", str(self.root / "x.sp"),
                                            "--cycles", "3"), "at least 4"),
            ("make_corner_variant.py", (), "usage:"),
        ]
        for script, args, message in cases:
            with self.subTest(script=script):
                self.assert_clean_failure(self.run_script(script, *args), message)

    def test_column_generator_rejects_negative_synthetic_chain(self):
        result = self.run_script("gen_col_tb_parasitic.py", "missing", "--ones=-1")
        self.assert_clean_failure(result, "cannot be negative")

    def test_periphery_generator_rejects_incompatible_persistent_mode(self):
        result = self.run_script("gen_periphery_power_tb.py", "missing", "1",
                          str(self.root / "x.sp"), "--cycles", "4",
                          "--settle-max-cycles", "6", "--pin-cap")
        self.assert_clean_failure(result, "only supported by the normal")

    def test_rom_explore_rejects_empty_netlist(self):
        md = self.macros / "empty"
        md.mkdir()
        (md / "empty.sp").write_text("")
        result = self.run_script("rom_explore.py", "empty")
        self.assert_clean_failure(result, "no cells found")

    def test_common_helpers_handle_invalid_budget_and_absent_measurement(self):
        command = (
            f'. "{CHAR / "common.sh"}"; '
            'test "$(rom_auto_jobs 0)" -ge 1; '
            f'test -z "$(meas "{self.root / "missing.log"}" nope)"; '
            'if load_geom missing; then exit 9; fi; '
            'echo survived-automatic-skip')
        result = subprocess.run(["bash", "-c", command], capture_output=True,
                                text=True, env=self.env, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("survived-automatic-skip", result.stdout)

    def test_every_run_script_rejects_a_missing_macro(self):
        scripts = sorted(name for name in EDGE_CASES
                         if name.startswith("run_") and name.endswith(".sh"))
        self.assertTrue(scripts)
        for script in scripts:
            with self.subTest(script=script):
                result = self.run_script(script, "missing")
                self.assert_clean_failure(result)
                self.assertRegex(result.stdout + result.stderr,
                                 r"no netlist|no such directory|cannot read geometry")

    def test_regenerator_rejects_empty_macro_tree(self):
        result = self.run_script("regen_rom_libs.sh")
        self.assert_clean_failure(result)


if __name__ == "__main__":
    unittest.main()
