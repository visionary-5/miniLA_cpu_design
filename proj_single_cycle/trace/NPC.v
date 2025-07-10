`timescale 1ns / 1ps
`include "defines.vh"

module NPC (
    input  wire [31:0] pc,     // 当前 PC
    input  wire [31:0] imm,    // 偏移量/立即数（SEXT1输出）
    input  wire [31:0] rj,     // rj寄存器的值（用于 jirl）
    input  wire        br,     // 分支是否成立（来自ALU）
    input  wire [3:0]  op,     // 控制信号：npc_op
    output reg  [31:0] npc,    // 下一条 PC
    output wire [31:0] pc4     // PC + 4（用于写回ra或控制信号）
);

// 顺序 PC+4 输出
assign pc4 = pc + 32'd4;

always @(*) begin
    case (op)
        `NPC_SEQ:  npc = pc + 32'd4;                         // 顺序执行
        `NPC_JIRL: npc = rj + imm;                           // jirl
        `NPC_JUMP: npc = pc + imm;                           // b / bl
        `NPC_BR:   npc = br ? (pc + imm) : (pc + 32'd4);     // 条件分支
        default:   npc = pc + 32'd4;                         // 默认顺序
    endcase
end

endmodule
