`timescale 1ns / 1ps

// ====================================================
// SEXT1 —— 立即数符号扩展单元1
// 支持 12位、16位、28位三种符号扩展类型
// 用于解析指令不同格式下的立即数
// ====================================================
module SEXT1 (
    input   wire  [2:0]   sext1_op,
    input   wire  [31:0]  inst,

    output  wire  [31:0]  sext1_ext
);

    assign sext1_ext =  (sext1_op == `EXT_OP_IMM12) ? {{20{inst[21]}}, inst[21:10]} :
                        (sext1_op == `EXT_OP_IMM16) ? {{14{inst[25]}}, inst[25:10], 2'b0} :
                        (sext1_op == `EXT_OP_IMM28) ? {{4{inst[9]}}, inst[9:0], inst[25:10], 2'b0} :
                        {32'b0};

endmodule
