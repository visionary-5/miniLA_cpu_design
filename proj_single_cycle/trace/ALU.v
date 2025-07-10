`timescale 1ns / 1ps
`include "defines.vh"

module ALU (
    input  wire [31:0] A,     // 操作数 A（来自寄存器）
    input  wire [31:0] B,     // 操作数 B（来自寄存器或立即数）
    input  wire [3:0]  op,    // 控制信号：alu_op

    output reg  [31:0] C,     // 运算结果
    output reg         br     // 比较标志（供 beq/bne/blt/bge使用）
);

    always @(*) begin
        br = 1'b0;
        case (op)
            `ALU_ADD:  C = A + B;
            `ALU_SUB:  C = A - B;
            `ALU_AND:  C = A & B;
            `ALU_OR:   C = A | B;
            `ALU_XOR:  C = A ^ B;
            `ALU_SLL:  C = A << B[4:0];
            `ALU_SRL:  C = A >> B[4:0];
            `ALU_SRA:  C = $signed(A) >>> B[4:0];
            `ALU_SCMP: begin         // 有符号比较（slt, blt, bge）
                C = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0;
                br = ($signed(A) < $signed(B));  // 供分支跳转判断
            end
            `ALU_UCMP: begin         // 无符号比较（sltu, bltu, bgeu）
                C = (A < B) ? 32'b1 : 32'b0;
                br = (A < B);
            end
            `ALU_PASS: C = A;        // 直通 A（用于 pcaddu12i 或兼容性）
            default:   C = 32'hxxxxxxxx;
        endcase

        // 特殊处理 beq/bne：只比较是否相等
        if (op == `ALU_SUB && A == B)
            br = 1'b1;  // beq
        else if (op == `ALU_SUB && A != B)
            br = 1'b0;  // bne (不等时 br=0 → 不跳转)
    end

endmodule
