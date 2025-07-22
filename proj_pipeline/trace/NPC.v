`timescale 1ns / 1ps
`include "defines.vh"

// ========================================================
// NPC —— Next PC (程序计数器更新单元)
// 控制PC的更新方式：顺序、偏移、条件分支、绝对跳转
// ========================================================
module NPC (
    // 跳转类型选择信号
    input   wire  [1:0]   npc_op,   // 下一PC选择方式      
    input   wire  [31:0]  alu_c,    // 绝对跳转目标
    input   wire  [31:0]  pc,       // 当前PC值
    input   wire  [31:0]  sext,     // 立即数扩展偏移
    input   wire          br,       // 条件分支比较结果

    output  wire  [31:0]  npc,      // 下一条指令PC
    output  wire  [31:0]  pc4       // 顺序PC+4
);

    // 顺序执行默认PC+4
    assign pc4 = pc + 4;

    // 综合所有跳转和分支方式
    assign npc =
        (npc_op == `NPC_SEL_PC_PLUS_4)      ? (pc + 4) :
        (npc_op == `NPC_SEL_PC_PLUS_OFFSET) ? (pc + sext) :
        (npc_op == `NPC_SEL_BRANCH_COND)    ? (br ? pc + sext : pc + 4) :
        (npc_op == `NPC_SEL_OFFSET_ABS)     ? alu_c :
        32'b0;

endmodule
