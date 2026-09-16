#!/usr/bin/env python3
"""Generate a `<macro>.v` that models each ROM macro's REAL behaviour.

WHY
---
The `<macro>.v` OpenRAM ships with the macro models the timing WRONGLY -- it
comes from the SRAM template:

    always @(posedge clk0) begin cs0_reg = cs0; addr0_reg = addr0; ... end
    always @(negedge clk0) if (cs0_reg) dout0 <= #(DELAY) mem[addr0_reg];
    // "All inputs are registers"  +  "FIXME: This delay is arbitrary"

Both assumptions are false here: (1) the inputs are not registered, (2) the
output is not registered. The macro's extracted cell inventory
(`<macro>/*.ext`) contains no dff, latch, sense_amp, replica_column or
delay_chain at all; the read element is a plain inverter. For comparison, the
same OpenRAM's SRAM contains row_addr_dff / col_addr_dff / data_dff /
sense_amp / replica_column / delay_chain -- the SRAM model's assumptions are
true THERE, not in the ROM.

The consequence: any simulation run against the OpenRAM model (gate-level
included) does NOT see the ROM's dynamic behaviour -- neither an address
changing in the middle of evaluate, nor the data disappearing when clk0 falls.

WHAT IT PRODUCES
----------------
One `<macro>.v` per macro in $ROM_OUT_DIR/verilog (default <repo>/output/
verilog), carrying that macro's own contents file and its own MEASURED timing.
Nothing is typed by hand; the values are read from the macro's own .lib files:

    access   <- "TOTAL (worst load)"          (the .lib header)
    t_pre    <- min_pulse_width fall_constraint
    setup    <- first setup_rising value

So after regenerating the .libs, rerunning this script is all it takes.

Usage:
    python3 gen_macro_behavioral_v.py                 # every macro in the tree
    python3 gen_macro_behavioral_v.py wrom0 wrom2     # selected macros
    python3 gen_macro_behavioral_v.py --corner TT_1p8V_25C
"""

import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rom_paths
REPO = rom_paths.ROOT

SIGNATURE = "REAL BEHAVIOURAL MODEL -- gen_macro_behavioral_v.py"

# Default corner: the worst one (SS), so the model stays pessimistic.
DEFAULT_CORNER = "SS_1p6V_100C"


def read_lib_timing(lib_path):
    """Return (access, t_pre, setup) in ns; None for anything not found."""
    if not os.path.exists(lib_path):
        return None, None, None
    txt = open(lib_path).read()

    access = None
    m = re.search(r"TOTAL \(worst load\)\s*:\s*([\d.]+)\s*ns", txt)
    if m:
        access = float(m.group(1))

    t_pre = None
    m = re.search(r'timing_type\s*:\s*"min_pulse_width".*?'
                  r'fall_constraint\(scalar\)\s*\{\s*values\("([\d.]+)"\)',
                  txt, re.S)
    if m:
        t_pre = float(m.group(1))

    setup = None
    m = re.search(r"timing_type\s*:\s*setup_rising.*?values\(\"([\d.]+)", txt, re.S)
    if m:
        setup = float(m.group(1))

    return access, t_pre, setup


def read_geometry(macro_dir, macro):
    """Return (words, width, addr_bits, wpr).

    GEOMETRY COMES FROM THE LEF AND THE .bin, never from a `<macro>.v` header:
    this script writes that file, so reading it back would be a self-locking
    loop (after one run there is no original header left to read). The LEF and
    the .bin are OpenRAM outputs and stay put.

        addr_bits, width <- LEF pin counts (PIN addr0[..], PIN dout0[..])
        words            <- .bin size / (width/8)   -- exact, integral
        wpr              <- comment only; columns / word width, from the netlist
    """
    lef = os.path.join(macro_dir, macro + ".lef")
    addr_bits = data_bits = 0
    if os.path.exists(lef):
        lt = open(lef).read()
        addr_bits = len(re.findall(r"^\s*PIN addr0\[", lt, re.M))
        data_bits = len(re.findall(r"^\s*PIN dout0\[", lt, re.M))

    words = 0
    binf = os.path.join(macro_dir, "rom_configs", macro + ".bin")
    if data_bits and os.path.exists(binf):
        words = os.path.getsize(binf) // (data_bits // 8)

    # words_per_row = column count / word width. The column count is taken from
    # the netlist (the same source as find_worst_column.py).
    wpr = 0
    try:
        from find_worst_column import analyse as _an
        _r = _an(os.path.join(macro_dir, macro + ".sp"))
        if _r and data_bits:
            wpr = _r[1] // data_bits
    except Exception:
        pass

    return words, data_bits, addr_bits, wpr


TEMPLATE = '''// OpenROM ROM model
// Words: {words}
// Word size: {width}
// Word per Row: {wpr}
// Data Type: bin
// Data File: rom_configs/{macro}.bin
//
// ^^^ THE SIX LINES ABOVE ARE KEPT IN OpenRAM FORMAT -- DO NOT DELETE THEM.
// Both this script (read_geometry) and the .bin converters in simulation
// flows read the word width from the "// Word size:" line. Without it a
// converter typically falls back to 8 bits and loads only the low 8 bits of
// every word -- the ROM contents then come out SILENTLY wrong.
// ---------------------------------------------------------------------------
// {macro} -- {sig}
//
// This file is a DELIVERABLE generated from measurements; it is written to
// the repository's output/verilog directory, not into the macro directory,
// so a later OpenRAM run cannot overwrite it. To regenerate:
//     python3 scripts/rom_char/gen_macro_behavioral_v.py {macro}
//
// WHY OpenRAM'S OWN MODEL IS NOT USED
// -----------------------------------
// The model OpenRAM generates comes from the SRAM template and assumes:
//     "All inputs are registers"                  -> address latched inside
//     always @(negedge clk0) dout0 <= mem[...]     -> data holds for the cycle
// BOTH ARE FALSE. This macro's extracted cell inventory ({macro}/*.ext) has no
// dff / latch / sense_amp / replica_column / delay_chain at all; the read
// element is a plain inverter (rom_bitline_inverter). The same OpenRAM's SRAM
// does contain row_addr_dff, col_addr_dff, data_dff, sense_amp,
// replica_column and delay_chain -- those assumptions hold THERE, not here.
//
// REAL BEHAVIOUR (values MEASURED with ngspice, from {macro}'s own .lib)
// ---------------------------------------------------------------------------
//   clk0 = 0 : PRECHARGE. The bitlines are pulled to VDD -> dout0 = all ones.
//              This phase must last at least T_PRE_NS.
//   clk0 = 1 : EVALUATE. The "0" bits of the selected row discharge their
//              bitline through {chain} series NMOS (worst column {wcol}).
//              dout0 becomes valid ACCESS_NS after the rising edge.
//   clk0 1->0: precharge restarts and THE DATA IS ERASED.
//   cs0  = 0 : precharge stays on; the bitlines sit at VDD, dout0 = all ones.
//              (Netlist: NAND(CS,clk) -> inverter chain -> prechrg, and the
//              precharge PMOS conducts while its gate is low, i.e.
//              prechrg = CS AND clk. Confirmed from the merge chain in
//              {macro}_rom_control_logic.ext.)
//
//   IRREVERSIBLE DISCHARGE: every device in the array is an NMOS; the only
//   PMOS in the macro is in the precharge cell. Outside precharge a bitline
//   has NO pull-up. If the address changes during evaluate, the bitlines the
//   old row discharged STAY discharged and the new row can only discharge
//   MORE of them -- the result is the bit-wise AND of every row selected
//   during that evaluate phase. Ones do not come back.
//
// GEOMETRY : {words} words x {width} bit, words_per_row {wpr}
//            {addr_bits} address bits, {rows} rows x {cols} columns
// TIMING   : {corner} corner (the worst one). Source: {libname}
//
// SIMULATION ONLY. Not synthesizable; the ASIC flow reads {macro}_bbox.v.
// ---------------------------------------------------------------------------
`timescale 1ns / 1ps

module {macro} (
`ifdef USE_POWER_PINS
    inout  vccd1,
    inout  vssd1,
`endif
    input  wire        clk0,
    input  wire        cs0,
    input  wire [{amsb}:0] addr0,
    output wire [{dmsb}:0] dout0
  );

  parameter DEPTH     = {words};
  parameter WIDTH     = {width};
  parameter INIT_FILE = "rom_configs/{macro}.bin";

  // MEASURED values -- {libname}
  parameter real ACCESS_NS = {access};   // clk0 rising -> dout0 valid
  parameter real T_PRE_NS  = {t_pre};   // minimum clk0 low phase
  parameter real SETUP_NS  = {setup};   // addr0/cs0 stable before clk0 rises

  // 1 = report violations with $display. The corruption is applied either way
  // -- that is what silicon does; the test is expected to catch the bad result.
  parameter REPORT = 1;

  reg [WIDTH-1:0] mem [0:DEPTH-1];

  initial begin
    if (INIT_FILE != "") $readmemb(INIT_FILE, mem);
  end

  // Bitline state: all ones while precharged, only 1 -> 0 during evaluate.
  reg [WIDTH-1:0] bl;
  reg             evaluating;
  reg             ready;        // has the access time elapsed?
  time            t_eval, t_fall, t_addr_chg;

  initial begin
    bl         = {{WIDTH{{1'b1}}}};
    evaluating = 1'b0;
    ready      = 1'b0;
    t_eval     = 0;
    t_fall     = 0;
    t_addr_chg = 0;
  end

  always @(addr0) t_addr_chg = $time;

  // --- PRECHARGE: clk0 low OR cs0 low --------------------------------------
  always @(negedge clk0 or negedge cs0) begin
    // IF THE EVALUATE PHASE IS SHORTER THAN ACCESS the data never becomes
    // valid and dout0 stays at its precharge value (all ones). That is a
    // SILENT failure -- the output looks plausible, it is just always 0xFF --
    // so it is reported explicitly.
    if (REPORT && evaluating && !ready)
      $display("ERROR %0t %m: evaluate phase SHORTER than access -- high phase %0t, need %.3f ns. dout0 never became valid (stuck at the precharge value).",
               $time, $time - t_eval, ACCESS_NS);
    evaluating = 1'b0;
    ready      = 1'b0;
    bl         = {{WIDTH{{1'b1}}}};
    t_fall     = $time;
  end

  // --- EVALUATE ------------------------------------------------------------
  always @(posedge clk0) begin
    if (cs0 === 1'b1) begin
      if (REPORT && t_fall > 0 && ($time - t_fall) < T_PRE_NS)
        $display("ERROR %0t %m: precharge phase TOO SHORT (%0t, need %.3f ns) -- the bitlines did not fully recharge",
                 $time, $time - t_fall, T_PRE_NS);
      if (REPORT && t_addr_chg > 0 && ($time - t_addr_chg) < SETUP_NS)
        $display("ERROR %0t %m: addr0 SETUP violation (address changed at %0t, need %.3f ns) -- the wrong wordline may open",
                 $time, t_addr_chg, SETUP_NS);

      t_eval     = $time;
      evaluating = 1'b1;
      bl         = bl & mem[addr0];

      // dout0 only becomes valid once access has elapsed. This block waits
      // ACCESS_NS; if the period is shorter than access the next edge is
      // missed -- which is a minimum_period violation and is reported above.
      #(ACCESS_NS);
      if (clk0 === 1'b1 && cs0 === 1'b1 && evaluating) ready = 1'b1;
    end
  end

  // --- ADDRESS CHANGING DURING EVALUATE ------------------------------------
  always @(addr0) begin
    if (evaluating && cs0 === 1'b1 && clk0 === 1'b1) begin
      if (REPORT)
        $display("ERROR %0t %m: addr0 changed DURING evaluate (clk0 rose at %0t) -- the bitlines are permanently corrupted, the read becomes the AND of the rows",
                 $time, t_eval);
      bl = bl & mem[addr0];
    end
  end

  // --- OUTPUT --------------------------------------------------------------
  // While precharged, and before access has elapsed, the bitlines are at VDD.
  assign dout0 = ready ? bl : {{WIDTH{{1'b1}}}};

endmodule
'''


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("macros", nargs="*",
                    help="default: every macro in the tree")
    ap.add_argument("--macros-dir", default=None,
                    help="macro tree (default: ROM_MACROS_DIR / <repo>/examples)")
    ap.add_argument("--lib-dir", default=None,
                    help="where the .lib files are (default: $ROM_OUT_DIR/lib)")
    ap.add_argument("--outdir", default=None,
                    help="output directory (default: $ROM_OUT_DIR/verilog)")
    ap.add_argument("--corner", default=DEFAULT_CORNER,
                    help="corner to take the timing from (default: %s)" % DEFAULT_CORNER)
    args = ap.parse_args()

    names = args.macros or rom_paths.discover(args.macros_dir)
    if not names:
        print("no macros found in %s" % rom_paths.macros_dir(args.macros_dir),
              file=sys.stderr)
        return 1

    libdir = args.lib_dir or rom_paths.lib_dir()
    outdir = args.outdir or rom_paths.verilog_dir()

    rc = 0
    for macro in names:
        mdir = rom_paths.macro_dir(macro, args.macros_dir)
        if not os.path.isdir(mdir):
            print("%-7s no such directory, skipped" % macro, file=sys.stderr)
            rc = 1
            continue

        libname = "%s_%s.lib" % (macro, args.corner)
        access, t_pre, setup = read_lib_timing(os.path.join(libdir, libname))
        words, width, addr_bits, wpr = read_geometry(mdir, macro)

        missing = [n for n, v in (("access", access), ("t_pre", t_pre), ("setup", setup))
                   if v is None]
        if missing:
            print("%-7s WARNING: could not read %s from %s -- the .lib may not "
                  "exist yet. SKIPPED."
                  % (macro, ",".join(missing), libname), file=sys.stderr)
            rc = 1
            continue
        if not (words and width and addr_bits):
            print("%-7s WARNING: could not read the geometry (.lef/.bin missing). "
                  "SKIPPED." % macro, file=sys.stderr)
            rc = 1
            continue

        # geometry from one source: rom_paths (netlist + LEF + config)
        g = rom_paths.geometry(macro, args.macros_dir)
        rows, cols, wcol, chain = g["rows"], g["cols"], g["worst_col"], g["chain"]

        out = TEMPLATE.format(
            macro=macro, sig=SIGNATURE, corner=args.corner, libname=libname,
            words=words, width=width, wpr=wpr, addr_bits=addr_bits,
            rows=rows, cols=cols, wcol=wcol, chain=chain,
            amsb=addr_bits - 1, dmsb=width - 1,
            access="%.4f" % access, t_pre="%.4f" % t_pre, setup="%.4f" % setup)

        path = os.path.join(outdir, macro + ".v")
        open(path, "w").write(out)
        print("%-7s written: %s  (access %.4f / t_pre %.4f / setup %.4f ns, %s)"
              % (macro, os.path.relpath(path, REPO), access, t_pre, setup, args.corner))

    return rc


if __name__ == "__main__":
    sys.exit(main())
