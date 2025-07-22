`timescale 1ns / 1ps

module ID_EX (
    input  wire        clk,
    input  wire        rst,
    // 数据信号
    input  wire [31:0] pc_in,
    input  wire [31:0] pc4_in,
    input  wire [31:0] rf_rD1_in,
    input  wire [31:0] rf_rD2_in,
    input  wire [31:0] sext1_ext_in,
    input  wire [31:0] zext_ext_in,
    input  wire [31:0] inst_in,

    // 控制信号
    input  wire [3:0]  alu_op_in,
    input  wire [2:0]  alu_sel_in,
    input  wire [1:0]  npc_op_in,
    input  wire        rf_sel_in,
    input  wire [2:0]  wD_sel_in,
    input  wire [1:0]  sext1_op_in,    
    input  wire        sext2_op_in,
    input  wire [1:0]  dram_sel_in,
    input  wire [1:0]  addr_mode_in,
    input  wire        wb_ena_in,

    // 输出到EX阶段
    output reg  [31:0] pc_out,
    output reg  [31:0] pc4_out,
    output reg  [31:0] rf_rD1_out,
    output reg  [31:0] rf_rD2_out,
    output reg  [31:0] sext1_ext_out,
    output reg  [31:0] zext_ext_out,
    output reg  [31:0] inst_out,

    output reg  [3:0]  alu_op_out,
    output reg  [2:0]  alu_sel_out,
    output reg  [1:0]  npc_op_out,
    output reg         rf_sel_out,
    output reg  [2:0]  wD_sel_out,
    output reg  [1:0]  sext1_op_out,   
    output reg         sext2_op_out,
    output reg  [1:0]  dram_sel_out,
    output reg  [1:0]  addr_mode_out,
    output reg         wb_ena_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out        <= 32'b0;
            pc4_out       <= 32'b0;
            rf_rD1_out    <= 32'b0;
            rf_rD2_out    <= 32'b0;
            sext1_ext_out <= 32'b0;
            zext_ext_out  <= 32'b0;
            inst_out      <= 32'b0;

            alu_op_out    <= 4'b0;
            alu_sel_out   <= 3'b0;
            npc_op_out    <= 2'b0;
            rf_sel_out    <= 1'b0;
            wD_sel_out    <= 3'b0;
            sext1_op_out  <= 2'b0;    
            sext2_op_out  <= 1'b0;
            dram_sel_out  <= 2'b0;
            addr_mode_out <= 2'b0;
            wb_ena_out    <= 1'b0;
        end else begin
            pc_out        <= pc_in;
            pc4_out       <= pc4_in;
            rf_rD1_out    <= rf_rD1_in;
            rf_rD2_out    <= rf_rD2_in;
            sext1_ext_out <= sext1_ext_in;
            zext_ext_out  <= zext_ext_in;
            inst_out      <= inst_in;

            alu_op_out    <= alu_op_in;
            alu_sel_out   <= alu_sel_in;
            npc_op_out    <= npc_op_in;
            rf_sel_out    <= rf_sel_in;
            wD_sel_out    <= wD_sel_in;
            sext1_op_out  <= sext1_op_in;
            sext2_op_out  <= sext2_op_in;
            dram_sel_out  <= dram_sel_in;
            addr_mode_out <= addr_mode_in;
            wb_ena_out    <= wb_ena_in;
        end
    end

endmodule
