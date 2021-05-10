// SPI Controller
module spi_ctrl (

  input clk_i,
  input sd_di_i,
  input ce_i,
  input we_i,
  input func_i,       // 0: RD/WR Buffer 1: WR SPI CS
  input [7:0] data_i,

  output reg [7:0] data_o,
  output reg val_o,
  output reg sd_clk_o,
  output reg sd_cs_o,
  output reg sd_do_o

);

  parameter REF_CLK = 10000000;
  parameter BAUDRATE = 400000;

  wire sd_pulse;    // Shift out pulse
  wire sd_pulse_p;  // Shift in pulse (180 deg out of phase)
  wire sd_clk_n;    // Out of phase clock

  // MOSI and MISO Shift Registers
  reg [7:0] miso_sr;
  reg [7:0] mosi_sr;

  // Counts number of shifts
  reg [3:0] sr_count;

  reg write_req;

  reg sd_pulse_en;
  reg ld_req;

  initial begin
    miso_sr <= 8'h62;
    mosi_sr <= 8'hB4; // Default BadVal
    data_o <=  8'b0;
    write_req <= 1'b0;
    sr_count <= 4'b0;
    sd_cs_o <= 1'b1;
    sd_do_o <= 1'b0;
  end

  // Peripheral Controller
  always @(posedge clk_i) begin
    
    val_o <= 1'b0;
    sd_pulse_en <= 1'b0;
    ld_req <= 1'b0;
    
    // CS request
    if (ce_i && we_i && func_i) begin

      sd_cs_o <= data_i[0];
      val_o <= 1'b1;

    // RD request
    end else if (ce_i && !we_i) begin

      data_o <= miso_sr;
      val_o <= 1'b1;

    // WR request
    end else if (ce_i && we_i) begin

      write_req <= 1'b1;
      ld_req <= 1'b1;

    end else if (write_req && (sr_count != 4'h9)) begin

      sd_pulse_en <= 1'b1;

    end else if (write_req && (sr_count == 4'h9)) begin
      
      write_req <= 1'b0;
      val_o <= 1'b1;

    // Idle
    end else begin

      val_o <= 1'b0;

    end

  end

  pulse_gen         #(.REF_CLK  (REF_CLK),
                      .BAUDRATE (BAUDRATE))
          SD_PULSEGEN(.clk_i    (clk_i),
                      .clr_i    (1'b0),
                      .clk_o    (sd_clk_n),
                      .pulse_p_o(sd_pulse_p),
                      .pulse_o  (sd_pulse));

/*
  clock_gen         #(.REF_CLK  (REF_CLK),
                      .BAUDRATE (BAUDRATE))
          SD_CLOCKGEN(.clk_i    (clk_i),
                      .clr_i    (1'b0),
                      .clk_o    (sd_clk_n));

*/
  // MOSI and MISO Shift Registers
  always @(posedge clk_i) begin
    
    sd_clk_o <= 1'b0;

    if (ld_req) begin

      mosi_sr <= data_i;

    end else if (sd_pulse_en) begin

      // Misses First Clock Edge
      if (sr_count != 4'b0) begin

        sd_clk_o <= sd_clk_n;

      end

      if (sd_pulse) begin
        sd_do_o <= mosi_sr[7];
        
        mosi_sr <= {mosi_sr[6:0], 1'b1};

        sr_count <= sr_count + 1'b1;
      end

      // Misses First Pulse
      if (sd_pulse_p && (sr_count != 4'b0)) begin

        miso_sr <= {miso_sr[6:0], sd_di_i};

      end

    end else if (!sd_pulse_en) begin

      sr_count <= 4'b0;
      //sd_do_o <= 1'b1;

    end

  end

  //assign sd_do_o = mosi_sr[7];

endmodule



// Pulse generator that outputs baud rate * oversampling
module pulse_gen (

	input clk_i,
  input clr_i,

	output reg clk_o,
	output reg pulse_p_o, // Out of phase pulse
	output reg pulse_o

);

  parameter REF_CLK  = 10000000;
  parameter BAUDRATE = 9600;
  parameter OVERSAMP = 1;

  reg [15:0] count;

  initial begin
    count <= 0;
    clk_o <= 0;
  end

  // Generate Transmit clock
  always @(posedge clk_i) begin
    
    pulse_o <= 1'b0;
    pulse_p_o <= 1'b0;

    if (clr_i) begin

      clk_o <= 0;
      count <= 16'b0;

    // Clock/Pulse 180 Degrees out of phase
    end else if (count == ((REF_CLK)/(BAUDRATE*OVERSAMP*2)) - 1) begin

      clk_o <= !clk_o;
      pulse_p_o <= 1'b1;

      count <= count + 1;

    end else if (count == ((REF_CLK)/(BAUDRATE*OVERSAMP)) - 1) begin

      pulse_o <= 1'b1;
      clk_o <= !clk_o;

      count <= 16'b0;

    end else begin

      count <= count + 1;

    end
    

  end

endmodule

// Clock generator that outputs baud rate * oversampling
module clock_gen (

	input clk_i,
  input clr_i,

	output reg clk_o

);

  parameter REF_CLK  = 10000000;
  parameter BAUDRATE = 9600;
  parameter OVERSAMP = 1;

  reg [15:0] count;

  initial begin
    count <= 0;
    clk_o <= 0;
  end

  // Generate Transmit clock
  always @(posedge clk_i) begin
    
    if (clr_i) begin

      clk_o <= 0;
      count <= 16'b0;

    end else if (count == ((REF_CLK)/(2*BAUDRATE*OVERSAMP)) - 1) begin

      clk_o <= !clk_o;

      count <= 16'b0;

    end else begin

      count <= count + 1;

    end
    

  end

endmodule
