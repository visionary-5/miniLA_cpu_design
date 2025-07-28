`timescale 1ns / 1ps 
`include "defines.vh"

// 算术逻辑单元（ALU）模块
module ALU (
    input wire [31:0] inst,           // 指令原码

    // ALU操作类型
    input wire [3:0] alu_op,

    // 可能的A操作数
    input wire [31:0] pc,             // 程序计数器
    input wire [31:0] rf_rD1,         // 通用寄存器1

    // 可能的B操作数
    input wire [31:0] rf_rD2,         // 通用寄存器2
    input wire [31:0] sext1,          // 符号扩展立即数
    input wire [31:0] zext,           // 零扩展立即数

    // A、B操作数的选择信号
    input wire [2:0] alu_sel,

    output wire [31:0] alu_c,         // 运算结果
    output wire alu_f                 // 比较结果（条件分支用）
);

    // 选择A操作数：部分指令用PC，部分用寄存器
    wire [31:0] A =  (alu_sel == `ALU_SEL_IMM20) ? pc : rf_rD1;
    
    // 选择B操作数：支持多种立即数和寄存器
    wire [31:0] B =  (alu_sel == `ALU_SEL_RF2) ? rf_rD2 :
                (alu_sel == `ALU_SEL_RF2_LOW5) ? {27'b0, rf_rD2[4:0]} :
                (alu_sel == `ALU_SEL_IMM5) ? {27'b0, inst[14:10]} :
                (alu_sel == `ALU_SEL_IMM20) ? {inst[24:5], 12'b0} :
                (alu_sel == `ALU_SEL_SEXT1) ? sext1 :
                (alu_sel == `ALU_SEL_ZEXT) ? zext :
                {32'b0};

    // 右移和算术右移辅助信号
    wire [31:0] shifted = A >> B[4:0];
    wire [31:0] sign_mask = ~(32'hFFFFFFFF >> B[4:0]);
    wire [31:0] sra = shifted | (A[31] ? sign_mask : 32'b0); // 算术右移

    // 计算ALU输出
    assign alu_c =  (alu_op == `ALU_OP_ADD) ? A + B :
                (alu_op == `ALU_OP_SUB) ? A - B :
                (alu_op == `ALU_OP_OR) ? A | B :
                (alu_op == `ALU_OP_XOR) ? A ^ B :
                (alu_op == `ALU_OP_AND) ? A & B :
                (alu_op == `ALU_OP_SLL) ? A << B[4:0] :
                (alu_op == `ALU_OP_SRL) ? A >> B[4:0] :
                (alu_op == `ALU_OP_SRA) ?  sra :
                (alu_op == `ALU_OP_EQ) ? A == B :
                (alu_op == `ALU_OP_NEQ) ? A != B :
                (alu_op == `ALU_OP_LT_S) ? $signed(A) < $signed(B) :
                (alu_op == `ALU_OP_LT_U) ? A < B :
                (alu_op == `ALU_OP_GE_S) ? $signed(A) >= $signed(B) :
                (alu_op == `ALU_OP_GE_U) ? A >= B :
                {32'b0};

    // 比较输出：用于条件分支等
    assign alu_f =  (alu_op == `ALU_OP_EQ) ? A == B :
                (alu_op == `ALU_OP_NEQ) ? A != B :
                (alu_op == `ALU_OP_LT_S) ? $signed(A) < $signed(B) :
                (alu_op == `ALU_OP_LT_U) ? A < B :
                (alu_op == `ALU_OP_GE_S) ? $signed(A) >= $signed(B) :
                (alu_op == `ALU_OP_GE_U) ? A >= B :
                {1'b0};

endmodule
