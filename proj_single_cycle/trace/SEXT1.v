`timescale 1ns / 1ps
`include "defines.vh"

module SEXT1 (
    input  wire [3:0]  op,
    input  wire [31:0] din,
    output reg  [31:0] ext
);

always @(*) begin
    case (op)
        `EXT1_0:     ext = 32'b0;
        `EXT1_12:    ext = {{18{din[25]}}, din[25:14]};
        `EXT1_16:    ext = {{16{din[25]}}, din[25:10]};
        `EXT1_20:    ext = {{12{din[24]}}, din[24:5]};
        `EXT1_28:    ext = {{17{din[23]}}, din[23:10], din[4:0]};
        default:     ext = 32'b0;
    endcase
end

endmodule
