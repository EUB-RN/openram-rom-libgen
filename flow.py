#!/usr/bin/env python3
"""Unified CLI Orchestrator for openram-rom-libgen.

Runs the characterization flow needed for a complete .lib and .v in one command:
  1. Pre-flight verification (netlist, LEF, sub-circuit integrity)
  2. SPICE simulations (column timing, back-end delay, periphery power/leakage, pin cap)
  3. Liberty (.lib) generation for TT, SS, FF corners from measured logs
  4. Behavioural Verilog (.v) generation with measured timing
  5. Comprehensive test validation (check_lib, test_rom_lib, test_verilog_model)

WHAT STEP 2 DOES NOT RUN. The sweep below is the set every .lib term needs.
Four further measurements exist and are deliberately left out of it, because
each costs far more than the rest of the flow put together and each has a
documented pessimistic fallback the generator announces when it fires:

    run_wl_slew.sh + run_hold_bisect.sh   the address hold; without it the
                                          .lib ships hold = access
    run_addr2wl.sh                        converts that hold to the clk0 pin's
                                          time frame
    run_slew_sweep.sh                     the measured index_1 (clk0 slew) axis

So a .lib produced by this script alone is correct and conservative, not
complete. Run those four by hand and re-run with --from-logs to close them;
regen_rom_libs.sh names each one it had to fall back on.

USAGE
-----
    ./flow.py wrom1                    # Run complete flow for wrom1
    ./flow.py --all                    # Run complete flow for all macros
    ./flow.py wrom1 --from-logs        # Build .lib and .v from existing logs (skip SPICE)
    ./flow.py wrom1 --check-only       # Pre-flight sanity checks only
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPTS_DIR = os.path.join(HERE, "scripts", "rom_char")
TESTS_DIR = os.path.join(HERE, "tests")

sys.path.insert(0, SCRIPTS_DIR)
import rom_paths


class Colors:
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    CYAN = "\033[96m"
    BOLD = "\033[1m"
    RESET = "\033[0m"


def log_step(step: int, total: int, title: str):
    print(f"\n{Colors.BOLD}{Colors.CYAN}[{step}/{total}] {title}{Colors.RESET}")


def log_ok(msg: str):
    print(f"  {Colors.GREEN}✓{Colors.RESET} {msg}")


def log_warn(msg: str):
    print(f"  {Colors.YELLOW}⚠{Colors.RESET} {msg}")


def log_err(msg: str):
    print(f"  {Colors.RED}✗ {msg}{Colors.RESET}", file=sys.stderr)


def run_cmd(cmd: list[str], env: dict | None = None, cwd: str = HERE) -> bool:
    """Execute a command, printing output in real-time. Return True on success."""
    p = subprocess.Popen(
        cmd,
        cwd=cwd,
        env=env or os.environ.copy(),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    for line in iter(p.stdout.readline, ""):
        print("  " + line, end="")
    p.stdout.close()
    return p.wait() == 0


def main():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("macros", nargs="*", help="Macro name(s) to characterize (e.g. wrom1)")
    parser.add_argument("--all", action="store_true", help="Process every macro discovered in macro directory")
    parser.add_argument(
        "--from-logs",
        action="store_true",
        help="Skip SPICE simulations and generate deliverables directly from existing characterization logs",
    )
    parser.add_argument(
        "--check-only",
        action="store_true",
        help="Run pre-flight checks and exit",
    )
    parser.add_argument(
        "--with-extract",
        action="store_true",
        help="Also run Magic parasitic C extraction (run_cap_extract.sh; very slow)",
    )
    parser.add_argument(
        "--macros-dir",
        help="Path to macros directory (overrides ROM_MACROS_DIR)",
    )
    parser.add_argument(
        "--out-dir",
        help="Path to output deliverables directory (overrides ROM_OUT_DIR)",
    )
    parser.add_argument(
        "--jobs",
        type=int,
        default=int(os.environ.get("JOBS", 4)),
        help="Parallel simulation jobs for ngspice (default: 4)",
    )

    args = parser.parse_args()

    # Setup environment
    if args.macros_dir:
        os.environ["ROM_MACROS_DIR"] = os.path.abspath(args.macros_dir)
    if args.out_dir:
        os.environ["ROM_OUT_DIR"] = os.path.abspath(args.out_dir)
    os.environ["JOBS"] = str(args.jobs)

    # Resolve macros. Named macros may be given as a bare name or as a path;
    # a path with no --macros-dir sets ROM_MACROS_DIR to its parent, so the
    # run_*.sh called below find the same tree. With no names (--all, or no
    # argument at all) every macro in the tree is processed.
    target_macros = []
    if args.macros:
        for m_arg in args.macros:
            name, md = rom_paths.split_macro(m_arg, args.macros_dir)
            target_macros.append(name)
            if ("/" in m_arg or "\\" in m_arg or os.path.isdir(m_arg)) and not args.macros_dir:
                parent = os.path.dirname(md)
                if parent:
                    os.environ["ROM_MACROS_DIR"] = parent
    else:
        target_macros = rom_paths.discover(args.macros_dir)

    # After the inference above, so a path argument reaches the child scripts.
    env = os.environ.copy()

    if not target_macros:
        log_err("No macros specified or discovered. Put your ROM in "
                "'./user/<macro>/', pass --macros-dir, or name a macro.")
        sys.exit(1)

    if args.check_only:
        mode = "Pre-flight check only"
    elif args.from_logs:
        mode = "Generate from logs"
    else:
        mode = "Full simulation flow"

    print(f"{Colors.BOLD}openram-rom-libgen Flow Orchestrator{Colors.RESET}")
    print(f"Target macros  : {', '.join(target_macros)}")
    print(f"Macro directory: {rom_paths.macros_dir(args.macros_dir)}")
    print(f"Output root    : {rom_paths.out_dir(explicit=args.out_dir)}")
    print(f"Mode           : {mode}")

    total_steps = 1 if args.check_only else (4 if args.from_logs else 5)
    current_step = 1

    # Step 1: Pre-flight checks
    log_step(current_step, total_steps, "Pre-flight checks")
    current_step += 1

    for m in target_macros:
        cmd = [sys.executable, os.path.join(SCRIPTS_DIR, "rom_paths.py"), "--check", m]
        if args.macros_dir:
            cmd += ["--macros-dir", args.macros_dir]
        if not run_cmd(cmd, env=env):
            log_err(f"Pre-flight check failed for macro: {m}")
            sys.exit(1)
        log_ok(f"Pre-flight verified for {m}")

    if args.check_only:
        print(f"\n{Colors.BOLD}{Colors.GREEN}All pre-flight checks passed successfully!{Colors.RESET}")
        return

    # Check simulator requirements if full simulation is requested
    if not args.from_logs:
        ng_bin = env.get("NGSPICE_BIN") or shutil.which("ngspice")
        if not ng_bin:
            log_err("ngspice binary not found ('ngspice').")
            log_err("Install ngspice, set NGSPICE_BIN, or use --from-logs to generate from existing logs.")
            sys.exit(1)

        pdk_lib = rom_paths.sky130_lib()
        if not os.path.exists(pdk_lib):
            log_warn(f"Sky130 model file not found at: {pdk_lib}")
            log_warn("SPICE simulations will fail unless PDK_ROOT or SKY130_LIB is correctly configured.")

        # Step 2: SPICE Simulations
        log_step(current_step, total_steps, "Running SPICE characterization simulations")
        current_step += 1

        sim_scripts = []
        if args.with_extract:
            sim_scripts.append(("Parasitic C extraction (Magic)", "run_cap_extract.sh"))

        sim_scripts.extend([
            ("Worst-case column timing (t_dis, t_pre)", "run_col_timing.sh"),
            ("Back-end delay & slew vs output load", "run_backend_delay.sh"),
            ("Periphery active/idle energy & gate capacitance", "run_periphery_power.sh"),
            ("Address setup time", "run_addr_setup.sh"),
            ("Column leakage power", "run_col_power.sh"),
            ("Column energy per cycle", "run_col_energy.sh"),
            ("Periphery leakage power (gmin-swept)", "run_periphery_leak.sh"),
            ("Column decoder delay race", "run_coldec_delay.sh"),
            ("Input pin capacitances", "run_pin_cap.sh"),
        ])

        for desc, script_name in sim_scripts:
            print(f"\n  {Colors.BOLD}--> {desc} ({script_name}){Colors.RESET}")
            script_path = os.path.join(SCRIPTS_DIR, script_name)
            cmd = ["/bin/sh", script_path] + target_macros
            if not run_cmd(cmd, env=env):
                log_err(f"Simulation failed during: {script_name}")
                sys.exit(1)

    # Step 3: Liberty Generation
    log_step(current_step, total_steps, "Generating Liberty (.lib) files from measurements")
    current_step += 1

    regen_script = os.path.join(SCRIPTS_DIR, "regen_rom_libs.sh")
    cmd = ["/bin/sh", regen_script] + target_macros
    if not run_cmd(cmd, env=env):
        log_err("Liberty (.lib) generation failed.")
        sys.exit(1)
    log_ok("Liberty libraries generated successfully for TT, SS, FF corners.")

    # Step 4: Behavioural Verilog Generation
    log_step(current_step, total_steps, "Generating behavioural Verilog (.v) models")
    current_step += 1

    gen_v_script = os.path.join(SCRIPTS_DIR, "gen_macro_behavioral_v.py")
    cmd = [sys.executable, gen_v_script] + target_macros
    if args.macros_dir:
        cmd += ["--macros-dir", args.macros_dir]
    if args.out_dir:
        cmd += ["--outdir", os.path.join(args.out_dir, "verilog"), "--lib-dir", os.path.join(args.out_dir, "lib")]
    if not run_cmd(cmd, env=env):
        log_err("Behavioural Verilog generation failed.")
        sys.exit(1)
    log_ok("Behavioural Verilog models updated with measured timing.")

    # Step 5: Testsuite Validation
    log_step(current_step, total_steps, "Running verification testsuite")
    current_step += 1

    test_script = os.path.join(TESTS_DIR, "run_tests.sh")
    cmd = ["/bin/sh", test_script]
    if not run_cmd(cmd, env=env):
        log_err("Testsuite verification failed.")
        sys.exit(1)

    print(f"\n{Colors.BOLD}{Colors.GREEN}======================================================{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.GREEN} FLOW COMPLETED SUCCESSFULLY! ALL DELIVERABLES READY. {Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.GREEN}======================================================{Colors.RESET}")
    lib_out = os.path.join(rom_paths.out_dir(), "lib")
    v_out = os.path.join(rom_paths.out_dir(), "verilog")
    print(f"Liberty deliverables : {lib_out}")
    print(f"Verilog deliverables : {v_out}")


if __name__ == "__main__":
    main()
