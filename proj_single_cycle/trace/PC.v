`timescale 1ns / 1ps

module PC (
    input wire clk,             // 时钟信号
    input wire rst,             // 异步复位信号
    input wire [31:0] din,      // 下一条指令地址
    output reg [31:0] pc        // 当前PC地址输出
);

// 在时钟的下降沿更新PC，满足 Trace 时序 & 避免冒险
always @(negedge clk or posedge rst) begin
    if (rst)
        pc <= 32'h00000000;     // Trace要求：复位后PC=0
    else
        pc <= din;              // 正常更新
end

endmodule
