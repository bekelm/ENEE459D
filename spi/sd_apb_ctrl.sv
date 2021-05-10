// SD Card APB Controller
module sd_apb_ctrl (

  apb_bus pbus,
  input psel,

  input [15:0] ld_buf_data_i,
  input [15:0] status_reg_data_i,
  output logic [15:0] data_o,
  //output st_buf_data_ld,
  output logic ctrl_reg_ld,
  output logic addr_reg_ld,
  output logic ld_buf_deq,    // Dequeue LD Buffer
  output logic st_buf_enq     // Enqueue ST Buffer

);

  parameter  WAIT_STATES = 2'b00;
  
  localparam IDLE     = 2'b00;
  localparam ACCESS   = 2'b01;
  localparam INVALID  = 2'b11;

  // APB State registers
  logic [1:0] state = IDLE;
  logic [1:0] nstate;

  logic [1:0] cyc_count;

  logic cyc_reset;


  // Next state transitions
  always_comb begin

    pbus.pready = 1'b0;

    cyc_reset = 0;

    // Default invalid
    nstate = INVALID;

    case (state)
      IDLE: begin
        if (psel & !pbus.penable) begin
          nstate = ACCESS;
        end else begin
          nstate = IDLE;
          cyc_reset = 1'b1;
        end
      end
      ACCESS: begin
        if (pbus.penable) begin
          if (cyc_count == (2'b01 + WAIT_STATES)) begin
            nstate = IDLE;
            pbus.pready = 1'b1;
            cyc_reset = 1'b1;
          end else begin
            nstate = ACCESS;
          end
        end else begin
          nstate = IDLE;
          cyc_reset = 1'b1;
        end
      end

    endcase

  end

  always @ (posedge pbus.pclk or negedge pbus.preset)  begin
    if (pbus.preset == 0) begin
        state <= IDLE;
        cyc_count <= 0;
    end else begin
        state <= nstate;
    end
  end

  always @(posedge pbus.pclk) begin

    if (cyc_reset) begin

      cyc_count <= 0;

    end else begin
      
      cyc_count <= cyc_count + 1;

    end

  end


  always_comb begin

    // Defaults
    data_o      = pbus.pwdata;
    pbus.prdata  = 16'hFF;
    st_buf_enq  = 1'b0;
    addr_reg_ld = 1'b0;
    ctrl_reg_ld = 1'b0;
    ld_buf_deq  = 1'b0;

    case(state)
      IDLE: begin
      end
      ACCESS: begin
        if (pbus.pwrite) begin

          // Write To WR Queue
          if (pbus.paddr[2:0] == 3'd0) begin
            data_o      = pbus.pwdata;
            st_buf_enq  = 1'b1;

          // Write to ADDR Reg
          end else if (pbus.paddr[2:0] == 3'd2) begin
            data_o      = pbus.pwdata;
            addr_reg_ld = 1'b1;

          // Write to CMD Reg
          end else if (pbus.paddr[2:0] == 3'd3) begin
            data_o      = pbus.pwdata;
            ctrl_reg_ld = 1'b1;

          // Invalid ADDR
          end else begin

          end

        end else begin

          // Read from RD Queue
          if (pbus.paddr[2:0] == 3'd1) begin
            pbus.prdata  = ld_buf_data_i;
            ld_buf_deq  = 1'b1;

          // Read from Status Reg
          end else if (pbus.paddr[2:0] == 3'd4) begin
            pbus.prdata  = status_reg_data_i;

          // Invalid ADDR
          end else begin

          end

        end
      end
    endcase

  end

endmodule
