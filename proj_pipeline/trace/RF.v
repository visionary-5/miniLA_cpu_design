`timescale 1ns / 1ps
`include "defines.vh"

// =============================================================
// RF —— 通用寄存器堆模块（Register File）- 流水线版本
// 支持两个读端口和一个写端口，写回方式多样，0号寄存器恒为零
// =============================================================
module RF (
    output  wire  [31:0]  rf_rD1,    // 读端口1
    output  wire  [31:0]  rf_rD2,    // 读端口2

    input   wire          rf_clk,    // 写时钟信号
    input   wire          rf_rst,    // 异步复位
    input   wire  [31:0]  inst_ID,   // ID阶段指令（用于读操作）
    input   wire  [31:0]  inst_WB,   // WB阶段指令（用于写操作）
    input   wire          rf_sel,    // 读端口2选择信号 (ID阶段)
    input   wire          wb_ena,    // 写回使能 (WB阶段)

    // 写回数据多路选择与数据源 (WB阶段)
    input   wire  [2:0]   wD_sel,
    input   wire  [31:0]  alu_c,
    input   wire  [31:0]  sext2,
    input   wire  [31:0]  pc4,
    input   wire  [31:0]  rdo

`ifdef RUN_TRACE
    ,output wire [4:0]   debug_wb_reg,
    output wire [31:0]   debug_wb_value
`endif
);

    // =============== 32×32 位寄存器阵列 ===============
    reg [31:0] register [0:31];

    // =============== 指令字段分解（寄存器索引） ===============
    // 读操作使用ID阶段指令
    wire [4:0] reg_rj_ID = inst_ID[9:5];     // 读端口1
    wire [4:0] reg_rk_ID = inst_ID[14:10];   // 读端口2
    wire [4:0] reg_rd_ID = inst_ID[4:0];     // 读端口2备选
    
    // 写操作使用WB阶段指令
    wire [4:0] reg_rd_WB = inst_WB[4:0];     // 写端口

    // =============== 异步读出 ===============
    assign rf_rD1 = register[reg_rj_ID];

    assign rf_rD2 = (rf_sel == `RF_SEL_RK) ? register[reg_rk_ID] :
                    (rf_sel == `RF_SEL_RD) ? register[reg_rd_ID] :
                    32'b0;

    // =============== 写端口判定 ===============
    // WD_PC4_R1 为特殊写回类型，写1号寄存器
    wire [4:0] wb_reg = (wD_sel != `WB_SEL_PC4_R1) ? reg_rd_WB : 5'b00001;

    // =============== 写回数据多路选择 ===============
    wire [31:0] wb_value =
        (wD_sel == `WB_SEL_ALU_RESULT)  ? alu_c :
        (wD_sel == `WB_SEL_EXT2_RESULT) ? sext2 :
        (wD_sel == `WB_SEL_DRAM_BYTE)   ? {register[wb_reg][31:8],  rdo[7:0]} :
        (wD_sel == `WB_SEL_DRAM_HALF)   ? {register[wb_reg][31:16], rdo[15:0]} :
        (wD_sel == `WB_SEL_DRAM_WORD)   ? rdo :
        (wD_sel == `WB_SEL_INST)        ? {inst_WB[24:5], 12'b0} :
        (wD_sel == `WB_SEL_PC4_RD)      ? pc4 :
        (wD_sel == `WB_SEL_PC4_R1)      ? pc4 :
        32'b0;

    // =============== 写时钟写入 ===============
    always @(posedge rf_clk or posedge rf_rst) begin
        if (rf_rst) begin
            // 可选：复位时全部清零
            // integer i; for(i=0;i<32;i=i+1) register[i] <= 32'b0;
        end else begin
            if (wb_ena) begin
                // 0号寄存器恒为零，不允许写入
                register[wb_reg] <= (wb_reg == 0) ? 32'b0 : wb_value;
            end
        end
    end

`ifdef RUN_TRACE
    // Trace调试接口输出
    assign debug_wb_reg   = wb_reg;
    assign debug_wb_value = wb_value;
`endif

endmodule
