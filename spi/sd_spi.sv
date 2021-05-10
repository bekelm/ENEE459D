// SPI SD Card Module
module sd_spi (

  apb_bus pbus,   // APB Bus
  input psel,
  spi_bus sbus    // SPI Bus

);

  // SD Registers
  logic [15:0] ctrl_reg;  // Command Reg
  //logic [15:0] status_reg;
  logic [15:0] addr_reg;

  // LD/ST buffers/Queues
  reg [7:0] ld_buf [511:0];
  reg [7:0] st_buf [511:0];

  // Wires
  logic [7:0] spi_data_in; 
  logic [7:0] spi_data_out; 

  logic [7:0] st_buf_out; 

  logic spi_val;
  logic spi_en;
  logic spi_we;

  logic busy_sdc;

  // APB Controller Signals
  logic [15:0] apb_data_out;
  logic ctrl_reg_ld;
  logic addr_reg_ld;
  logic ld_buf_deq;
  logic st_buf_enq;

  integer i = 0;
  initial begin
    
    for (i=0; i < 512; i = i + 1) begin
      
      st_buf[i] <= i;

    end

  end

  // SD Controller
  sd_ctrl SDC(.clk_i        (pbus.pclk),
              .rst_i        (1'b0),         // reset not yet implemented
              .spi_data_out (spi_data_out),
              .st_buf_out   (st_buf_out),
              .spi_val      (spi_val),
              .ctrl_reg     (ctrl_reg),
              .addr_reg     (addr_reg),
              .spi_data_in  (spi_data_in),
              .spi_en       (spi_en),
              .spi_we       (spi_we),
              .ld_buf_enq   (ld_buf_enq_sdc),
              .st_buf_enq   (st_buf_enq_sdc),
              .busy         (busy_sdc),
              .ctrl_reg_clr (ctrl_reg_clr),
              .sd_cs        (sbus.cs));

  
  // APB Controller
  sd_apb_ctrl APB_CTRL (.pbus               (pbus),
                        .psel               (psel),
                        .ld_buf_data_i      ({8'b0, ld_buf[511]}),
                        .status_reg_data_i  ({15'b0, busy_sdc}),
                        .data_o             (apb_data_out),
                        //.st_buf_data_ld     (), // Redundant with enq
                        .ctrl_reg_ld        (ctrl_reg_ld),
                        .addr_reg_ld        (addr_reg_ld),
                        .ld_buf_deq         (ld_buf_deq),
                        .st_buf_enq         (st_buf_enq));

  // SPI Master
  spi_ctrl         #(.REF_CLK   (10000000),
                     .BAUDRATE  (400000))       // 400KHz
       SPI_CTRL     (.clk_i     (pbus.pclk),
                     //.rst_i     (1'b0),         // reset not yet implemented
                     .sd_di_i   (sbus.miso),
                     .ce_i      (spi_en),       // Transacton Request
                     .we_i      (spi_we),
                     .func_i    (1'b0),
                     .data_i    (spi_data_in),
                     .data_o    (spi_data_out),
                     .val_o     (spi_val),      // Transaction Complete
                     .sd_clk_o  (sbus.clk),
                     //.sd_cs_o   (spi_cs),       // Generated Elsewhere
                     .sd_do_o   (sbus.mosi));


  // 
  always_ff @(posedge pbus.pclk) begin
    
    if (ld_buf_enq_sdc) begin
      //ld_buf <= {ld_buf[510:0], spi_data_out};
      ld_buf <= {spi_data_out, ld_buf[511:1]};
    end else if (ld_buf_deq) begin
      //ld_buf <= {ld_buf[510:0], spi_data_out};
      ld_buf <= {ld_buf[510:0], 8'hFF};
    end

    if (st_buf_enq_sdc) begin
      //ld_buf <= {ld_buf[510:0], spi_data_out};
      st_buf <= {8'hFF, st_buf[511:1]};
    end else if (st_buf_enq) begin
      //ld_buf <= {ld_buf[510:0], spi_data_out};
      st_buf <= {apb_data_out[7:0], st_buf[511:1]};
    end

    if (ctrl_reg_ld) begin
      
      ctrl_reg <= apb_data_out;

    end else if (ctrl_reg_clr) begin

      ctrl_reg <= 16'b0;

    end

    if (addr_reg_ld) begin
      
      addr_reg <= apb_data_out;

    end

  end

  assign st_buf_out = st_buf[0];


endmodule
