`timescale 1ns / 1ps

// 下一条PC（Next PC）生成模块
// 负责根据分支、跳转等控制信号，输出正确的下一条指令地址
module NPC (
    input   wire          br,         // 分支条件是否成立
    input   wire  [31:0]  pc,         // 当前PC

    input   wire  [31:0]  EX_pc,      // EX阶段PC（用于部分跳转）

    // 偏移量
    input   wire  [31:0]  alu_c,      // 绝对跳转目标
    input   wire  [31:0]  sext,       // 有符号偏移量

    // NPC操作类型（4种）
    input   wire  [1:0]   npc_op,

    output  wire  [31:0]  npc,        // 下一条PC输出
    output  wire  [31:0]  pc4         // 当前PC+4
);

    // 计算pc+4，顺序执行时使用
    assign pc4 = pc + 4;

    // 根据npc_op类型选择下一条PC
    // 支持顺序、相对跳转、条件分支、绝对跳转
    assign npc =    (npc_op == `NPC_SEL_PC_PLUS_4) ? pc + 4 :
                    (npc_op == `NPC_SEL_PC_PLUS_OFFSET) ? EX_pc + sext :
                    (npc_op == `NPC_SEL_BRANCH_COND) ? (br ? EX_pc + sext : pc + 4) :
                    (npc_op == `NPC_SEL_OFFSET_ABS) ? alu_c :
                    32'b0;

endmodule
