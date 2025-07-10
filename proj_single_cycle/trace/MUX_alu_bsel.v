`timescale 1ns / 1ps
`include "defines.vh"

module MUX_alu_bsel (
    input  wire [1:0] sel,           // 控制信号 alu_bsel
    input  wire [31:0] rD2,          // 寄存器堆第二读口输出（rs2）
    input  wire [31:0] sext1_ext,    // SEXT1 拓展立即数
    input  wire [31:0] sext2_ext,    // SEXT2 拓展偏移
    output reg  [31:0] B             // ALU 的 B 端输入
);

always @(*) begin
    case (sel)
        `ALUB_RS2:   B = rD2;
        `ALUB_IMM1:  B = sext1_ext;
        `ALUB_IMM2:  B = sext2_ext;
        default:     B = 32'h0000_0000;
    endcase
end

endmodule
