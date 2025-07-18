`timescale 1ns / 1ps
module switch(
    input  wire        rst,
    input  wire        clk,
    input  wire [31:0] addr,    // 直接用32位，方便Bridge兼容
    input  wire [15:0] switch,
    output wire [31:0] rdata
);
    assign rdata = {16'b0, switch};
    
endmodule
