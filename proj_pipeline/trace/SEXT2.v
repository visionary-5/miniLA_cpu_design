`timescale 1ns / 1ps

`include "defines.vh"

// ====================================================
// SEXT2 —— DRAM数据符号扩展单元
// 仅用于对 DRAM 读出的字节/半字数据做有符号扩展
// 支持8位、16位两种扩展
// ====================================================
module SEXT2 (
    output  wire  [31:0]  sext2_ext,     // 扩展后数据输出

    input   wire          sext2_op,     // 扩展类型选择
    input   wire  [31:0]  dram_rdata     // 原始DRAM读数据
);

    assign sext2_ext =
        (sext2_op == `EXT2_SEL_BYTE) ? {{24{dram_rdata[7]}}, dram_rdata[7:0]} :
        (sext2_op == `EXT2_SEL_HALF) ? {{16{dram_rdata[15]}}, dram_rdata[15:0]} :
        32'b0; // 默认输出零

endmodule
