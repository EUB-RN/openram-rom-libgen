// OpenROM ROM model
// Words: 64
// Word size: 32
// Word per Row: 8
// Data Type: bin
// Data File: rom_configs/rom_256b.bin

module rom_256b(
`ifdef USE_POWER_PINS
    vccd1,
    vssd1,
`endif
// Port 0: R
    clk0,cs0,addr0,dout0
  );

  parameter DATA_WIDTH = 32 ;
  parameter ADDR_WIDTH = 6 ;
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

  reg [DATA_WIDTH-1:0]    mem [0:ROM_DEPTH-1];

  initial begin
    $readmemb("rom_configs/rom_256b.bin",mem,0,ROM_DEPTH-1);
  end

  reg  cs0_reg;
  reg [ADDR_WIDTH-1:0]  addr0_reg;
  reg [DATA_WIDTH-1:0]  dout0;

  // All inputs are registers
  always @(posedge clk0)
  begin
    cs0_reg = cs0;
    addr0_reg = addr0;
    #(T_HOLD) dout0 = 32'bx;
    if ( cs0_reg && VERBOSE ) 
      $display($time," Reading %m addr0=%b dout0=%b",addr0_reg,mem[addr0_reg]);
  end


  // Memory Read Block Port 0
  // Read Operation : When cs0 = 1
  always @ (negedge clk0)
  begin : MEM_READ0
    if (cs0_reg)
       dout0 <= #(DELAY) mem[addr0_reg];
  end

endmodule
