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
//   clk0 1->0: precharge restarts and THE DATA IS ERASED.
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
  parameter real ACCESS_NS = 46.4773;   // clk0 rising -> dout0 valid
  parameter real T_PRE_NS  = 12.3934;   // minimum clk0 low phase
  parameter real SETUP_NS  = 0.0519;   // addr0/cs0 stable before clk0 rises

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
    bl         = {WIDTH{1'b1}};
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
    bl         = {WIDTH{1'b1}};
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
  assign dout0 = ready ? bl : {WIDTH{1'b1}};

endmodule
