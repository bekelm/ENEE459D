`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/31/2021 11:14:32 AM
// Design Name: 
// Module Name: CPU_master
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
  logic       psel;
  logic       penable;
  logic [15:0] prdata;
  logic       pready;
  logic [15:0] pwdata;
endinterface


module CPU_master(
    input clk,
    input data_in,
    input reset
    );
    
    reg apb_bus_ctrl;
    reg [2:0] rf_wr_sel;
    reg [2:0] reg_1_sel;
    reg [2:0] reg_2_sel;
    reg IR_in;
    reg PC_sel;
    reg R1_sel;
    reg R2_sel;
    reg AddSub;
    reg rf_write_sel;
    //reg APB_addr;
    //reg APB_bus_ctrl;
    
    
    reg [15:0]APB_addr;
    reg [15:0]APB_bus_ctrl;
    
    apb_bus pbus(.pclk(pclk));
    
    cpu_data_path cpu_core(
        .clk(clk),
        .data_in(data_in),
        .reset(reset),
        .apb_bus_ctrl(apb_bus_ctrl),
        .rf_wr_sel(rf_wr_sel),
        .reg_1_sel(reg_1_sel),
        .reg_2_sel(reg_2_sel),
        .IR_in(IR_in),
        .PC_sel(PC_sel),
        .R1_sel(R1_sel),
        .R2_sel(R2_sel),
        .AddSub(AddSub),
        .rf_write_sel(rf_write_sel),
        .APB_addr(APB_addr),
        .pbus(pbus)
    );
    
    
    
    
endmodule
