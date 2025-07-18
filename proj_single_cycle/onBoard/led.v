`timescale 1ns / 1ps
module led(
    input  wire        rst,
    input  wire        clk,
    input  wire [31:0] addr,
    input  wire        we,
    input  wire [31:0] wdata,
    output reg [15:0]  led
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            led <= 16'd0;
        end else begin 
            if (we) begin // 使用不同的偏移地址
                led <= wdata[15:0];
            end
        end   
    end
endmodule