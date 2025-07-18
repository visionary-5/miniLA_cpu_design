`timescale 1ns / 1ps
`include "defines.vh"

/*
 * ================================================
 * myCPU - miniLA 单周期处理器核心模块
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

    /* 控制路径信号声明 */
    wire [3:0]  alu_op;      // 算术逻辑单元操作码
    wire [2:0]  alu_sel;     // ALU数据源选择信号
    wire [1:0]  npc_op;      // 下一PC计算方式选择
    wire        rf_sel;      // 寄存器堆读端口选择
    wire [2:0]  wD_sel;      // 写回数据源多路选择
    wire [2:0]  sext1_op;    // 立即数符号扩展操作类型
    wire        sext2_op;    // 存储器数据符号扩展方式
    wire [1:0]  dram_sel;    // 存储器写入操作类型
    wire [1:0]  addr_mode;   // 存储器访问数据宽度
    wire        wb_ena;      // 寄存器写回控制使能

    /* 数据路径信号声明 */
    wire [31:0] alu_c;           // ALU运算结果主输出
    wire        alu_f;           // ALU条件判断标志输出
    wire [31:0] rf_rD1, rf_rD2;  // 寄存器堆双端口读数据
    wire [31:0] npc, pc4;        // 下一条指令PC及PC+4
    wire [31:0] pc;              // 当前程序计数器值
    wire [31:0] sext1_ext;       // 立即数符号扩展结果
    wire [31:0] sext2_ext;       // 存储器读数据符号扩展结果
    wire [31:0] zext_ext;        // 立即数零扩展结果
    wire [3:0]  dram_we;         // 存储器字节级写使能
    wire [31:0] dram_addr;       // 存储器访问物理地址
    wire [31:0] dram_rdata;      // 存储器读数据（经处理）
    wire [31:0] dram_wdata;      // 存储器写数据（最终）

`ifdef RUN_TRACE
    wire [4:0]  wb_reg;      // 调试模式：写回寄存器号
    wire [31:0] wb_value;    // 调试模式：写回数据值
`endif

    /* 各功能单元模块实例化 */
    
    // 程序计数器寄存器模块
    PC program_counter (
        .pc_rst     (cpu_rst),
        .pc_clk     (cpu_clk),
        .din        (npc),
        .pc         (pc)
    );

    // 指令地址映射逻辑
    assign inst_addr = pc[31:2];

    // 下一PC计算单元
    NPC next_pc_calculator (
        .br         (alu_f),
        .pc         (pc),
        .alu_c      (alu_c),
        .sext       (sext1_ext),
        .npc_op     (npc_op),
        .npc        (npc),
        .pc4        (pc4)
    );

    // 算术逻辑运算单元
    ALU arithmetic_logic_unit (
        .inst       (inst),
        .alu_op     (alu_op),
        .pc         (pc),
        .rf_rD1     (rf_rD1),
        .rf_rD2     (rf_rD2),
        .sext1      (sext1_ext),
        .zext       (zext_ext),
        .alu_sel    (alu_sel),
        .alu_c      (alu_c),
        .alu_f      (alu_f)
    );

    // 通用寄存器堆模块
    RF register_file (
        .rf_rst     (cpu_rst),
        .rf_clk     (cpu_clk),
        .inst       (inst),
        .rf_sel     (rf_sel),
        .wD_sel     (wD_sel),
        .alu_c      (alu_c),
        .sext2      (sext2_ext),
        .pc4        (pc4),
        .rdo        (dram_rdata),
        .rf_rD1     (rf_rD1),
        .rf_rD2     (rf_rD2),
        .wb_ena     (wb_ena)
`ifdef RUN_TRACE
        ,
        .debug_wb_reg   (wb_reg),
        .debug_wb_value (wb_value)
`endif
    );

    // 立即数扩展处理单元（符号扩展+零扩展）
    EXIT_UNIT immediate_extension_unit (
        .sext1_op   (sext1_op),
        .inst       (inst),
        .sext1_ext  (sext1_ext),
        .zext_ext   (zext_ext) 
    );

    // 存储器读数据符号扩展单元
    SEXT2 memory_data_sign_extender (
        .sext2_op   (sext2_op),
        .dram_rdata (dram_rdata),
        .sext2_ext  (sext2_ext)
    );

    // 指令解码与控制信号生成器
    Controller instruction_decoder_controller (
        .inst       (inst),
        .alu_op     (alu_op),
        .alu_sel    (alu_sel),
        .npc_op     (npc_op),
        .rf_sel     (rf_sel),
        .wD_sel     (wD_sel),
        .sext1_op   (sext1_op),
        .sext2_op   (sext2_op),
        .dram_sel   (dram_sel),
        .addr_mode  (addr_mode),
        .wb_ena     (wb_ena)
    );

    // 存储器访问数据处理抽象层
    DramSel memory_access_controller (
        .dram_sel       (dram_sel),
        .alu_c          (alu_c),
        .addr_mode      (addr_mode),
        .dram_addr      (dram_addr),
        .dram_rdata_raw (Bus_rdata),
        .dram_rdata     (dram_rdata),
        .rf_rD2         (rf_rD2),
        .dram_wdata     (dram_wdata),
        .dram_we        (dram_we)
    );

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

    // 写回信息寄存缓存
    reg [31:0] current_pc;
    reg [4:0]  current_wb_reg;
    reg [31:0] current_wb_value;
    reg        current_wb_ena;
    
    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            current_pc <= 32'b0;
        end else if (cpu_clk) begin
            current_pc     <= pc;
            current_wb_reg <= wb_reg;
            current_wb_value <= wb_value;
            current_wb_ena   <= wb_ena;
        end
    end

    // 调试信号输出连接
    assign debug_wb_have_inst = have_inst;
    assign debug_wb_pc        = current_pc;
    assign debug_wb_ena       = current_wb_ena;
    assign debug_wb_reg       = current_wb_reg;
    assign debug_wb_value     = current_wb_value;
`endif

endmodule