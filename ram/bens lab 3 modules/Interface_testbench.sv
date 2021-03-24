`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Kelm
// 
// Create Date: 02/17/2021 09:34:35 AM
// Design Name: 
// Module Name: Interface_testbench
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

interface intf (input logic pclk);
    logic pwrite, psel, penable;
    logic [7:0] paddr;
    logic [7:0] pwdata;
    logic [7:0] prdata;
    logic [7:0] wait_count;
    logic [7:0] wait_left;
    logic pready, pslverr;
    logic [1:0] out_state;
    logic preset;
    
    task initialize;
        begin
        @(negedge pclk);
        pwrite = 0;
        psel = 0;
        penable = 0;
        pwdata = 0;
        prdata = 0;
        pslverr = 0;
        paddr = 0;
        wait_count = 0;
        end
    endtask: initialize
    
    // Write with optional wait(set to 0 if no wait is desired)
    task write(input [7:0] paddr_in, input [7:0] wait_count_in, input [7:0] pwdata_in);
        begin
        pwrite <= 1'b1;
        psel <= 1'b1;
        paddr <= paddr_in;
        wait_count <= wait_count_in;
        pwdata <= pwdata_in;
        @(posedge pclk);
        penable = 1'b1;
        @(negedge pready);
        penable = 1'b0;
        psel = 1'b0;
        end
    endtask: write
    
    // Read with optional wait (set to 0 if no wait is desired)
    task read (input [7:0] paddr_in, input [7:0] wait_count_in);
        begin
        pwrite = 1'b0;
        psel = 1'b1;
        prdata = 8'h00;
        paddr <= paddr_in;
        wait_count <= wait_count_in;
        @(posedge pclk);
        penable = 1'b1;
        @(negedge pready);
        penable = 1'b0;
        psel = 1'b0;
        end
    endtask: read
    
    task reset();
        begin
        #10
        preset = 0;
        #10
        preset = 1;
        end
    endtask: reset
    
endinterface : intf


module Interface_testbench();
    logic pclk, psel, penable, pready;
    logic [7:0] paddr;
    logic [7:0] pwdata;
    logic [7:0] prdata;
    logic [7:0] wait_count;
    logic [1:0] out_state;
    logic [7:0] wait_left;
    
    
    intf amba(.pclk(pclk));
    AMBA_3_APB slave_driver(.pclk(pclk), .preset(amba.preset), .paddr(amba.paddr), .pwrite(amba.pwrite), 
        .psel(amba.psel), .penable(amba.penable), .pwdata(amba.pwdata), .prdata(amba.prdata), .pready(amba.pready), 
        .pslverr(amba.pslverr), .wait_count(amba.wait_count), .out_state(amba.out_state), .wait_left(amba.wait_left));
    
    // Instintiate clock at 0
    initial begin
        pclk = 0;
        amba.initialize();
    end
    
    // Set clock to flip every 5ns
    always begin
        #5 pclk = ~pclk;
    end
    
    // Set up variables to be observed in testbench simulation
    always begin
        #1
        psel <= amba.psel;
        penable <= amba.penable;
        paddr <= amba.paddr;
        pwdata <= amba.pwdata;
        prdata <= amba.prdata;
        wait_count <= amba.wait_count;
        out_state <= amba.out_state;
        wait_left <= amba.wait_left;
        pready <= amba.pready;
    end
    
    initial begin
        // Write with no wait example
        amba.reset();
        #20
        amba.write(.paddr_in(8'h11), .wait_count_in(8'h00), .pwdata_in(8'h22));
        
        // Write with wait example
        amba.reset();
        #40
        amba.write(.paddr_in(8'h15), .wait_count_in(8'h03), .pwdata_in(8'h51));
                    
        // Read with no wait example
        amba.reset();
        #40
        amba.read(.paddr_in(8'h11), .wait_count_in(8'h00));
        
        // Read with wait example
        amba.reset();
        #40
        amba.read(.paddr_in(8'h15), .wait_count_in(8'h03));
        
    end

endmodule
