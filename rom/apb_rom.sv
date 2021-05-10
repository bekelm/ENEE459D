// APB Slave ROM module
module apb_rom (

  apb_bus bus,
  input reg psel

);

  parameter  FILE = "";

  localparam  WAIT_STATES = 2'b00;
  
  localparam IDLE     = 2'b00;
  localparam ACCESS   = 2'b01;
  localparam INVALID  = 2'b11;

  // APB State registers
  logic [1:0] state;
  logic [1:0] nstate;

  logic [1:0] cyc_count;

  logic finished = 1'b0;

  logic cyc_reset;

  // Memory registers
  logic mem_ce, mem_wren, mem_rden;

  logic [15:0] mem_wr_data;
  logic [15:0] mem_addr;
  logic [15:0] mem_rd_data;

  assign bus.prdata = mem_rd_data;

  rom_mem   #(.FILE(FILE)) 
          MEM(.clk(bus.pclk),
              .addr(mem_addr),
              .ce(mem_ce),
              .wren(mem_wren),
              .rden(mem_rden),
              .wr_data(mem_wr_data),
              .rd_data(mem_rd_data));

  // Next state transitions
  always_comb begin

    bus.pready = 1'b0;

    cyc_reset = 0;

    // Default invalid
    nstate = INVALID;

    case (state)
      IDLE: begin
        if (psel && !bus.penable) begin
          nstate = ACCESS;
        end else begin
          nstate = IDLE;
          cyc_reset = 1'b1;
        end
      end
      ACCESS: begin
        if (bus.penable) begin
          if (cyc_count == (2'b01 + WAIT_STATES)) begin
            nstate = IDLE;
            bus.pready = 1'b1;
            cyc_reset = 1'b1;
          end else begin
            nstate = ACCESS;
          end
        end else begin
          nstate = ACCESS;
          //cyc_reset = 1'b1;
        end
      end

    endcase

  end

  always @ (posedge bus.pclk or negedge bus.preset)  begin
    if (bus.preset == 0) begin
        state <= IDLE;
        cyc_count <= 0;
    end else begin
        state <= nstate;
    end
  end

  always @(posedge bus.pclk) begin

    if (cyc_reset) begin

      cyc_count <= 0;

    end else begin
      
      cyc_count <= cyc_count + 1;

    end

  end


  always_comb begin

    case(state)
      IDLE: begin
        // Default read memory
        mem_addr  = bus.paddr;
        mem_ce    = 1'b1;
        mem_wren  = 1'b0;
        mem_rden  = 1'b1;
        mem_wr_data = 16'b0;
        finished  = 1'b0;
      end
      ACCESS: begin
        if (bus.pwrite) begin
          mem_addr  = bus.paddr;
          mem_ce    = 1'b1;
          mem_wren  = 1'b1;
          mem_rden  = 1'b0;
          mem_wr_data = bus.pwdata;
          finished  = 1'b1;
        end else begin
          mem_addr  = bus.paddr;
          mem_ce    = 1'b1;
          mem_wren  = 1'b0;
          mem_rden  = 1'b1;
          mem_wr_data = 16'b0;
          finished  = 1'b1;
        end
      end
    endcase

  end

endmodule


module rom_mem (clk, addr, ce, wren, rden, wr_data, rd_data);

  input clk, ce, wren, rden;
  input [15:0] addr, wr_data;
  output reg [15:0] rd_data = 0;

  reg [15:0] mem [0:16383];

  parameter FILE = "";

  initial begin

    if (FILE != "") begin

      $readmemh(FILE, mem);
      
    end

  end

  always @ (posedge clk) 
  if (ce) 
  begin
     if (rden) 
         rd_data <= mem[addr];
  end

endmodule
