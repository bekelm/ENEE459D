`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Benjamin Kelm
// 
// Create Date: 02/10/2021 09:41:12 AM
// Design Name: 
// Module Name: AMBA_3_APB
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


module AMBA_3_APB(pclk, preset, paddr, pwrite, psel, penable, pwdata, prdata, pready, pslverr, wait_count, out_state, wait_left);
    // Initialize all of the appropriate input and output signals for the AMBA_3_APB module
    // Additionally initialize a "wait_count" to determine if the module will use a wait state or not
    input logic pclk, pwrite, psel, penable;
    input logic [7:0] paddr;
    input logic [7:0] pwdata;
    input logic [7:0] wait_count;
    input logic preset;
    output logic [7:0] prdata;
    output logic pready;
    output logic pslverr;
    output logic [1:0] out_state;
    
    // Create an enum with the 4 states used, IDLE, SETUP, WAIT_STATE, and ACCESS
    enum logic [1:0] {
        IDLE = 2'b00, 
        SETUP = 2'b01,
        WAIT_STATE = 2'b10
    } state, next_state;
    
    // Instantiate the necessary inputs for the previously used memory module
    logic ce, wren, rden;
    
    // Instantiate the slave memory module
    memory slave_mem(.clk(pclk), .addr(paddr), .ce(ce), .wren(wren),
                    .rden(rden), .wr_data(pwdata), .rd_data(prdata));
    
    // Create a counter for how many cycles left to wait
    output logic [7:0] wait_left;
    
    // Output current state for debugging purposes
    always @(*) begin
        out_state = state;
    end
    
    always @ (posedge pclk or negedge preset)  begin
        if (preset == 0) begin
            state <= IDLE;
            next_state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end
        
    always_comb begin
        // if in the IDLE state and PSEL is 1, the next state will be SETUP
        if (state == IDLE && psel == 1) begin
            next_state <= SETUP;
        end
        // Otherwise if already in SETUP and penable = 1, go to WAIT_STATE 
        // if wait_count is non-zero or IDLE if there is no wait_count
        else if (state == SETUP && penable == 1) begin
            if (wait_count != 0) begin
                next_state <= WAIT_STATE;
                wait_left <= wait_count - 1;
            end
            else begin
                next_state <= IDLE;
            end
        end 
    end
    
    always_comb begin
        // If in WAIT_STATE and there is no time left to wait the next state will be IDLE
        if (state == WAIT_STATE && wait_left == 0 && penable == 1) begin
            next_state <= IDLE;
        end
    end
    
    // WAIT_STATE logic placed here
    always_ff @(posedge pclk) begin
        // If in WAIT_STATE and the time left to wait is non-zero subtract one
        if (state == WAIT_STATE && wait_left > 0) begin
            wait_left <= wait_left - 1;
        end
    end
    
    // If in the ACCESS state, begin a memory access, read if pwrite = 0
    // write if pwrite = 1
    always_comb begin
        if ((state == SETUP && penable == 1 && wait_count == 0) || (state == WAIT_STATE && wait_left == 0 && penable == 1)) begin
            pready <= 1;
            ce <= 1;
            wren <= pwrite;
            rden <= ~pwrite;
        end 
        else begin
            pready <= 0;
            ce <= 0;
            wren <= 0;
            rden <= 0;
        end  
    end
    
    
endmodule
