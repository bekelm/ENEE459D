`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/10/2021 11:03:22 AM
// Design Name: 
// Module Name: testbench
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


module testbench();
    logic pclk, preset, pwrite, psel, penable;
    logic [7:0] paddr;
    logic [7:0] pwdata;
    logic [7:0] prdata;
    logic [7:0] wait_count, wait_left;
    logic pready;
    logic pslverr;
    logic [1:0] out_state;
    
    AMBA_3_APB slave_driver(.pclk(pclk), .preset(preset), .paddr(paddr), .pwrite(pwrite), 
        .psel(psel), .penable(penable), .pwdata(pwdata), .prdata(prdata), .pready(pready), 
        .pslverr(pslverr), .wait_count(wait_count), .out_state(out_state), .wait_left(wait_left));
    
    // Instintiate clock at 0
    initial begin
        pclk = 0;
        pwrite = 0;
        psel = 0;
        penable = 0;
        pwdata = 0;
        prdata = 0;
    end
    
    // Set clock to flip every 5ns
    always begin
        #5 pclk = ~pclk;
    end
    
    
    initial begin
        // Write with no wait example
        #10
        preset = 1;
        #10
        preset = 0;
        #10
        preset = 1;
        paddr = 8'h11;
        pwrite = 1'b1;
        psel = 1'b1;
        pwdata = 8'h22;
        @(posedge pclk);
        penable = 1'b1;
        wait_count = 8'h00;
        @(negedge pready);
        penable = 1'b0;
        psel = 1'b0;
        
        preset = 0;
        #10
        preset = 1;
        
        // Write with wait example
        #40
        paddr = 8'h15;
        pwrite = 1'b1;
        psel = 1'b1;
        pwdata = 8'h51;
        @(negedge pclk);
        penable = 1'b1;
        wait_count = 8'h03;
        @(negedge pready);
        penable = 1'b0;
        psel = 1'b0;
        
        preset = 0;
        #10
        preset = 1;
        
        // Read with no wait example
        #40
        paddr = 8'h11;
        pwrite = 1'b0;
        psel = 1'b1;
        prdata = 8'h00;
        @(negedge pclk);
        penable = 1'b1;
        wait_count = 8'h00;
        @(negedge pready);
        penable = 1'b0;
        psel = 1'b0;
        
        preset = 0;
        #10
        preset = 1;
        
        // Read with wait example
        #40
        paddr = 8'h15;
        pwrite = 1'b0;
        psel = 1'b1;
        prdata = 8'h00;
        @(posedge pclk);
        penable = 1'b1;
        wait_count = 8'h03;
        @(negedge pready);
        penable = 1'b0;
        psel = 1'b0;
        
        preset = 0;
        #10
        preset = 1;
        
    end


endmodule
