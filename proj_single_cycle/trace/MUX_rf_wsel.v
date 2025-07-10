`timescale 1ns / 1ps
`include "defines.vh"

module MUX_rf_wsel (
    input  wire [1:0] sel,           // 控制信号 rf_wsel
    input  wire [31:0] pc4,          // pc + 4
    input  wire [31:0] alu_c,        // ALU 结果
    input  wire [31:0] dram_data,    // RAM 输出数据
    input  wire [31:0] sext1_ext,    // SEXT1 扩展结果
    output reg  [31:0] wD            // 最终写回数据
);

always @(*) begin
    case (sel)
        `WSEL_ALU:   wD = alu_c;
        `WSEL_RAM:   wD = dram_data;
        `WSEL_PC:    wD = pc4;
        `WSEL_SEXT:  wD = sext1_ext;
        default:     wD = 32'h0000_0000;
    endcase
end

endmodule
