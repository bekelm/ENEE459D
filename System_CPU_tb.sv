`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2021 05:37:28 PM
// Design Name: 
// Module Name: System_CPU_tb
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


module System_CPU_tb();

    logic pclk;
    logic reset;
    integer i;

    initial begin
        pclk = 1'b0;
    end

    always begin
        #5 pclk = ~pclk;
    end

    parameter to_test = "E:/Xilinx_labs/Semester Project again/test1.txt";

    system #(.file(to_test)) complete_system (.clk(pclk), .reset(reset));

    initial begin
        complete_system.ROM.MEM.mem[0] <= 16'h2420;
        complete_system.ROM.MEM.mem[1] <= 16'h2807;
        complete_system.ROM.MEM.mem[2] <= 16'h0CA0;
        complete_system.ROM.MEM.mem[3] <= 16'h50A0;
        complete_system.ROM.MEM.mem[4] <= 16'h341F;
        complete_system.ROM.MEM.mem[5] <= 16'h7950;
        complete_system.ROM.MEM.mem[6] <= 16'h8400;
        complete_system.ROM.MEM.mem[7] <= 16'h8004;
        complete_system.ROM.MEM.mem[8] <= 16'h0000;
        complete_system.ROM.MEM.mem[9] <= 16'h0000;
        complete_system.ROM.MEM.mem[10] <= 16'h0000;
        complete_system.ROM.MEM.mem[11] <= 16'h3C0D;
        complete_system.ROM.MEM.mem[12] <= 16'h0000;
        complete_system.ROM.MEM.mem[13] <= 16'hE010;
        complete_system.ROM.MEM.mem[14] <= 16'h0000;
        complete_system.ROM.MEM.mem[15] <= 16'h0000;
        complete_system.ROM.MEM.mem[16] <= 16'hC438;
        //complete_system.ROM.MEM.mem[17] <= 16'h

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

        #500000
        for (i = 0; i < 100; i = i) begin
            @(posedge pclk)
            i = i + 1;
        end

        #1000000

        $finish;
    end

endmodule
