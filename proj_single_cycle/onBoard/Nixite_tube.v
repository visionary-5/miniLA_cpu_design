`timescale 1ns / 1ps
module Nixie_tube(
    input  wire      clk,
    input  wire      rst,
    input  wire [3:0]DIG,
    output reg  [7:0]SEGMENT
);
    always @(*) begin
        case (DIG)
            4'd0:  SEGMENT = 8'b0011_1111;  // 0
            4'd1:  SEGMENT = 8'b0000_0110;  // 1
            4'd2:  SEGMENT = 8'b0101_1011;  // 2
            4'd3:  SEGMENT = 8'b0100_1111;  // 3
            4'd4:  SEGMENT = 8'b0110_0110;  // 4
            4'd5:  SEGMENT = 8'b0110_1101;  // 5
            4'd6:  SEGMENT = 8'b0111_1101;  // 6
            4'd7:  SEGMENT = 8'b0000_0111;  // 7
            4'd8:  SEGMENT = 8'b0111_1111;  // 8
            4'd9:  SEGMENT = 8'b0110_1111;  // 9
            4'd10: SEGMENT = 8'b0111_0111;  // A
            4'd11: SEGMENT = 8'b0111_1100;  // B
            4'd12: SEGMENT = 8'b0011_1001;  // C
            4'd13: SEGMENT = 8'b0101_1110;  // D
            4'd14: SEGMENT = 8'b0111_1001;  // E
            4'd15: SEGMENT = 8'b0111_0001;  // F
            default: SEGMENT = 8'b0000_0000;  
        endcase
    end
endmodule