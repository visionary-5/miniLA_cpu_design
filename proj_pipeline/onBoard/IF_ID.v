`timescale 1ns / 1ps

// IF/ID流水段寄存器模块
// 用于连接取指(IF)和译码(ID)阶段，保存指令及相关PC信息，实现数据在前两级流水线的正确传递
module IFID (
    input wire rst,         // 复位信号
    input wire clk,         // 时钟信号

    // 控制信号
    input wire        flush,    // 清空（气泡）信号，控制/数据冒险时置零
    input wire        stop,     // 暂停信号，数据冒险时保持原值
    
    // 数据信号
    input wire [31:0] inst_in,  // 取指阶段输出的指令
    output reg [31:0] inst_out, // 传递到ID阶段的指令
    input wire [31:0] pc_in,    // 当前PC
    output reg [31:0] pc_out,   // 传递到ID阶段的PC
    input wire [31:0] pc4_in,   // PC+4
    output reg [31:0] pc4_out   // 传递到ID阶段的PC+4
);

    // 时钟/复位同步，保存所有信号，实现IF到ID的完整传递
    always @(posedge rst or posedge clk) begin
        if (rst) begin
            // 复位时全部清零，防止错误数据进入ID
            inst_out <= 32'b0;
            pc_out <= 32'b0;
            pc4_out <= 32'b0;
        end else if (flush) begin
            // flush时插入气泡，清空流水段，消除冒险
            inst_out <= 32'b0;
            pc_out <= 32'b0;
            pc4_out <= 32'b0;
        end else if (stop) begin
            // 暂停时保持原值，防止新指令进入
            inst_out <= inst_out;
            pc_out <= pc_out;
            pc4_out <= pc4_out;
        end else begin
            // 正常工作时，所有信号逐拍传递到ID阶段
            inst_out <= inst_in;
            pc_out <= pc_in;
            pc4_out <= pc4_in;
        end
    end


endmodule