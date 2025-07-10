
`timescale 1ns / 1ps
`include "defines.vh"

module myCPU (
    input  wire         cpu_rst,
    input  wire         cpu_clk,

    // Interface to IROM
`ifdef RUN_TRACE
    output wire [15:0]  inst_addr,
`else
    output wire [13:0]  inst_addr,
`endif
    input  wire [31:0]  inst,

    // Interface to Bridge
    output wire [31:0]  Bus_addr,
    input  wire [31:0]  Bus_rdata,
    output wire         Bus_we,
    output wire [31:0]  Bus_wdata

`ifdef RUN_TRACE
    ,// Debug Interface
    output wire         debug_wb_have_inst,
    output wire [31:0]  debug_wb_pc,
    output              debug_wb_ena,
    output wire [ 4:0]  debug_wb_reg,
    output wire [31:0]  debug_wb_value
`endif
);

    // 内部连线
    wire [31:0] pc, npc, pc4;
    wire [31:0] imm1, imm2;
    wire [31:0] rd1, rd2;
    wire [31:0] alu_b, alu_c;
    wire [31:0] rf_wd;
    wire [4:0] rf_rR1, rf_rR2, rf_wR;
    wire rf_we;
    wire [3:0] npc_op;
    wire [2:0] sext1_op, sext2_op;
    wire [3:0] alu_op;
    wire alu_bsel;
    wire [1:0] rf_wsel;
    wire br;

    // 实例化模块
    PC pc_reg(.clk(cpu_clk), .rst(cpu_rst), .din(npc), .pc(pc));
    NPC npc_unit(.pc(pc), .imm(imm1), .rj(rd1), .br(br), .op(npc_op), .npc(npc), .pc4(pc4));
    SEXT1 sext1(.inst(inst), .op(sext1_op), .ext(imm1));
    SEXT2 sext2(.inst(inst), .op(sext2_op), .ext(imm2));
    RF rf(.clk(cpu_clk), .rst(cpu_rst), .rR1(rf_rR1), .rR2(rf_rR2), .wR(rf_wR), .we(rf_we), .wD(rf_wd), .rD1(rd1), .rD2(rd2));
    Controller ctrl(.op(inst[31:26]), .npc_op(npc_op), .sext1_op(sext1_op), .sext2_op(sext2_op),
                    .alu_op(alu_op), .alu_bsel(alu_bsel), .rf_wsel(rf_wsel), .rf_we(rf_we));
    MUX_alu_bsel mux_b(.b(rd2), .imm(imm2), .sel(alu_bsel), .out(alu_b));
    ALU alu(.a(rd1), .b(alu_b), .op(alu_op), .c(alu_c), .br(br));
    MUX_rf_wsel mux_wd(.alu_c(alu_c), .dram_rdo(Bus_rdata), .pc4(pc4), .sext1_ext(imm1), .sel(rf_wsel), .wd(rf_wd));

    // DRAM 接口
    assign Bus_addr = alu_c;
    assign Bus_wdata = rd2;
    assign Bus_we = /* TODO: 添加写使能控制信号 */ 1'b0;

    // Inst_addr 接口
    assign inst_addr = pc[15:2]; // 字地址转换（字对齐）

`ifdef RUN_TRACE
    assign debug_wb_have_inst = 1'b1;  // 每周期都有指令写回
    assign debug_wb_pc        = pc;
    assign debug_wb_ena       = rf_we;
    assign debug_wb_reg       = rf_wR;
    assign debug_wb_value     = rf_wd;
`endif

endmodule
