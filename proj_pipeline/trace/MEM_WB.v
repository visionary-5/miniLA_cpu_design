`timescale 1ns / 1ps

module MEM_WB (
    input  wire        clk,
    input  wire        rst,
    
    // 数据信号
    input  wire [31:0] pc_in,
    input  wire [31:0] pc4_in,
    input  wire [31:0] alu_c_in,
    input  wire [31:0] sext2_ext_in,
    input  wire [31:0] dram_rdata_in,
    input  wire [31:0] inst_in,

    // 控制信号
    input  wire [2:0]  wD_sel_in,
    input  wire        wb_ena_in,

    // 输出到WB阶段
    output reg  [31:0] pc_out,
    output reg  [31:0] pc4_out,
    output reg  [31:0] alu_c_out,
    output reg  [31:0] sext2_ext_out,
    output reg  [31:0] dram_rdata_out,
    output reg  [31:0] inst_out,

    output reg  [2:0]  wD_sel_out,
    output reg         wb_ena_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out         <= 32'b0;
            pc4_out        <= 32'b0;
            alu_c_out      <= 32'b0;
            sext2_ext_out  <= 32'b0;
            dram_rdata_out <= 32'b0;
            inst_out       <= 32'b0;

            wD_sel_out     <= 3'b0;
            wb_ena_out     <= 1'b0;
        end else begin
            pc_out         <= pc_in;
            pc4_out        <= pc4_in;
            alu_c_out      <= alu_c_in;
            sext2_ext_out  <= sext2_ext_in;
            dram_rdata_out <= dram_rdata_in;
            inst_out       <= inst_in;

            wD_sel_out     <= wD_sel_in;
            wb_ena_out     <= wb_ena_in;
        end
    end

endmodule
