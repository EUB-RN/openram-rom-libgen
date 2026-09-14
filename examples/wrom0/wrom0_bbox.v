// OpenROM ROM model
// Words: 1064
// Word size: 32
// Word per Row: 10
// Data Type: bin
// Data File: rom_configs/wrom0.bin

module wrom0(
`ifdef USE_POWER_PINS
    vccd1,
    vssd1,
`endif
// Port 0: R
    clk0,cs0,addr0,dout0
  );

  parameter DATA_WIDTH = 32 ;
  parameter ADDR_WIDTH = 11 ;
  parameter ROM_DEPTH = 1 << ADDR_WIDTH;
  // FIXME: This delay is arbitrary.
  parameter DELAY = 3 ;
  parameter VERBOSE = 1 ; //Set to 0 to only display warnings
  parameter T_HOLD = 1 ; //Delay to hold dout value after posedge. Value is arbitrary

`ifdef USE_POWER_PINS
    inout vccd1;
    inout vssd1;
`endif
  input  clk0; // clock
  input   cs0; // active high chip select
  input [ADDR_WIDTH-1:0]  addr0;
  output [DATA_WIDTH-1:0] dout0;


endmodule
