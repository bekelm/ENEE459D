// Parameterised Simple Dual Port RAM with address stall
// Reads old value
module mem_1w_1r_stall_param (

  input clock,
  input [(DATA_WIDTH-1):0] data,
  input [(ADDR_WIDTH-1):0] rdaddress, wraddress,
  input wren,
  //input rd_addressstall,
  output reg [(DATA_WIDTH-1):0] q,
  input reset

);

  parameter FILE = "";
  parameter ADDR_WIDTH = 3;
  parameter DATA_WIDTH = 16;

  reg [(ADDR_WIDTH-1):0] rdaddress_buf;
  reg [(ADDR_WIDTH-1):0] rdaddress_in;

  // Declare the RAM variable
  reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

  integer i;

  initial begin

    if (FILE != "") begin

      $readmemb(FILE, ram);
      
    end else begin
      
      for (i = 0; i < 2**ADDR_WIDTH-1; i = i + 1)
        ram[i] <= 0;

    end

    // NOTE: Add `ifdef SIMULATE to remove initial undefined values
    // q <= 0;

  end

  // RD Port address stall buffer
  always @(*) begin
    
   // if (rd_addressstall)
   //   rdaddress_in = rdaddress_buf;
   // else
    rdaddress_in = rdaddress;

  end

  always @ (posedge clock) begin
    
    //if (!rd_addressstall)
    rdaddress_buf <= rdaddress;

  end


  // Read Port
  always @ (posedge clock) begin
    q <= ram[rdaddress_in];
  end

  // Write port
  always @ (posedge clock) begin
    if (reset == 1'b1) begin
      ram[0] <= 0;
      ram[1] <= 0;
      ram[2] <= 0;
      ram[3] <= 0;
      ram[4] <= 0;
      ram[5] <= 0;
      ram[6] <= 0;
      ram[7] <= 0;
    end
    else if (wren) begin
      ram[wraddress] <= data;
      ram[0] <= 0;
    end
  end

endmodule
