`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/07/2021 10:21:00 AM
// Design Name: 
// Module Name: CPU_control
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


module CPU_control (
    input clk,
    input reset,
    input [15:0] IR,
    input [15:0] reg_1,
    input [15:0] reg_2,
    
    output [15:0] apb_bus_ctrl,

    output reg [2:0] rf_wr_sel,
    output reg [2:0] reg_1_sel,
    output reg [2:0] reg_2_sel,

    output reg IR_in,
    output reg PC_sel,
    output reg R1_sel,
    output reg R2_sel,
    output reg [2:0]ALU_sel,
    output reg rf_write_sel,
    output reg write_rf_bool
);

    // Instruction formats
    // Instruction format 1: 
    // | 3 bit  | 3 bit | 3 bit | 3 bit | 4 bit |
    // | opcode |  rd   |  rs1  |  rs2  |   -   |

    // Instruction format 2:
    // | 3 bit  | 3 bit | 3 bit |      7 bit     |
    // | opcode |  rd   |  rs1  |signed immediate|

    // Instruction format 3: 
    // | 3 bit  |  3 bit   | 3 bit | 3 bit |  4 bit   |
    // | opcode | imm[6:4] |  rs1  |  rs2  | imm[3:0] |

    always_ff @(posedge clk) begin
        reg sel = IR[15:13];
        case (sel)
            // ADD - instruction format 1 -  rd <= rs1 + rs2
            3'b000 : begin
                rf_wr_sel <= IR[12:10];
                reg_1_sel <= IR[9:7];
                reg_2_sel <= IR[6:4];
                R1_sel <= 1'b0;
                R2_sel <= 1'b0;
                PC_sel <= 1'b0;
                ALU_sel <= 3'b000;
                rf_write_sel <= 1'b1;
                write_rf_bool <= 1'b1;
            end
            
            // ADDI - instruction format 2 - rd <= rs1 + imm
            3'b001 : begin
                rf_wr_sel <= IR[12:10];
                reg_1_sel <= IR[9:7];
                R1_sel <= 1'b0;
                R2_sel <= 1'b1;
                PC_sel <= 1'b0;
                ALU_sel <= 1'b000;
                rf_write_sel <= 1'b1;
                write_rf_bool <= 1'b1;
            end

            // SUB - instruction format 1 - rd <= rs1 - rs2
            3'b010 : begin
                rf_wr_sel <= IR[12:10];
                reg_1_sel <= IR[9:7];
                reg_2_sel <= IR[6:4];
                R1_sel <= 1'b0;
                R2_sel <= 1'b0;
                PC_sel <= 1'b0;
                ALU_sel <= 3'b001;
                rf_write_sel <= 1'b1;
                write_rf_bool <= 1'b1;
            end
            
            // NAND - instruction format 1 - rd <= rs1 NAND rs2
            3'b011 : begin
                rf_wr_sel <= IR[12:10];
                reg_1_sel <= IR[9:7];
                reg_2_sel <= IR[6:4];
                R1_sel <= 1'b0;
                R2_sel <= 1'b0;
                PC_sel <= 1'b0;
                ALU_sel <= 3'b010;
                rf_write_sel <= 1'b1;
                write_rf_bool <= 1'b1;
            end

            // BNE - instruction format 3 - if rs1 != rs2 
            //                              PC <= PC + imm
            3'b100 : begin
                reg_1_sel <= IR[9:7];
                reg_2_sel <= IR[6:4];
                R1_sel <= 1'b0;
                R2_sel <= 1'b0;
                PC_sel <= 1'b0;
                ALU_sel <= 3'b010;
                rf_write_sel <= 1'b1;
                write_rf_bool <= 1'b0;
            end
            // LW - instruction format 1 - rd <= mem[rs1+imm]
            3'b101 : begin
                
            end

            // SW - instruction format 3 - mem[rs1 + imm] <= rs2
            3'b110 : begin
            
            end
            
            // J - instruction format 1 - PC <= rs1 + imm
            3'b111 : begin
            
            end
            
        endcase
    end


endmodule