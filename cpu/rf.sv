// 16 bit X 8 register file, 1 Write port, 2 Read ports
module rf (
  
  input clk, reset, wr_en,
  input [15:0] wr_port,

  input [2:0] wr_sel, rd_a_sel, rd_b_sel,
  input write_rf_bool,

  //input rd_stall,

  output reg [15:0] rd_a_port, rd_b_port

);

  wire [15:0] rd_a_port_buf, rd_b_port_buf;

  reg [2:0] wr_sel_buf, rd_a_sel_buf, rd_b_sel_buf;
  reg [15:0] wr_port_buf;

  mem_1w_1r_stall_param #(.FILE     (""),
                        .ADDR_WIDTH (3),
                        .DATA_WIDTH (16))
                  RF_P0(.clock      (clk),
                        //.rd_addressstall  (rd_stall),
                        .data       (wr_port),
                        .rdaddress  (rd_a_sel),
                        .wraddress  (wr_sel),
                        .wren       (wr_en),
                        .q          (rd_a_port_buf),
                        .reset      (reset));

  mem_1w_1r_stall_param #(.FILE     (""),
                        .ADDR_WIDTH (3),
                        .DATA_WIDTH (16))
                  RF_P1(.clock      (clk),
                        //.rd_addressstall  (rd_stall),
                        .data       (wr_port),
                        .rdaddress  (rd_b_sel),
                        .wraddress  (wr_sel),
                        .wren       (wr_en),
                        .q          (rd_b_port_buf),
                        .reset      (reset));

  // Forwarding registers
  always @(posedge clk) begin

    if (write_rf_bool == 1'b1) begin
      wr_sel_buf <= wr_sel;
      wr_port_buf <= wr_port;
    end
    
    //if (!rd_stall) begin
    rd_a_sel_buf <= rd_a_sel;
    rd_b_sel_buf <= rd_b_sel;
    //end

  end
  
  // split a and b into two always blocks ^^^

  // Read port and write forwarding logic
  always @ (*) begin
    
    //if (rd_a_sel_buf == wr_sel_buf)
    //    rd_a_port = wr_port_buf;
    //else
        rd_a_port = rd_a_port_buf;
    
    //if (rd_b_sel_buf == wr_sel_buf)
    //    rd_b_port = wr_port_buf;
    //else
        rd_b_port = rd_b_port_buf;
    
  end

endmodule
