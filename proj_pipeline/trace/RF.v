`timescale 1ns / 1ps

`include "defines.vh"

// 通用寄存器堆模块
module RF (
    input   wire          rf_rst,
    input   wire          rf_clk,

    input   wire  [31:0]  inst1, // 用于译码阶段
    input   wire  [31:0]  inst2, // 用于回写阶段

    // 可能的rR1和rR2选择
    input   wire rf_sel,

    input   wire wb_ena,
    input   wire  [4:0]   wb_reg,

    // 用于load-use冒险，
    // 在MEM阶段获取回写数据
    // 需要支持字节/半字写回
    input   wire  [4:0]   ID_wb_reg,
    output  wire  [31:0]  ID_wb_reg_value,

    // 可能的写回数据选择
    input   wire  [2:0]   wD_sel,
    input   wire  [31:0]  alu_c,
    input   wire  [31:0]  sext2,
    input   wire  [31:0]  pc4,
    input   wire  [31:0]  rdo,

    output  wire  [31:0]  rf_rD1,
    output  wire  [31:0]  rf_rD2

`ifdef RUN_TRACE
    ,// 调试接口
    output wire [31:0]  debug_wb_value
`endif
);

    // 32个32位寄存器
    reg  [31:0]  register [0:31];

    // 指令字段提取
    wire [4:0] reg1 = inst1[9:5];    // rj
    wire [4:0] reg2 = inst1[14:10];  // rk
    wire [4:0] reg3 = inst1[4:0];    // rd

    assign ID_wb_reg_value = register[ID_wb_reg];

    // 读操作为非阻塞
    // 读出寄存器1
    assign rf_rD1 = register[reg1];

    // 读出寄存器2
    assign rf_rD2 = (rf_sel == `RF_SEL_RK) ? register[reg2] :
                    (rf_sel == `RF_SEL_RD) ? register[reg3] :
                    32'b0;

    // 写回数据选择
    wire [31:0] wb_value = 
                        (wD_sel == `WB_SEL_ALU_RESULT) ? alu_c :
                        (wD_sel == `WB_SEL_EXT2_RESULT) ? sext2 :
                        (wD_sel == `WB_SEL_DRAM_BYTE) ? {register[wb_reg][31:8], rdo[7:0]} :
                        (wD_sel == `WB_SEL_DRAM_HALF) ? {register[wb_reg][31:16], rdo[15:0]} :
                        (wD_sel == `WB_SEL_DRAM_WORD) ? rdo :
                        (wD_sel == `WB_SEL_INST) ? {inst2[24:5], 12'b0} :
                        (wD_sel == `WB_SEL_PC4_RD) ? pc4 :
                        (wD_sel == `WB_SEL_PC4_R1) ? pc4 :
                        32'b0; 

    always @(posedge rf_rst or posedge rf_clk) begin
        if (rf_rst) begin
            // 复位时只清零r0
            register[0] <= 32'b0;
        end else begin
            if (wb_ena && wb_reg != 0) begin
                // 不允许修改r0
                register[wb_reg] <= wb_value;
            end
        end
    end

`ifdef RUN_TRACE
    assign debug_wb_value = wb_value;
`endif

endmodule
