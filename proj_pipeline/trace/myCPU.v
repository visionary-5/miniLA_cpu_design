`timescale 1ns / 1ps
`include "defines.vh"

/*
 * ================================================
 * myCPU - miniLA 五级流水线处理器核心模块
 * 集成完整数据通路、指令控制、存储接口、调试功能
 * ================================================
 */
module myCPU (
    input  wire         cpu_rst,      // 系统复位信号
    input  wire         cpu_clk,      // 系统时钟信号

    // 指令存储器访问接口
`ifdef RUN_TRACE
    output wire [15:0]  inst_addr,    // 指令地址输出（调试模式扩展位宽）
`else
    output wire [13:0]  inst_addr,    // 指令地址输出（标准模式）
`endif
    input  wire [31:0]  inst,         // 指令数据输入

    // 数据总线访问接口
    output wire [31:0]  Bus_addr,     // 总线地址输出
    input  wire [31:0]  Bus_rdata,    // 总线读数据输入
    output wire [3:0]   Bus_we,       // 总线写使能输出
    output wire [31:0]  Bus_wdata     // 总线写数据输出

`ifdef RUN_TRACE
    ,
    // 调试追踪接口（用于性能分析和验证）
    output wire         debug_wb_have_inst,   // 当前周期指令有效标志
    output wire [31:0]  debug_wb_pc,          // 写回阶段PC值
    output              debug_wb_ena,         // 寄存器写回使能
    output wire [ 4:0]  debug_wb_reg,         // 写回目标寄存器编号
    output wire [31:0]  debug_wb_value        // 写回数据值
`endif
);

    /* 各阶段信号声明 */
    // IF阶段信号
    wire [31:0] pc_IF, pc4_IF, npc;
    
    // ID阶段信号  
    wire [31:0] pc_ID, pc4_ID, inst_ID;
    wire [31:0] rf_rD1_ID, rf_rD2_ID, sext1_ext_ID, zext_ext_ID;
    wire [3:0]  alu_op_ID;
    wire [2:0]  alu_sel_ID, wD_sel_ID;
    wire [1:0]  sext1_op_ID;              
    wire [1:0]  npc_op_ID, dram_sel_ID, addr_mode_ID;
    wire        rf_sel_ID, sext2_op_ID, wb_ena_ID;
    
    // EX阶段信号
    wire [31:0] pc_EX, pc4_EX, inst_EX;
    wire [31:0] rf_rD1_EX, rf_rD2_EX, sext1_ext_EX, zext_ext_EX;
    wire [31:0] alu_c_EX, sext2_ext_EX;
    wire        alu_f_EX;
    wire [3:0]  alu_op_EX;
    wire [2:0]  alu_sel_EX, wD_sel_EX;
    wire [1:0]  sext1_op_EX;              
    wire [1:0]  npc_op_EX, dram_sel_EX, addr_mode_EX;
    wire        rf_sel_EX, sext2_op_EX, wb_ena_EX;
    
    // MEM阶段信号
    wire [31:0] pc_MEM, pc4_MEM, inst_MEM;
    wire [31:0] alu_c_MEM, rf_rD2_MEM, sext1_ext_MEM, sext2_ext_MEM;
    wire [31:0] dram_addr, dram_rdata, dram_wdata;
    wire [3:0]  dram_we;
    wire        alu_f_MEM;
    wire [2:0]  wD_sel_MEM;
    wire [1:0]  dram_sel_MEM, addr_mode_MEM;
    wire        sext2_op_MEM, wb_ena_MEM;
    
    // WB阶段信号
    wire [31:0] pc_WB, pc4_WB, inst_WB;
    wire [31:0] alu_c_WB, sext2_ext_WB, dram_rdata_WB;
    wire [2:0]  wD_sel_WB;
    wire        wb_ena_WB;

`ifdef RUN_TRACE
    wire [4:0]  wb_reg;      // 调试模式：写回寄存器号
    wire [31:0] wb_value;    // 调试模式：写回数据值
`endif

    /* ===================================== IF 阶段 ===================================== */
    
    // 程序计数器寄存器模块
    PC program_counter (
        .pc_rst     (cpu_rst),
        .pc_clk     (cpu_clk),
        .din        (npc),
        .pc         (pc_IF)
    );

    // 指令地址映射逻辑
    assign inst_addr = pc_IF[31:2];

    // 下一PC计算单元 
    NPC next_pc_calculator (
        .br         (alu_f_EX),        // 分支判断来自EX阶段
        .pc         (pc_IF),                  // 使用IF阶段当前PC作为基址
        .alu_c      (alu_c_EX),               // 绝对跳转地址来自EX阶段ALU
        .sext       (sext1_ext_EX),    // 相对跳转偏移来自EX阶段
        .npc_op     (npc_op_EX),       // 跳转类型控制来自EX阶段
        .npc        (npc),             // 计算出的下一PC
        .pc4        (pc4_IF)           // IF阶段PC+4
    );

    // IF/ID 流水线寄存器
    IF_ID if_id_register (
        .clk        (cpu_clk),
        .rst        (cpu_rst),
        .pc_in      (pc_IF),
        .inst_in    (inst),
        .pc4_in     (pc4_IF),
        .pc_out     (pc_ID),
        .inst_out   (inst_ID),
        .pc4_out    (pc4_ID)
    );

    /* ===================================== ID 阶段 ===================================== */

    // 通用寄存器堆模块 (写回在WB阶段)
    RF register_file (
        .rf_rst     (cpu_rst),
        .rf_clk     (cpu_clk),
        .inst_ID    (inst_ID),      // ID阶段指令用于读操作
        .inst_WB    (inst_WB),      // WB阶段指令用于写操作
        .rf_sel     (rf_sel_ID),    // 使用ID阶段的控制信号
        .wD_sel     (wD_sel_WB),    // 使用WB阶段的控制信号
        .alu_c      (alu_c_WB),     // 使用WB阶段的数据
        .sext2      (sext2_ext_WB), // 使用WB阶段的数据
        .pc4        (pc4_WB),       // 使用WB阶段的数据
        .rdo        (dram_rdata_WB),// 使用WB阶段的数据
        .rf_rD1     (rf_rD1_ID),
        .rf_rD2     (rf_rD2_ID),
        .wb_ena     (wb_ena_WB)     // 使用WB阶段的控制信号
`ifdef RUN_TRACE
        ,
        .debug_wb_reg   (wb_reg),
        .debug_wb_value (wb_value)
`endif
    );

    // 立即数扩展处理单元
    EXIT_UNIT immediate_extension_unit (
        .sext1_op   (sext1_op_ID),
        .inst       (inst_ID),
        .sext1_ext  (sext1_ext_ID),
        .zext_ext   (zext_ext_ID) 
    );

    // 指令解码与控制信号生成器
    Controller instruction_decoder_controller (
        .inst       (inst_ID),
        .alu_op     (alu_op_ID),
        .alu_sel    (alu_sel_ID),
        .npc_op     (npc_op_ID),
        .rf_sel     (rf_sel_ID),
        .wD_sel     (wD_sel_ID),
        .sext1_op   (sext1_op_ID),
        .sext2_op   (sext2_op_ID),
        .dram_sel   (dram_sel_ID),
        .addr_mode  (addr_mode_ID),
        .wb_ena     (wb_ena_ID)
    );

    // ID/EX 流水线寄存器
    ID_EX id_ex_register (
        .clk            (cpu_clk),
        .rst            (cpu_rst),
        .pc_in          (pc_ID),
        .pc4_in         (pc4_ID),
        .rf_rD1_in      (rf_rD1_ID),
        .rf_rD2_in      (rf_rD2_ID),
        .sext1_ext_in   (sext1_ext_ID),
        .zext_ext_in    (zext_ext_ID),
        .inst_in        (inst_ID),
        .alu_op_in      (alu_op_ID),
        .alu_sel_in     (alu_sel_ID),
        .npc_op_in      (npc_op_ID),
        .rf_sel_in      (rf_sel_ID),
        .wD_sel_in      (wD_sel_ID),
        .sext1_op_in    (sext1_op_ID),
        .sext2_op_in    (sext2_op_ID),
        .dram_sel_in    (dram_sel_ID),
        .addr_mode_in   (addr_mode_ID),
        .wb_ena_in      (wb_ena_ID),
        .pc_out         (pc_EX),
        .pc4_out        (pc4_EX),
        .rf_rD1_out     (rf_rD1_EX),
        .rf_rD2_out     (rf_rD2_EX),
        .sext1_ext_out  (sext1_ext_EX),
        .zext_ext_out   (zext_ext_EX),
        .inst_out       (inst_EX),
        .alu_op_out     (alu_op_EX),
        .alu_sel_out    (alu_sel_EX),
        .npc_op_out     (npc_op_EX),
        .rf_sel_out     (rf_sel_EX),
        .wD_sel_out     (wD_sel_EX),
        .sext1_op_out   (sext1_op_EX),
        .sext2_op_out   (sext2_op_EX),
        .dram_sel_out   (dram_sel_EX),
        .addr_mode_out  (addr_mode_EX),
        .wb_ena_out     (wb_ena_EX)
    );

    /* ===================================== EX 阶段 ===================================== */

    // 算术逻辑运算单元
    ALU arithmetic_logic_unit (
        .inst       (inst_EX),
        .alu_op     (alu_op_EX),
        .pc         (pc_EX),
        .rf_rD1     (rf_rD1_EX),
        .rf_rD2     (rf_rD2_EX),
        .sext1      (sext1_ext_EX),
        .zext       (zext_ext_EX),
        .alu_sel    (alu_sel_EX),
        .alu_c      (alu_c_EX),
        .alu_f      (alu_f_EX)
    );

    // 存储器读数据符号扩展单元 (在EX阶段计算，MEM阶段使用)
    SEXT2 memory_data_sign_extender (
        .sext2_op   (sext2_op_EX),
        .dram_rdata (dram_rdata),   // 这里暂时使用MEM阶段的数据
        .sext2_ext  (sext2_ext_EX)
    );

    // EX/MEM 流水线寄存器
    EX_MEM ex_mem_register (
        .clk            (cpu_clk),
        .rst            (cpu_rst),
        .pc_in          (pc_EX),
        .pc4_in         (pc4_EX),
        .alu_c_in       (alu_c_EX),
        .alu_f_in       (alu_f_EX),
        .rf_rD2_in      (rf_rD2_EX),
        .sext1_ext_in   (sext1_ext_EX),
        .sext2_ext_in   (sext2_ext_EX),
        .inst_in        (inst_EX),
        .wD_sel_in      (wD_sel_EX),
        .sext2_op_in    (sext2_op_EX),
        .dram_sel_in    (dram_sel_EX),
        .addr_mode_in   (addr_mode_EX),
        .wb_ena_in      (wb_ena_EX),
        .pc_out         (pc_MEM),
        .pc4_out        (pc4_MEM),
        .alu_c_out      (alu_c_MEM),
        .alu_f_out      (alu_f_MEM),
        .rf_rD2_out     (rf_rD2_MEM),
        .sext1_ext_out  (sext1_ext_MEM),
        .sext2_ext_out  (sext2_ext_MEM),
        .inst_out       (inst_MEM),
        .wD_sel_out     (wD_sel_MEM),
        .sext2_op_out   (sext2_op_MEM),
        .dram_sel_out   (dram_sel_MEM),
        .addr_mode_out  (addr_mode_MEM),
        .wb_ena_out     (wb_ena_MEM)
    );

    /* ===================================== MEM 阶段 ===================================== */

    // 存储器访问数据处理抽象层
    DramSel memory_access_controller (
        .dram_sel       (dram_sel_MEM),
        .alu_c          (alu_c_MEM),
        .addr_mode      (addr_mode_MEM),
        .dram_addr      (dram_addr),
        .dram_rdata_raw (Bus_rdata),
        .dram_rdata     (dram_rdata),
        .rf_rD2         (rf_rD2_MEM),
        .dram_wdata     (dram_wdata),
        .dram_we        (dram_we)
    );

    // 重新计算存储器读数据符号扩展 (使用正确的MEM阶段数据)
    SEXT2 memory_data_sign_extender_mem (
        .sext2_op   (sext2_op_MEM),
        .dram_rdata (dram_rdata),
        .sext2_ext  (sext2_ext_MEM)
    );

    // MEM/WB 流水线寄存器
    MEM_WB mem_wb_register (
        .clk            (cpu_clk),
        .rst            (cpu_rst),
        .pc_in          (pc_MEM),
        .pc4_in         (pc4_MEM),
        .alu_c_in       (alu_c_MEM),
        .sext2_ext_in   (sext2_ext_MEM),
        .dram_rdata_in  (dram_rdata),
        .inst_in        (inst_MEM),
        .wD_sel_in      (wD_sel_MEM),
        .wb_ena_in      (wb_ena_MEM),
        .pc_out         (pc_WB),
        .pc4_out        (pc4_WB),
        .alu_c_out      (alu_c_WB),
        .sext2_ext_out  (sext2_ext_WB),
        .dram_rdata_out (dram_rdata_WB),
        .inst_out       (inst_WB),
        .wD_sel_out     (wD_sel_WB),
        .wb_ena_out     (wb_ena_WB)
    );

    /* ===================================== WB 阶段 ===================================== */
    // 写回操作在RF模块中完成

    /* 总线接口信号连接 */
    assign Bus_addr   = dram_addr;
    assign Bus_we     = dram_we;
    assign Bus_wdata  = dram_wdata;

`ifdef RUN_TRACE
    /* 调试追踪接口实现 */
    reg have_inst;
    always @(cpu_rst) begin
        have_inst = 1'b1;
    end

    // 调试信号输出连接 (使用WB阶段信号)
    assign debug_wb_have_inst = have_inst;
    assign debug_wb_pc        = pc_WB;
    assign debug_wb_ena       = wb_ena_WB;
    assign debug_wb_reg       = wb_reg;
    assign debug_wb_value     = wb_value;
`endif

endmodule