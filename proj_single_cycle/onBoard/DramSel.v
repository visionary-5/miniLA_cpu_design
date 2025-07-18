`timescale 1ns / 1ps
`include "defines.vh"

// ===========================================
// DramSel —— DRAM 数据访问抽象层（分级冗余辅助信号版）
// ===========================================
module DramSel (
    input  wire [1:0]   dram_sel,
    input  wire [31:0]  alu_c,
    input  wire [1:0]   addr_mode,

    output wire [31:0]  dram_addr,

    input  wire [31:0]  dram_rdata_raw,
    output wire [31:0]  dram_rdata,

    input  wire [31:0]  rf_rD2,
    output wire [31:0]  dram_wdata,
    output wire [3:0]   dram_we
);

    // ===== 地址处理 =====
    wire [1:0] byte_offset = alu_c[1:0];
    wire [31:0] word_addr = {alu_c[31:2], 2'b00}; // 字对齐，部分场景可能用不上
    assign dram_addr = alu_c;

    // ===== 读数据分组 =====
    wire [7:0] byte0 = dram_rdata_raw[7:0];
    wire [7:0] byte1 = dram_rdata_raw[15:8];
    wire [7:0] byte2 = dram_rdata_raw[23:16];
    wire [7:0] byte3 = dram_rdata_raw[31:24];

    wire [15:0] half0 = dram_rdata_raw[15:0];
    wire [15:0] half1 = dram_rdata_raw[31:16];

    // 读数据组装
    wire [7:0]  sel_byte = (byte_offset == 2'b00) ? byte0 :
                           (byte_offset == 2'b01) ? byte1 :
                           (byte_offset == 2'b10) ? byte2 : byte3;

    wire [15:0] sel_half = (byte_offset == 2'b00) ? half0 : half1;

    // read data（辅助信号分组）
    wire [31:0] r_byte  = {24'b0, sel_byte};
    wire [31:0] r_half  = {16'b0, sel_half};
    wire [31:0] r_word  = dram_rdata_raw;

    assign dram_rdata = (addr_mode == `ADDR_MODE_BYTE) ? r_byte :
                        (addr_mode == `ADDR_MODE_HALF) ? r_half :
                        (addr_mode == `ADDR_MODE_WORD) ? r_word :
                        32'b0;

    // ===== 写数据分组 =====
    // write mask（按字节/半字/字不同）
    wire [31:0] write_mask_byte  = ~(32'hff   << (byte_offset * 8));
    wire [31:0] write_mask_half  = ~(32'hffff << (byte_offset * 8));
    wire [31:0] write_mask_word  = 32'h00000000;

    // write data部分
    wire [31:0] wdata_byte = (dram_rdata_raw & write_mask_byte) | (rf_rD2[7:0]  << (byte_offset * 8));
    wire [31:0] wdata_half = (dram_rdata_raw & write_mask_half) | (rf_rD2[15:0] << (byte_offset * 8));
    wire [31:0] wdata_word = rf_rD2;

    assign dram_wdata =
        (dram_sel == `DRAM_OP_WRITE_BYTE) ? wdata_byte :
        (dram_sel == `DRAM_OP_WRITE_HALF) ? wdata_half :
        (dram_sel == `DRAM_OP_WRITE_WORD) ? wdata_word :
        32'b0;

    // ===== 写使能信号 =====
    wire [3:0] we_byte  = 4'b0001 << byte_offset;
    wire [3:0] we_half  = 4'b0011 << byte_offset;
    wire [3:0] we_word  = 4'b1111;

    assign dram_we =
        (dram_sel == `DRAM_OP_WRITE_BYTE) ? we_byte :
        (dram_sel == `DRAM_OP_WRITE_HALF) ? we_half :
        (dram_sel == `DRAM_OP_WRITE_WORD) ? we_word :
        4'b0000;

endmodule
