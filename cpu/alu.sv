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
    input clk,
    input reset,
    input [15:0] reg1,
    input [15:0] reg2,
    input [15:0] IR,
    input [2:0] ALU_sel,
    input alu_active,
    apb_bus pbus,
    output reg [15:0] alu_out,
    output reg alu_out_ready
    );
    
    localparam IDLE = 2'b00;
    localparam ACCESS = 2'b01;
    localparam ENABLE = 2'b10;
    localparam DONE = 2'b11;

    reg [1:0] state;
    reg [1:0] next_state;

    always @(posedge clk) begin
        if (reset == 1'b1) begin
            state <= 2'b00;
            next_state <= 2'b00;
            alu_out_ready <= 1'b1;
            alu_out <= 16'b0000000000000000;
        end
        else begin
            if (state == IDLE && next_state == DONE) begin
                state <= IDLE;
            end
            else begin
                state <= next_state;
            end
        end
    end 

    always @(posedge clk) begin
        if (alu_active == 1'b1) begin
            case (ALU_sel)
                // Add
                3'b000 : begin
                    alu_out <= reg1 + reg2;
                    alu_out_ready <= 1'b1;
                end
                // Addi
                3'b001 : begin
                    if (reg2[6] == 1'b0) begin
                        alu_out <= reg1 + reg2[5:0];
                    end
                    else begin
                        alu_out <= reg1 - reg2[5:0];
                    end
                    alu_out_ready <= 1'b1;
                end
                // Sub
                3'b010 : begin
                    alu_out <= reg1 - reg2;
                    alu_out_ready <= 1'b1;
                end
                // NAND
                3'b011 : begin 
                    alu_out <= ~(reg1 & reg2);
                    alu_out_ready <= 1'b1;
                end
                // BNE 
                3'b100 : begin
                    if (reg2[12] == 1'b0) begin
                        alu_out <= reg1 + ((reg2[11:10]  << 4) + reg2[3:0]);
                    end
                    else begin
                        alu_out <= reg1 - ((reg2[11:10]  << 4) - reg2[3:0]);
                    end
                    
                    alu_out_ready <= 1'b1;
                end
                // LW 
                3'b101 : begin
                    case (state) 
                        IDLE : begin    
                            pbus.paddr <= reg1 + reg2[6:0];
                            pbus.psel <= 1'b1;
                            pbus.penable <= 1'b0;
                            pbus.pwrite <= 1'b0;
                            next_state <= ACCESS;
                            alu_out_ready <= 1'b0;
                        end
                        ACCESS : begin
                            pbus.penable <= 1'b1;
                            next_state <= DONE;
                        end
                        // Not used?
                        ENABLE : begin
                            next_state <= DONE;
                        end
                        DONE : begin
                            // DO RD <= MEM[PADDR]
                            if (pbus.pready == 1'b1) begin
                                alu_out_ready <= 1'b1;
                                alu_out <= pbus.prdata;
                                next_state <= IDLE;
                                pbus.psel <= 1'b0;
                                pbus.penable <= 1'b0;
                            end
                            else begin
                                next_state <= DONE;
                            end
                        end
                    endcase
                end
                // SW
                3'b110 : begin
                    case (state) 
                        IDLE : begin
                            pbus.paddr <= reg1 + ((IR[12:10]  << 4) + IR[3:0]);
                            pbus.psel <= 1'b1;
                            pbus.penable <= 1'b0;
                            pbus.pwrite <= 1'b1;
                            pbus.pwdata <= reg2;
                            next_state <= ACCESS;
                            alu_out_ready <= 1'b0;
                        end
                        ACCESS : begin
                            pbus.penable <= 1'b1;
                            next_state <= DONE;
                        end
                        // Not used?
                        ENABLE : begin
                            next_state <= DONE;
                        end
                        DONE : begin
                            // DO MEM[PADDR] <= RS2
                            if (pbus.pready == 1'b1) begin
                                alu_out_ready <= 1'b1;
                                next_state <= IDLE;
                            end
                            else begin
                                next_state <= DONE;
                            end
                        end
                    endcase
                end
                // J
                3'b111 : begin
                    alu_out <= reg1 + reg2[6:0];
                    alu_out_ready <= 1'b1;
                end
                default : begin
                    alu_out <= reg1 + reg2;
                    alu_out_ready <= 1'b1;
                end
            endcase
        end 
    end
    
endmodule
