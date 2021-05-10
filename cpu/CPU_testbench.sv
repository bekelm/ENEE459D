`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/28/2021 09:26:45 AM
// Design Name: 
// Module Name: CPU_testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

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

module CPU_testbench();
    logic pclk;
    logic reset;
    logic psel;
    apb_bus pbus(.pclk(pclk));
    
    integer i;
    //apb_bus ir_bus(.pclk(pclk));
    //apb_bus IR_ram(.pclk(pclk));

    apb_ram test_ram(.bus(pbus), .psel(psel));
    CPU_master cpu_under_test(.clk(pclk), .reset(reset), .pbus(pbus), .psel(psel));

    initial begin
        pclk = 1'b0;
    end

    always begin
        #5 pclk = ~pclk;
    end

    // Write to the test_ram
    task write(input [15:0] paddr_in, input [15:0] pwdata_in);
        begin
        pbus.pwrite <= 1'b1;
        psel <= 1'b1;
        pbus.penable <= 1'b0;
        pbus.paddr <= paddr_in;
        pbus.pwdata <= pwdata_in;
        @(posedge pclk);
        pbus.penable = 1'b1;
        @(negedge pbus.pready);
        pbus.penable = 1'b0;
        psel <= 1'b0;
        end
    endtask: write
    
    // Write to the test_ram
    task read(input [15:0] paddr_in);
        begin
        pbus.pwrite <= 1'b0;
        psel <= 1'b1;
        pbus.penable <= 1'b0;
        pbus.paddr <= paddr_in;
        @(posedge pclk);
        pbus.penable = 1'b1;
        @(negedge pbus.pready);
        pbus.penable = 1'b0;
        psel <= 1'b0;
        end
    endtask: read

    initial begin
       
        pbus.preset <= 1'b1;
        @(posedge pclk)
        #1
        pbus.preset <= 1'b0;
        @(posedge pclk)
        #1
        pbus.preset <= 1'b1;
        @(posedge pclk)
        #1
        // Write b0010010000100000 to address b0000000000000000
        // b0010010000100000 corresponds to addi r1 <= r0 + 0100000
        write(.paddr_in(16'b0000000000000000), .pwdata_in(16'b0010010000100000));
        @(posedge pclk)
        #1
        // Write b0010100000000111 to address b0000000000000001
        // b0010100000000111 corresponds to addi r2 <= r0 + 0000111
        write(.paddr_in(16'b0000000000000001), .pwdata_in(16'b0010100000000111));
        
        @(posedge pclk)
        #1
        // Write b0000110010100000 to address b0000000000000010
        // b0000110010100000 corresponds to addi r3 <= r1 + r2
        write(.paddr_in(16'b0000000000000010), .pwdata_in(16'b0000110010100000));
            

        @(posedge pclk)
        #1
        // Write b0101000010100000 to address b0000000000000011
        // b0101000010100000 corresponds to SUB so that r4 <= r1 - r2
        write(.paddr_in(16'b0000000000000011), .pwdata_in(16'b0101000010100000));

        @(posedge pclk)
        #1
        // Write b0011010000011111 to address b0000000000000100
        // b0011010000001111 corresponds to ADDI so that r5 <= r0 + 0011111
        write(.paddr_in(16'b0000000000000100), .pwdata_in(16'b0011010000011111));

        @(posedge pclk)
        #1 
        // Write b0111100101010000 to address b0000000000000101
        // b0111100101010000 corresponds to NAND r6 <= r2 NAND r5
        write(.paddr_in(16'b0000000000000101), .pwdata_in(16'b0111100101010000));

        @(posedge pclk)
        #1
        // Write b100001000000000 to address b0000000000000110
        // b1000 0100 0000 0000 corresponds to BNE if r0 != r0 then PC <= PC + 0010000
        // should not branch since r0 == r0
        write(.paddr_in(16'b0000000000000110), .pwdata_in(16'b1000010000000000));

        @(posedge pclk)
        #1
        // Write b1000000000001100 to address b0000000000000111
        // b1000000000000100 corresponds to BNE if r0 != r1 then PC <= PC + 0000100
        // should not branch since r0 == r0
        write(.paddr_in(16'b0000000000000111), .pwdata_in(16'b1000000000000100));

        @(posedge pclk)
        #1 
        // Write b0011110000001101 to address b0000000000001011
        // b0011110000001101 corresponds to ADDI so r7 <= r0 + 0001101 
        write(.paddr_in(16'b0000000000001011), .pwdata_in(16'b0011110000001101));


        @(posedge pclk)
        #1
        // Write b1011100001111111 to address b0000000000001100
        // b101 110 000 1111111 corresponds to LW so r6 <= [r0 + 1111111]
        write(.paddr_in(16'b0000000000001100), .pwdata_in(16'b1011100001111111));

        // Write b0000000000001111 to address b0000000001111111 as data to read
        write(.paddr_in(16'b0000000001111111), .pwdata_in(16'b0000000000001111));

        
        @(posedge pclk)
        #1
        // Write b1110000000010000 to address b0000000000001101
        // b1110000000010000 corresponds to J so PC <= r0 + 0010000
        write(.paddr_in(16'b0000000000001101), .pwdata_in(16'b1110000000010000));

        
        @(posedge pclk)
        #1
        // Write b1100010000111000 to address b0000000000010000
        // b110 001 000 0111000 corresponds to SW so that MEM[r0 + 0011000] <= r3
        write(.paddr_in(16'b0000000000010000), .pwdata_in(16'b1100010000111000));   
        

        @(posedge pclk)
             
        
        @(posedge pclk)
        #1
        reset <= 1'b0;
        
        @(posedge pclk)
        #1
        reset <= 1'b1;
        
        @(posedge pclk)
        //@(posedge pclk)
        #1
        reset <= 1'b0;
        //@(posedge pclk)
        //#1
        //$display(test_ram.mem);
        
        for (i = 0; i < 100; i = i) begin
            @(posedge pclk)
            i = i + 1;
        end
        
    end
    


endmodule
