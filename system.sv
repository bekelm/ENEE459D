
// APB Bus Interface
interface apb_bus (input pclk);
  logic [15:0] paddr;
  logic       pwrite;
  //logic       psel;
  logic       penable;
  logic [15:0] prdata;
  logic       pready;
  logic [15:0] pwdata;
  logic       preset;
endinterface

interface spi_bus();
  logic       clk;
  logic       cs;
  logic       miso;
  logic       mosi;
endinterface


// Top Level System Module
module system (

  input clk, 
  input reset

);

  parameter file = "";

  // APB Bus
  apb_bus pbus(clk);
  
  // SPI Bus
  spi_bus sbus();

  // Select Lines
  reg psel_cpu;
  logic psel_rom;
  logic psel_ram;
  logic psel_spi;


  // Program ROM Module  
 
  apb_rom  #(.FILE(file)) ROM  
                  (.bus        (pbus),
                  .psel       (psel_rom));

  // RAM Module
  apb_ram   RAM  (.bus        (pbus),
                  .psel       (psel_ram));

  // SDC Interface
  sd_spi   SPI  (.pbus        (pbus),
                  .psel       (psel_spi),
                  .sbus       (sbus));
  
  // APB Bus Address Decoder
  always_comb begin

    psel_rom = 1'b0;
    psel_ram = 1'b0;
    psel_spi = 1'b0;

    if (pbus.paddr[15:14] == 2'b00 && psel_cpu == 1'b1) begin
      
      psel_rom = 1'b1;

    end else if (pbus.paddr[15:14] == 2'b01 && psel_cpu == 1'b1) begin

      psel_ram = 1'b1;

    end else if (pbus.paddr[15:14] == 2'b10 && psel_cpu == 1'b1) begin

      psel_spi = 1'b1;

    end else if (pbus.paddr[15:14] == 2'b11 && psel_cpu == 1'b1) begin

      psel_rom = 1'b0;
      psel_ram = 1'b0;
      psel_spi = 1'b0;

    end

  end


  CPU_master cpu(.clk(clk), .reset(reset), .pbus(pbus), .psel(psel_cpu));


endmodule
