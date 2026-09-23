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

    access   <- the largest cell_rise on the rising_edge arc of dout0
                (the banner "TOTAL (worst load)" is a cross-check only)
    t_pre    <- min_pulse_width fall_constraint
    setup    <- first setup_rising value
    hold     <- hold_rising inside bus(addr0)   -- the ADDRESS hold
    hold_cs  <- hold_rising inside pin(cs0)     -- NOT the same number

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


def _cell_rise_max(txt):
    """Worst cell_rise on the rising_edge arc of dout0, in ns.

    That IS the access time: the largest entry of the CELL_TABLE (slowest
    clk0 edge, heaviest output load). It is read from the DATA the tool
    reads, not from the banner comment above it -- the banner is prose and
    rewording it must not change this model.
    """
    best = None
    for m in re.finditer(r"timing_type\s*:\s*rising_edge\s*;", txt):
        tail = txt[m.end():m.end() + 4000]
        vm = re.search(r"cell_rise\s*\([^)]*\)\s*\{(.*?)\);", tail, re.S)
        if not vm:
            continue
        vals = [float(x) for x in
                re.findall(r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?", vm.group(1))]
        if vals:
            best = max(vals) if best is None else max(best, max(vals))
    return best


def read_lib_timing(lib_path):
    """Return (access, t_pre, setup) in ns; None for anything not found."""
    if not os.path.exists(lib_path):
        return None, None, None, None, None
    txt = open(lib_path).read()

    # access comes from the cell_rise table. The banner line the generator
    # prints above it says the same number, but a comment is documentation:
    # it is used only as a cross-check, and a disagreement is reported rather
    # than silently preferred either way.
    access = _cell_rise_max(txt)
    m = re.search(r"TOTAL \(worst load\)\s*:\s*([\d.]+)\s*ns", txt)
    banner = float(m.group(1)) if m else None
    if access is None:
        access = banner
        if banner is not None:
            print("WARNING: %s: no rising_edge cell_rise table -- access taken "
                  "from the banner comment" % os.path.basename(lib_path),
                  file=sys.stderr)
    elif banner is not None and abs(banner - access) > 1e-3:
        print("WARNING: %s: banner says access %.4f ns, the cell_rise table "
              "says %.4f ns -- using the table"
              % (os.path.basename(lib_path), banner, access), file=sys.stderr)

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

    # HOLD, once per pin GROUP -- addr0 and cs0 no longer carry the same
    # number and the model must not flatten them back together. The address
    # hold is measured (run_hold_bisect.sh, converted to the clk0 pin's frame
    # by run_addr2wl.sh) and is SHORTER than access; cs0 keeps the full access
    # window because it gates the precharge and its loss ends the read at any
    # point in the cycle. Each is read from inside its own container: the
    # first hold_rising after `bus(addr0)` belongs to the address, the first
    # after `pin(cs0)` to the chip select.
    def _hold_after(marker):
        i = txt.find(marker)
        if i < 0:
            return None
        mm = re.search(r"timing_type\s*:\s*hold_rising.*?values\(\"([\d.]+)",
                       txt[i:], re.S)
        return float(mm.group(1)) if mm else None

    hold = _hold_after("bus(addr0)")
    hold_cs = _hold_after("pin(cs0)")

    return access, t_pre, setup, hold, hold_cs


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
  // HOLD is not one number. The address may move once the bitline is past the
  // inverter's trip point -- the read is decided there and the back-end delay
  // after it does not depend on the address -- so HOLD_NS is SHORTER than
  // access. cs0 gets no such relief: it gates the precharge, so losing it
  // turns the precharge PMOS back on and destroys the read at ANY point in
  // the cycle, including the part the address is excused from.
  parameter real HOLD_NS    = {hold};   // addr0 stable after clk0 rises
  parameter real HOLD_CS_NS = {hold_cs};   // cs0 stable after clk0 rises

  // 1 = report violations with $display. The corruption is applied either way
  // -- that is what silicon does; the test is expected to catch the bad result.
  parameter REPORT = 1;

  reg [WIDTH-1:0] mem [0:DEPTH-1];

  initial begin
    if (INIT_FILE != "") $readmemb(INIT_FILE, mem);
  end

  // Bitline state: all ones while precharged, only 1 -> 0 during evaluate.
  reg [WIDTH-1:0] bl;
  reg [WIDTH-1:0] late_row;    // mask owed by address changes past the hold window
  reg             evaluating;
  reg             ready;        // has the access time elapsed?
  time            t_eval, t_fall, t_addr_chg;

  initial begin
    bl         = {{WIDTH{{1'b1}}}};
    late_row   = {{WIDTH{{1'b1}}}};
    evaluating = 1'b0;
    ready      = 1'b0;
    t_eval     = 0;
    t_fall     = 0;
    t_addr_chg = 0;
  end

  always @(addr0) t_addr_chg = $time;

  // --- PRECHARGE: clk0 low OR cs0 low --------------------------------------
  always @(negedge clk0 or negedge cs0) begin
    // cs0 HOLD. Unlike the address, cs0 has NO window in which it is free --
    // not a longer one, none at all. Dropping it re-opens the precharge PMOS,
    // and the bitline is the only place this macro keeps a read (there is no
    // latch anywhere in it), so the data is pulled back to VDD whether or not
    // it had become valid. The deadline is therefore not a duration after the
    // rising edge but an EVENT: clk0's fall, where the consumer captures. Any
    // deselection while the phase is open is a violation, and the .lib says
    // the same thing with hold_falling = 0 -- the only form of the statement
    // that survives a change of clock period.
    if (REPORT && evaluating && clk0 === 1'b1 && cs0 !== 1'b1)
      $display("ERROR %0t %m: cs0 HOLD violation -- deselected %0t after clk0 rose, with the evaluate phase still open. cs0 must reach clk0's FALLING edge (the capture point): the precharge PMOS turns back on and the read is lost, valid or not. hold_rising is %.3f ns, but the real deadline is the falling edge.",
               $time, $time - t_eval, HOLD_CS_NS);
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
    late_row   = {{WIDTH{{1'b1}}}};
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
  // There are TWO distinct things a mid-evaluate address change does, and
  // they have different deadlines. Getting this block to say only one of them
  // is how it was wrong twice in a row.
  //
  //   INSIDE the hold window: the read is destroyed before it was ever valid.
  //     The bitline had not yet driven bl_b to a logic level, so the new row's
  //     conduction pattern lands on top of the old one and dout0 comes out as
  //     the AND. Not recoverable -- a decoder node does not come back until
  //     the next precharge.
  //
  //   PAST the hold window: the read ON ITS WAY survives. That is exactly what
  //     run_hold_bisect.sh established (its pass criterion is bl_b within 10%
  //     of the rail). But the PHASE does not survive, and that is NOT the same
  //     statement. The newly selected row's zeros start discharging their
  //     bitlines the moment the address moves, and outside precharge there is
  //     no pull-up anywhere in the array to undo it. So dout0 holds the
  //     correct value for about one more access time and then turns into the
  //     AND -- if the evaluate phase is still open by then. A model that
  //     ignored the late change would call the data good for an arbitrarily
  //     long high phase, which the silicon does not.
  //
  // The delay applied is ACCESS_NS. The real path is addr0 -> wordline ->
  // bitline -> dout0, which is slightly LONGER than access (access starts at
  // clk0, whose front-end term is shorter than addr0 -> wordline), so the
  // model corrupts slightly EARLY: the safe direction for a check.
  //
  // SIMPLIFICATION, stated rather than hidden: this treats every address bit
  // as a ROW bit. The low bits drive the column mux, and a column-only change
  // re-routes dout0 to other bitlines of the SAME row -- different data, but
  // not corrupt data, and it arrives in a mux delay rather than a discharge
  // time. Modelling it as the AND is pessimistic there, which is the direction
  // to be wrong in.
  always @(addr0) begin
    if (evaluating && cs0 === 1'b1 && clk0 === 1'b1) begin
      if (($time - t_eval) < HOLD_NS) begin
        if (REPORT)
          $display("ERROR %0t %m: addr0 HOLD violation -- changed %0t after clk0 rose, need %.3f ns. The bitlines are permanently corrupted; the read becomes the AND of the rows.",
                   $time, $time - t_eval, HOLD_NS);
        bl = bl & mem[addr0];
      end else begin
        // Accumulated rather than overwritten: the corruption is monotonic
        // (bits only clear), so if two late changes overlap, applying the
        // combined mask at the earlier deadline is the pessimistic order.
        late_row = late_row & mem[addr0];
        fork
          begin
            #(ACCESS_NS);
            // Only if the phase is still open. A precharge in between has
            // already restored the bitlines and there is nothing to corrupt.
            if (evaluating && clk0 === 1'b1 && cs0 === 1'b1) begin
              if (REPORT)
                $display("ERROR %0t %m: dout0 CORRUPTED by a late address change -- the change at %0t was past the %.3f ns hold window, so the read in flight survived, but the new row has been discharging ever since and the evaluate phase is still open. dout0 is now the AND of the rows.",
                         $time, $time - ACCESS_NS, HOLD_NS);
              bl = bl & late_row;
            end
          end
        join_none
      end
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
        access, t_pre, setup, hold, hold_cs = read_lib_timing(
            os.path.join(libdir, libname))
        words, width, addr_bits, wpr = read_geometry(mdir, macro)

        # A missing hold falls back to the full access window -- the rule the
        # library itself used before the measurement existed, and the safe
        # direction -- rather than skipping the macro, so an older .lib still
        # produces a model. It is announced, never silent.
        if access is not None:
            for _n, _v in (("addr0", hold), ("cs0", hold_cs)):
                if _v is None:
                    print("%-7s WARNING: no hold_rising for %s in %s -- the "
                          "model falls back to the full access window "
                          "(%.4f ns), which is the pessimistic direction."
                          % (macro, _n, libname, access), file=sys.stderr)
            if hold is None:
                hold = access
            if hold_cs is None:
                hold_cs = access
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
            access="%.4f" % access, t_pre="%.4f" % t_pre, setup="%.4f" % setup,
            hold="%.4f" % hold, hold_cs="%.4f" % hold_cs)

        path = os.path.join(outdir, macro + ".v")
        open(path, "w").write(out)
        print("%-7s written: %s  (access %.4f / t_pre %.4f / setup %.4f / "
              "hold %.4f addr, %.4f cs0 ns, %s)"
              % (macro, os.path.relpath(path, REPO), access, t_pre, setup,
                 hold, hold_cs, args.corner))

    return rc


if __name__ == "__main__":
    sys.exit(main())
