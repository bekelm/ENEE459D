interface apb_bus (input pclk);
  logic [7:0] paddr;
  logic       pwrite;
  //logic       psel;
  logic       penable;
  logic [7:0] prdata;
  logic       pready;
  logic [7:0] pwdata;
  logic       preset;
endinterface

interface spi_bus();
  logic       clk;
  logic       cs;
  logic       miso;
  logic       mosi;
endinterface

module sd_spi_tb();
  
  reg clk;

  apb_bus pbus(clk);
  spi_bus sbus();

  // Request Bridge Inputs
  reg [15:0] addr_req;
  reg req;
  reg wr_req;
  reg [15:0] data_send;
  wire [15:0] data_reciv;
  wire ack;
  wire complete;


  logic psel_spi;

  sd_spi   SDC   (.pbus       (pbus),
                  .psel       (psel_spi),
                  .sbus       (sbus));

  sd_sim   SDSIM (.sbus       (sbus),
                  .rst        (1'b0));


  apb_master MST (.addr_req   (addr_req),
                  .req        (req),
                  .wr_req     (wr_req),
                  .data_send  (data_send),
                  .data_reciv (data_reciv),
                  .ack        (ack),
                  .complete   (complete),
                  .pbus       (pbus),
                  .psel       (psel_spi));


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

    $dumpfile ("sd_spi_tb.vcd");
    $dumpvars (0, sd_spi_tb);

    #500000

    @ (posedge clk);
    #1;
    addr_req  = 16'h03;
    req       = 1'b1;
    wr_req    = 1'b1;
    data_send = 16'h01;
    @ (posedge ack);
    
    /*
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
    */

    #1000000

    //#1500000

    $finish;

  end


endmodule
