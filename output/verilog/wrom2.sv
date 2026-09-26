// OpenROM ROM model
// Words: 1064
// Word size: 32
// Word per Row: 8
// Data Type: bin
// Data File: rom_configs/wrom2.bin
//
// ^^^ THE SIX LINES ABOVE ARE KEPT IN OpenRAM FORMAT -- DO NOT DELETE THEM.
// Both this script (read_geometry) and the .bin converters in simulation
// flows read the word width from the "// Word size:" line. Without it a
// converter typically falls back to 8 bits and loads only the low 8 bits of
// every word -- the ROM contents then come out SILENTLY wrong.
// ---------------------------------------------------------------------------
// wrom2 -- REAL BEHAVIOURAL MODEL -- gen_macro_behavioral_v.py
//
// This file is a DELIVERABLE generated from measurements; it is written to
// the repository's output/verilog directory, not into the macro directory,
// so a later OpenRAM run cannot overwrite it. To regenerate:
//     python3 scripts/rom_char/gen_macro_behavioral_v.py wrom2
//
// WHY OpenRAM'S OWN MODEL IS NOT USED
// -----------------------------------
// The model OpenRAM generates comes from the SRAM template and assumes:
//     "All inputs are registers"                  -> address latched inside
//     always @(negedge clk0) dout0 <= mem[...]     -> data holds for the cycle
// BOTH ARE FALSE. This macro's extracted cell inventory (wrom2/*.ext) has no
// dff / latch / sense_amp / replica_column / delay_chain at all; the read
// element is a plain inverter (rom_bitline_inverter). The same OpenRAM's SRAM
// does contain row_addr_dff, col_addr_dff, data_dff, sense_amp,
// replica_column and delay_chain -- those assumptions hold THERE, not here.
//
// REAL BEHAVIOUR (values MEASURED with ngspice, from wrom2's own .lib)
// ---------------------------------------------------------------------------
//   clk0 = 0 : PRECHARGE. The bitlines are pulled to VDD -> dout0 = all ones.
//              This phase must last at least T_PRE_NS.
//   clk0 = 1 : EVALUATE. The "0" bits of the selected row discharge their
//              bitline through 91 series NMOS (worst column 236).
//              dout0 becomes valid ACCESS_NS after the rising edge.
//   clk0 1->0: precharge restarts and THE DATA IS ERASED -- but not at the
//              edge. The precharge PMOS takes T_FALL_NS to pull the bitlines
//              back to VDD, which is the .lib's falling_edge arc on dout0 and
//              is exactly the window a consumer capturing on that edge lives
//              in. Erasing at the edge instead would make this model and the
//              library disagree by a whole arc.
//   cs0  = 0 : precharge stays on; the bitlines sit at VDD, dout0 = all ones.
//              (Netlist: NAND(CS,clk) -> inverter chain -> prechrg, and the
//              precharge PMOS conducts while its gate is low, i.e.
//              prechrg = CS AND clk. Confirmed from the merge chain in
//              wrom2_rom_control_logic.ext.)
//
//   IRREVERSIBLE DISCHARGE: every device in the array is an NMOS; the only
//   PMOS in the macro is in the precharge cell. Outside precharge a bitline
//   has NO pull-up. If the address changes during evaluate, the bitlines the
//   old row discharged STAY discharged and the new row can only discharge
//   MORE of them -- the result is the bit-wise AND of every row selected
//   during that evaluate phase. Ones do not come back.
//
// GEOMETRY : 1064 words x 32 bit, words_per_row 8
//            11 address bits, 134 rows x 256 columns
// TIMING   : SS_1p6V_100C corner (the worst one). Source: wrom2_SS_1p6V_100C.lib
//
// SIMULATION ONLY. Not synthesizable; the ASIC flow reads wrom2_bbox.v.
//
// The extension is .sv because this file IS SystemVerilog -- the late-address
// corruption below needs fork/join_none. Handed to a tool as .v it is parsed
// as Verilog-2001, join_none is not a keyword there, and what gets reported
// is a syntax error on the following `end`. In Vivado, if the file must keep
// a .v name: set_property file_type SystemVerilog [get_files wrom2.v].
// ---------------------------------------------------------------------------
`timescale 1ns / 1ps

module wrom2 (
`ifdef USE_POWER_PINS
    inout  vccd1,
    inout  vssd1,
`endif
    input  wire        clk0,
    input  wire        cs0,
    input  wire [10:0] addr0,
    output wire [31:0] dout0
  );

  parameter DEPTH     = 1064;
  parameter WIDTH     = 32;
  parameter INIT_FILE = "rom_configs/wrom2.bin";

  // MEASURED values -- wrom2_SS_1p6V_100C.lib
  parameter real ACCESS_NS = 44.3104;   // clk0 rising -> dout0 valid
  parameter real T_PRE_NS  = 13.6668;   // minimum clk0 low phase
  parameter real SETUP_NS  = 0.0480;   // addr0/cs0 stable before clk0 rises
  // HOLD is not one number. The address may move once the bitline is past the
  // inverter's trip point -- the read is decided there and the back-end delay
  // after it does not depend on the address -- so HOLD_NS is SHORTER than
  // access. cs0 gets no such relief: it gates the precharge, so losing it
  // turns the precharge PMOS back on and destroys the read at ANY point in
  // the cycle, including the part the address is excused from.
  parameter real HOLD_NS    = 39.2514;   // addr0 stable after clk0 rises
  parameter real HOLD_CS_NS = 44.3104;   // cs0 stable after clk0 rises

  // The shortest LEGAL evaluate phase, from the .lib's min_pulse_width(rise).
  // It is deliberately LONGER than ACCESS_NS: characterisation puts an
  // analytic guard band on top of the measured delay. A high phase between
  // the two hands this model valid data and still fails timing closure
  // against the library, so the phase is checked against the library's
  // number rather than against the model's own access.
  parameter real MPW_HIGH_NS = 45.2354;   // minimum clk0 high phase
  // The .lib's falling_edge arc on dout0. The precharge PMOS has to charge
  // the bitline back up; until it has, dout0 still carries the read.
  parameter real T_FALL_NS   = 3.4380;   // clk0 falling -> dout0 back at VDD

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
  // REAL, not `time`. `time` is an integer in units of the timescale, so
  // with `timescale 1ns/1ps every stamp taken through $time rounds to a whole
  // nanosecond -- and the constraints this model checks are not whole
  // nanoseconds. SETUP_NS is 0.048 ns and the gap between access and the
  // .lib's minimum high pulse is under 1 ns; quantised to 1 ns both checks
  // are noise. $realtime carries the timescale's precision (1 ps here).
  real            t_eval, t_fall, t_addr_chg;

  // dout0 is driven from here rather than straight off `bl`, because the two
  // directions have different delays: becoming valid is timed by ACCESS_NS
  // from the rising edge, going back to all ones by T_FALL_NS from the
  // falling one. A single continuous assignment cannot say both.
  reg [WIDTH-1:0] dout_r;

  initial begin
    bl         = {WIDTH{1'b1}};
    late_row   = {WIDTH{1'b1}};
    dout_r     = {WIDTH{1'b1}};
    evaluating = 1'b0;
    ready      = 1'b0;
    t_eval     = 0;
    t_fall     = 0;
    t_addr_chg = 0;
  end

  always @(addr0) t_addr_chg = $realtime;

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
      $display("ERROR %.3f ns %m: cs0 HOLD violation -- deselected %.3f ns after clk0 rose, with the evaluate phase still open. cs0 must reach clk0's FALLING edge (the capture point): the precharge PMOS turns back on and the read is lost, valid or not. hold_rising is %.3f ns, but the real deadline is the falling edge.",
               $realtime, $realtime - t_eval, HOLD_CS_NS);
    // IF THE EVALUATE PHASE IS SHORTER THAN ACCESS the data never becomes
    // valid and dout0 stays at its precharge value (all ones). That is a
    // SILENT failure -- the output looks plausible, it is just always 0xFF --
    // so it is reported explicitly.
    if (REPORT && evaluating && !ready)
      $display("ERROR %.3f ns %m: evaluate phase SHORTER than access -- high phase %.3f ns, need %.3f ns. dout0 never became valid (stuck at the precharge value).",
               $realtime, $realtime - t_eval, ACCESS_NS);
    // Long enough to read, too short for the library. The data is good here
    // and the macro still does not close timing: the .lib's minimum high
    // phase carries a guard band the model has no way to reproduce, so the
    // only honest thing the model can do is say so.
    else if (REPORT && evaluating && ($realtime - t_eval) < MPW_HIGH_NS)
      $display("WARNING %.3f ns %m: clk0 min_pulse_width(rise) violation -- high phase %.3f ns, the .lib requires %.3f ns. dout0 did become valid, because access is only %.3f ns; the remaining %.3f ns is the characterisation guard band. Timing closure against the .lib will fail even though this simulation reads correctly.",
               $realtime, $realtime - t_eval, MPW_HIGH_NS, ACCESS_NS,
               MPW_HIGH_NS - ACCESS_NS);
    evaluating = 1'b0;
    ready      = 1'b0;
    bl         = {WIDTH{1'b1}};
    late_row   = {WIDTH{1'b1}};
    t_fall     = $realtime;
  end

  // --- EVALUATE ------------------------------------------------------------
  always @(posedge clk0) begin
    if (cs0 === 1'b1) begin
      if (REPORT && t_fall > 0 && ($realtime - t_fall) < T_PRE_NS)
        $display("ERROR %.3f ns %m: precharge phase TOO SHORT (%.3f ns, need %.3f ns) -- the bitlines did not fully recharge",
                 $realtime, $realtime - t_fall, T_PRE_NS);
      if (REPORT && t_addr_chg > 0 && ($realtime - t_addr_chg) < SETUP_NS)
        $display("ERROR %.3f ns %m: addr0 SETUP violation (address changed at %.3f ns, need %.3f ns) -- the wrong wordline may open",
                 $realtime, t_addr_chg, SETUP_NS);

      t_eval     = $realtime;
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
      if (($realtime - t_eval) < HOLD_NS) begin
        if (REPORT)
          $display("ERROR %.3f ns %m: addr0 HOLD violation -- changed %.3f ns after clk0 rose, need %.3f ns. The bitlines are permanently corrupted; the read becomes the AND of the rows.",
                   $realtime, $realtime - t_eval, HOLD_NS);
        bl = bl & mem[addr0];
      end else begin
        // Accumulated rather than overwritten: the corruption is monotonic
        // (bits only clear), so if two late changes overlap, applying the
        // combined mask at the earlier deadline is the pessimistic order.
        late_row = late_row & mem[addr0];
        fork
          begin
            #(ACCESS_NS);
            // Only if THE SAME phase is still open. `evaluating` alone does
            // not ask that: the wait above is a whole access time, and a
            // cycle whose high phase is shorter than that ends, precharges
            // and starts the NEXT evaluate before this block wakes up. It
            // would then find evaluating high again and report a corruption
            // against a read it has nothing to do with -- harmless, since
            // the precharge reset late_row to all ones on the way past, and
            // therefore a pure false alarm in the log, which is worse than a
            // real one: it teaches the reader to ignore the message.
            //
            // t_eval is stamped once per rising edge, so the phase this block
            // belongs to is the one that started BEFORE the address moved.
            // ($realtime - ACCESS_NS is that moment.) No per-invocation state
            // is needed to ask it, which matters because several of these can
            // be in flight at once and `automatic` inside fork is not
            // universally supported.
            if (evaluating && clk0 === 1'b1 && cs0 === 1'b1
                && t_eval < ($realtime - ACCESS_NS)) begin
              if (REPORT)
                $display("ERROR %.3f ns %m: dout0 CORRUPTED by a late address change -- the change at %.3f ns was past the %.3f ns hold window, so the read in flight survived, but the new row has been discharging ever since and the evaluate phase is still open. dout0 is now the AND of the rows.",
                         $realtime, $realtime - ACCESS_NS, HOLD_NS);
              bl = bl & late_row;
            end
          end
        join_none
      end
    end
  end

  // --- OUTPUT --------------------------------------------------------------
  // While precharged, and before access has elapsed, the bitlines are at VDD.
  //
  // Live read: dout_r follows the bitlines with no delay of its own -- the
  // delay is already in `ready`, which the evaluate block sets ACCESS_NS
  // after the rising edge. `bl` can still move after that (a late address
  // change discharges more bits) and dout0 has to follow it, so this cannot
  // be a one-shot capture.
  always @(*) if (ready) dout_r = bl;

  // Invalidation: T_FALL_NS after clk0 falls, NOT at the edge. This is the
  // .lib's falling_edge arc, and it is the reason a consumer is allowed to
  // capture on the falling edge at all. The evaluate state (`ready`, `bl`)
  // is torn down at the edge by the precharge block above -- that is the
  // array; this is the pin catching up with it.
  always @(negedge clk0 or negedge cs0)
    #(T_FALL_NS) dout_r = {WIDTH{1'b1}};

  assign dout0 = dout_r;

endmodule
