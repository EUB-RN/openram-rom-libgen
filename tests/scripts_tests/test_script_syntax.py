#!/usr/bin/env python3
"""Cheap whole-tree guard: every maintained Python and shell script parses."""

from pathlib import Path
import os
import subprocess
import sys
import unittest


ROOT = Path(__file__).resolve().parents[2]


class ScriptSyntaxTests(unittest.TestCase):
    def test_all_python_scripts_compile_without_writing_bytecode(self):
        scripts = sorted((ROOT / "scripts").rglob("*.py"))
        self.assertTrue(scripts)
        env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
        for script in scripts:
            with self.subTest(script=script.name):
                result = subprocess.run(
                    [sys.executable, "-m", "py_compile", str(script)],
                    capture_output=True, text=True, env=env)
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_all_shell_scripts_pass_bash_syntax_check(self):
        scripts = sorted((ROOT / "scripts").rglob("*.sh"))
        self.assertTrue(scripts)
        for script in scripts:
            with self.subTest(script=script.name):
                result = subprocess.run(
                    ["bash", "-n", str(script)], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
