// SPI SD Card Simulator
module sd_sim (

  spi_bus sbus,   // SPI Bus
  input rst

);

  // SD CTRL States
  typedef enum reg [5:0] {
    INIT0,
    INIT1,
    INIT2,
    INIT3,
    INIT4,
    INIT5,
    INIT6,
    INIT7,
    INIT8,
    INIT9,
    INIT10,
    INIT11,
    INIT12,
    READ0,
    READ1,
    READ2,
    READ3,
    READ4,
    READ5,
    READ6,
    READ7,
    READ8,
    READ9,
    READ10,
    READ11,
    WRITE0,
    WRITE1,
    WRITE2,
    WRITE3,
    WRITE4,
    WRITE5,
    WRITE6,
    WRITE7,
    WRITE8,
    WRITE9,
    WRITE10,
    IDLE,
    ERROR
  } SD_CTRL_T;

  // State Registers
  SD_CTRL_T state = INIT1;
  SD_CTRL_T nstate;

  // MOSI and MISO Shift Registers
  reg [8:0] miso_reg;
  reg [7:0] mosi_reg;

  reg [47:0] mosi_cmd;


  // 
  reg [2:0] shift_count = 3'b0;

  reg [7:0] retval;
  reg miso_ld;
  reg shift;

  reg [31:0] addr_reg;
  reg addr_ld;

  reg mem_ld;

  reg [11:0] block_count;
  reg [11:0] block_count_wr;
  reg block_count_clr;

  // Memory
  reg [7:0] mem [0:511];

/*
  integer i = 0;
  initial begin
    
    for (i=0; i < 512; i = i + 1) begin
      
      mem[i] <= i;

    end

  end

*/
  // SD Controller
  always_comb begin

    case (state)
      // TODO: INIT0 synchronizes clock
      INIT1: begin    // Waits for SD Card to init CMD0
        shift     = 1'b0;
        miso_ld   = 1'b0;
        retval    = 8'hFF;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        // Initializes card if cs and mosi_cmd is init cmd
        if (!sbus.cs && (mosi_cmd == 48'h400000000095)) begin
          nstate    = INIT2;
        end else begin
          nstate    = INIT1;
        end
      end
      INIT2: begin    // 
        shift     = 1'b0;
        miso_ld   = 1'b1;
        retval    = 8'h01;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b110) begin
          nstate    = INIT3;
        end else begin
          nstate    = INIT2;
        end
      end
      INIT3: begin    // Shifts out first Val
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'h01;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        nstate    = INIT4;
      end
      INIT4: begin    // 
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'h01;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b111) begin
          nstate    = INIT5;
        end else begin
          nstate    = INIT4;
        end
      end
      INIT5: begin    // Waits for CMD1
        shift     = 1'b0;
        miso_ld   = 1'b0;
        retval    = 8'hFF;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        // Initializes card if cs and mosi_cmd is init cmd
        if (!sbus.cs && (mosi_cmd == 48'h410000000095)) begin
          nstate    = INIT6;
        end else begin
          nstate    = INIT5;
        end
      end
      INIT6: begin    // 
        shift     = 1'b0;
        miso_ld   = 1'b1;
        retval    = 8'h00;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b110) begin
          nstate    = INIT7;
        end else begin
          nstate    = INIT6;
        end
      end
      INIT7: begin    // Shifts out first Val
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'h01;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        nstate    = INIT8;
      end
      INIT8: begin    // 
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'h01;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b111) begin
          nstate    = INIT9;
        end else begin
          nstate    = INIT8;
        end
      end
      INIT9: begin    // Waits for CMD16
        shift     = 1'b0;
        miso_ld   = 1'b0;
        retval    = 8'hFF;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (!sbus.cs && (mosi_cmd == 48'h5000000200FF)) begin
          nstate    = INIT10;
        end else begin
          nstate    = INIT9;
        end
      end
      INIT10: begin    // 
        shift     = 1'b0;
        miso_ld   = 1'b1;
        retval    = 8'h00;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b110) begin
          nstate    = INIT11;
        end else begin
          nstate    = INIT10;
        end
      end
      INIT11: begin    // Shifts out first Val
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'h01;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        nstate    = INIT12;
      end
      INIT12: begin    // 
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'h01;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b111) begin
          nstate    = IDLE;
        end else begin
          nstate    = INIT12;
        end
      end
      IDLE: begin    // 
        shift     = 1'b0;
        miso_ld   = 1'b0;
        retval    = 8'hFF;
        addr_ld   = 1'b1;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        // Read Command
        if (!sbus.cs && (mosi_cmd[47:40] == 8'h51)) begin
          nstate    = READ0;
        end else if (!sbus.cs && (mosi_cmd[47:40] == 8'h58)) begin
          nstate    = WRITE0;
        end else begin
          nstate    = IDLE;
        end
      end

      READ0: begin    // Respond with valid
        shift     = 1'b0;
        miso_ld   = 1'b1;
        retval    = 8'h00;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b110) begin
          nstate    = READ1;
        end else begin
          nstate    = READ0;
        end
      end
      READ1: begin    // Shifts out first Val
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'h01;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        nstate    = READ2;
      end
      READ2: begin    // 
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'h01;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b111) begin
          nstate    = READ3;
        end else begin
          nstate    = READ2;
        end
      end
      READ3: begin    // Send Data Token
        shift     = 1'b0;
        miso_ld   = 1'b1;
        retval    = 8'hFE;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b110) begin
          nstate    = READ4;
        end else begin
          nstate    = READ3;
        end
      end
      READ4: begin    // Shifts out first Val
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'hFE;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        nstate    = READ5;
      end
      READ5: begin    // 
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'hFE;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b101) begin
          nstate    = READ6;
        end else begin
          nstate    = READ5;
        end
      end
      READ6: begin    // Last Bit shifted/load first data
        shift     = 1'b0;
        miso_ld   = 1'b1;
        retval    = mem[block_count];//mem[addr_reg][block_count];
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        nstate    = READ7;
      end
      READ7: begin    // Shift
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = mem[block_count];//mem[addr_reg][block_count];
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        nstate    = READ8;
      end
      /*
      READ7: begin    // Shifts out first Val
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = mem[addr_reg][block_count];
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b0;
        nstate    = READ5;
      end
      */
      READ8: begin    // 
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = mem[block_count];//mem[addr_reg][block_count];
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b0;
        if (shift_count == 3'b101 && block_count == 12'h1FF) begin
          nstate    = READ10;
        end else if (shift_count == 3'b101) begin
          nstate    = READ9;
        end else begin
          nstate    = READ8;
        end
      end
      READ9: begin    // Pre Load Bit Again
        shift     = 1'b0;
        miso_ld   = 1'b1;
        retval    = mem[block_count];//mem[addr_reg][block_count];
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b0;
        nstate    = READ8;
      end
      READ10: begin    // Synchronizes clock (2 clock pulses)
        shift     = 1'b0;
        miso_ld   = 1'b1;
        retval    = 8'hFF;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        nstate    = READ11;
      end
      READ11: begin    // Synchronizes clock (2 clock pulses)
        shift     = 1'b0;
        miso_ld   = 1'b1;
        retval    = 8'hFF;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        nstate    = IDLE;
      end

      WRITE0: begin    // Respond with valid
        shift     = 1'b0;
        miso_ld   = 1'b1;
        retval    = 8'h00;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b110) begin
          nstate    = WRITE1;
        end else begin
          nstate    = WRITE0;
        end
      end
      WRITE1: begin   // Shifts out first Val
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'h01;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        nstate    = WRITE2;
      end
      WRITE2: begin   // 
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'h01;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b111) begin
          nstate    = WRITE3;
        end else begin
          nstate    = WRITE2;
        end
      end
      WRITE3: begin    // Wait for Data Token
        shift     = 1'b0;
        miso_ld   = 1'b0;
        retval    = 8'hFF;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (mosi_reg == 8'hFE) begin
          nstate    = WRITE4;
        end else begin
          nstate    = WRITE3;
        end
      end
      WRITE4: begin    // Read In Data Val
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'hFF;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b0;
        if (shift_count == 3'b110 && block_count_wr == 12'h200) begin
          nstate    = WRITE6;
        end else if (shift_count == 3'b110) begin
          nstate    = WRITE5;
        end else begin
          nstate    = WRITE4;
        end
      end
      WRITE5: begin    // Write Data Val To Mem
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'hFF;
        addr_ld   = 1'b0;
        mem_ld    = 1'b1;
        block_count_clr = 1'b0;
        nstate    = WRITE4;
      end
      WRITE6: begin   // Wait for CRC Bytes
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'hFF;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b110) begin
          nstate    = WRITE7;
        end else begin
          nstate    = WRITE6;
        end
      end
      WRITE7: begin   // Wait for CRC Bytes
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'hFF;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b110) begin
          nstate    = WRITE8;
        end else begin
          nstate    = WRITE7;
        end
      end
      WRITE8: begin    // Valid Data Response
        shift     = 1'b0;
        miso_ld   = 1'b1;
        retval    = 8'h05;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b110) begin
          nstate    = WRITE9;
        end else begin
          nstate    = WRITE8;
        end
      end
      WRITE9: begin   // Shifts out first Val
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'h05;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        nstate    = WRITE10;
      end
      WRITE10: begin   // 
        shift     = 1'b1;
        miso_ld   = 1'b0;
        retval    = 8'h05;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        if (shift_count == 3'b111) begin
          nstate    = IDLE;
        end else begin
          nstate    = WRITE10;
        end
      end

      ERROR: begin    // Invalid State
        shift     = 1'b0;
        miso_ld   = 1'b0;
        retval    = 8'hFF;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        nstate    = ERROR;
      end
      // Invalid State
      default: begin
        shift     = 1'b0;
        miso_ld   = 1'b0;
        retval    = 8'hFF;
        addr_ld   = 1'b0;
        mem_ld    = 1'b0;
        block_count_clr = 1'b1;
        nstate    = ERROR;  // Could reset to INIT0
      end

    endcase

  end


  always_ff @(posedge sbus.clk) begin

    // NOTE: Clockedge
    if (rst) begin
      state <= INIT1;
    end else begin
      state <= nstate;
    end
      
    if (miso_ld && shift) begin
      
      miso_reg <= {miso_reg[7], retval};

      shift_count = shift_count + 1'b1;

    end else if (miso_ld) begin
      
      miso_reg <= {retval, 1'b1};

      shift_count = shift_count + 1'b1;

    end else if (shift) begin
      
      miso_reg <= {miso_reg[7:0], 1'b1};

      shift_count <= shift_count + 1'b1;

    end

    if (block_count_clr) begin
      block_count <= 0;
    end else if (shift_count == 3'b101) begin
      block_count <= block_count + 1'b1;
    end

    if (block_count_clr) begin
      block_count_wr <= 0;
    end else if (shift_count == 3'b111) begin
      block_count_wr <= block_count_wr + 1'b1;
    end

    if (addr_ld) begin
      
      addr_reg <= mosi_cmd[39:8];

    end

    if (mem_ld) begin
      
      mem[block_count_wr] <= mosi_reg;

    end

    mosi_reg <= {mosi_reg[6:0], sbus.mosi};
    mosi_cmd <= {mosi_cmd[46:0], sbus.mosi};


  end

  assign sbus.miso = (shift || (state == READ6) || (state == READ9)) ? miso_reg[8] : 1'b1;



endmodule
