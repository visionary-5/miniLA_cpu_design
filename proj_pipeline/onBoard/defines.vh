//========================================
//  miniLA 单周期CPU全局宏定义
//  仿真与综合时请仔细确认各宏定义
//========================================

// ---------- 调试/仿真模式宏 ----------
// 合成时注释掉，仿真trace时开启
`define RUN_TRACE

// ---------- 内存地址范围 ----------
`define MEM_ADDR_BASE   32'h0000_0000   // 内存基地址
`define MEM_ADDR_TOP    32'h0001_FFFF   // 内存顶地址


// ---------- NPC（下一条PC）选择方式 ----------
`define NPC_SEL_PC_PLUS_4        2'b00   // 顺序执行，PC=PC+4
`define NPC_SEL_PC_PLUS_OFFSET   2'b01   // 跳转，PC=PC+offset
`define NPC_SEL_BRANCH_COND      2'b10   // 条件分支，PC=branch?PC+offset:PC+4
`define NPC_SEL_OFFSET_ABS       2'b11   // 绝对跳转，PC=offset

// ---------- ALU操作类型控制 ----------
`define ALU_OP_ADD   4'b0001   // 加法
`define ALU_OP_SUB   4'b0010   // 减法
`define ALU_OP_OR    4'b0011   // 按位或
`define ALU_OP_XOR   4'b0100   // 按位异或
`define ALU_OP_SLL   4'b0101   // 逻辑左移
`define ALU_OP_SRL   4'b0110   // 逻辑右移
`define ALU_OP_SRA   4'b0111   // 算术右移
`define ALU_OP_AND   4'b1000   // 按位与
`define ALU_OP_EQ    4'b1001   // 相等比较
`define ALU_OP_NEQ   4'b1010   // 不等比较
`define ALU_OP_LT_S  4'b1011   // 有符号小于
`define ALU_OP_LT_U  4'b1100   // 无符号小于
`define ALU_OP_GE_S  4'b1101   // 有符号大于等于
`define ALU_OP_GE_U  4'b1110   // 无符号大于等于

// ---------- ALU输入源多路选择 ----------
`define ALU_SEL_RF2           3'b001   // 寄存器2
`define ALU_SEL_RF2_LOW5      3'b010   // 寄存器2低5位
`define ALU_SEL_IMM5          3'b011   // 指令立即数5位
`define ALU_SEL_IMM20         3'b100   // 指令立即数20位
`define ALU_SEL_SEXT1         3'b101   // 立即数符号扩展
`define ALU_SEL_ZEXT          3'b110   // 立即数零扩展

// ---------- 寄存器文件RF读端口选择 ----------
`define RF_SEL_RK             1'b0     // 读rk
`define RF_SEL_RD             1'b1     // 读rd

// ---------- 寄存器写回数据源多路选择 ----------
`define WB_SEL_ALU_RESULT     3'b000   // ALU运算结果
`define WB_SEL_EXT2_RESULT    3'b001   // 扩展结果（如符号扩展）
`define WB_SEL_DRAM_BYTE      3'b010   // DRAM读字节
`define WB_SEL_DRAM_HALF      3'b011   // DRAM读半字
`define WB_SEL_DRAM_WORD      3'b100   // DRAM读字
`define WB_SEL_INST           3'b101   // 指令拼接写回
`define WB_SEL_PC4_RD         3'b110   // 跳转后PC+4（如JIRL/BL）
`define WB_SEL_PC4_R1         3'b111   // 跳转后PC+4（特殊用例）

// ---------- 立即数扩展相关 ----------
`define ZEXT_OP               2'b00   // 零扩展
`define EXT_OP_IMM12          2'b01   // 12位立即数扩展
`define EXT_OP_IMM16          2'b10   // 16位立即数扩展
`define EXT_OP_IMM28          2'b11   // 28位立即数扩展

`define EXT2_SEL_BYTE         1'b0    // 8位扩展
`define EXT2_SEL_HALF         1'b1    // 16位扩展

// ---------- DRAM读写操作类型 ----------
`define DRAM_OP_READ          2'b00   // 读操作
`define DRAM_OP_WRITE_BYTE    2'b01   // 字节写
`define DRAM_OP_WRITE_HALF    2'b10   // 半字写
`define DRAM_OP_WRITE_WORD    2'b11   // 字写

// ---------- DRAM地址访问粒度 ----------
`define ADDR_MODE_BYTE        2'b01   // 字节访问
`define ADDR_MODE_HALF        2'b10   // 半字访问
`define ADDR_MODE_WORD        2'b11   // 字访问

// ---------- 外设I/O端口地址（保持原名） ----------
`define PERI_ADDR_DIG   32'hFFFF_F000   // 数码管显示端口基地址
`define PERI_ADDR_LED   32'hFFFF_F060   // LED灯输出端口基地址
`define PERI_ADDR_SW    32'hFFFF_F070   // 拨码开关输入端口基地址
`define PERI_ADDR_BTN   32'hFFFF_F078   // 按键输入端口基地址
`define PERI_ADDR_TIMER 32'hFFFF_F020   // UART串口通信端口基地址