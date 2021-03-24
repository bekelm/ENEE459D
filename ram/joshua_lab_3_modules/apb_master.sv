// Bridge/Request APB Master
module apb_master (

  input pclk,

  // Reqeust side
  input [7:0] addr_req,
  input req,
  input wr_req,
  input [7:0] data_send,
  output reg [7:0] data_reciv,
  output reg ack,
  output reg complete,

  // APB side
  apb_bus pbus

);
  
  localparam IDLE = 2'b00;
  localparam SETUP = 2'b01;
  localparam ACCESS = 2'b10;
  localparam INVALID = 2'b11;

  // APB State registers
  reg [1:0] state = 2'b00;
  reg [1:0] nstate;

  initial begin
    
    state   <= 2'b00;

    pbus.pwrite  <= 1'b0;
    pbus.psel    <= 1'b0;
    pbus.penable <= 1'b0;
    pbus.paddr   <= 8'h0;
    pbus.pwdata  <= 8'h0;

    ack     <= 1'b0;
    complete<= 1'b0;
    data_reciv  <= 8'h0;

  end

  always @(posedge pbus.pclk) begin

    case(state)
      IDLE: begin
        complete  <= 1'b0;
        if (req) begin
          state   <= SETUP;
          pbus.psel    <= 1'b1;
          pbus.paddr   <= addr_req;
          pbus.pwrite  <= wr_req;
          ack     <= 1'b1;
          if (wr_req) begin
            pbus.pwdata  <= data_send;
          end
        end else begin
          state   <= IDLE;
          pbus.psel    <= 1'b0;
          pbus.penable <= 1'b0;
        end
      end
      SETUP: begin
        state   <= ACCESS;
        ack     <= 1'b0;
        pbus.penable <= 1'b1;
        complete  <= 1'b0;
      end
      ACCESS: begin
        if (pbus.pready) begin
          complete  <= 1'b1;
          pbus.penable   <= 1'b0;
          if (!pbus.pwrite) begin
            data_reciv <= pbus.prdata;
          end
          if (req) begin
            state   <= SETUP;
            pbus.paddr   <= addr_req;
            pbus.pwrite  <= wr_req;
            ack     <= 1'b1;
            if (wr_req) begin
              pbus.pwdata  <= data_send;
            end
          end else begin
            state   <= IDLE;
            pbus.psel    <= 1'b0;
          end
        end else begin
          nstate = ACCESS;
        end
      end
    endcase

  end

endmodule
