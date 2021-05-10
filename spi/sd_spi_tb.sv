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

class RandT;
  rand reg [7:0] data;
endclass

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

  // Comparison Memory
  reg [7:0] mem [0:511];

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
    req       = 1'b0; wr_req    = 1'b0;
    data_send = 8'h0;

  end

  always begin
    #5 clk = ~clk;
  end

  integer i;

  RandT rand_val = new();

  initial begin

    $dumpfile ("sd_spi_tb.vcd");
    $dumpvars (0, sd_spi_tb);

    #5000

    // Wait for Initialization
    do begin

    @ (posedge clk);
    #1;
    addr_req  = 16'h04;
    req       = 1'b1;
    wr_req    = 1'b0;
    data_send = 16'h00;
    @ (posedge ack);
    @ (posedge complete);

    end while (data_reciv != 16'h0);
    #1;
    req       = 1'b0;
    @ (posedge clk);

    // Send Bytes to WR Buffer
    for (i = 0; i < 512; i = i + 1) begin
      
      rand_val.randomize();

      mem[i] <= rand_val.data;
      @ (posedge clk);
      #1;
      addr_req  = 16'h00;   // WR Buffer Address
      req       = 1'b1;
      wr_req    = 1'b1;
      data_send = {8'h0, rand_val.data};
      @ (posedge ack);
      #1;
      req       = 1'b0;
      @ (posedge complete);


    end

    // Send WR Command
    @ (posedge clk);
    #1;
    addr_req  = 16'h03;
    req       = 1'b1;
    wr_req    = 1'b1;
    data_send = 16'h01;
    @ (posedge ack);
    #1;
    req       = 1'b0;
    @ (posedge complete);

    // Wait for Ready
    do begin

    @ (posedge clk);
    #1;
    addr_req  = 16'h04;
    req       = 1'b1;
    wr_req    = 1'b0;
    data_send = 16'h00;
    @ (posedge ack);
    @ (posedge complete);

    end while (data_reciv != 16'h0);
    #1;
    req       = 1'b0;
    @ (posedge clk);

    // Send RD Command
    @ (posedge clk);
    #1;
    addr_req  = 16'h03;
    req       = 1'b1;
    wr_req    = 1'b1;
    data_send = 16'h02;
    @ (posedge ack);
    #1;
    req       = 1'b0;
    @ (posedge complete);

    // Wait for Ready
    do begin

    @ (posedge clk);
    #1;
    addr_req  = 16'h04;
    req       = 1'b1;
    wr_req    = 1'b0;
    data_send = 16'h00;
    @ (posedge ack);
    @ (posedge complete);

    end while (data_reciv != 16'h0);
    #1;
    req       = 1'b0;
    @ (posedge clk);

      @ (posedge clk);
      #1;
      addr_req  = 16'h01;   // RD Buffer Address
      req       = 1'b1;
      wr_req    = 1'b0;
      data_send = i;
      @ (posedge ack);
      #1;
      req       = 1'b0;
      @ (posedge complete);

    // Compare Memory
    for (i = 2; i < 512; i = i + 1) begin

      @ (posedge clk);
      #1;
      addr_req  = 16'h01;   // RD Buffer Address
      req       = 1'b1;
      wr_req    = 1'b0;
      data_send = i;
      @ (posedge ack);
      #1;
      req       = 1'b0;
      @ (posedge complete);

      if (mem[i-1] != data_reciv) begin
        $display("Returned: %h", data_reciv);
        $display("Should be: %h", mem[i-1]);
      end else begin
        $display("Returned Correct Value: %h", data_reciv);
      end


    end

    $finish;

  end


endmodule
