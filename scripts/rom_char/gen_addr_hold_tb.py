#!/usr/bin/env python3
"""Build a column deck that CUTS THE CHAIN mid-evaluate -- the HOLD experiment.

WHY THIS EXISTS: `hold` in the .lib is the one constraint that is not measured.
regen_rom_libs.sh passes --hold "$acc", i.e. "addr0 must stay stable for the
whole evaluate window", and gen_rom_lib.py turns that into hold = access_eff.
The reasoning is sound -- the row decoder is CLOCKED, so an address that moves
during evaluate pulls a second wordline down and that wordline does not come
back within the cycle -- but 17.33 ns of hold is expensive in STA and nobody
had ever measured where the real limit is.

WHAT IT SIMULATES: the macro is reading a 0 out of the worst column. Every
wordline is held high, which IS that read (the selected row's cell is a
zero_cell, a metal strap, so its gate is irrelevant). Then, TBREAK into the
evaluate phase, the address changes to a row whose cell in this column is a
one_cell: that wordline falls and the series chain is cut.

The cut is placed at the cell NEAREST THE BITLINE, which is the worst case --
it isolates the entire chain at once. After the cut the bitline cannot recover
either way: the precharge PMOS is off for the rest of the phase, so whatever
level the bitline has reached is the level the inverter resolves.

HOLD IS THEREFORE the smallest TBREAK at which the read still completes: the
bitline has already fallen past the inverter's trip point when the chain is
cut, and dout0 still lands on the correct 0.

Everything else -- the parasitics, the wire resistance, the 1 us saturated
precharge phase, the three-cycle settling -- is inherited unchanged from the
deck gen_col_tb_parasitic.py already writes, so the numbers stay comparable
with the ones in the .lib.
"""
import argparse
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def geom(macro, macros_dir=None):
    cmd = [sys.executable, os.path.join(HERE, "rom_paths.py"), macro, "--sh"]
    if macros_dir:
        cmd += ["--macros-dir", macros_dir]
    out = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    return dict(re.findall(r"^(G_\w+)='([^']*)'$", out, re.M))


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("macro")
    p.add_argument("out")
    p.add_argument("--corner", choices=("tt", "ss", "ff"), default="tt")
    p.add_argument("--break-ns", type=float,
                   help="cut the chain this many ns after the evaluate edge of "
                        "the measured (third) cycle. Omit for the reference "
                        "run with no cut at all.")
    p.add_argument("--csv", help="also dump v(bitline)/v(bl_b) here")
    p.add_argument("--retention-us", type=float,
                   help="RETENTION mode: cut the chain at the evaluate edge "
                        "(so the whole phase is a read of 1, bitline floating "
                        "high) and hold evaluate open this many us. Answers "
                        "whether a precharged ROM has a MINIMUM clock "
                        "frequency: the bitline is a dynamic node and nothing "
                        "refreshes it while clk0 is high.")
    p.add_argument("--sweep-ns",
                   help="comma-separated cut times for an INTERACTIVE deck: "
                        "ngspice runs them one after another and draws every "
                        "trace in one window. Implies --break-ns and ignores "
                        "--csv. Open it with plain `ngspice <deck>`.")
    p.add_argument("--wl-slew-ns", type=float, default=0.1,
                   help="FALL TIME of the wordline that cuts the chain, full "
                        "VDD->0. The deck used a fixed 100 ps edge until this "
                        "became a parameter, and 100 ps is not what the macro "
                        "produces: the real wordline is driven by one "
                        "rom_row_decode_wordline_buffer into the array's wire "
                        "C plus one cell gate per column (~290 fF on wrom0). "
                        "Measure it with run_wl_slew.sh. The ideal step is "
                        "the PESSIMISTIC end -- a real edge keeps the chain "
                        "partly conducting while it falls, so the bitline goes "
                        "on discharging and the read survives an EARLIER "
                        "address move. --break-ns always names the wordline's "
                        "50%% crossing, whatever the slew, so two slews stay "
                        "comparable on one axis.")
    p.add_argument("--macros-dir")
    args = p.parse_args()

    sweep = None
    if args.retention_us:
        if args.sweep_ns:
            sys.exit("--retention-us and --sweep-ns are different experiments")
        args.break_ns = 0.1          # cut as the evaluate edge arrives
    if args.sweep_ns:
        sweep = [float(x) for x in args.sweep_ns.split(",") if x.strip()]
        if not sweep:
            sys.exit("--sweep-ns is empty")
        args.break_ns = sweep[0]

    g = geom(args.macro, args.macros_dir)
    sfx = "" if args.corner == "tt" else "_" + args.corner
    src = os.path.join(g["G_CHAR"],
                       "%s_worst_case_parasitic%s.sp" % (g["G_COLTAG"], sfx))
    if not os.path.exists(src):
        sys.exit("no column deck: %s\n  run scripts/rom_char/run_col_timing.sh "
                 "%s first" % (src, args.macro))
    s = open(src).read()

    bl = "bl_0_%s" % g["G_WORST_COL"]
    if bl not in s:
        sys.exit("bitline node %s not found in %s" % (bl, src))

    # The cell nearest the bitline: the chain element whose drain is the
    # bitline (possibly through its own wire-resistance node, <bl>_r). Its
    # gate is the wordline to drop. Found by structure, not by name, so this
    # keeps working when the worst column moves.
    m = re.search(r"^X\S+\s+%s(?:_r\d*)?\s+\S+\s+(\S+)\s+\S+\s+\S*one_cell\s*$"
                  % re.escape(bl), s, re.M)
    if not m:
        sys.exit("could not find the chain cell adjacent to %s in %s" % (bl, src))
    wl = m.group(1)

    src_line = re.search(r"^(V\w+)\s+%s\s+0\s+DC\s+\{VDD\}\s*$" % re.escape(wl),
                         s, re.M)
    if not src_line:
        sys.exit("no DC source drives %s in %s" % (wl, src))

    head = ["* ADDRESS HOLD experiment -- generated by gen_addr_hold_tb.py",
            "* column deck: %s" % os.path.basename(src),
            "* chain cut at %s (the cell adjacent to %s -- worst case)" % (wl, bl)]
    if args.break_ns is None:
        head.append("* REFERENCE RUN: no cut, the address is stable all cycle")
    else:
        head.append("* the address moves %.4f ns after the evaluate edge "
                    "(50%% crossing of a %.4f ns wordline fall)"
                    % (args.break_ns, args.wl_slew_ns))
    s = "\n".join(head) + "\n" + s

    if args.break_ns is not None:
        # One fall, then low for the rest of the run: a clocked decoder cannot
        # raise a wordline again inside the same evaluate phase.
        # The edge is centred on TBREAK -- half of it before, half after --
        # so that --break-ns is the wordline's 50% CROSSING and not the
        # instant it starts to move. Without that the axis would shift under
        # itself whenever the slew changed and two slews could not be compared.
        s = s.replace(src_line.group(0),
                      "%s %s 0 PWL(0 {VDD} '{TBREAK}-{TWLSLEW}/2' {VDD} "
                      "'{TBREAK}+{TWLSLEW}/2' 0)" % (src_line.group(1), wl))
        # The measured cycle's evaluate edge is at 2.5*TCLK (the precharge
        # source rises at TCLK/2 + k*TCLK and the third cycle is the one the
        # column deck measures).
        s = re.sub(r"^(\.param TCLK=[^\n]*)$",
                   r"\1\n.param TBRK_NS=%.6f\n"
                   r".param TWLSLEW=%.6fn\n"
                   r".param TBREAK='2.5*TCLK + TBRK_NS*1n'"
                   % (args.break_ns, args.wl_slew_ns),
                   s, count=1, flags=re.M)

    if args.retention_us:
        # The periodic precharge source is replaced by one that runs the two
        # settling cycles normally and then LEAVES EVALUATE OPEN. The chain
        # filling during the 1 us precharge phases is what makes the numbers
        # comparable with the rest of the flow, so those cycles are kept
        # exactly as they were; only the last phase is stretched.
        pre = re.search(r"^(V\w+)\s+precharge\s+0\s+PULSE\([^\n]*\)$",
                        s, re.M)
        if not pre:
            sys.exit("could not find the precharge source in %s" % src)
        stop = "'2.5*TCLK + %.6fu'" % args.retention_us
        at_end = "'2.5*TCLK + %.6fu - 10n'" % args.retention_us
        s = s.replace(pre.group(0),
                      "%s precharge 0 PWL(0 0 '0.5*TCLK' 0 '0.5*TCLK+100p' {VDD}\n"
                      "+ 'TCLK' {VDD} 'TCLK+100p' 0 '1.5*TCLK' 0 '1.5*TCLK+100p' {VDD}\n"
                      "+ '2*TCLK' {VDD} '2*TCLK+100p' 0 '2.5*TCLK' 0\n"
                      "+ '2.5*TCLK+100p' {VDD} %s {VDD})" % (pre.group(1), stop))
        # tmax keeps the quiet stretch cheap; the solver still refines at the
        # edges, and t_dis_50_prev (cycle 2, untouched) is the check that the
        # coarser grid did not move the physics.
        s = re.sub(r"^\.tran [^\n]*$",
                   ".tran 200p %s 0 50n" % stop, s, count=1, flags=re.M)
        s = s.replace("\n.tran ", """
* DATA LOSS: the read is a 1 (bitline held high). bl_b sits low while that is
* true; when leakage has dragged the bitline through the inverter's trip
* point the stored 1 has turned into a 0 and bl_b rises. That crossing is the
* retention limit, and 1/(2 x it) is the minimum clock frequency.
.measure tran t_flip TRIG v(precharge) VAL='VDD/2' RISE=1 TD='2.4*TCLK'
+                    TARG v(bl_b)      VAL='VDD/2' RISE=1 TD='2.4*TCLK'
.measure tran bl_hold_end FIND v(%s) AT=%s
.measure tran blb_hold_end FIND v(bl_b) AT=%s
\n.tran """ % (bl, at_end, at_end), 1)

    # PASS/FAIL of the read itself: bl_b is the bitline inverter's output, so
    # a 0 read means bl_b RISES. If the cut comes too early the bitline stalls
    # above the trip point, bl_b never crosses, and this measurement fails --
    # that failure IS the hold violation.
    probes = """
.measure tran t_read TRIG v(precharge) VAL='VDD/2' RISE=1 TD='2.5*TCLK'
+                    TARG v(bl_b)      VAL='VDD/2' RISE=1 TD='2.5*TCLK'
.measure tran bl_end   FIND v(%s) AT='3*TCLK - 1n'
.measure tran bl_b_end FIND v(bl_b)    AT='3*TCLK - 1n'
""" % bl
    s = s.replace("\n.tran ", probes + "\n.tran ", 1)

    if sweep:
        # One ngspice session, one window. alterparam moves the cut time,
        # `reset` rebuilds the circuit from it, and each run lands in its own
        # plot (tran1, tran2, ...) so they can all be drawn together at the
        # end. Nothing is written to disk: this deck exists to be LOOKED at.
        runs = "\n".join(
            "alterparam TBRK_NS = %g\nreset\nrun\necho \"  cut at %g ns "
            "-> done\"" % (b, b) for b in sweep)
        bl_traces = " ".join("tran%d.v(%s)" % (i + 1, bl) for i in range(len(sweep)))
        blb_traces = " ".join("tran%d.v(bl_b)" % (i + 1) for i in range(len(sweep)))
        # the wordline IS the address: its falling edge is the moment addr0
        # moved, i.e. the cut time of that run. Drawn next to the waveform it
        # explains, so the cause is on the same axis as the effect.
        wl_traces = " ".join("tran%d.v(%s)" % (i + 1, wl) for i in range(len(sweep)))
        ctrl = """
.control
echo "address hold sweep -- %d runs, roughly a minute each"
%s
echo ""
echo "THREE WINDOWS OPEN -- every one of them also shows v(%s),"
echo "the wordline: ITS FALLING EDGE IS WHEN THE ADDRESS MOVED."
echo "  1  v(%s) + the address -- the bitline FREEZES the instant the"
echo "     wordline falls, and never moves again"
echo "  2  v(bl_b) + the address -- the value that is read: railed high = 0,"
echo "     railed low = 1, anything in between is not a digital value at all"
echo "  3  the address edges alone, so the sweep points are readable"
echo ""
echo "trace order = cut times: %s ns   (the evaluate edge is at 5 us)"
echo "you are at the ngspice prompt: redraw with e.g."
echo "  plot %s %s xlimit 4.999u 5.06u"
echo "quit with: quit"
plot %s %s xlimit 4.999u 5.03u title 'bitline + address -- frozen at the cut'
plot %s %s xlimit 4.999u 5.03u title 'bl_b (read value) + address (falling edge = addr moved)'
plot %s xlimit 4.999u 5.03u title 'the address: each fall is one sweep point'
.endc
""" % (len(sweep), runs, wl, bl, ", ".join("%g" % b for b in sweep),
         bl_traces, wl_traces,
         bl_traces, wl_traces, blb_traces, wl_traces, wl_traces)
        s = re.sub(r"^(\.tran [^\n]*)$", lambda m: m.group(1) + ctrl, s,
                   count=1, flags=re.M)
    elif args.csv:
        s = re.sub(r"^(\.tran [^\n]*)$",
                   r"\1\n.control\nrun\nset wr_singlescale\n"
                   "wrdata %s v(%s) v(bl_b) v(precharge)\n.endc" % (args.csv, bl),
                   s, count=1, flags=re.M)

    open(args.out, "w").write(s)
    print("written: %s  (%s %s, cut at %s, %s)"
          % (args.out, args.macro, args.corner, wl,
             "no cut" if args.break_ns is None
             else "%.4f ns into evaluate, wl slew %.4f ns"
                  % (args.break_ns, args.wl_slew_ns)))


if __name__ == "__main__":
    main()
