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
    ./flow.py --list-steps             # Show restart points without running anything
    ./flow.py wrom1 --from-step 2      # Skip pre-flight; run simulations and later steps
    ./flow.py wrom1 --from-step pin-cap --pin-cap-gap 2
                                      # Retry pin cap with a new parameter, then continue
"""

from __future__ import annotations

import argparse
import os
import shlex
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPTS_DIR = os.path.join(HERE, "scripts", "rom_char")
TESTS_DIR = os.path.join(HERE, "tests")

sys.path.insert(0, SCRIPTS_DIR)
import rom_paths


# Stable names for restarting within the simulation phase (step 2).
SIMULATION_STEPS = [
    ("extract", "Parasitic C extraction (Magic)", "run_cap_extract.sh"),
    ("col-timing", "Worst-case column timing (t_dis, t_pre)", "run_col_timing.sh"),
    ("early-path", "Best-case column timing (retain_*, the early path)", "run_early_path.sh"),
    ("backend-delay", "Back-end delay & slew vs output load", "run_backend_delay.sh"),
    ("periphery-power", "Periphery active/idle energy & gate capacitance", "run_periphery_power.sh"),
    ("addr-setup", "Address setup time", "run_addr_setup.sh"),
    ("col-power", "Column leakage power", "run_col_power.sh"),
    ("col-energy", "Column energy per cycle", "run_col_energy.sh"),
    ("periphery-leak", "Periphery leakage power (gmin-swept)", "run_periphery_leak.sh"),
    ("coldec-delay", "Column decoder delay race", "run_coldec_delay.sh"),
    ("pin-cap", "Input pin capacitances (iterative settling)", "run_pin_cap.sh"),
    ("wl-slew", "Wordline fall edge (the hold deck's stimulus)", "run_wl_slew.sh"),
    ("hold-bisect", "Address hold, bisected", "run_hold_bisect.sh"),
    ("addr2wl", "addr0 -> wordline, for the clk0 time frame", "run_addr2wl.sh"),
    ("slew-sweep", "Front-end delay vs clk0 slew (the index_1 axis)", "run_slew_sweep.sh"),
]
FULL_STEPS = {"wl-slew", "hold-bisect", "addr2wl", "slew-sweep"}
STEP_CHOICES = ["1", "2", "3", "4", "5"] + [s[0] for s in SIMULATION_STEPS]
DEFAULT_CORNERS = "tt:1.8:25:34.1 ss:1.6:100:18.3 ff:1.95:-40:48.2"


def list_steps():
    print("1  Pre-flight checks")
    print("2  SPICE simulations (extraction only if needed or --with-extract)")
    for name, description, _ in SIMULATION_STEPS:
        suffix = " [requires --full]" if name in FULL_STEPS else ""
        print(f"   {name:16} {description}{suffix}")
    print("3  Liberty generation from existing measurement logs")
    print("4  Behavioural SystemVerilog generation from existing Liberty files")
    print("5  Verification testsuite")
    print("--from-step reruns the selected step and every subsequent step.")


def resume_command(step):
    """Keep the user's arguments, replacing the previous starting point."""
    argv = iter(sys.argv[1:])
    keep = []
    for arg in argv:
        if arg == "--from-step":
            next(argv, None)
        elif arg.startswith("--from-step=") or arg in {
            "--from-logs", "--check-only", "--with-extract", "--list-steps"
        }:
            continue
        else:
            keep.append(arg)
    return shlex.join([sys.executable, os.path.abspath(__file__), *keep,
                       "--from-step", step])


def run_step(cmd, env, step, failure):
    """Stop at the failing stage and show a command that retries that stage."""
    if not run_cmd(cmd, env=env):
        log_err(failure)
        log_err("After fixing the problem, continue with: " + resume_command(step))
        sys.exit(1)


def check_resume_inputs(sim_start, macros, env):
    """Catch missing upstream inputs that measurement scripts otherwise skip."""
    names = [step[0] for step in SIMULATION_STEPS]
    if not sim_start:
        return
    required = []
    if names.index(sim_start) > names.index("periphery-power"):
        required.append(("cellgate", "periphery-power"))
    if sim_start == "hold-bisect":
        required.append(("wlslew", "wl-slew"))
    corners = [entry.split(":")[0] for entry in env.get("ROM_CORNERS", DEFAULT_CORNERS).split()]
    missing = False
    for macro in macros:
        char_dir = rom_paths.char_dir(macro, create=False)
        for prefix, producer in required:
            for corner in corners:
                path = os.path.join(char_dir, f"{prefix}_{corner}.log")
                if not os.path.isfile(path) or os.path.getsize(path) == 0:
                    log_err(f"Missing resume input: {path}; restart from {producer}.")
                    missing = True
    if missing:
        sys.exit(1)


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
        allow_abbrev=False,
    )
    parser.add_argument("macros", nargs="*", help="Macro name(s) to characterize (e.g. wrom1)")
    parser.add_argument("--all", action="store_true", help="Process every macro discovered in macro directory")
    start_options = parser.add_mutually_exclusive_group()
    start_options.add_argument(
        "--from-logs",
        action="store_true",
        help="Skip SPICE simulations and generate deliverables directly from existing characterization logs",
    )
    start_options.add_argument(
        "--check-only",
        action="store_true",
        help="Run pre-flight checks and exit",
    )
    start_options.add_argument(
        "--from-step", choices=STEP_CHOICES,
        help="Rerun this step and all later steps; earlier outputs must already exist. "
             "Use 1-5 for main phases or a simulation name (see --list-steps).",
    )
    start_options.add_argument(
        "--list-steps", action="store_true",
        help="List restart points and exit without checking tools or macros",
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
        default=None,
        help="Parallel simulation jobs for ngspice (default: automatic from CPU and free RAM)",
    )
    parser.add_argument(
        "--pin-cap-gap",
        type=float,
        default=float(os.environ.get("PIN_GAP_THRESH", "12.0")),
        help="Target maximum rise/fall capacitance settling gap quota in percent (default: 12.0%%). "
             "Iterative hold-time refinement will automatically run until all pins settle within this gap.",
    )
    parser.add_argument(
        "--settle-max-pct",
        type=float,
        default=float(os.environ.get("SETTLE_MAX_PCT", "3.0")),
        help="Energy-cycle convergence settling gap threshold in percent (default: 3.0%%).",
    )

    args = parser.parse_args()

    if args.list_steps:
        list_steps()
        return
    if args.from_step in FULL_STEPS and not args.full:
        parser.error(f"--from-step {args.from_step} requires --full")
    start_step = (int(args.from_step) if args.from_step and args.from_step.isdigit()
                  else 2 if args.from_step else 1)
    sim_start = args.from_step if args.from_step and not args.from_step.isdigit() else None
    if args.with_extract and (start_step > 2 or sim_start not in (None, "extract")):
        parser.error("--with-extract conflicts with this starting point; "
                     "use --from-step extract to rerun extraction and all later steps")

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
    if args.jobs is not None:
        os.environ["JOBS"] = str(args.jobs)
    os.environ["PIN_GAP_THRESH"] = str(args.pin_cap_gap)
    os.environ["SETTLE_MAX_PCT"] = str(args.settle_max_pct)

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
    if args.from_step:
        print(f"Starting at    : {args.from_step} (earlier steps are not rerun)")

    # Phase numbers stay stable even when a preceding phase is skipped.
    if start_step <= 1:
        log_step(1, 5, "Pre-flight checks")
        for m in target_macros:
            cmd = [sys.executable, os.path.join(SCRIPTS_DIR, "rom_paths.py"), "--check", m]
            if args.macros_dir:
                cmd += ["--macros-dir", args.macros_dir]
            run_step(cmd, env, "1", f"Pre-flight check failed for macro: {m}")
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
    if not args.from_logs and start_step <= 2:
        # Decided BEFORE the environment check, because it is what makes Magic
        # required or merely nice to have.
        missing_cap = [m for m in target_macros
                       if not os.path.exists(rom_paths.cap_netlist(m, args.macros_dir))]

        # An explicit simulation restart must not silently go back to extraction.
        if sim_start not in (None, "extract") and missing_cap:
            log_err("Cannot continue: missing <macro>_cap_only.spice for "
                    + ", ".join(missing_cap))
            log_err("Restore the previous extraction or use --from-step extract.")
            sys.exit(1)
        check_resume_inputs(sim_start, target_macros, env)

        extraction_macros = (target_macros if args.with_extract or sim_start == "extract"
                             else missing_cap)
        do_extract = bool(extraction_macros)
        if not check_environment(env, need_magic=do_extract):
            sys.exit(1)

        # Step 2: SPICE Simulations
        log_step(2, 5, "Running SPICE characterization simulations")

        # EXTRACTION IS NOT OPTIONAL WHEN ITS OUTPUT IS MISSING.
        #
        # run_col_timing.sh and everything after it read
        # <macro>_cap_only.spice. --with-extract exists so a macro that
        # already has one does not pay for Magic again -- but when the file is
        # absent the flow cannot run at all, and making the user remember a
        # flag for that turned into a failure some minutes in, on the first
        # macro anyone brings. So: if it is missing, extract. If it is missing
        # and there is no GDS to extract from, say so now rather than later.
        if do_extract:
            no_gds = [m for m in extraction_macros
                      if not os.path.exists(os.path.join(
                          rom_paths.split_macro(m, args.macros_dir)[1], m + ".gds"))]
            if no_gds:
                log_err("Cannot run extraction: no GDS for "
                        + ", ".join(no_gds))
                log_err("  <macro>_cap_only.spice is what every deck is built on.")
                log_err("  Add <macro>.gds to the macro directory, or copy an")
                log_err("  existing <macro>_cap_only.spice in beside the netlist.")
                sys.exit(1)
            if missing_cap:
                log_warn("No <macro>_cap_only.spice for: " + ", ".join(missing_cap))
            log_warn("Running Magic extraction before the measurements.")

        sim_scripts = [step for step in SIMULATION_STEPS
                       if (step[0] != "extract" or do_extract)
                       and (args.full or step[0] not in FULL_STEPS)]
        if sim_start:
            start_index = next(i for i, step in enumerate(sim_scripts) if step[0] == sim_start)
            sim_scripts = sim_scripts[start_index:]

        for name, desc, script_name in sim_scripts:
            print(f"\n  {Colors.BOLD}--> {name}: {desc} ({script_name}){Colors.RESET}")
            script_path = os.path.join(SCRIPTS_DIR, script_name)
            # The extraction script accepts one macro, unlike measurement scripts.
            groups = [[m] for m in extraction_macros] if name == "extract" else [target_macros]
            for macros in groups:
                cmd = ["/bin/sh", script_path] + macros
                run_step(cmd, env, name, f"Simulation failed during: {script_name}")

    if start_step <= 3:
        log_step(3, 5, "Generating Liberty (.lib) files from measurements")
        cmd = ["/bin/sh", os.path.join(SCRIPTS_DIR, "regen_rom_libs.sh")] + target_macros
        run_step(cmd, env, "3", "Liberty (.lib) generation failed.")
        log_ok("Liberty libraries generated successfully for TT, SS, FF corners.")

    if start_step <= 4:
        log_step(4, 5, "Generating behavioural SystemVerilog (.sv) models")
        cmd = [sys.executable, os.path.join(SCRIPTS_DIR, "gen_macro_behavioral_v.py")] + target_macros
        if args.macros_dir:
            cmd += ["--macros-dir", args.macros_dir]
        if args.out_dir:
            cmd += ["--outdir", os.path.join(args.out_dir, "verilog"),
                    "--lib-dir", os.path.join(args.out_dir, "lib")]
        run_step(cmd, env, "4", "Behavioural Verilog generation failed.")
        log_ok("Behavioural Verilog models updated with measured timing.")

    log_step(5, 5, "Running verification testsuite")
    test_env = env.copy()
    test_env.pop("SETTLE_MAX_PCT", None)
    run_step(["/bin/sh", os.path.join(TESTS_DIR, "run_tests.sh")] + target_macros, test_env, "5",
             "Testsuite verification failed.")

    print(f"\n{Colors.BOLD}{Colors.GREEN}======================================================{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.GREEN} FLOW COMPLETED SUCCESSFULLY! ALL DELIVERABLES READY. {Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.GREEN}======================================================{Colors.RESET}")
    lib_out = os.path.join(rom_paths.out_dir(), "lib")
    v_out = os.path.join(rom_paths.out_dir(), "verilog")
    print(f"Liberty deliverables : {lib_out}")
    print(f"Verilog deliverables : {v_out}")


if __name__ == "__main__":
    main()
