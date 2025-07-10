`timescale 1ns / 1ps
`include "defines.vh"

module SEXT2 (
    input  wire [3:0]  op,
    input  wire [31:0] din,
    output reg  [31:0] ext
);

always @(*) begin
    case (op)
        `EXT2_0:   ext = 32'b0;
        `EXT2_8:   ext = {{24{din[20]}}, din[20:13]};     // st.b
        `EXT2_16:  ext = {{16{din[20]}}, din[20:5]};      // st.h
        default:   ext = 32'b0;
    endcase
end

endmodule
