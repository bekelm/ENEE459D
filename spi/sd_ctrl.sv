// SD Card Controller/State Machine

module sd_ctrl (
  
  input clk_i,
  input rst_i,

  input [7:0] spi_data_out,     // Output from SPI
  input [7:0] st_buf_out,       // Head of Store Buffer

  input spi_val,

  input [15:0] ctrl_reg,
  input [15:0] addr_reg,

  output reg [7:0] spi_data_in, // Input to SPI
  output reg spi_en,
  output reg spi_we,
  
  output reg ld_buf_enq,
  output reg st_buf_enq,
  output reg busy,
  output reg ctrl_reg_clr,
  output reg sd_cs

);
  
  // SD CTRL States
  typedef enum reg [4:0] {
    INIT0,
    INIT1,
    INIT2,
    INIT3,
    INIT4,
    INIT5,
    INIT6,
    READ0,
    READ1,
    READ2,
    READ3,
    READ4,
    WRITE0,
    WRITE1,
    WRITE2,
    WRITE3,
    WRITE4,
    WRITE5,
    WRITE6,
    IDLE,
    ERROR
  } SD_CTRL_T;
  /*
  localparam [3:0] INIT0  = 4'h0;
  localparam [3:0] INIT1  = 4'h1;
  localparam [3:0] INIT2  = 4'h2;
  localparam [3:0] INIT3  = 4'h3;
  localparam [3:0] INIT4  = 4'h4;
  localparam [3:0] INIT5  = 4'h5;
  localparam [3:0] INIT6  = 4'h6;

  localparam [3:0] IDLE   = 4'h7;

  localparam [3:0] ERROR  = 4'hF;
  */

  // TR CTRL States
  typedef enum reg [4:0] {
    TR_CMD0,
    TR_CMD1,
    TR_CMD2,
    TR_CMD3,
    TR_DAT0,
    TR_DAT1,
    TR_DAT2,
    TR_DAT3,
    TR_WFR0,
    TR_WFR1,
    TR_WFR2,
    TR_WFR3,
    TR_WFR4,
    TR_WFR5,
    TR_WFR6,
    TR_IDLE
  } TR_CTRL_T;
  /*
  localparam [3:0] TR_CMD0= 4'h0;
  localparam [3:0] TR_CMD1= 4'h1;
  localparam [3:0] TR_CMD2= 4'h2;
  localparam [3:0] TR_CMD3= 4'h3;

  localparam [3:0] TR_WFR0= 4'h4;
  localparam [3:0] TR_WFR1= 4'h5;
  localparam [3:0] TR_WFR2= 4'h6;
  localparam [3:0] TR_WFR3= 4'h7;

  localparam [3:0] TR_IDLE= 4'h8;
  */

  // State Registers
  SD_CTRL_T state = INIT0;
  TR_CTRL_T tr_state = TR_IDLE;

  SD_CTRL_T nstate;
  TR_CTRL_T tr_nstate;

  reg [47:0] sd_cmd_reg = 48'b0;
  reg [7:0] sd_resp = 8'b0;

  reg [3:0] cmd_count = 4'b0;
  reg [10:0] loop_count = 4'b0;

  // SD Controller Registers
  reg tr_wfr;  // Wait For Responce
  reg tr_req;   // CMD send Request
  reg tr_dat;   // DATA send Request

  reg [47:0] sd_cmd;
  reg loop_req;
  reg [10:0] loop_req_count;

  reg ld_buf_enq_en;
  reg st_buf_enq_en;

  // TFR Registers
  reg loop_count_clr;
  reg cmd_count_clr;
  reg sd_cmd_reg_ld;

  reg loop_count_inc;
  reg cmd_count_inc;
  reg sd_cmd_reg_shift;

  reg sd_resp_ld;

  reg tr_wfr_ack;
  reg tr_ack;
  reg ld_buf_enq_wfr;
  reg st_buf_enq_dat;


  // SD Controller
  always_comb begin

    case (state)
      INIT0: begin    // Send Required Dummy Bytes For CLK Synch
        loop_req = 1'b1;
        loop_req_count = 4'h1;    // This many loops not required
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b1;
        tr_req = 1'b1;
        tr_wfr = 1'b0;
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_ack) begin
          nstate    = INIT1;
        end else begin
          nstate    = INIT0;
        end
      end
      INIT1: begin    // Send CMD0 to Software Reset Card
        loop_req = 1'b0;      // May be redundant with loop_req_count set to 0
        loop_req_count = 4'h0;
        sd_cmd = 48'h400000000095; // CMD0
        sd_cs = 1'b0;
        tr_req = 1'b1;
        tr_wfr = 1'b0;
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_ack) begin
          nstate    = INIT2;
        end else begin
          nstate    = INIT1;
        end
      end
      INIT2: begin    // Wait for/Check Response
        loop_req = 1'b0;      // May be redundant with loop_req_count set to 0
        loop_req_count = 4'h0;
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b0;
        tr_req = 1'b0;
        tr_wfr = 1'b1;  // Wait For Response
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_wfr_ack) begin
          // Good Val Returned
          if (sd_resp == 8'h01) begin
            nstate    = INIT3;
          // Bad Val Returned
          end else begin
            nstate    = ERROR;
          end
        end else begin
          nstate    = INIT2;
        end
      end
      /*
      INIT3: begin    // Send CMD8 to Check Card Version
        loop_req = 1'b0;      // May be redundant with loop_req_count set to 0
        loop_req_count = 4'h0;
        sd_cmd = 48'h48000001AA??; // CMD8 (Needs CRC)
        sd_cs = 1'b0;
        nstate    = INIT2;
      end
      INIT4: begin    // Check Card Version
        loop_req = 1'b0;      // May be redundant with loop_req_count set to 0
        loop_req_count = 4'h0;
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b0;
        sd_wfr = 1'b1;  // Wait For Response
        if (tr_wfr_ack) begin
          // Card is Not SDV2
          if (sd_resp == 8'h05) begin
            nstate    = INIT3;
          end else begin
            nstate    = ERROR;
          end
        end else begin
          nstate    = INIT2;
        end
      end
      */
      INIT3: begin    // Send CMD1 to Initialize Card
        loop_req = 1'b0;      // May be redundant with loop_req_count set to 0
        loop_req_count = 4'h0;
        sd_cmd = 48'h410000000095; // CMD1 (!!!Check CRC)
        sd_cs = 1'b0;
        tr_req = 1'b1;
        tr_wfr = 1'b0;
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_ack) begin
          nstate    = INIT4;
        end else begin
          nstate    = INIT3;
        end
      end
      INIT4: begin    // Check if CMD1 Was Accepted
        loop_req = 1'b0;      // May be redundant with loop_req_count set to 0
        loop_req_count = 4'h0;
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b0;
        tr_req = 1'b0;
        tr_wfr = 1'b1;  // Wait For Response
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_wfr_ack) begin
          // Card is MMC/V3
          if (sd_resp == 8'h00) begin
            nstate    = INIT5;
          // Waiting in Idle State
          end else if (sd_resp == 8'h01) begin
            nstate    = INIT4;
          // Bad Val Returned
          end else begin
            nstate    = ERROR;
          end
        end else begin
          nstate    = INIT4;
        end
      end
      INIT5: begin    // Set Block Length to 512 Bytes
        loop_req = 1'b0;      // May be redundant with loop_req_count set to 0
        loop_req_count = 4'h0;
        sd_cmd = 48'h5000000200FF; // CMD16
        sd_cs = 1'b0;
        tr_req = 1'b1;
        tr_wfr = 1'b0;
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_ack) begin
          nstate    = INIT6;
        end else begin
          nstate    = INIT5;
        end
      end
      INIT6: begin    // Check if CMD16 Was Accepted
        loop_req = 1'b0;      // May be redundant with loop_req_count set to 0
        loop_req_count = 4'h0;
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b0;
        tr_req = 1'b0;
        tr_wfr = 1'b1;  // Wait For Response
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_wfr_ack) begin
          // Correct Val Returned
          if (sd_resp == 8'h00) begin
            nstate    = IDLE;
          // Bad Val Returned
          end else begin
            nstate    = ERROR;
          end
        end else begin
          nstate    = INIT6;
        end
      end

      IDLE: begin    // Waits For RD/WR Command
        loop_req = 1'b0;      // May be redundant with loop_req_count set to 0
        loop_req_count = 4'h0;
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b0;
        tr_req = 1'b0;
        tr_wfr = 1'b0;
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy  = 1'b0;
        if (ctrl_reg == 16'h02) begin
          nstate    = READ0;
        end else if (ctrl_reg == 16'h01) begin
          nstate    = WRITE0;
        end else begin
          nstate    = IDLE;
        end
      end

      READ0: begin    // Begins Block Read
        loop_req = 1'b0;
        loop_req_count = 4'h0;
        sd_cmd = 48'h51DEADBEEFFF; // CMD17
        sd_cmd[39:8] = {16'h0, addr_reg};
        sd_cs = 1'b0;
        tr_req = 1'b1;
        tr_wfr = 1'b0;
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b1;
        busy = 1'b1;
        if (tr_ack) begin
          nstate    = READ1;
        end else begin
          nstate    = READ0;
        end
      end
      READ1: begin    // Check if CMD17 Was Accepted
        loop_req = 1'b0;
        loop_req_count = 4'h0;
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b0;
        tr_req = 1'b0;
        tr_wfr = 1'b1;  // Wait For Response
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_wfr_ack) begin
          if (sd_resp == 8'h00) begin
            nstate    = READ2;
          // Bad Val Returned
          end else begin
            nstate    = ERROR;
          end
        end else begin
          nstate    = READ1;
        end
      end
      READ2: begin    // Wait for Data Token (Data Packet first Byte)
        loop_req = 1'b0;
        loop_req_count = 4'h0;
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b0;
        tr_req = 1'b0;
        tr_wfr = 1'b1;  // Wait For Response
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_wfr_ack) begin
          // Data token CMD17
          if (sd_resp == 8'hFE) begin
            nstate    = READ3;
          // Waiting for Packet
          end else if (sd_resp == 8'hFF) begin
            nstate    = READ2;
          // Bad Val Returned
          end else begin
            nstate    = ERROR;
          end
        end else begin
          nstate    = READ2;
        end
      end
      READ3: begin    // Read in 512 Bytes
        loop_req = 1'b1;
        loop_req_count = 10'h200;    // TODO: change length
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b0;
        tr_req = 1'b0;
        tr_wfr = 1'b1;  // Wait For Response
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b1;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_wfr_ack) begin
          nstate    = READ4;
        end else begin
          nstate    = READ3;
        end
      end
      READ4: begin    // Read in CRC Bytes
        loop_req = 1'b1;
        loop_req_count = 10'h001;    // TODO: change length
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b0;
        tr_req = 1'b0;
        tr_wfr = 1'b1;  // Wait For Response
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_wfr_ack) begin
          nstate    = IDLE;//READ4;
        end else begin
          nstate    = READ4;
        end
      end

      WRITE0: begin    // Begins Block Write
        loop_req = 1'b0;
        loop_req_count = 4'h0;
        sd_cmd = 48'h58DEADBEEFFF; // CMD24 TODO: ADD ADDRESS
        sd_cmd[39:8] = {16'h0, addr_reg};
        sd_cs = 1'b0;
        tr_req = 1'b1;
        tr_wfr = 1'b0;
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b1;
        busy = 1'b1;
        if (tr_ack) begin
          nstate    = WRITE1;
        end else begin
          nstate    = WRITE0;
        end
      end
      WRITE1: begin    // Check if CMD24 Was Accepted
        loop_req = 1'b0;
        loop_req_count = 4'h0;
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b0;
        tr_req = 1'b0;
        tr_wfr = 1'b1;  // Wait For Response
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_wfr_ack) begin
          if (sd_resp == 8'h00) begin
            nstate    = WRITE2;
          // Bad Val Returned
          end else begin
            nstate    = ERROR;
          end
        end else begin
          nstate    = WRITE1;
        end
      end
      WRITE2: begin    // Send Dummy Bytes and Data Token
        loop_req = 1'b0;
        loop_req_count = 4'h0;
        sd_cmd = 48'hFFFFFFFFFFFE; // Dummy Bytes and Data Token
        sd_cs = 1'b1;
        tr_req = 1'b1;
        tr_wfr = 1'b0;
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_ack) begin
          nstate    = WRITE3;
        end else begin
          nstate    = WRITE2;
        end
      end
      WRITE3: begin    // Write 512 Bytes
        loop_req = 1'b1;
        loop_req_count = 10'h200;    // TODO: change length
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b0;
        tr_req = 1'b0;
        tr_wfr = 1'b0;  // Wait For Response
        tr_dat = 1'b1;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b1;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_ack) begin
          nstate    = WRITE4;
        end else begin
          nstate    = WRITE3;
        end
      end
      WRITE4: begin    // Send CRC Bytes
        loop_req = 1'b0;
        loop_req_count = 4'h0;
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b0;
        tr_req = 1'b0;
        tr_wfr = 1'b0;  // Wait For Response
        tr_dat = 1'b1;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_ack) begin
          nstate    = WRITE5;
        end else begin
          nstate    = WRITE4;
        end
      end
      WRITE5: begin    // Send CRC Bytes
        loop_req = 1'b0;
        loop_req_count = 4'h0;
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b0;
        tr_req = 1'b0;
        tr_wfr = 1'b0;  // Wait For Response
        tr_dat = 1'b1;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_ack) begin
          nstate    = WRITE6;
        end else begin
          nstate    = WRITE5;
        end
      end
      WRITE6: begin    // Check if Write Was successful
        loop_req = 1'b0;
        loop_req_count = 4'h0;
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b0;
        tr_req = 1'b0;
        tr_wfr = 1'b1;  // Wait For Response
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy = 1'b1;
        if (tr_wfr_ack) begin
          if (sd_resp == 8'h05) begin
            nstate    = IDLE;
          // Bad Val Returned
          end else begin
            nstate    = ERROR;
          end
        end else begin
          nstate    = WRITE6;
        end
      end

      ERROR: begin
        loop_req = 1'b0;
        loop_req_count = 4'h0;
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b1;
        tr_req = 1'b0;
        tr_wfr = 1'b0;
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy  = 1'b1;
        nstate    = ERROR;
      end
      // Invalid State
      default: begin
        loop_req = 1'b0;
        loop_req_count = 4'h0;
        sd_cmd = 48'hFFFFFFFFFFFF; // Dummy Bytes
        sd_cs = 1'b1;
        tr_req = 1'b0;
        tr_wfr = 1'b0;
        tr_dat = 1'b0;
        ld_buf_enq_en = 1'b0;
        st_buf_enq_en = 1'b0;
        ctrl_reg_clr  = 1'b0;
        busy  = 1'b1;
        nstate    = ERROR;  // Could reset to INIT0
      end

    endcase

  end

  // Transfer Controller
  always_comb begin

    loop_count_clr = 1'b0;
    cmd_count_clr = 1'b0;
    sd_cmd_reg_ld = 1'b0;

    loop_count_inc = 1'b0;
    cmd_count_inc = 1'b0;
    sd_cmd_reg_shift = 1'b0;

    sd_resp_ld = 1'b0;

    spi_en = 1'b0;
    spi_we = 1'b0;

    tr_wfr_ack = 1'b0;
    tr_ack     = 1'b0;

    ld_buf_enq_wfr = 1'b0;
    st_buf_enq_dat = 1'b0;

    case (tr_state)
      TR_IDLE: begin    // Wait For Transaction Request
        loop_count_clr = 1'b1;  // Reset Loop Counter
        cmd_count_clr = 1'b1;   // Reset CMD counter
        sd_cmd_reg_ld = 1'b1;
        if (tr_req) begin
          tr_nstate = TR_CMD0;
        end else if (tr_wfr) begin
          tr_nstate = TR_WFR0;
        end else if (tr_dat) begin
          tr_nstate = TR_DAT0;
        end else begin
          tr_nstate = TR_IDLE;
        end
      end
      TR_CMD0: begin    // Transmit CMD
        cmd_count_inc = 1'b1;
        spi_en = 1'b1;
        spi_we = 1'b1;
        spi_data_in = sd_cmd_reg[47:40];
        tr_nstate = TR_CMD1;
      end
      TR_CMD1: begin    // Transmit CMD
        sd_cmd_reg_shift = 1'b1;
        // One Byte Sent
        if (spi_val) begin
          // If all CMD Bytes are not yet sent
          if (cmd_count != 4'h6) begin
            tr_nstate = TR_CMD0;
          // All CMD Bytes are sent
          end else begin
            tr_nstate = TR_CMD2;
          end
        end else begin
          tr_nstate = TR_CMD1;
        end
      end
      TR_CMD2: begin    // Transmit CMD
        loop_count_inc = 1'b1;

        // If all CMD Loops are not yet sent
        if (((loop_count+1) != loop_req_count) && loop_req) begin
          tr_nstate = TR_CMD0;
        // All CMD Loops Executed
        end else begin
          tr_nstate = TR_CMD3;
        end
      end
      TR_CMD3: begin    // Finish
        tr_ack    = 1'b1;
        tr_nstate = TR_IDLE;
      end

      TR_DAT0: begin    // Transmit DAT
        cmd_count_inc = 1'b1;
        spi_en = 1'b1;
        spi_we = 1'b1;
        spi_data_in = st_buf_out;
        tr_nstate = TR_DAT1;
      end
      TR_DAT1: begin    // Transmit DAT
        sd_cmd_reg_shift = 1'b1;
        // One Byte Sent
        if (spi_val) begin
          tr_nstate = TR_DAT2;
        end else begin
          tr_nstate = TR_DAT1;
        end
      end
      TR_DAT2: begin    // Transmit DAT
        loop_count_inc = 1'b1;
        st_buf_enq_dat = 1'b1;

        // If all DAT Loops are not yet sent
        if (((loop_count+1) != loop_req_count) && loop_req) begin
          tr_nstate = TR_DAT0;
        // All DAT Loops Executed
        end else begin
          tr_nstate = TR_DAT3;
        end
      end
      TR_DAT3: begin    // Finish
        tr_ack    = 1'b1;
        tr_nstate = TR_IDLE;
      end

      TR_WFR0: begin    // Transmit Dummy Byte
        spi_en = 1'b1;
        spi_we = 1'b1;
        spi_data_in = 8'hFF;  // Dummy Byte
        tr_nstate = TR_WFR1;
      end
      TR_WFR1: begin    // Transmit Dummy Byte
        // One Byte Sent
        if (spi_val) begin
          tr_nstate = TR_WFR2;
        end else begin
          tr_nstate = TR_WFR1;
        end
      end
      TR_WFR2: begin    // Finish Byte Transmit
        tr_ack    = 1'b1;
        tr_nstate = TR_WFR3;
      end
      TR_WFR3: begin    // Recieve Byte
        //timeout_count_inc = 1'b1;
        spi_en = 1'b1;
        spi_we = 1'b0;
        tr_nstate = TR_WFR4;
      end
      TR_WFR4: begin    // Wait For Byte
        sd_resp_ld = 1'b1;
        // One Byte Recieved
        if (spi_val) begin
          tr_nstate = TR_WFR5;
        end else begin
          tr_nstate = TR_WFR4;
        end
      end
      TR_WFR5: begin    // Check if Byte is Non empty (May collapse with WFR4)
                        // Also repeats if counter is enabled
        loop_count_inc = 1'b1;
        ld_buf_enq_wfr = 1'b1;
        // One Valid Byte Recieved
        if ((!loop_req && (sd_resp != 8'hFF)) || 
            (((loop_count+1) == loop_req_count) && loop_req)) begin
          tr_nstate = TR_WFR6;
        end else begin
          tr_nstate = TR_WFR0;
        end
      end
      TR_WFR6: begin    // Finish
        tr_wfr_ack = 1'b1;
        tr_nstate = TR_IDLE;
      end
      // Invalid State
      default: begin
        tr_nstate = TR_IDLE;
      end
    endcase

  end



  // Register Control
  always_ff @(posedge clk_i) begin
    
    if (rst_i) begin
      state <= INIT0;
      tr_state <= TR_IDLE;
    end else begin
      state <= nstate;
      tr_state <= tr_nstate;
    end

    // Loop counter
    if (loop_count_clr) begin
      loop_count <= 4'h0;
    end else if (loop_count_inc) begin
      loop_count <= loop_count + 1;
    end

    // Command Counter
    if (cmd_count_clr) begin
      cmd_count <= 4'h0;  // Reset Loop Counter
    end else if (cmd_count_inc) begin
      cmd_count <= cmd_count + 1;
    end

    if (sd_cmd_reg_ld) begin
      sd_cmd_reg <= sd_cmd;
    end else if (sd_cmd_reg_shift && spi_val) begin
      sd_cmd_reg <= {sd_cmd_reg[39:0], 8'hFF};
    end

    if (sd_resp_ld) begin
      sd_resp <= spi_data_out;
    end


  end

  // LD Buffer only enqueues once per Byte transaction
  assign ld_buf_enq = ld_buf_enq_en && ld_buf_enq_wfr;

  assign st_buf_enq = st_buf_enq_en && st_buf_enq_dat;

endmodule
