`timescale 1ns / 1ps
`include "defines.vh"

module RF (
    input  wire        clk,
    input  wire        rst,

    input  wire        rf_we,      // 写使能
    input  wire [4:0]  rR1,        // 读端口1地址
    input  wire [4:0]  rR2,        // 读端口2地址
    input  wire [4:0]  WR,         // 写地址
    input  wire [31:0] WD,         // 写数据

    output wire [31:0] RD1,        // 读端口1数据
    output wire [31:0] RD2         // 读端口2数据
);

    // 32个32位寄存器，r0始终为0
    reg [31:0] regs [31:0];
    integer i;

    // 初始化（可选，用于仿真观察）
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'h00000000;
    end

    // 写操作：上升沿同步写入，r0不能写
    always @(posedge clk) begin
        if (rf_we && (WR != 5'd0))
            regs[WR] <= WD;
    end

    // 异步读：组合逻辑
    assign RD1 = (rR1 == 5'd0) ? 32'h00000000 : regs[rR1];
    assign RD2 = (rR2 == 5'd0) ? 32'h00000000 : regs[rR2];

endmodule
