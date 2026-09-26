#!/usr/bin/env python3
"""Waveform testbench generator -- a TB whose purpose is to be LOOKED AT.

WHY A SECOND TESTBENCH
----------------------
tests/test_verilog_model.py already builds a testbench, but it is a different
instrument: it is self-checking, it writes no VCD, it lives in a temporary
directory that is deleted when the run ends, and it drives the model through
its VIOLATIONS on purpose. Nothing about it is meant to be opened in a wave
viewer.

This one is. It produces ONE standalone file per macro that

  * only ever drives LEGAL cycles (setup, precharge and hold all respected),
    so the waves show the macro working rather than failing,
  * sweeps a run of addresses, one read per clock cycle, so the ROM contents
    can be read off the dout0 trace directly,
  * carries extra observation-only signals that the real macro does not have
    (see below) -- a wave viewer shows what is in the netlist, and what is in
    this netlist during precharge is all ones,
  * dumps a VCD, and ships a Vivado xsim script next to it.

THE OBSERVATION SIGNALS, AND WHY THEY ARE NOT CHEATING
------------------------------------------------------
dout0 is only valid for part of the cycle: every clk0 fall restarts precharge
and dout0 goes back to all ones. That is the truth about this macro and it is
why `dout0` alone makes a confusing waveform -- half of it is 0xFFFFFFFF.

  dout_cap   : dout0 sampled just before the falling edge -- what a register
               clocked on clk0's fall would actually capture. This is the
               trace to read the ROM contents off.
  expected   : the .bin content at the address being read, straight from the
               model's own memory array.
  mismatch   : dout_cap !== expected at the capture point. Flat zero is the
               whole point; a spike means the model and the data disagree.
  phase      : an ASCII tag (PRECHARGE / EVALUATE / VALID) -- readable in the
               wave viewer as a string, so the two halves of the cycle and the
               access time inside the high phase are visible without measuring.

THE .bin IS NOT A $readmemb FILE
-------------------------------
rom_configs/<macro>.bin is RAW BINARY -- 4 bytes per 32-bit word, no text at
all. $readmemb wants ASCII ones and zeros, so the model's default INIT_FILE
loads NOTHING from it: iverilog stops at the first byte with "Invalid input
character" and the whole array stays X. That is a property of the generated
model, not of this script, and the waves would have been a screen of xxxxxxxx.

So this script CONVERTS: it writes <macro>_rom.mem next to the testbench, one
WIDTH-bit binary word per line, and points the TB's INIT_FILE at that. The
byte order is a choice -- see --endian.

USAGE
-----
    python3 scripts/rom_char/gen_wave_tb.py                # every macro
    python3 scripts/rom_char/gen_wave_tb.py wrom0
    python3 scripts/rom_char/gen_wave_tb.py wrom0 --reads 64 --start 0
    python3 scripts/rom_char/gen_wave_tb.py wrom0 --endian big

OUTPUTS
-------
tests/wave/tb_<macro>_wave.v    the testbench
tests/wave/tb_<macro>_wave.tcl  the xsim wave-logging batch
tests/wave/<macro>_rom.mem      the .bin as $readmemb-readable text

The MODEL is read from $ROM_OUT_DIR/verilog/<macro>.sv and stays there:
output/verilog holds deliverable Verilog only. Everything this script writes
is test material, so it lands under tests/.

The TB reads its timing from the GENERATED MODEL (<macro>.v), not from the
.lib, so the two can never drift apart: if the model is regenerated at another
corner the TB follows on its next run.
"""

from __future__ import annotations

import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)

import rom_paths  # noqa: E402

SIGNATURE = os.path.basename(__file__)


def read_model(v_path):
    """Pull the geometry and the measured timing out of a generated model."""
    txt = open(v_path).read()

    def num(name):
        m = re.search(r"parameter\s+(?:real\s+)?%s\s*=\s*([\d.]+)\s*;" % name, txt)
        return float(m.group(1)) if m else None

    def intg(name):
        v = num(name)
        return int(v) if v is not None else None

    amsb = re.search(r"input\s+wire\s+\[(\d+):0\]\s+addr0", txt)
    init = re.search(r'parameter\s+INIT_FILE\s*=\s*"([^"]*)"\s*;', txt)
    corner = re.search(r"^//\s*TIMING\s*:\s*(\S+)", txt, re.M)

    info = {
        "depth": intg("DEPTH"),
        "width": intg("WIDTH"),
        "addr_bits": int(amsb.group(1)) + 1 if amsb else None,
        "access": num("ACCESS_NS"),
        "t_pre": num("T_PRE_NS"),
        "setup": num("SETUP_NS"),
        "hold": num("HOLD_NS"),
        "hold_cs": num("HOLD_CS_NS"),
        "mpw_high": num("MPW_HIGH_NS"),
        "t_fall": num("T_FALL_NS"),
        "init": init.group(1) if init else "",
        "corner": corner.group(1) if corner else "unknown",
    }
    missing = [k for k, v in info.items() if v is None]
    return (None, missing) if missing else (info, [])


def write_mem(bin_path, mem_path, width, depth, endian):
    """Raw .bin -> $readmemb text. Returns the word count actually written.

    The .bin holds width/8 bytes per word and says nothing about their order,
    so the order is an argument rather than a guess made silently. If the data
    comes out byte-swapped in the waves, this is the knob: --endian big.
    """
    nbytes = width // 8
    data = open(bin_path, "rb").read()
    words = len(data) // nbytes
    if words > depth:
        words = depth
    with open(mem_path, "w") as fh:
        fh.write("// %s as $readmemb text -- %d x %d bit, %s-endian bytes\n"
                 % (os.path.basename(bin_path), words, width, endian))
        fh.write("// generated by %s; do not edit, regenerate\n" % SIGNATURE)
        for i in range(words):
            chunk = data[i * nbytes:(i + 1) * nbytes]
            fh.write(format(int.from_bytes(chunk, endian), "0%db" % width) + "\n")
    return words


TB_TEMPLATE = '''// ---------------------------------------------------------------------------
// tb_{macro}_wave -- WAVEFORM testbench for {macro}, generated by {sig}
//
// Regenerate:  python3 scripts/rom_char/gen_wave_tb.py {macro}
//
// This TB drives ONLY LEGAL cycles. Every constraint the model checks is
// respected with margin, so a clean run prints nothing and `mismatch` stays
// low for the whole simulation -- what you are meant to be looking at is the
// DATA, not a failure.
//
// Timing below is MEASURED ({corner} corner, via {macro}.sv):
//     access {access} ns / precharge {t_pre} ns / setup {setup} ns
// The cycle built from it:
//     low phase  = {t_pre} * PRE_MARGIN
//     high phase = {access} * EVAL_MARGIN
//     addr0 lands = {setup} * SETUP_MARGIN before the rising edge
// so the period is roughly {period_ns} ns -- this macro is SLOW, do not expect
// the waves to look like a synchronous SRAM.
//
// WHAT TO PUT IN THE WAVE WINDOW (top to bottom)
//     clk0, cs0        the drive
//     phase            PRECHARGE / EVALUATE / VALID, as ASCII
//     addr0            the address being read (radix: unsigned)
//     dout0            the raw output -- all ones for half of every cycle
//     dout_cap         the value captured at the falling edge  <-- THE DATA
//     expected         the .bin content at addr0
//     mismatch         must stay 0
//
// VIVADO, batch from the repository root -- this is the one that ends with a
// wave database you can open:
//     xvlog -sv output/verilog/{macro}.sv tests/wave/tb_{macro}_wave.v
//     xelab -debug typical tb_{macro}_wave -s tb_{macro}_wave_sim
//     xsim tb_{macro}_wave_sim -tclbatch tests/wave/tb_{macro}_wave.tcl
//     xsim --gui tb_{macro}_wave_sim.wdb
// -debug typical is not optional: without it nothing is logged and the wave
// window is empty.
//
// VIVADO GUI: add {macro}.sv and this file to a simulation fileset, set
// tb_{macro}_wave as the simulation top, Run Behavioral Simulation. Set
// `phase` to ASCII radix and addr0 to unsigned once the window is up.
//
// iverilog, for the same waves without Vivado:
//     iverilog -g2012 -o /tmp/{macro}_wave.vvp \\
//              output/verilog/{macro}.sv tests/wave/tb_{macro}_wave.v
//     vvp /tmp/{macro}_wave.vvp && gtkwave tb_{macro}_wave.vcd
// ---------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_{macro}_wave;

  // ---- what the run covers ------------------------------------------------
  parameter integer START_ADDR = {start};
  parameter integer N_READS    = {reads};

  // ---- margins -------------------------------------------------------------
  // EVERY edge in this testbench is placed by a .lib constraint times one of
  // these. Nothing is a round number somebody liked the look of, because a
  // waveform whose edges come from nowhere demonstrates nothing: what the
  // picture is supposed to show is WHERE THE LIMITS ARE, and an edge at ten
  // times the limit shows only that the testbench was generous.
  //
  // 1.0 would sit exactly on the constraint, and a wave viewer cannot show
  // you which side of an equality you are on, so they sit just above it.
  //
  // BELOW 1.0 EACH ONE IS A DELIBERATE VIOLATION and the model reports it
  // once per cycle -- that is the other picture worth taking:
  //     gen_wave_tb.py {macro} --setup-margin 0.6
  //     gen_wave_tb.py {macro} --hold-margin 0.5
  //     gen_wave_tb.py {macro} --pre-margin 0.8 --eval-margin 0.9
  parameter real PRE_MARGIN   = {pre_margin:.2f};   // low  phase = T_PRE * this   (min_pulse_width fall)
  parameter real EVAL_MARGIN  = {eval_margin:.2f};   // high phase = MPW_HIGH * this (min_pulse_width rise)
  parameter real SETUP_MARGIN = {setup_margin:.2f};   // addr0 before the rise = SETUP * this
  parameter real HOLD_MARGIN  = {hold_margin:.2f};   // addr0 held after the rise = HOLD * this
  // cs0 is the one pin with NO free window. The .lib says so twice: the plain
  // hold_rising is the whole access ({hold_cs} ns), and
  // clock_gating_hold_falling is 0.0000 -- a hold of zero against the FALLING
  // edge, which is not a slack but a different anchor. It means the deadline
  // is an EVENT, not a duration: cs0 must still be high when clk0 falls, for
  // any clock period. Dropping it earlier re-opens the precharge PMOS and the
  // bitline is the only place this macro keeps a read.
  //
  // So cs0's margin is on the PHASE, measured from the rising edge: 1.0
  // releases it exactly on the deadline, above 1.0 is past it, below 1.0 is
  // inside the evaluate phase and the model reports the violation.
  parameter real CS_MARGIN    = {cs_margin:.2f};   // cs0 released after the rise = T_HIGH * this

  // The data the model loads. NOT rom_configs/{macro}.bin: that file is raw
  // binary and $readmemb cannot read it (it aborts on the first byte and the
  // array stays X). {macro}_rom.mem is the same contents as $readmemb text,
  // written by {sig} at the same time as this file.
  //
  // The path is absolute because a simulator's working directory is its own
  // business -- Vivado runs from <project>.sim/sim_1/behav/xsim, where a
  // relative path does not resolve. Override it if the tree moves:
  //     xelab -generic_top "INIT_FILE=/other/path/{macro}_rom.mem" ...
  parameter INIT_FILE = "{init}";

  // Straight out of {macro}.sv, which took them straight out of the .lib.
  localparam real T_PRE    = {t_pre};    // min_pulse_width, fall
  localparam real MPW_HIGH = {mpw_high};    // min_pulse_width, rise
  localparam real ACCESS   = {access};    // clk0 rise -> dout0 valid
  localparam real SETUP    = {setup};    // setup_rising, addr0
  localparam real HOLD     = {hold};    // hold_rising, addr0
  localparam real T_FALL   = {t_fall};    // falling_edge arc on dout0

  // The high phase is sized from MPW_HIGH, not from ACCESS. They are not the
  // same number -- the library's minimum pulse carries a guard band on top of
  // the measured access -- and a phase between them reads correctly while
  // still failing timing closure. Sizing from access would put this testbench
  // in that gap at any margin under {mpw_over_access:.3f}.
  localparam real T_LOW   = T_PRE    * PRE_MARGIN;
  localparam real T_HIGH  = MPW_HIGH * EVAL_MARGIN;
  // The address moves inside the low phase -- the bitlines are at VDD
  // throughout, so it costs nothing until the edge arrives.
  localparam real T_SETUP = SETUP    * SETUP_MARGIN;
  // ...and is free again this long after the rise. hold_rising is SHORTER
  // than access (it is the only constraint here that is): the read is decided
  // at the bitline inverter's trip point and the back end after it does not
  // depend on the address. Holding the address for the whole evaluate phase
  // hides that -- it is the single most specific thing this macro's .lib
  // says, and the wave should show it.
  localparam real T_HOLD  = HOLD     * HOLD_MARGIN;
  // Exactly 1.0 would put the release in the same timestep as the falling
  // edge, where the model has two negedge processes to run and which one goes
  // first would decide whether a violation is reported. A testbench must not
  // hand that to the scheduler.
  localparam real T_CS    = T_HIGH   * CS_MARGIN;
  // Observation only: how long `mismatch` is left standing after the falling
  // edge so it can be seen in the window. Part of the low phase, not extra.
  localparam real T_TAIL  = 1.0;

  localparam integer WIDTH     = {width};
  localparam integer ADDR_BITS = {addr_bits};
  localparam integer DEPTH     = {depth};

  reg                  clk0  = 1'b0;
  reg                  cs0   = 1'b0;
  reg  [{amsb}:0]  addr0 = {{ADDR_BITS{{1'b0}}}};
  wire [{dmsb}:0] dout0;

  {macro} #(.INIT_FILE(INIT_FILE)) dut (
    .clk0 (clk0),
    .cs0  (cs0),
    .addr0(addr0),
    .dout0(dout0)
  );

  // ---- observation only; none of this exists in the macro -----------------
  reg  [{dmsb}:0] dout_cap = {{WIDTH{{1'b1}}}};  // value at the capture point
  reg  [{dmsb}:0] expected = {{WIDTH{{1'b0}}}};  // .bin content at addr0
  reg                  mismatch = 1'b0;
  // 1 = the .lib says addr0 is free to move. Goes high T_HOLD after the rise
  // and stays high until the next address is placed, so the low stretch in
  // the wave window is exactly hold_rising.
  reg                  addr_held = 1'b0;
  // 1 = cs0 is required high. Unlike addr_held this never goes low while the
  // evaluate phase is open: side by side in the wave window the two signals
  // are the whole difference between the address's constraint and the chip
  // select's.
  reg                  cs_held   = 1'b0;
  reg  [8*9:1]         phase    = "IDLE";
  integer              read_idx = 0;
  integer              errors   = 0;

  // The address the read was STARTED with -- not addr0, which walks off to a
  // far row once the hold window closes. Comparing against addr0 would make
  // `expected` follow it and the check would compare the read to the wrong
  // row for most of the evaluate phase.
  reg [{amsb}:0] addr_rd = {{ADDR_BITS{{1'b0}}}};
  always @(*) expected = dut.mem[addr_rd];

  // cs0's release is timed from the RISING edge and driven here rather than
  // from the sequence below, because where it falls depends on CS_MARGIN: at
  // the default it is past the falling edge, under 1.0 it is inside the
  // evaluate phase. One process covers both without the main sequence having
  // to be re-ordered around it.
  always @(posedge clk0) begin
    #(T_CS);
    cs0     = 1'b0;
    cs_held = 1'b0;
  end

  // ---- the run ------------------------------------------------------------
  integer i;
  initial begin
    $dumpfile("tb_{macro}_wave.vcd");
    $dumpvars(0, tb_{macro}_wave);

    $display("=== {macro} waveform run: %0d reads from address %0d ===",
             N_READS, START_ADDR);
    $display("    cycle = %.3f ns low + %.3f ns high (measured {corner})",
             T_LOW, T_HIGH);

    // The FIRST precharge is not optional. Power-up leaves the bitlines
    // undefined and the model only puts them at VDD on a clk0 fall, so the
    // run opens with cs0 low and a full low phase before anything is read.
    clk0  = 1'b0;
    cs0   = 1'b0;
    phase = "PRECHARGE";
    #(T_LOW);

    for (i = 0; i < N_READS; i = i + 1) begin
      read_idx = i;

      // The low phase runs with the PREVIOUS address still on the pins; the
      // new one goes on T_SETUP before the edge, so the gap you measure in
      // the wave window is the .lib's setup_rising and nothing else.
      //
      // T_SETUP is tens of picoseconds and the cycle is tens of nanoseconds,
      // so at full-cycle zoom the address and the clock edge look
      // simultaneous. THAT IS THE MEASUREMENT: zoom to the edge to see it.
      phase = "PRECHARGE";
      // mismatch from the previous cycle stays up a moment so it is visible
      // in the window, then the rest of the low phase runs.
      #(T_TAIL);
      mismatch = 1'b0;
      #(T_LOW - T_TAIL - T_SETUP);
      addr0     = (START_ADDR + i) % DEPTH;
      addr_rd   = addr0;
      addr_held = 1'b1;
      // The .lib gives cs0 the same setup_rising as addr0 -- 0.0480 ns, and
      // again as clock_gating_setup_rising -- so it is selected on the same
      // edge of the same window. It is released by the process above.
      cs0       = 1'b1;
      cs_held   = 1'b1;
      #(T_SETUP);

      clk0  = 1'b1;
      phase = "EVALUATE";

      // HOLD. The address is released the moment the .lib stops requiring
      // it, and released to a FAR ROW so the release is unmistakable in the
      // wave window -- half the array away, every bit of the row index
      // different. The read in flight survives this: that is what
      // run_hold_bisect.sh measured and it is why hold_rising is
      // {hold} ns rather than the full access window.
      //
      // The far row does start discharging its own bitlines, and about one
      // access time later dout0 would become the AND -- irreversibly, there
      // is no pull-up in the array. The evaluate phase is over long before
      // then; gen_wave_tb.py refuses to write a testbench where it is not.
      #(T_HOLD);
      addr0     = (START_ADDR + i + DEPTH / 2) % DEPTH;
      addr_held = 1'b0;

      // dout0 is NOT the data yet; the bitlines are still discharging.
      #(ACCESS - T_HOLD);
      phase = "VALID";
      #(T_HIGH - ACCESS);

      // CAPTURE, at the point a real consumer would: just before the fall.
      // cs0 is still held -- it has no free window at all, the .lib states
      // its deadline as this very edge -- while addr0 has been off on a far
      // row since T_HOLD, which is the whole point. The macro does give a
      // slack past the edge -- T_FALL_NS, the .lib's falling_edge arc on
      // dout0, is how long the precharge PMOS takes to pull the bitlines
      // back up -- but that window is a few nanoseconds and it is not what
      // a testbench should be spending. Capture before the edge.
      dout_cap = dout0;
      mismatch = (dout0 !== expected);
      if (mismatch) begin
        errors = errors + 1;
        $display("MISMATCH %0t: addr %0d -> dout0 %h, .bin says %h",
                 $time, addr_rd, dout0, expected);
      end
      $display("%8t  addr %4d  dout %h", $time, addr_rd, dout0);

      clk0  = 1'b0;
      phase = "PRECHARGE";
      // The low phase belongs to the TOP of the next iteration, where the
      // address is placed against setup_rising. Waiting one here as well --
      // which this loop used to do -- makes the real precharge 2 * T_LOW and
      // the printed period a lie about the run.
    end

    // The last read's own low phase. It used to live at the bottom of the
    // loop; without it here the falling edge and the tail below land in the
    // SAME timestep, cs0 is released in the same delta as the clock falls,
    // and whichever of the model's two negedge processes runs first decides
    // whether a cs0 hold violation is reported. A testbench must not make
    // the report depend on the simulator's scheduling order.
    phase = "PRECHARGE";
    #(T_TAIL);
    mismatch = 1'b0;
    #(T_LOW - T_TAIL);

    // Tail: one deselected cycle. cs0 low keeps the precharge on through the
    // whole high phase, so dout0 stays at all ones with clk0 toggling -- the
    // shape to recognise when a read "returns 0xFF...F for no reason".
    phase = "IDLE";
    cs0   = 1'b0;   // already low; the loop never re-asserts it from here
    clk0  = 1'b1;
    #(T_HIGH);
    clk0  = 1'b0;
    #(T_LOW);

    if (errors == 0)
      $display("=== done: %0d reads, every one matched {macro}.bin ===", N_READS);
    else
      $display("=== done: %0d MISMATCHES in %0d reads ===", errors, N_READS);
    $finish;
  end

endmodule
'''

TCL_TEMPLATE = '''# xsim wave-logging batch for tb_{macro}_wave -- generated by {sig}
#
# This is the tcl xsim itself runs, not a Vivado project script. The three
# commands around it, from the repository root:
#
#   xvlog -sv output/verilog/{macro}.sv tests/wave/tb_{macro}_wave.v
#   xelab -debug typical tb_{macro}_wave -s tb_{macro}_wave_sim
#   xsim tb_{macro}_wave_sim -tclbatch tests/wave/tb_{macro}_wave.tcl
#
# -debug typical is what makes the signals visible; without it log_wave has
# nothing to log and the .wdb comes out empty. Then open the waves with
#
#   xsim --gui tb_{macro}_wave_sim.wdb
#
# In the GUI set `phase` to ASCII radix (right-click -> Radix -> ASCII) and
# addr0 to unsigned; dout_cap is the trace that holds the ROM data.

log_wave -recursive *
run all
exit
'''


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("macros", nargs="*", help="default: every generated model")
    ap.add_argument("--macros-dir", default=None,
                    help="macro tree (default: ROM_MACROS_DIR / <repo>/examples)")
    ap.add_argument("--model-dir", default=None,
                    help="where the behavioural models are (default: "
                         "$ROM_OUT_DIR/verilog). Read-only: nothing is written "
                         "there -- that directory is for deliverable Verilog.")
    ap.add_argument("--outdir", default=None,
                    help="where the TB, its tcl and the .mem go (default: "
                         "<repo>/tests/wave)")
    ap.add_argument("--reads", type=int, default=16,
                    help="how many addresses to sweep (default: 16)")
    ap.add_argument("--start", type=int, default=0,
                    help="first address (default: 0)")
    # One knob per .lib constraint. The default sits just above each limit so
    # the waveform shows where the limit IS; below 1.0 each one is a
    # deliberate violation and the model reports it once per cycle.
    ap.add_argument("--pre-margin", type=float, default=1.05, metavar="K",
                    help="low phase = min_pulse_width(fall) * K (default 1.05)")
    ap.add_argument("--eval-margin", type=float, default=1.05, metavar="K",
                    help="high phase = min_pulse_width(rise) * K (default 1.05)")
    ap.add_argument("--setup-margin", type=float, default=1.05, metavar="K",
                    help="addr0 lands setup_rising * K before the rise "
                         "(default 1.05)")
    ap.add_argument("--hold-margin", type=float, default=1.05, metavar="K",
                    help="addr0 is released hold_rising * K after the rise "
                         "(default 1.05)")
    ap.add_argument("--cs-margin", type=float, default=1.05, metavar="K",
                    help="cs0 is released (high phase) * K after the rise "
                         "(default 1.05). cs0's deadline is the falling edge "
                         "itself -- clock_gating_hold_falling is 0 -- so 1.0 "
                         "is exactly on it and below 1.0 is a violation.")
    ap.add_argument("--endian", choices=("little", "big"), default="little",
                    help="byte order of a word inside the .bin (default: "
                         "little). The .bin carries no byte order of its own; "
                         "if the waves come out byte-swapped, flip this.")
    args = ap.parse_args()

    model_dir = args.model_dir or rom_paths.verilog_dir()
    outdir = args.outdir or os.path.join(REPO, "tests", "wave")
    os.makedirs(outdir, exist_ok=True)
    names = args.macros or rom_paths.discover(args.macros_dir)
    if not names:
        print("no macros found in %s" % rom_paths.macros_dir(args.macros_dir),
              file=sys.stderr)
        return 1

    rc = 0
    for macro in names:
        # .sv is what gen_macro_behavioral_v.py writes now; .v is still
        # accepted so a tree generated before the rename keeps working.
        v_path = os.path.join(model_dir, macro + ".sv")
        if not os.path.exists(v_path):
            v_path = os.path.join(model_dir, macro + ".v")
        if not os.path.exists(v_path):
            print("%-7s no behavioural model at %s -- run "
                  "gen_macro_behavioral_v.py first. SKIPPED."
                  % (macro, os.path.relpath(v_path, REPO)), file=sys.stderr)
            rc = 1
            continue

        info, missing = read_model(v_path)
        if info is None:
            print("%-7s could not read %s from %s. SKIPPED."
                  % (macro, ",".join(missing), os.path.relpath(v_path, REPO)),
                  file=sys.stderr)
            rc = 1
            continue

        # The model's INIT_FILE is relative to the macro tree, and it points at
        # a raw .bin that $readmemb cannot read. Both are fixed here: the .bin
        # is converted to text and the TB gets an absolute path to that.
        mdir = rom_paths.macro_dir(macro, args.macros_dir)
        bin_path = os.path.join(mdir, info["init"]) if info["init"] else ""
        init, words = "", 0
        mem_path = os.path.join(outdir, macro + "_rom.mem")
        if bin_path and os.path.exists(bin_path):
            words = write_mem(bin_path, mem_path, info["width"], info["depth"],
                              args.endian)
            init = mem_path
        else:
            print("%-7s WARNING: %s does not exist -- the TB will simulate "
                  "against an empty memory (dout0 all X)."
                  % (macro, os.path.relpath(bin_path, REPO) if bin_path
                     else "the .bin"), file=sys.stderr)

        reads = min(args.reads, info["depth"])
        t_low = info["t_pre"] * args.pre_margin
        t_high = info["mpw_high"] * args.eval_margin
        t_setup = info["setup"] * args.setup_margin
        t_hold = info["hold"] * args.hold_margin
        t_cs = t_high * args.cs_margin
        period = t_low + t_high

        # The testbench has to stay a testbench. Each of these is a way for a
        # margin to turn the run into something that no longer demonstrates
        # what it claims to, and every one of them would show up as data that
        # simply looks wrong -- which is the hardest kind of broken waveform
        # to read. They are refused here instead.
        bad = []
        if t_setup >= t_low:
            bad.append("the address would have to be placed before the low "
                       "phase starts (setup gap %.4f ns >= low phase %.4f ns)"
                       % (t_setup, t_low))
        if t_hold >= info["access"]:
            bad.append("the address would be released at %.4f ns, at or after "
                       "access (%.4f ns) -- past that point the release is no "
                       "longer the hold boundary, it is the read itself"
                       % (t_hold, info["access"]))
        # The released address is a real row and it starts discharging. One
        # access time later dout0 becomes the AND of the two rows and stays
        # that way -- the array has no pull-up outside precharge. If the
        # evaluate phase is still open then, every capture in the run is
        # corrupt and the waveform says the macro is broken.
        if t_hold + info["access"] <= t_high:
            bad.append("the evaluate phase (%.4f ns) outlasts the released "
                       "address's own discharge (%.4f + %.4f = %.4f ns): "
                       "dout0 would turn into the AND of the two rows before "
                       "the capture point and every read in the run would be "
                       "corrupt. Lower --eval-margin or raise --hold-margin."
                       % (t_high, t_hold, info["access"],
                          t_hold + info["access"]))
        # cs0 is released by a process armed on the rising edge, so its wait
        # must finish inside the cycle that armed it -- otherwise the next
        # rising edge arrives while the process is still waiting, that edge is
        # dropped, and cs0 is never re-armed again.
        if t_cs >= t_high + t_low - t_setup:
            bad.append("cs0 would still be waiting to be released (%.4f ns "
                       "after the rise) when the next cycle selects it "
                       "(%.4f ns) -- lower --cs-margin"
                       % (t_cs, t_high + t_low - t_setup))
        if bad:
            for b in bad:
                print("%-7s REFUSED: %s" % (macro, b), file=sys.stderr)
            rc = 1
            continue

        tb = TB_TEMPLATE.format(
            macro=macro, sig=SIGNATURE, corner=info["corner"],
            access="%.4f" % info["access"], t_pre="%.4f" % info["t_pre"],
            setup="%.4f" % info["setup"], period_ns="%.1f" % period,
            width=info["width"], addr_bits=info["addr_bits"],
            depth=info["depth"], amsb=info["addr_bits"] - 1,
            dmsb=info["width"] - 1, init=init,
            start=args.start, reads=reads,
            hold="%.4f" % info["hold"], mpw_high="%.4f" % info["mpw_high"],
            t_fall="%.4f" % info["t_fall"],
            mpw_over_access=info["mpw_high"] / info["access"],
            pre_margin=args.pre_margin, eval_margin=args.eval_margin,
            setup_margin=args.setup_margin, hold_margin=args.hold_margin,
            cs_margin=args.cs_margin, hold_cs="%.4f" % info["hold_cs"])

        tb_path = os.path.join(outdir, "tb_%s_wave.v" % macro)
        open(tb_path, "w").write(tb)
        tcl_path = os.path.join(outdir, "tb_%s_wave.tcl" % macro)
        open(tcl_path, "w").write(TCL_TEMPLATE.format(macro=macro, sig=SIGNATURE))

        viol = [n for n, k in (("pre", args.pre_margin),
                               ("eval", args.eval_margin),
                               ("setup", args.setup_margin),
                               ("hold", args.hold_margin),
                               ("cs", args.cs_margin)) if k < 1.0]
        print("%-7s written: %s  (%d reads from %d, cycle %.3f = %.3f low + "
              "%.3f high, setup %.4f, hold %.4f, cs %.4f ns%s, %s)"
              % (macro, os.path.relpath(tb_path, REPO), reads, args.start,
                 period, t_low, t_high, t_setup, t_hold, t_cs,
                 "  <-- VIOLATES " + ",".join(viol) if viol else "",
                 info["corner"]))
        if words:
            print("%-7s          %s  (%d x %d bit, %s-endian)"
                  % ("", os.path.relpath(mem_path, REPO), words,
                     info["width"], args.endian))

    return rc


if __name__ == "__main__":
    sys.exit(main())
