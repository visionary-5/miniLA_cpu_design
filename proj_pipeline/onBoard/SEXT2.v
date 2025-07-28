`timescale 1ns / 1ps

`include "defines.vh"

// SEXT2模块：用于对DRAM读取的数据进行符号扩展
// 只在访存阶段对字节、半字数据进行符号扩展
module SEXT2 (
    input   wire          sext2_sel,      // 扩展类型选择信号
    input   wire  [31:0]  dram_rdata,     // DRAM读取数据
    output  wire  [31:0]  sext2_ext       // 扩展后输出
);
    // 根据sext2_sel选择字节或半字符号扩展，默认输出全0（不应到达）
    assign sext2_ext =  (sext2_sel == `EXT2_SEL_BYTE) ? {{24{dram_rdata[7]}}, dram_rdata[7:0]} :
                        (sext2_sel == `EXT2_SEL_HALF) ? {{16{dram_rdata[15]}}, dram_rdata[15:0]} :
                        {32'b0}; // 理论上不应到达此分支

endmodule
