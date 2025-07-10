//========================================
//   defines.vh
//   全局宏定义头文件（适用于 miniLA CPU）
//========================================

// ---------- 运行模式 ----------
`define RUN_TRACE     // 取消注释以启用 Trace 测试支持（提交时需打开）

// ---------- 外设地址 ----------
`define PERI_ADDR_DIG   32'hFFFF_F000
`define PERI_ADDR_LED   32'hFFFF_F060
`define PERI_ADDR_SW    32'hFFFF_F070
`define PERI_ADDR_BTN   32'hFFFF_F078

// ---------- NPC 控制信号 ----------
`define NPC_SEQ     4'b0000  // PC + 4
`define NPC_JIRL    4'b0001  // rj + offset
`define NPC_JUMP    4'b0010  // PC + offset (bl/b)
`define NPC_BR      4'b0011  // 条件跳转 (beq等)

// ---------- ALU 控制信号 ----------
`define ALU_ADD     4'b0000
`define ALU_SUB     4'b0001
`define ALU_AND     4'b0010
`define ALU_OR      4'b0011
`define ALU_XOR     4'b0100
`define ALU_SLL     4'b0101
`define ALU_SRL     4'b0110
`define ALU_SRA     4'b0111
`define ALU_SCMP    4'b1000  // 有符号比较（如 slt）
`define ALU_UCMP    4'b1001  // 无符号比较（如 sltu）
`define ALU_PASS    4'b1111  // 直通A或B，用于pcaddu12i等

// ---------- ALU第二操作数选择（B端） ----------
`define ALUB_RS2    2'b00   // rD2
`define ALUB_IMM1   2'b01   // SEXT1
`define ALUB_IMM2   2'b10   // SEXT2
// 你也可以合并一部分选项到 IMM

// ---------- 写回数据选择 rf_wsel ----------
`define WSEL_ALU      2'b00   // 来自ALU.C
`define WSEL_RAM      2'b01   // 来自 DRAM.rdo[31:0]
`define WSEL_PC       2'b10   // 来自 pc4 (用于 bl / jirl)
`define WSEL_SEXT     2'b11   // Sext1拓展结果

// ---------- SEXT1 操作类型 sext1_op ----------
`define EXT1_0      4'd0
`define EXT1_12     4'd1
`define EXT1_16     4'd2
`define EXT1_20     4'd3
`define EXT1_28     4'd4

// ---------- SEXT2 操作类型 sext2_op ----------
`define EXT2_0     4'd0
`define EXT2_8     4'd1
`define EXT2_16    4'd2

// ---------- RF 寄存器读源选择 ----------
`define RSEL_1    2'b00
`define RSEL_2    2'b01

// ---------- 默认宏 ----------
`define ZERO_WORD  32'h00000000

