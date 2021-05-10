`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2021 03:37:09 AM
// Design Name: 
// Module Name: system_tb
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


module system_tb();

    logic pclk;
    logic reset;
    integer i;

    initial begin
        pclk = 1'b0;
    end

    always begin
        #5 pclk = ~pclk;
    end

    parameter to_test = "";

    system #(.file(to_test)) complete_system (.clk(pclk), .reset(reset));

    initial begin
        // LW  - r1 <= mem[r0 + 0000010]
        // r1 = 16'h8000
        // b1010010000000010 = hA402
        complete_system.ROM.MEM.mem[0] <= 16'hA402;

        // J - PC <= r0 + 0000011
        // PC <= 0000100
        // b1110000000000100 = E004
        complete_system.ROM.MEM.mem[1] <= 16'hE004;

        // Command won't be run since it'll be jumped over
        // Write 8000 for LW at beginning
        complete_system.ROM.MEM.mem[2] <= 16'h8000;

        // SW - mem[r1 + 0000010] <= r0
        // mem[16'h8002] <= 16'h0000
        // b1100000010000010 = hC082
        complete_system.ROM.MEM.mem[3] <= 16'hC082;

        // ADDI - r2 <= r0 + 0111111
        // r2 = b0111111 = d63
        // b0010100000111111 = h283F
        complete_system.ROM.MEM.mem[4] <= 16'h283F;

        // ADD - r2 <= r2 + r2
        // r2 = d126
        // b0000100100100000 = h0920
        complete_system.ROM.MEM.mem[5] <= 16'h0920;

        // ADD - r2 <= r2 + r2
        // r2 = d252
        // b0000100100100000 = h0920
        complete_system.ROM.MEM.mem[6] <= 16'h0920;

        // ADD - r2 <= r2 + r2
        // r2 = d504
        // b0000100100100000 = h0920
        complete_system.ROM.MEM.mem[7] <= 16'h0920;

        // ADDI - r2 <= r2 + 0001000
        // r2 = d512
        // b0010100100000111 = h2908
        // r2 is to be compared to for bne for a loop
        complete_system.ROM.MEM.mem[8] <= 16'h2908;

        // LW - r6 <= mem[r1 + 0000100]
        // read status register to r6
        // b1011100010000100 = hB884
        complete_system.ROM.MEM.mem[9] <= 16'hB884;

        // BNE if r0 != r6 jump to PC <= 9 (PC - 1)
        // b1001000001100001 = h9061
        complete_system.ROM.MEM.mem[10] <= 16'h9061;

        // ADDI r7 = r0 + 1
        // b0011110000000001 = h3C01
        complete_system.ROM.MEM.mem[11] <= 16'h3C01;

        // SW - mem[r1 + h0003] = r7 to specify write block to SPI 
        // b1100000011110011 = hC0F3
        complete_system.ROM.MEM.mem[12] <= 16'hC0F3;


        // BEGIN LOOP
        // ADD - r3 <= r0 + r0
        // r3 <= 0 for the loop counter
        // b0000110000000000 = h0C00
        complete_system.ROM.MEM.mem[13] <= 16'h0C00;

        // BNE to jump to loop if r3 != r2 == 512
        // if r3 != r2 then PC <= PC + 0000010 == d16
        // b1000000110100010 = h81A2
        complete_system.ROM.MEM.mem[14] <= 16'h81A2;

        // JUMP to end if fell through BNE
        // PC <= 19
        // b1110000000010011 = hE013
        complete_system.ROM.MEM.mem[15] <= 16'hE013;


        // SW - mem[rs1 + 0000000] <= r3
        // adds the current value of the counter to the write queue for the SPI interface
        // b1100000010110000 = hC0B0
        complete_system.ROM.MEM.mem[16] <= 16'hC0B0;

        // ADDI - r3 <= r3 + 0000001
        // b0010110110000001 = h2D81
        complete_system.ROM.MEM.mem[17] <= 16'h2D81;

        // J - Jump back to beginning of loop
        // PC <= r0 + 0001110
        // PC <= 1110 = d14
        // b1110000000001110 = hE00E
        complete_system.ROM.MEM.mem[18] <= 16'hE00E;

        // Continue rest of program

        // LW  - r4 <= mem[r0 + 0010001]
        // r4 = 16'h4000
        // b1011000000010001 = hB011
        complete_system.ROM.MEM.mem[19] <= 16'hB011;

        // J - PC <= r0 + 0010110
        // PC <= 0010110 = d22
        // b1110000000010110 = E016
        complete_system.ROM.MEM.mem[20] <= 16'hE016;

        // Command won't be run since it'll be jumped over
        // Write 4000 for LW at beginning (as a basis for writing in RAM)
        complete_system.ROM.MEM.mem[21] <= 16'h4000;
        
        // LW - r6 <= mem[r1 + 0000100]
        // read status register to r6
        // b1011100010000100 = hB884
        complete_system.ROM.MEM.mem[22] <= 16'hB884;

        // BNE if r0 != r6 jump to PC <= 22 (PC - 1)
        // b1001000001100001 = h9061
        complete_system.ROM.MEM.mem[23] <= 16'h9061;


        // ADDI r7 = r0 + 2
        // b0011110000000010 = h3C02
        complete_system.ROM.MEM.mem[24] <= 16'h3C02;

        // SW - mem[r1 + h0003] = r7 to specify read block to SPI 
        // b1100000011110011 = hC0F3
        complete_system.ROM.MEM.mem[25] <= 16'hC0F3;

        // BEGIN LOOP
        // ADD - r3 <= r0 + r0
        // r3 <= 0 for the loop counter
        // b0000110000000000 = h0C00
        complete_system.ROM.MEM.mem[26] <= 16'h0C00;

        // BNE to jump to loop if r3 != r2 == 512
        // if r3 != r2 then PC <= PC + 0000010 == d21
        // b1000000110100010 = h81A2
        complete_system.ROM.MEM.mem[27] <= 16'h81A2;

        // JUMP to end if fell through BNE
        // PC <= 34
        // b1110000000100010 = hE022
        complete_system.ROM.MEM.mem[28] <= 16'hE022;


        // LW - r5 <= mem[rs1 + 0000001] 
        // reads the current value of the read queue for the SPI interface
        // b1011010010000001 = hB481
        complete_system.ROM.MEM.mem[29] <= 16'hB481;

        // SW - mem[r4 + 0000000] <= r5
        // store the value read into ram
        // b1100001001010000 = hC250
        complete_system.ROM.MEM.mem[30] <= 16'hC250;

        // ADDI - r3 <= r3 + 0000001
        // b0010110110000001 = h2D81
        complete_system.ROM.MEM.mem[31] <= 16'h2D81;

        // ADDI - r4 <= r4 + 0000001
        // b0011001000000001 = h3201
        complete_system.ROM.MEM.mem[32] <= 16'h3201;


        // J - Jump back to beginning of loop
        // PC <= r0 + 0011011
        // PC <= 0011011 = d27
        // b1110000000011011 = hE01B
        complete_system.ROM.MEM.mem[33] <= 16'hE01B;
        
        // NOP from r0 <= r0 + r0
        complete_system.ROM.MEM.mem[34] <= 16'h0000;

        complete_system.pbus.preset <= 1'b1;
        @(posedge pclk)
        #1
        complete_system.pbus.preset <= 1'b0;
        @(posedge pclk)
        #1
        complete_system.pbus.preset <= 1'b1;
        @(posedge pclk)
        #1

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

        for (i = 0; i < 100; i = i) begin
            @(posedge pclk)
            i = i + 1;
        end
    end

endmodule
