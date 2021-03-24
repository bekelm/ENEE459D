interface apb_bus (input pclk);
  logic [7:0] paddr;
  logic       pwrite;
  logic       psel;
  logic       penable;
  logic [7:0] prdata;
  logic       pready;
  logic [7:0] pwdata;
endinterface

module apb_master_tb();
  
  reg clk;

  apb_bus pbus(clk);

  // Request Bridge Inputs
  reg [7:0] addr_req;
  reg req;
  reg wr_req;
  reg [7:0] data_send;
  wire [7:0] data_reciv;
  wire ack;
  wire complete;


  apb_slave     #(.WAIT_STATES(0))  // Number of peripheral wait states
            SLV  (.bus        (pbus));

  apb_master MST (.addr_req   (addr_req),
                  .req        (req),
                  .wr_req     (wr_req),
                  .data_send  (data_send),
                  .data_reciv (data_reciv),
                  .ack        (ack),
                  .complete   (complete),
                  .pbus       (pbus));

  initial begin
    
    clk = 1'b0;

    addr_req  = 8'h0;
    req       = 1'b0;
    wr_req    = 1'b0;
    data_send = 8'h0;

  end

  always begin
    #5 clk = ~clk;
  end

  initial begin

    $dumpfile ("apb_master_tb.vcd");
    $dumpvars (0, apb_master_tb);
    
    @ (posedge clk);
    #1;
    addr_req  = 8'h0A;
    req       = 1'b1;
    wr_req    = 1'b1;
    data_send = 8'hF1;
    @ (posedge ack);
    #1;
    addr_req  = 8'h0A;
    req       = 1'b1;
    wr_req    = 1'b0;
    data_send = 8'h0;
    @ (posedge ack);
    #1;
    req       = 1'b0;
    @ (posedge clk);
    @ (posedge clk);
    @ (posedge clk);
    @ (posedge clk);

    #80

    $finish;

  end


endmodule
