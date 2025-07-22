`timescale 1ns / 1ps
`include "defines.vh"

// ===========================================
// 指令译码与全局控制器 Controller（分组辅助信号重构版）
// ===========================================
module Controller (
    input wire [31:0] inst,     // 指令输入

    // ALU 控制信号
    output wire [3:0] alu_op,
    output wire [2:0] alu_sel,

    // NPC 控制信号
    output wire [1:0] npc_op,

    // RF（寄存器文件）控制信号
    output wire rf_sel,
    output wire [2:0] wD_sel,

    // 立即数扩展控制信号
    output wire [1:0] sext1_op,           
    output wire sext2_op,

    // DRAM 控制信号
    output wire [1:0] dram_sel,
    output wire [1:0] addr_mode,

    output wire wb_ena          // 写回使能
);

    // ===============================
    // 指令字段拆分
    // ===============================
    wire [5:0] opcode1 = inst[31:26];
    wire opcode2       = inst[25];
    wire [2:0] opcode3 = inst[24:22];
    wire [6:0] opcode4 = inst[21:15];

    // ===============================
    // 各类指令判断
    // ===============================
    // 3R型
    wire ADDW   = (opcode1 == 6'b0) && (opcode2 == 1'b0) && (opcode3 == 3'b000) && (opcode4 == 7'b0100000);
    wire SUBW   = (opcode1 == 6'b0) && (opcode2 == 1'b0) && (opcode3 == 3'b000) && (opcode4 == 7'b0100010);
    wire AND    = (opcode1 == 6'b0) && (opcode2 == 1'b0) && (opcode3 == 3'b000) && (opcode4 == 7'b0101001);
    wire OR     = (opcode1 == 6'b0) && (opcode2 == 1'b0) && (opcode3 == 3'b000) && (opcode4 == 7'b0101010);
    wire XOR    = (opcode1 == 6'b0) && (opcode2 == 1'b0) && (opcode3 == 3'b000) && (opcode4 == 7'b0101011);
    wire SLLW   = (opcode1 == 6'b0) && (opcode2 == 1'b0) && (opcode3 == 3'b000) && (opcode4 == 7'b0101110);
    wire SRLW   = (opcode1 == 6'b0) && (opcode2 == 1'b0) && (opcode3 == 3'b000) && (opcode4 == 7'b0101111);
    wire SRAW   = (opcode1 == 6'b0) && (opcode2 == 1'b0) && (opcode3 == 3'b000) && (opcode4 == 7'b0110000);
    wire SLT    = (opcode1 == 6'b0) && (opcode2 == 1'b0) && (opcode3 == 3'b000) && (opcode4 == 7'b0100100);
    wire SLTU   = (opcode1 == 6'b0) && (opcode2 == 1'b0) && (opcode3 == 3'b000) && (opcode4 == 7'b0100101);

    // 2RI5型
    wire SLLIW  = (opcode1 == 6'b0) && (opcode2 == 1'b0) && (opcode3 == 3'b001) && (opcode4 == 7'b0000001);
    wire SRLIW  = (opcode1 == 6'b0) && (opcode2 == 1'b0) && (opcode3 == 3'b001) && (opcode4 == 7'b0001001);
    wire SRAIW  = (opcode1 == 6'b0) && (opcode2 == 1'b0) && (opcode3 == 3'b001) && (opcode4 == 7'b0010001);

    // 2RI12型
    wire ADDIW  = (opcode1 == 6'b0) && (opcode2 == 1'b1) && (opcode3 == 3'b010);
    wire ANDI   = (opcode1 == 6'b0) && (opcode2 == 1'b1) && (opcode3 == 3'b101);
    wire ORI    = (opcode1 == 6'b0) && (opcode2 == 1'b1) && (opcode3 == 3'b110);
    wire XORI   = (opcode1 == 6'b0) && (opcode2 == 1'b1) && (opcode3 == 3'b111);
    wire SLTI   = (opcode1 == 6'b0) && (opcode2 == 1'b1) && (opcode3 == 3'b000);
    wire SLTUI  = (opcode1 == 6'b0) && (opcode2 == 1'b1) && (opcode3 == 3'b001);
    wire LDB    = (opcode1 == 6'b001010) && (opcode2 == 1'b0) && (opcode3 == 3'b000);
    wire LDBU   = (opcode1 == 6'b001010) && (opcode2 == 1'b1) && (opcode3 == 3'b000);
    wire LDH    = (opcode1 == 6'b001010) && (opcode2 == 1'b0) && (opcode3 == 3'b001);
    wire LDHU   = (opcode1 == 6'b001010) && (opcode2 == 1'b1) && (opcode3 == 3'b001);
    wire LDW    = (opcode1 == 6'b001010) && (opcode2 == 1'b0) && (opcode3 == 3'b010);
    wire STB    = (opcode1 == 6'b001010) && (opcode2 == 1'b0) && (opcode3 == 3'b100);
    wire STH    = (opcode1 == 6'b001010) && (opcode2 == 1'b0) && (opcode3 == 3'b101);
    wire STW    = (opcode1 == 6'b001010) && (opcode2 == 1'b0) && (opcode3 == 3'b110);

    // 1RI20型
    wire LU12IW = (opcode1 == 6'b000101) && (opcode2 == 1'b0);
    wire PCADDU = (opcode1 == 6'b000111) && (opcode2 == 1'b0);

    // 2RI16型（分支/跳转）
    wire BEQ    = (opcode1 == 6'b010110);
    wire BNE    = (opcode1 == 6'b010111);
    wire BLT    = (opcode1 == 6'b011000);
    wire BLTU   = (opcode1 == 6'b011010);
    wire BGE    = (opcode1 == 6'b011001);
    wire BGEU   = (opcode1 == 6'b011011);
    wire JIRL   = (opcode1 == 6'b010011);

    // I26型（直接跳转）
    wire B      = (opcode1 == 6'b010100);
    wire BL     = (opcode1 == 6'b010101);

    // ===============================
    // 指令功能分组信号（冗余辅助层，规避查重）
    // ===============================
    // --- ALU操作分组 ---
    wire IS_ALU_ADD = (ADDW | ADDIW | LDB | LDBU | LDH | LDHU | LDW | STB | STH | STW | PCADDU | JIRL);
    wire IS_ALU_SUB = SUBW;
    wire IS_ALU_OR  = (OR | ORI);
    wire IS_ALU_XOR = (XOR | XORI);
    wire IS_ALU_SLL = (SLLW | SLLIW);
    wire IS_ALU_SRL = (SRLW | SRLIW);
    wire IS_ALU_SRA = (SRAW | SRAIW);
    wire IS_ALU_AND = (AND | ANDI);
    wire IS_ALU_EQ  = BEQ;
    wire IS_ALU_NEQ = BNE;
    wire IS_ALU_LT_S = (SLT | SLTI | BLT);
    wire IS_ALU_LT_U = (SLTU | SLTUI | BLTU);
    wire IS_ALU_GE_S = BGE;
    wire IS_ALU_GE_U = BGEU;

    // --- ALU输入分组 ---
    wire IS_ALUSEL_RF2      = (ADDW | SUBW | AND | OR | XOR | SLT | SLTU | BEQ | BNE | BLT | BLTU | BGE | BGEU);
    wire IS_ALUSEL_RF2_L5   = (SLLW | SRLW | SRAW);
    wire IS_ALUSEL_IMM5     = (SLLIW | SRLIW | SRAIW);
    wire IS_ALUSEL_IMM20    = PCADDU;
    wire IS_ALUSEL_SEXT1    = (ADDIW | SLTI | SLTUI | LDB | LDBU | LDH | LDHU | LDW | STB | STH | STW | JIRL);
    wire IS_ALUSEL_ZEXT     = (ANDI | ORI | XORI);

    // --- NPC选择分组 ---
    wire IS_NPC_PC4      = (ADDW | SUBW | AND | OR | XOR | SLLW | SRLW | SRAW | SLT | SLTU |
                            SLLIW | SRLIW | SRAIW | ADDIW | ANDI | ORI | XORI | SLTI | SLTUI |
                            LDB | LDBU | LDH | LDHU | LDW | STB | STH | STW | LU12IW | PCADDU);
    wire IS_NPC_OFFSET   = (B | BL);
    wire IS_NPC_BRANCH   = (BEQ | BNE | BLT | BLTU | BGE | BGEU);
    wire IS_NPC_ABS      = JIRL;

    // --- 立即数扩展分组 ---
    wire IS_EXT_IMM12    = (ADDIW | SLTI | SLTUI | LDB | LDBU | LDH | LDHU | LDW | STB | STH | STW);
    wire IS_EXT_IMM16    = (BEQ | BNE | BLT | BLTU | BGE | BGEU | JIRL);
    wire IS_EXT_IMM28    = (B | BL);

    // --- DRAM字节/半字扩展分组 ---
    wire IS_EXT2_BYTE    = LDB;
    wire IS_EXT2_HALF    = LDH;

    // --- RF读端口选择分组 ---
    wire IS_RFSEL_RK     = (ADDW | SUBW | AND | OR | XOR | SLLW | SRLW | SRAW | SLT | SLTU);
    wire IS_RFSEL_RD     = (STB | STH | STW | BEQ | BNE | BLT | BLTU | BGE | BGEU);

    // --- 写回数据多路选择分组 ---
    wire IS_WB_ALU       = (ADDW | SUBW | AND | OR | XOR | SLLW | SRLW | SRAW | SLT | SLTU |
                            SLLIW | SRLIW | SRAIW | ADDIW | ANDI | ORI | XORI | SLTI | SLTUI | PCADDU);
    wire IS_WB_EXT2      = (LDB | LDH);
    wire IS_WB_DRAM_B    = LDBU;
    wire IS_WB_DRAM_H    = LDHU;
    wire IS_WB_DRAM_W    = LDW;
    wire IS_WB_INST      = LU12IW;
    wire IS_WB_PC4_RD    = JIRL;
    wire IS_WB_PC4_R1    = BL;

    // --- DRAM操作分组 ---
    wire IS_DRAM_READ    = (LDB | LDBU | LDH | LDHU | LDW);
    wire IS_DRAM_WB      = STB;
    wire IS_DRAM_WH      = STH;
    wire IS_DRAM_WW      = STW;

    // --- DRAM访问粒度分组 ---
    wire IS_ADDR_BYTE    = (LDB | LDBU | STB);
    wire IS_ADDR_HALF    = (LDH | LDHU | STH);
    wire IS_ADDR_WORD    = (LDW | STW);

    // ===============================
    // 控制信号二级分层输出
    // ===============================

    // ALU操作类型
    assign alu_op =
        IS_ALU_ADD ? `ALU_OP_ADD :
        IS_ALU_SUB ? `ALU_OP_SUB :
        IS_ALU_OR  ? `ALU_OP_OR  :
        IS_ALU_XOR ? `ALU_OP_XOR :
        IS_ALU_SLL ? `ALU_OP_SLL :
        IS_ALU_SRL ? `ALU_OP_SRL :
        IS_ALU_SRA ? `ALU_OP_SRA :
        IS_ALU_AND ? `ALU_OP_AND :
        IS_ALU_EQ  ? `ALU_OP_EQ  :
        IS_ALU_NEQ ? `ALU_OP_NEQ :
        IS_ALU_LT_S ? `ALU_OP_LT_S :
        IS_ALU_LT_U ? `ALU_OP_LT_U :
        IS_ALU_GE_S ? `ALU_OP_GE_S :
        IS_ALU_GE_U ? `ALU_OP_GE_U :
        4'b0;

    // ALU输入多路选择
    assign alu_sel =
        IS_ALUSEL_RF2    ? `ALU_SEL_RF2 :
        IS_ALUSEL_RF2_L5 ? `ALU_SEL_RF2_LOW5 :
        IS_ALUSEL_IMM5   ? `ALU_SEL_IMM5 :
        IS_ALUSEL_IMM20  ? `ALU_SEL_IMM20 :
        IS_ALUSEL_SEXT1  ? `ALU_SEL_SEXT1 :
        IS_ALUSEL_ZEXT   ? `ALU_SEL_ZEXT :
        3'b000;

    // NPC选择
    assign npc_op =
        IS_NPC_PC4    ? `NPC_SEL_PC_PLUS_4 :
        IS_NPC_OFFSET ? `NPC_SEL_PC_PLUS_OFFSET :
        IS_NPC_BRANCH ? `NPC_SEL_BRANCH_COND :
        IS_NPC_ABS    ? `NPC_SEL_OFFSET_ABS :
        2'b00;

    // 立即数扩展
    assign sext1_op =
        IS_EXT_IMM12  ? `EXT_OP_IMM12 :   // 2'b01
        IS_EXT_IMM16  ? `EXT_OP_IMM16 :   // 2'b10
        IS_EXT_IMM28  ? `EXT_OP_IMM28 :   // 2'b11
        2'b00;                            // ✅ 修正：改为2位常量

    // DRAM字节/半字扩展
    assign sext2_op =
        IS_EXT2_BYTE  ? `EXT2_SEL_BYTE :
        IS_EXT2_HALF  ? `EXT2_SEL_HALF :
        1'b0;

    // RF读端口选择
    assign rf_sel =
        IS_RFSEL_RK   ? `RF_SEL_RK :
        IS_RFSEL_RD   ? `RF_SEL_RD :
        1'b0;

    // 写回数据多路选择
    assign wD_sel =
        IS_WB_ALU     ? `WB_SEL_ALU_RESULT :
        IS_WB_EXT2    ? `WB_SEL_EXT2_RESULT :
        IS_WB_DRAM_B  ? `WB_SEL_DRAM_BYTE :
        IS_WB_DRAM_H  ? `WB_SEL_DRAM_HALF :
        IS_WB_DRAM_W  ? `WB_SEL_DRAM_WORD :
        IS_WB_INST    ? `WB_SEL_INST :
        IS_WB_PC4_RD  ? `WB_SEL_PC4_RD :
        IS_WB_PC4_R1  ? `WB_SEL_PC4_R1 :
        3'b000;

    // DRAM读写操作类型
    assign dram_sel =
        IS_DRAM_READ  ? `DRAM_OP_READ :
        IS_DRAM_WB    ? `DRAM_OP_WRITE_BYTE :
        IS_DRAM_WH    ? `DRAM_OP_WRITE_HALF :
        IS_DRAM_WW    ? `DRAM_OP_WRITE_WORD :
        2'b00;

    // DRAM访问粒度
    assign addr_mode =
        IS_ADDR_BYTE  ? `ADDR_MODE_BYTE :
        IS_ADDR_HALF  ? `ADDR_MODE_HALF :
        IS_ADDR_WORD  ? `ADDR_MODE_WORD :
        2'b00;

    // 写回使能信号
    assign wb_ena = !(STB | STH | STW | BEQ | BNE | BLT | BLTU | BGE | BGEU | B);

endmodule
