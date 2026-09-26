#!/usr/bin/env python3
"""Unified CLI Orchestrator for openram-rom-libgen.

Runs the characterization flow needed for a complete .lib and .v in one command:
  1. Pre-flight verification (netlist, LEF, sub-circuit integrity)
  2. SPICE simulations (column timing, back-end delay, periphery power/leakage, pin cap)
  3. Liberty (.lib) generation for TT, SS, FF corners from measured logs
  4. Behavioural Verilog (.v) generation with measured timing
  5. Comprehensive test validation (check_lib, test_rom_lib, test_verilog_model)

THE TWO MODES
-------------
No script in this repository is meant to be run by hand: every number that
reaches a .lib comes out of a log this orchestrator produced. What differs
between the two modes is how many of them it produces.

STANDARD (the default). Every .lib term is measured except two, and each of
those two falls back to a value that is pessimistic rather than wrong:

    the address hold         ships as hold = access, 5-12% longer than the
                             measured requirement -- a constraint that is too
                             long fails a design that would have worked; it
                             never passes one that would not
    the index_1 (clk0 slew)  ships as a flat axis, because the front-end term
    axis                     is the only one that can see the clk0 edge and it
                             moves `access` by 0.24% over a 10x change in slew

FULL (--full). The same run plus the four stages that close those two, so
nothing in the .lib is a fallback:

    run_wl_slew.sh        the real wordline edge the hold deck cuts with
    run_hold_bisect.sh    the address hold itself, bisected
    run_addr2wl.sh        carries that hold into the clk0 pin's time frame
    run_slew_sweep.sh     the measured index_1 axis

It costs roughly an afternoon per macro against tens of minutes, which is the
whole reason there are two modes rather than one.

run_early_path.sh runs in BOTH modes. Its output (retain_rise/retain_fall, the
earliest dout0 can move) has no pessimistic fallback: without it those arcs
are simply ABSENT, and a hold check against the capture flop then has nothing
to fail on. A missing constraint is not a conservative one, so it is not a
mode.

USAGE
-----
    ./flow.py wrom1                    # Standard flow for wrom1
    ./flow.py wrom1 --full             # ... plus hold, wordline slew and the slew axis
    ./flow.py --all                    # Standard flow for every macro
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
    # stderr is unbuffered, stdout is BLOCK-buffered as soon as it is not a
    # terminal. Without this flush the error lines overtake everything printed
    # before them, so `./flow.py ... > log 2>&1` put "ngspice MISSING" at the
    # top of the file, detached from the table it belongs to and above the
    # banner. Looks fine on a terminal, where both are line-buffered, and
    # wrong in every log anyone would send you.
    sys.stdout.flush()
    print(f"  {Colors.RED}✗ {msg}{Colors.RESET}", file=sys.stderr)
    sys.stderr.flush()


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


def check_environment(env: dict, need_magic: bool = False) -> bool:
    """Report every external tool and the PDK, found or missing, in one pass.

    WHY THIS EXISTS. Someone who has just cloned this has five things to get
    right -- four binaries and a sky130 PDK -- and before this they found out
    one at a time, each as a failure some minutes into a run: ngspice missing
    ended the flow immediately, a missing PDK only warned and then every deck
    died on a model it could not load, and Magic and iverilog were not checked
    at all, so their absence surfaced as a dead extraction or a silently
    skipped test layer. One table, before anything is launched, says what is
    there, what is not, and what to do about each -- and it distinguishes what
    STOPS the flow from what merely narrows it.
    """
    def which(var, exe):
        return env.get(var) or shutil.which(exe)

    ng = which("NGSPICE_BIN", "ngspice")
    magic = which("MAGIC_BIN", "magic")
    iv = which("IVERILOG_BIN", "iverilog")
    vvp = which("VVP_BIN", "vvp")
    pdk_lib = rom_paths.sky130_lib()
    pdk = os.path.exists(pdk_lib)

    print(f"\n  {'tool':10} {'status':8} {'what it is for'}")
    rows = [
        ("python3", sys.executable, "the generators", True),
        ("ngspice", ng, "every measurement", True),
        ("sky130", pdk_lib if pdk else None, "the transistor models", True),
        ("magic", magic, "parasitic extraction (--with-extract)", need_magic),
        ("iverilog", iv and vvp, "simulates the generated .v in the testsuite", False),
    ]
    fatal = []
    for name, found, why, required in rows:
        if found:
            log_ok(f"{name:10} {why}")
        elif required:
            log_err(f"{name:10} MISSING -- {why}")
            fatal.append(name)
        else:
            log_warn(f"{name:10} not found -- {why} (that part is skipped)")

    if not fatal:
        return True

    print()
    log_err("Cannot run the simulation flow. Missing: " + ", ".join(fatal))
    if "sky130" in fatal:
        log_err(f"  sky130   : looked for {pdk_lib}")
        log_err("             export PDK_ROOT=<dir containing sky130A/>, or")
        log_err("             export SKY130_LIB=<path to sky130.lib.spice>")
    for n in ("ngspice", "magic"):
        if n in fatal:
            log_err(f"  {n:9}: install it, or set {n.upper()}_BIN to its path")
    log_err("  --from-logs rebuilds the .lib and .v from existing logs and")
    log_err("             needs none of the above.")
    return False


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
        "--full",
        action="store_true",
        help="Full characterisation: also measure the address hold (wordline slew, "
             "bisect, clk0 frame conversion) and the index_1 clk0-slew axis, so no "
             ".lib term is left on a fallback. Costs roughly an afternoon per macro.",
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

    # --full names extra SIMULATIONS, and both of these modes skip the
    # simulation step outright. Saying so beats letting the flag look honoured.
    if args.full and (args.from_logs or args.check_only):
        other = "--from-logs" if args.from_logs else "--check-only"
        log_warn(f"--full has no effect with {other}: no simulation runs. "
                 f"The .lib is built from whatever logs are on disk, and "
                 f"regen_rom_libs.sh names every term it had to fall back on.")

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
    elif args.full:
        mode = "Full characterisation (hold and slew axis measured, no fallbacks)"
    else:
        mode = "Standard (hold and slew axis on their pessimistic fallbacks)"

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
        # --check-only is what someone runs FIRST, before committing hours to
        # a flow, so it answers both halves of "can this run here": the macro
        # (above) and the machine (below). It exits non-zero when the machine
        # cannot, which makes it usable as a gate in a script.
        env_ok = check_environment(env, need_magic=args.with_extract)
        if not env_ok:
            sys.exit(1)
        print(f"\n{Colors.BOLD}{Colors.GREEN}All pre-flight checks passed successfully!{Colors.RESET}")
        return

    # Check simulator requirements if full simulation is requested
    if not args.from_logs:
        # Decided BEFORE the environment check, because it is what makes Magic
        # required or merely nice to have.
        missing_cap = [m for m in target_macros
                       if not os.path.exists(rom_paths.cap_netlist(m, args.macros_dir))]

        if not check_environment(env, need_magic=args.with_extract or bool(missing_cap)):
            sys.exit(1)

        # Step 2: SPICE Simulations
        log_step(current_step, total_steps, "Running SPICE characterization simulations")
        current_step += 1

        # EXTRACTION IS NOT OPTIONAL WHEN ITS OUTPUT IS MISSING.
        #
        # run_col_timing.sh and everything after it read
        # <macro>_cap_only.spice. --with-extract exists so a macro that
        # already has one does not pay for Magic again -- but when the file is
        # absent the flow cannot run at all, and making the user remember a
        # flag for that turned into a failure some minutes in, on the first
        # macro anyone brings. So: if it is missing, extract. If it is missing
        # and there is no GDS to extract from, say so now rather than later.
        do_extract = args.with_extract or bool(missing_cap)

        if missing_cap and not args.with_extract:
            no_gds = [m for m in missing_cap
                      if not os.path.exists(os.path.join(
                          rom_paths.split_macro(m, args.macros_dir)[1], m + ".gds"))]
            if no_gds:
                log_err("No parasitic netlist and no GDS to extract one from: "
                        + ", ".join(no_gds))
                log_err("  <macro>_cap_only.spice is what every deck is built on.")
                log_err("  Add <macro>.gds to the macro directory, or copy an")
                log_err("  existing <macro>_cap_only.spice in beside the netlist.")
                sys.exit(1)
            log_warn("No <macro>_cap_only.spice for: " + ", ".join(missing_cap))
            log_warn("Running the Magic extraction first -- it is slow, and "
                     "every later deck needs it.")

        sim_scripts = []
        if do_extract:
            sim_scripts.append(("Parasitic C extraction (Magic)", "run_cap_extract.sh"))

        # Both modes. run_early_path.sh sits next to run_col_timing.sh because
        # it is the same deck on the other column -- worst for the late arcs,
        # best for the early ones -- and shares its <macro>_cap_only.spice
        # prerequisite. It is not optional: without its logs the .lib carries
        # no retain_rise/retain_fall at all, and an absent arc has no
        # pessimistic reading the way a too-long hold does.
        sim_scripts.extend([
            ("Worst-case column timing (t_dis, t_pre)", "run_col_timing.sh"),
            ("Best-case column timing (retain_*, the early path)", "run_early_path.sh"),
            ("Back-end delay & slew vs output load", "run_backend_delay.sh"),
            ("Periphery active/idle energy & gate capacitance", "run_periphery_power.sh"),
            ("Address setup time", "run_addr_setup.sh"),
            ("Column leakage power", "run_col_power.sh"),
            ("Column energy per cycle", "run_col_energy.sh"),
            ("Periphery leakage power (gmin-swept)", "run_periphery_leak.sh"),
            ("Column decoder delay race", "run_coldec_delay.sh"),
            ("Input pin capacitances", "run_pin_cap.sh"),
        ])

        # --full only, and appended in dependency order rather than in the
        # order they are described anywhere:
        #   run_wl_slew, run_addr2wl and run_slew_sweep each read
        #   cellgate_<corner>.log, which run_periphery_power.sh above writes;
        #   run_hold_bisect reads wlslew_<corner>.log from run_wl_slew, and
        #   without it cuts the chain with an ideal step instead of the edge
        #   the macro really produces -- a pessimistic hold, i.e. the very
        #   fallback this mode exists to retire.
        if args.full:
            sim_scripts.extend([
                ("Wordline fall edge (the hold deck's stimulus)", "run_wl_slew.sh"),
                ("Address hold, bisected", "run_hold_bisect.sh"),
                ("addr0 -> wordline, for the clk0 time frame", "run_addr2wl.sh"),
                ("Front-end delay vs clk0 slew (the index_1 axis)", "run_slew_sweep.sh"),
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
    log_step(current_step, total_steps, "Generating behavioural SystemVerilog (.sv) models")
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
