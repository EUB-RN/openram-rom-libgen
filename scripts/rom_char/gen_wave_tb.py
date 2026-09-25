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

The MODEL is read from $ROM_OUT_DIR/verilog/<macro>.v and stays there:
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
// Timing below is MEASURED ({corner} corner, via {macro}.v):
//     access {access} ns / precharge {t_pre} ns / setup {setup} ns
// The cycle built from it:
//     low phase  = {t_pre} * PRE_MARGIN
//     high phase = {access} * EVAL_MARGIN
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
//     xvlog -sv output/verilog/{macro}.v tests/wave/tb_{macro}_wave.v
//     xelab -debug typical tb_{macro}_wave -s tb_{macro}_wave_sim
//     xsim tb_{macro}_wave_sim -tclbatch tests/wave/tb_{macro}_wave.tcl
//     xsim --gui tb_{macro}_wave_sim.wdb
// -debug typical is not optional: without it nothing is logged and the wave
// window is empty.
//
// VIVADO GUI: add {macro}.v and this file to a simulation fileset, set
// tb_{macro}_wave as the simulation top, Run Behavioral Simulation. Set
// `phase` to ASCII radix and addr0 to unsigned once the window is up.
//
// iverilog, for the same waves without Vivado:
//     iverilog -g2012 -o /tmp/{macro}_wave.vvp \\
//              output/verilog/{macro}.v tests/wave/tb_{macro}_wave.v
//     vvp /tmp/{macro}_wave.vvp && gtkwave tb_{macro}_wave.vcd
// ---------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_{macro}_wave;

  // ---- what the run covers ------------------------------------------------
  parameter integer START_ADDR = {start};
  parameter integer N_READS    = {reads};

  // Margins on the MEASURED minimums. 1.0 would sit exactly on the constraint
  // and a wave viewer cannot show you whether you are on the right side of an
  // equality, so they are deliberately above it.
  parameter real PRE_MARGIN  = 1.50;   // low  phase = T_PRE_NS  * this
  parameter real EVAL_MARGIN = 1.30;   // high phase = ACCESS_NS * this

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

  localparam real T_PRE  = {t_pre};
  localparam real ACCESS = {access};
  localparam real SETUP  = {setup};
  localparam real T_LOW  = T_PRE  * PRE_MARGIN;
  localparam real T_HIGH = ACCESS * EVAL_MARGIN;

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
  reg  [8*9:1]         phase    = "IDLE";
  integer              read_idx = 0;
  integer              errors   = 0;

  always @(*) expected = dut.mem[addr0];

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
    cs0 = 1'b1;

    for (i = 0; i < N_READS; i = i + 1) begin
      read_idx = i;
      addr0    = (START_ADDR + i) % DEPTH;

      // SETUP: the address is placed, then the edge -- never together. The
      // wait is far longer than SETUP_NS so the separation is visible.
      phase = "PRECHARGE";
      #(T_LOW);

      clk0  = 1'b1;
      phase = "EVALUATE";
      // dout0 is NOT the data yet; the bitlines are still discharging.
      #(ACCESS);
      phase = "VALID";
      #(T_HIGH - ACCESS);

      // CAPTURE, at the point a real consumer would: just before the fall,
      // with the address and cs0 still held. After the fall there is nothing
      // left to capture -- precharge erases it.
      dout_cap = dout0;
      mismatch = (dout0 !== expected);
      if (mismatch) begin
        errors = errors + 1;
        $display("MISMATCH %0t: addr %0d -> dout0 %h, .bin says %h",
                 $time, addr0, dout0, expected);
      end
      $display("%8t  addr %4d  dout %h", $time, addr0, dout0);

      clk0  = 1'b0;
      phase = "PRECHARGE";
      #(1.0);
      mismatch = 1'b0;
      #(T_LOW - 1.0);
    end

    // Tail: one deselected cycle. cs0 low keeps the precharge on through the
    // whole high phase, so dout0 stays at all ones with clk0 toggling -- the
    // shape to recognise when a read "returns 0xFF...F for no reason".
    phase = "IDLE";
    cs0   = 1'b0;
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
#   xvlog -sv output/verilog/{macro}.v tests/wave/tb_{macro}_wave.v
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
        period = info["t_pre"] * 1.50 + info["access"] * 1.30

        tb = TB_TEMPLATE.format(
            macro=macro, sig=SIGNATURE, corner=info["corner"],
            access="%.4f" % info["access"], t_pre="%.4f" % info["t_pre"],
            setup="%.4f" % info["setup"], period_ns="%.1f" % period,
            width=info["width"], addr_bits=info["addr_bits"],
            depth=info["depth"], amsb=info["addr_bits"] - 1,
            dmsb=info["width"] - 1, init=init,
            start=args.start, reads=reads)

        tb_path = os.path.join(outdir, "tb_%s_wave.v" % macro)
        open(tb_path, "w").write(tb)
        tcl_path = os.path.join(outdir, "tb_%s_wave.tcl" % macro)
        open(tcl_path, "w").write(TCL_TEMPLATE.format(macro=macro, sig=SIGNATURE))

        print("%-7s written: %s  (%d reads from %d, cycle ~%.1f ns, %s)"
              % (macro, os.path.relpath(tb_path, REPO), reads, args.start,
                 period, info["corner"]))
        if words:
            print("%-7s          %s  (%d x %d bit, %s-endian)"
                  % ("", os.path.relpath(mem_path, REPO), words,
                     info["width"], args.endian))

    return rc


if __name__ == "__main__":
    sys.exit(main())
