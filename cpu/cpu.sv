`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/24/2021 10:05:26 AM
// Design Name: 
// Module Name: cpu
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

module mux_2_to_1(
    input [15:0] reg1,
    input [15:0] reg2,
    input mux_sel,
    output reg [15:0] reg_out
    );
    
    always_comb begin
        case (mux_sel) 
            1'b0 : reg_out <= reg1;
            1'b1 : reg_out <= reg2;
        endcase
    end
endmodule

module cpu_data_path(
    input clk,
    input data_in,
    input reset,
    inout [15:0] apb_bus_ctrl,
    
    input [2:0] rf_wr_sel,
    input [2:0] reg_1_sel,
    input [2:0] reg_2_sel,
    
    input IR_in,
    input PC_sel,
    input R1_sel,
    input R2_sel,
    input [2:0] ALU_sel,
    input rf_write_sel,
    input write_rf_bool,
    
    
    output APB_addr,
    output reg [15:0] reg_1_out,
    //output APB_bus_ctrl,
    
    // APB_Bus
    apb_bus pbus
    );
    
    // Registers File declarations for registers and wires
    wire wr_en;
    reg [15:0] rf_write;
    
    //wire [15:0] reg_1_out;
    wire [15:0] reg_2_out;
    wire [15:0] alu_out;
    
    rf RF(.clk(clk), .wr_en(wr_en), .wr_port(rf_write), .wr_sel(rf_wr_sel),
          .rd_a_sel(reg_1_sel), .rd_b_sel(reg_2_sel), .rd_a_port(reg_1_out), .rd_b_port(reg_2_out));
    
    alu alu_unit(.reg1(alu_r1), .reg2(alu_r2), .addsub(ALU_sel), .alu_out(alu_out));
    
    
    reg [15:0] IR;
    reg [15:0] PC;
    
    // Wires within the CPU    
    
    reg [15:0] alu_r1;
    reg [15:0] alu_r2;
    
    // Implement MUXs for PC, R1_Sel (for ALU), R2_Sel (for ALU) and rf_write_sel
    always_ff @(posedge clk) begin
        if (reset == 1) begin
            alu_r1 <= 0;
            alu_r2 <= 0;
            rf_write <= 0;
            IR <= 0;
            PC <= 0;
        end
        else begin
            case (R1_sel)
                1'b0 : alu_r1 <= reg_1_out;
                1'b1 : alu_r1 <= PC;
            endcase
            
            case (R2_sel) 
                1'b0 : alu_r2 <= reg_2_out;
                1'b1 : alu_r2 <= IR[6:0];
            endcase

        end
    end

    always_ff @(negedge clk) begin 
        if (reset == 1'b0) begin
            case (PC_sel)
                1'b0 : PC <= PC + 1;
                1'b1 : PC <= alu_out;
            endcase

            case (rf_write_sel)
                1'b0 : rf_write <= data_in;
                1'b1 : rf_write <= alu_out;
            endcase
        end
    end
   
        
    
    
    
    
endmodule
