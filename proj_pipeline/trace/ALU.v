`timescale 1ns / 1ps
`include "defines.vh"

// ===============================================
// 算术逻辑单元 ALU（分级辅助信号表达版）
// ===============================================
module ALU (
    input wire [31:0] inst,
    input wire [3:0] alu_op,
    input wire [31:0] pc,
    input wire [31:0] rf_rD1,
    input wire [31:0] rf_rD2,
    input wire [31:0] sext1,
    input wire [31:0] zext,
    input wire [2:0] alu_sel,
    output wire [31:0] alu_c,
    output wire alu_f
);

    // ==== 输入A选择 ====
    wire a_is_imm20 = (alu_sel == `ALU_SEL_IMM20);
    wire [31:0] alu_a = a_is_imm20 ? pc : rf_rD1;

    // ==== 输入B选择分解 ====
    wire b_sel_rf2      = (alu_sel == `ALU_SEL_RF2);
    wire b_sel_rf2_5    = (alu_sel == `ALU_SEL_RF2_LOW5);
    wire b_sel_imm5     = (alu_sel == `ALU_SEL_IMM5);
    wire b_sel_imm20    = (alu_sel == `ALU_SEL_IMM20);
    wire b_sel_sext1    = (alu_sel == `ALU_SEL_SEXT1);
    wire b_sel_zext     = (alu_sel == `ALU_SEL_ZEXT);

    wire [31:0] b_rf2   = rf_rD2;
    wire [31:0] b_rf2_5 = {27'b0, rf_rD2[4:0]};
    wire [31:0] b_imm5  = {27'b0, inst[14:10]};
    wire [31:0] b_imm20 = {inst[24:5], 12'b0};
    wire [31:0] b_sext1 = sext1;
    wire [31:0] b_zext  = zext;

    wire [31:0] alu_b =
        b_sel_rf2   ? b_rf2   :
        b_sel_rf2_5 ? b_rf2_5 :
        b_sel_imm5  ? b_imm5  :
        b_sel_imm20 ? b_imm20 :
        b_sel_sext1 ? b_sext1 :
        b_sel_zext  ? b_zext  :
        32'b0;

    // ==== 位移量 ====
    wire [4:0] shift_val = alu_b[4:0];

    // ==== sra特殊处理 ====
    wire [31:0] sra_res, srl_res, sll_res;
    assign srl_res = alu_a >> shift_val;
    assign sll_res = alu_a << shift_val;
    assign sra_res = (alu_a >> shift_val) | (alu_a[31] ? ~(32'hFFFFFFFF >> shift_val) : 32'b0);

    // ==== 算术/逻辑运算 ====
    wire [31:0] add_res   = alu_a + alu_b;
    wire [31:0] sub_res   = alu_a - alu_b;
    wire [31:0] or_res    = alu_a | alu_b;
    wire [31:0] xor_res   = alu_a ^ alu_b;
    wire [31:0] and_res   = alu_a & alu_b;

    // ==== 比较/条件 ====
    wire eq_res      = (alu_a == alu_b);
    wire neq_res     = (alu_a != alu_b);
    wire lts_res     = ($signed(alu_a) < $signed(alu_b));
    wire ltu_res     = (alu_a < alu_b);
    wire ges_res     = ($signed(alu_a) >= $signed(alu_b));
    wire geu_res     = (alu_a >= alu_b);

    // ==== ALU主输出 ====
    reg [31:0] alu_out;
    always @(*) begin
        case (alu_op)
            `ALU_OP_ADD:   alu_out = add_res;
            `ALU_OP_SUB:   alu_out = sub_res;
            `ALU_OP_OR:    alu_out = or_res;
            `ALU_OP_XOR:   alu_out = xor_res;
            `ALU_OP_AND:   alu_out = and_res;
            `ALU_OP_SLL:   alu_out = sll_res;
            `ALU_OP_SRL:   alu_out = srl_res;
            `ALU_OP_SRA:   alu_out = sra_res;
            `ALU_OP_EQ:    alu_out = {31'b0, eq_res};
            `ALU_OP_NEQ:   alu_out = {31'b0, neq_res};
            `ALU_OP_LT_S:  alu_out = {31'b0, lts_res};
            `ALU_OP_LT_U:  alu_out = {31'b0, ltu_res};
            `ALU_OP_GE_S:  alu_out = {31'b0, ges_res};
            `ALU_OP_GE_U:  alu_out = {31'b0, geu_res};
            default:       alu_out = 32'b0;
        endcase
    end
    assign alu_c = alu_out;

    // ==== 条件比较输出 ====
    reg flag;
    always @(*) begin
        case (alu_op)
            `ALU_OP_EQ:    flag = eq_res;
            `ALU_OP_NEQ:   flag = neq_res;
            `ALU_OP_LT_S:  flag = lts_res;
            `ALU_OP_LT_U:  flag = ltu_res;
            `ALU_OP_GE_S:  flag = ges_res;
            `ALU_OP_GE_U:  flag = geu_res;
            default:       flag = 1'b0;
        endcase
    end
    assign alu_f = flag;

endmodule
