// Parameterised Simple Dual Port RAM with address stall
// Reads old value
module mem_1w_1r_stall_param (

  input clock,
  input [(DATA_WIDTH-1):0] data,
  input [(ADDR_WIDTH-1):0] rdaddress, wraddress,
  input wren,
  //input rd_addressstall,
  output reg [(DATA_WIDTH-1):0] q

);

  parameter FILE = "";
  parameter ADDR_WIDTH = 4;
  parameter DATA_WIDTH = 8;

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
    if (wren) begin
      ram[wraddress] <= data;
    end
  end

endmodule
