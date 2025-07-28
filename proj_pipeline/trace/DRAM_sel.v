`timescale 1ns / 1ps

`include "defines.vh"

// DRAM抽象层模块
// 负责处理字节/半字/字的读写操作
module DramSel (
    // 写操作类型选择
    input wire  [1:0]   dram_sel,
    // 原始地址
    input wire  [31:0]  alu_c,
    input wire  [1:0]   addr_mode,
    // DRAM -> DramSel
    output wire [31:0]  dram_addr,
    // 从DRAM读取数据
    input wire  [31:0]  dram_rdata_raw, // DRAM原始数据输入
    output wire [31:0]  dram_rdata,     // 处理后数据输出到用户
    // 写入DRAM
    input wire  [31:0]  rf_rD2,         // 用户写入数据
    output wire [31:0]  dram_wdata,     // 写入DRAM的数据
    output wire         dram_we  // 写使能
);

    // 地址对齐到字，byte_offset用于字节/半字寻址
    wire [1:0] byte_offset = alu_c[1:0];
    wire [31:0] word_addr = {alu_c[31:2], 2'b0};
    assign dram_addr =  word_addr;

    // 字节读取（根据偏移选择）
    wire [7:0] read_byte =  (byte_offset == 2'b00) ? dram_rdata_raw[7:0] :
                            (byte_offset == 2'b01) ? dram_rdata_raw[15:8] :
                            (byte_offset == 2'b10) ? dram_rdata_raw[23:16] :
                            dram_rdata_raw[31:24];

    // 半字读取（低16位或高16位）
    wire [15:0] read_hw =   (byte_offset == 2'b00) ? dram_rdata_raw[15:0] :
                            dram_rdata_raw[31:16];

    // 输出到CPU的数据，按访问类型选择
    assign dram_rdata = (addr_mode == `ADDR_MODE_BYTE) ? {24'b0, read_byte} :
                        (addr_mode == `ADDR_MODE_HALF) ? {16'b0, read_hw} :
                        (addr_mode == `ADDR_MODE_WORD) ? dram_rdata_raw :
                        32'b0;

    // 字节写入（根据偏移将rf_rD2的低8位写入对应字节）
    wire [31:0] write_byte =    (byte_offset == 2'b00) ? {dram_rdata_raw[31:8], rf_rD2[7:0]} :
                                (byte_offset == 2'b01) ? {dram_rdata_raw[31:16], rf_rD2[7:0], dram_rdata_raw[7:0]} :
                                (byte_offset == 2'b10) ? {dram_rdata_raw[31:24], rf_rD2[7:0], dram_rdata_raw[15:0]} :
                                (byte_offset == 2'b11) ? {rf_rD2[7:0], dram_rdata_raw[23:0]} :
                                32'b0;
    
    // 半字写入（根据偏移将rf_rD2的低16位写入对应半字）
    wire [31:0] write_hw =      (byte_offset == 2'b00) ? {dram_rdata_raw[31:16], rf_rD2[15:0]} :
                                (byte_offset == 2'b10) ? {rf_rD2[15:0], dram_rdata_raw[15:0]} :
                                32'b0;

    // 写入DRAM的数据选择
    assign dram_wdata = (dram_sel == `DRAM_OP_WRITE_BYTE) ? write_byte :
                        (dram_sel == `DRAM_OP_WRITE_HALF) ? write_hw :
                        (dram_sel == `DRAM_OP_WRITE_WORD) ? rf_rD2 :
                        32'b0;

    // 写使能信号
    assign dram_we =    (dram_sel == `DRAM_OP_WRITE_BYTE | dram_sel == `DRAM_OP_WRITE_HALF | dram_sel == `DRAM_OP_WRITE_WORD) ? 1'b1 : 1'b0;
endmodule
