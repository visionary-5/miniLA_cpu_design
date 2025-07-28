`include "defines.vh"

/*
===============================================
模块名称：DataHazard

模块功能：
    本模块用于处理流水线 CPU 中的数据冒险问题（Read After Write）。
    当 ID 阶段读取寄存器的指令，其源操作数来自 EX/MEM/WB 阶段的写回目标时，可能会发生 RAW 冒险。

处理机制：
    1. 利用前递（forwarding）技术，从 EX / MEM / WB 阶段直接提供结果；
    2. 对于无法前递的 load-use 冒险，发出流水线暂停信号（PC_stop / IFID_stop）并刷新 IDEX。

关联模块：
    - 与 Controller 模块协同，识别寄存器读写信息；
    - 与 Forwarding 单元及 PC 控制单元共同处理暂停或前递信号；
    - 与 IDEX、IFID 寄存器配合实现冒险处理。

===============================================
*/

module DataHazard (
    input wire [31:0] inst,             // 当前 ID 阶段指令
    input wire rf_sel,                 // rf 选择信号（决定第二个读寄存器来自 rk 还是 rd）

    input wire [4:0] EX_wb_reg,        // EX 阶段目标寄存器编号
    input wire EX_wb_ena,              // EX 阶段是否写回寄存器
    input wire [2:0] EX_wD_sel,        // EX 阶段写回选择类型（判断是否为 load 指令）
    input wire [31:0] EX_wb_value,     // EX 阶段将写入的值（用于前递）

    input wire [4:0] MEM_wb_reg,       // MEM 阶段目标寄存器
    input wire MEM_wb_ena,             // MEM 阶段写回使能
    input wire [31:0] MEM_wb_value,    // MEM 阶段写回值

    input wire [4:0] WB_wb_reg,        // WB 阶段目标寄存器
    input wire WB_wb_ena,              // WB 阶段写回使能
    input wire [31:0] WB_wb_value,     // WB 阶段写回值

    input wire read1,                  // 是否读取 rj
    input wire read2,                  // 是否读取 rk/rd

    output wire forward_op1,           // 是否对 rf_rD1 启用前递
    output wire forward_op2,           // 是否对 rf_rD2 启用前递
    output wire [31:0] forward_rD1,    // rf_rD1 的前递数据（如需要）
    output wire [31:0] forward_rD2,    // rf_rD2 的前递数据（如需要）
    output wire PC_stop,               // 是否暂停 PC（load-use 冲突）
    output wire IFID_stop,             // 是否暂停 IFID（同上）
    output wire IDEX_flush             // 是否刷新 IDEX（同上）
);

    // ----------------------------------------
    // 提取当前指令的两个源寄存器编号
    // r1 为 rj
    // r2 取决于 rf_sel，可能是 rk 或 rd
    // ----------------------------------------
    wire [4:0] r1 = inst[9:5];
    wire [4:0] r2 = (rf_sel == `RF_SEL_RK) ? inst[14:10] :
                    (rf_sel == `RF_SEL_RD) ? inst[4:0] :
                    5'b0;

    // ----------------------------------------
    // 阶段 A（EX）检测 RAW 冲突
    // ----------------------------------------
    wire A_conflict_r1 = (r1 == EX_wb_reg) && EX_wb_ena && read1 && (EX_wb_reg != 5'b0);
    wire A_conflict_r2 = (r2 == EX_wb_reg) && EX_wb_ena && read2 && (EX_wb_reg != 5'b0);

    // ----------------------------------------
    // 阶段 B（MEM）检测 RAW 冲突
    // ----------------------------------------
    wire B_conflict_r1 = (r1 == MEM_wb_reg) && MEM_wb_ena && read1 && (MEM_wb_reg != 5'b0);
    wire B_conflict_r2 = (r2 == MEM_wb_reg) && MEM_wb_ena && read2 && (MEM_wb_reg != 5'b0);

    // ----------------------------------------
    // 阶段 C（WB）检测 RAW 冲突
    // ----------------------------------------
    wire C_conflict_r1 = (r1 == WB_wb_reg) && WB_wb_ena && read1 && (WB_wb_reg != 5'b0);
    wire C_conflict_r2 = (r2 == WB_wb_reg) && WB_wb_ena && read2 && (WB_wb_reg != 5'b0);

    // ----------------------------------------
    // 判断是否为 load 类型指令
    // 这些写回数据在 MEM 阶段才可用，不能直接前递
    // ----------------------------------------
    wire is_load_inst = 
        (EX_wD_sel == `WB_SEL_EXT2_RESULT) || 
        (EX_wD_sel == `WB_SEL_DRAM_BYTE)   ||
        (EX_wD_sel == `WB_SEL_DRAM_HALF)   ||
        (EX_wD_sel == `WB_SEL_DRAM_WORD);

    // ----------------------------------------
    // load-use 冒险判断：
    // 如果当前指令依赖 EX 阶段的 load 指令，就必须暂停
    // ----------------------------------------
    wire load_use = (A_conflict_r1 || A_conflict_r2) && is_load_inst;
    
    // ----------------------------------------
    // load-use 冲突需要暂停流水线
    // ----------------------------------------
    assign PC_stop    = load_use;
    assign IFID_stop  = load_use;
    assign IDEX_flush = load_use;

    // ----------------------------------------
    // 是否启用前递信号
    // ----------------------------------------
    assign forward_op1 = A_conflict_r1 | B_conflict_r1 | C_conflict_r1;
    assign forward_op2 = A_conflict_r2 | B_conflict_r2 | C_conflict_r2;

    // ----------------------------------------
    // 为 rf_rD1、rf_rD2 提供前递数据（always 组合逻辑实现，使用与或非等逻辑表达式）
    // 优先级：EX > MEM > WB
    // ----------------------------------------
    reg [31:0] forward_rD1_reg;
    reg [31:0] forward_rD2_reg;
    assign forward_rD1 = forward_rD1_reg;
    assign forward_rD2 = forward_rD2_reg;


    always @(*) begin
        // forward_rD1: 仅有最高优先级的通路有效
        // 优先级 EX > MEM > WB
        // 若EX阶段有冲突，直接前递EX_wb_value
        // 若无EX冲突但有MEM冲突，前递MEM_wb_value
        // 若EX和MEM都无冲突但WB有冲突，前递WB_wb_value
        // 若都无冲突，输出0
        forward_rD1_reg = (A_conflict_r1 & EX_wb_value) | // EX优先
                          (~A_conflict_r1 & B_conflict_r1 & MEM_wb_value) | // MEM次之
                          (~A_conflict_r1 & ~B_conflict_r1 & C_conflict_r1 & WB_wb_value); // WB最低
        if (~A_conflict_r1 & ~B_conflict_r1 & ~C_conflict_r1)
            forward_rD1_reg = 32'b0; // 无前递

        // forward_rD2: 仅有最高优先级的通路有效，同上
        forward_rD2_reg = (A_conflict_r2 & EX_wb_value) | // EX优先
                          (~A_conflict_r2 & B_conflict_r2 & MEM_wb_value) | // MEM次之
                          (~A_conflict_r2 & ~B_conflict_r2 & C_conflict_r2 & WB_wb_value); // WB最低
        if (~A_conflict_r2 & ~B_conflict_r2 & ~C_conflict_r2)
            forward_rD2_reg = 32'b0; // 无前递
    end


endmodule
