`timescale 1ns / 1ps

module IF_ID (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] pc_in,    // IF阶段PC
    input  wire [31:0] inst_in,  // IF阶段指令
    input  wire [31:0] pc4_in,   // IF阶段PC+4

    output reg  [31:0] pc_out,   // 传给ID阶段的PC
    output reg  [31:0] inst_out,  // 传给ID阶段的指令
    output reg  [31:0] pc4_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out   <= 32'b0;
            inst_out <= 32'b0;
            pc4_out  <= 32'b0;
        end else begin
            pc_out   <= pc_in;
            inst_out <= inst_in;
            pc4_out  <= pc4_in;
        end
    end

endmodule
