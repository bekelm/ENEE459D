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
  //logic       psel;
  logic       penable;
  logic [15:0] prdata;
  logic       pready;
  logic [15:0] pwdata;
  logic       preset;
endinterface


module CPU_master(
    input clk,
    //input data_in,
    input reset,
    apb_bus pbus,
    output reg psel
    //,
    //apb_bus ir_bus,
    //apb_bus IR_ram//,
   // input [15:0] IR_vals [0:255]
    );
    
    localparam PC_READ = 2'b00;
    localparam IDLE     = 2'b01;
    localparam ACCESS   = 2'b10;
    localparam READ     = 2'b11;
    
    reg [15:0] reg_1;
    reg [15:0] reg_2;
    reg [15:0] PC;
    reg [15:0] PC_out;
    reg [15:0] IR;

    //reg [15:0] apb_bus_ctrl;
    reg [2:0] rf_wr_sel;
    reg [2:0] reg_1_sel;
    reg [2:0] reg_2_sel;
    reg IR_in;
    reg PC_sel;
    reg R1_sel;
    reg R2_sel;
    //reg AddSub;
    reg rf_write_sel;
    reg next_IR;
    reg [2:0] ALU_sel;
    reg write_rf_bool;

    //reg APB_addr;
    //reg APB_bus_ctrl;
    
    reg [15:0]APB_addr;
    //reg [15:0]APB_bus_ctrl;
    
    //apb_bus pbus(.pclk(clk));
    
    /*
    always_ff @(posedge clk) begin
        if (reset == 1) begin
            IR <= IR_vals[0];
        end
        else begin
            IR <= IR_vals[PC];
        end
    end
    */
    
    //apb_bus ir_bus(.pclk(clk));
    //apb_ram IR_ram(.bus(ir_bus));
    //reg rf_write;
    reg [1:0] ir_write_state;
    reg [1:0] next_state;
    reg read_IR;
    
    //reg reading_alu;
    reg begin_instruction;

    always @(posedge clk) begin
        if (reset == 1'b0 && read_IR == 1'b1) begin
            if (ir_write_state == PC_READ && next_state == READ) begin
                ir_write_state <= PC_READ;
            end
            else begin
                ir_write_state <= next_state;
            end
        end
    end

    always @(posedge clk) begin
        if (next_IR == 1'b1) begin
            read_IR <= 1'b1;
        end
        if (ir_write_state > 2'b00) begin
            read_IR <= 1'b1;
        end
    end


    always @(posedge clk) begin
        if (reset == 1) begin
            //rf_write <= 0;
            //IR <= 0;
            //PC <= 0;
            ir_write_state <= PC_READ;
            next_state <= PC_READ;
            psel <= 1'b0;
            pbus.penable <= 1'b0;
            //next_IR <= 1'b1;
            begin_instruction <= 1'b0;
            read_IR <= 1'b0;
            PC <= -1;
        end
        else begin
            if (read_IR == 1'b1) begin
                case (ir_write_state) 
                    PC_READ : begin 
                        PC <= PC_out;
                        next_state <= IDLE;
                        begin_instruction <= 1'b0;
                    end
                    IDLE : begin
                        psel <= 1'b1;
                        pbus.penable <= 1'b0;
                        pbus.paddr <= PC;
                        pbus.pwrite <= 1'b0;
                        next_state <= ACCESS;
                    end
                    ACCESS : begin
                        pbus.penable <= 1'b1;
                        next_state <= READ;
                    end
                    READ : begin
                        if (pbus.pready == 1'b1 && pbus.prdata != 4'bXXXX) begin
                            IR <= pbus.prdata;
                            psel <= 1'b0;
                            pbus.penable <= 1'b0;
                            next_state <= PC_READ;
                            begin_instruction <= 1'b1;
                            read_IR <= 1'b0;
                        end
                        else if (ir_write_state != PC_READ) begin
                            next_state <= READ;
                        end
                    end

                endcase
                /*
                if (ir_write_state == PC_READ) begin
                    PC <= PC_out;
                    next_state <= IDLE;
                end
                else if (ir_write_state == IDLE) begin
                    pbus.psel <= 1'b1;
                    pbus.penable <= 1'b0;
                    pbus.paddr <= PC;
                    pbus.pwrite <= 1'b0;
                    next_state <= ACCESS;
                end
                else if (ir_write_state == ACCESS) begin
                    pbus.penable <= 1'b1;
                    next_state <= READ;
                end
                else if (ir_write_state == READ) begin
                    if (pbus.pready == 1'b1) begin
                        IR <= pbus.prdata;
                        pbus.psel <= 1'b0;
                        pbus.penable <= 1'b0;
                        next_state <= PC_READ;
                        begin_instruction <= 1'b1;
                    end
                    else begin
                        if (ir_write_state != PC_READ) begin
                            next_state <= READ;
                        end
                    end
                end
                */
            end
        end
    end
    
    
    CPU_control cpu_logic(
        .clk(clk),
        .reset(reset),
        .IR(IR),
        .reg_1(reg_1),
        .reg_2(reg_2),
        //.apb_bus_ctrl(apb_bus_ctrl),

        .rf_wr_sel(rf_wr_sel),
        .reg_1_sel(reg_1_sel),
        .reg_2_sel(reg_2_sel),

        //.IR_in(IR_in),
        .PC_sel(PC_sel),
        .R1_sel(R1_sel),
        .R2_sel(R2_sel),
        .ALU_sel(ALU_sel),
        .rf_write_sel(rf_write_sel),
        .write_rf_bool(write_rf_bool)
    );
    
    cpu_data_path cpu_core(
        .clk(clk),
        .data_in(data_in),
        .reset(reset),
        //.apb_bus_ctrl(apb_bus_ctrl),
        .rf_wr_sel(rf_wr_sel),
        .reg_1_sel(reg_1_sel),
        .reg_2_sel(reg_2_sel),
        //.IR_in(IR_in),
        .IR(IR),
        .PC_sel(PC_sel),
        .R1_sel(R1_sel),
        .R2_sel(R2_sel),
        //.AddSub(AddSub),
        .ALU_sel(ALU_sel),
        .rf_write_sel(rf_write_sel),
        .write_rf_bool(write_rf_bool),
        .begin_instruction(begin_instruction),
        .PC(PC),


        .APB_addr(APB_addr),
        .reg_1_out(reg_1),
        .reg_2_out(reg_2),
        .PC_out(PC_out),
        .next_IR(next_IR),
        .pbus(pbus)
    );
    
    
    
    
endmodule
