`timescale 1ns / 1ps

// ===================================================
// PC —— 程序计数器寄存器
// 上升沿同步写入，异步复位，支持外部直接赋值
// ===================================================
module PC (
    output  reg   [31:0]  pc,      // 当前PC输出
    input   wire          pc_clk,  // 时钟信号
    input   wire          pc_rst,  // 异步复位，高有效
    input   wire  [31:0]  din      // 下一个PC输入
);

    // PC寄存器实现
    always @(posedge pc_clk or posedge pc_rst) begin
        if (pc_rst) begin
            pc <= 32'b0;           // 复位时清零
        end else begin
            pc <= din;             // 时钟上升沿采样
        end
    end

endmodule
