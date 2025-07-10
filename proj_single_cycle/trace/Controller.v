`timescale 1ns / 1ps
`include "defines.vh"

module Controller (
    input  wire [31:0] inst,       // 当前指令

    output reg        rf_we,
    output reg [1:0]  rf_rsel,
    output reg [1:0]  rf_wsel,
    output reg [3:0]  sext1_op,
    output reg [3:0]  sext2_op,
    output reg [3:0]  alu_op,
    output reg [2:0]  alu_bsel,
    output reg [3:0]  npc_op,
    output reg        ram_we
);

    wire [5:0] op = inst[31:26];

    always @(*) begin
        // 默认值（顺序执行，无写入）
        rf_we     = 0;
        rf_rsel   = `RSEL_1;
        rf_wsel   = `WSEL_ALU;
        sext1_op  = 4'b0000;
        sext2_op  = 4'b0000;
        alu_op    = `ALU_ADD;
        alu_bsel  = `BSEL_RD2;
        npc_op    = `NPC_SEQ;
        ram_we    = 0;

        case (op)
            // ------- 算术指令 3R -------
            6'b000000: begin // add.w
                rf_we    = 1;
                alu_op   = `ALU_ADD;
                alu_bsel = `BSEL_RD2;
            end
            6'b000001: begin // sub.w
                rf_we    = 1;
                alu_op   = `ALU_SUB;
                alu_bsel = `BSEL_RD2;
            end
            6'b000010: begin // and
                rf_we    = 1;
                alu_op   = `ALU_AND;
                alu_bsel = `BSEL_RD2;
            end
            6'b000011: begin // or
                rf_we    = 1;
                alu_op   = `ALU_OR;
                alu_bsel = `BSEL_RD2;
            end
            6'b000100: begin // xor
                rf_we    = 1;
                alu_op   = `ALU_XOR;
                alu_bsel = `BSEL_RD2;
            end
            6'b000101: begin // slt
                rf_we    = 1;
                alu_op   = `ALU_SCMP;
                alu_bsel = `BSEL_RD2;
            end
            6'b000110: begin // sltu
                rf_we    = 1;
                alu_op   = `ALU_UCMP;
                alu_bsel = `BSEL_RD2;
            end

            // ------- 立即数算术指令 -------
            6'b001000: begin // addi.w
                rf_we     = 1;
                alu_op    = `ALU_ADD;
                alu_bsel  = `BSEL_IMM;
                sext1_op  = `EXT1_12;
            end
            6'b001001: begin // andi
                rf_we     = 1;
                alu_op    = `ALU_AND;
                alu_bsel  = `BSEL_IMM;
                sext1_op  = `EXT1_12;
            end
            6'b001010: begin // ori
                rf_we     = 1;
                alu_op    = `ALU_OR;
                alu_bsel  = `BSEL_IMM;
                sext1_op  = `EXT1_12;
            end
            6'b001011: begin // xori
                rf_we     = 1;
                alu_op    = `ALU_XOR;
                alu_bsel  = `BSEL_IMM;
                sext1_op  = `EXT1_12;
            end

            // ------- 立即数比较 -------
            6'b001100: begin // slti
                rf_we     = 1;
                alu_op    = `ALU_SCMP;
                alu_bsel  = `BSEL_IMM;
                sext1_op  = `EXT1_12;
            end
            6'b001101: begin // sltui
                rf_we     = 1;
                alu_op    = `ALU_UCMP;
                alu_bsel  = `BSEL_IMM;
                sext1_op  = `EXT1_12;
            end

            // ------- 移位立即数指令 -------
            6'b001110: begin // slli.w
                rf_we     = 1;
                alu_op    = `ALU_SLL;
                alu_bsel  = `BSEL_SHAMT;
            end
            6'b001111: begin // srli.w
                rf_we     = 1;
                alu_op    = `ALU_SRL;
                alu_bsel  = `BSEL_SHAMT;
            end
            6'b010000: begin // srai.w
                rf_we     = 1;
                alu_op    = `ALU_SRA;
                alu_bsel  = `BSEL_SHAMT;
            end

            // ------- load & store -------
            6'b010001: begin // ld.w
                rf_we     = 1;
                alu_op    = `ALU_ADD;
                alu_bsel  = `BSEL_IMM;
                rf_wsel   = `WSEL_RAM32;
                sext2_op  = `EXT2_31;
            end
            6'b010010: begin // st.w
                rf_we     = 0;
                ram_we    = 1;
                alu_op    = `ALU_ADD;
                alu_bsel  = `BSEL_IMM;
                sext2_op  = `EXT2_31;
            end

            // ------- 跳转与链接 -------
            6'b010011: begin // jirl
                rf_we     = 1;
                rf_wsel   = `WSEL_PC;
                npc_op    = `NPC_JIRL;
                sext1_op  = `EXT1_16;
            end
            6'b010100: begin // bl
                rf_we     = 1;
                rf_wsel   = `WSEL_PC;
                npc_op    = `NPC_JUMP;
                sext1_op  = `EXT1_26;
            end
            6'b010101: begin // b
                rf_we     = 0;
                npc_op    = `NPC_JUMP;
                sext1_op  = `EXT1_26;
            end

            // ------- 条件跳转 -------
            6'b010110: begin // beq
                rf_we     = 0;
                npc_op    = `NPC_BR;
                sext1_op  = `EXT1_16;
            end
            6'b010111: begin // bne
                rf_we     = 0;
                npc_op    = `NPC_BR;
                sext1_op  = `EXT1_16;
            end
            6'b011000: begin // blt
                rf_we     = 0;
                npc_op    = `NPC_BR;
                sext1_op  = `EXT1_16;
            end
            6'b011001: begin // bge
                rf_we     = 0;
                npc_op    = `NPC_BR;
                sext1_op  = `EXT1_16;
            end

            // 其他扩展或保留指令可按需添加
        endcase
    end

endmodule
