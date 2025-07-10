`timescale 1ns / 1ps

module DRAM (
    input  wire        clk,     // 时钟
    input  wire [15:0] adr,     // 地址
    input  wire        we,      // 写使能（1 写，0 读）
    input  wire [31:0] wdin,    // 写入数据
    output wire [31:0] rdo      // 读出数据
);

    // 定义 16KB 内存（可调），4K 个 32 位字
    reg [31:0] mem [0:4095];    

    // 异步读
    assign rdo = mem[adr[13:2]];  // 以 word 对齐寻址（舍去 adr[1:0]）

    // 同步写
    always @(posedge clk) begin
        if (we) begin
            mem[adr[13:2]] <= wdin;
        end
    end

endmodule
