`timescale 1ns / 1ps

// EX/MEM流水段寄存器模块
// 用于连接执行(EX)和访存(MEM)阶段，保存各类信号，实现数据在中后段流水线的正确传递
module EXMEM (
    input wire rst,         // 复位信号
    input wire clk,         // 时钟信号

    // 控制信号与数据通路
    input wire sext2_sel_in,        // SEXT2选择信号
    output reg sext2_sel_out,
    input wire wb_ena_in,           // 写使能
    output reg wb_ena_out,
    input wire [2:0] wD_sel_in,     // 写回数据选择
    output reg [2:0] wD_sel_out,
    input wire [1:0] dram_sel_in,   // DRAM操作类型
    output reg [1:0] dram_sel_out,
    input wire [1:0] npc_op_in,     // 下一PC操作类型
    output reg [1:0] npc_op_out,
    input wire [4:0] wb_reg_in,     // 写回寄存器编号
    output reg [4:0] wb_reg_out,
    input wire [31:0] wb_reg_value_in, // 写回寄存器值
    output reg [31:0] wb_reg_value_out,

    // 冒险相关信号
    input wire [31:0] wb_value_in,   // 写回数据（用于前递）
    output reg [31:0] wb_value_out,

    // 其它数据通路信号
    input wire [31:0] alu_c_in,      // ALU计算结果
    output reg [31:0] alu_c_out,

    input wire [1:0] addr_mode_in,   // 地址模式
    output reg [1:0] addr_mode_out,

    input wire        have_inst_in,  // 是否为有效指令
    output reg        have_inst_out,

    input wire [31:0] rf_rD2_in,     // 通用寄存器2
    output reg [31:0] rf_rD2_out,

    input wire [31:0] sext1_in,      // 符号扩展结果
    output reg [31:0] sext1_out,

    input wire [31:0] pc_in,         // 当前PC
    output reg [31:0] pc_out,

    input wire [31:0] pc4_in,        // PC+4
    output reg [31:0] pc4_out,

    input wire [31:0] inst_in,       // 指令原码
    output reg [31:0] inst_out
);

    // 时钟/复位同步，保存所有信号，实现EX到MEM的完整传递
    always @(posedge rst or posedge clk) begin
        if (rst) begin
            // 复位时全部清零，防止错误数据进入MEM
            wb_ena_out <= 0;
            wD_sel_out <= 0;
            dram_sel_out <= 0;
            alu_c_out <= 0;
            addr_mode_out <= 0;
            rf_rD2_out <= 0;
            sext1_out <= 0;
            npc_op_out <= 2'b00;
            pc_out <= 32'b0;
            pc4_out <= 32'b0;
            inst_out <= 32'b0;
            have_inst_out <= 0'b0;
            wb_reg_out <= 0;
            wb_reg_value_out <= 0;
            wb_value_out <= 0;
            sext2_sel_out <= 0;
        end else begin
            // 正常工作时，所有信号逐拍传递到MEM阶段
            wb_ena_out <= wb_ena_in;
            wD_sel_out <= wD_sel_in;
            dram_sel_out <= dram_sel_in;
            alu_c_out <= alu_c_in;
            addr_mode_out <= addr_mode_in;
            rf_rD2_out <= rf_rD2_in;
            sext1_out <= sext1_in;
            npc_op_out <= npc_op_in;
            pc_out <= pc_in;
            pc4_out <= pc4_in;
            inst_out <= inst_in;
            have_inst_out <= have_inst_in;
            wb_reg_out <= wb_reg_in;
            wb_reg_value_out <= wb_reg_value_in;
            wb_value_out <= wb_value_in;
            sext2_sel_out <= sext2_sel_in;
        end
    end


endmodule