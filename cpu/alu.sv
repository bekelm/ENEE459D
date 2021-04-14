`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/31/2021 10:15:34 AM
// Design Name: 
// Module Name: alu
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


module alu(
    input [15:0] reg1,
    input [15:0] reg2,
    input [2:0] ALU_sel,
    output reg [15:0] alu_out
    );
    
    always @(*) begin
        case (ALU_sel)
            // Add
            3'b000 : alu_out <= reg1 + reg2;
            // Sub
            3'b001 : alu_out <= reg1 - reg2;
            // NAND
            3'b010 : alu_out <= ~(reg1 & reg2);
            //
            default : alu_out <= reg1 + reg2;
        endcase
    end
    
endmodule
