`timescale 1ns / 1ps

module button(
    input  wire         clk,
    input  wire         rst,
    input  wire [31:0]  addr,          
    input  wire [4:0]   button_input,  // 板上button输入
    output reg  [31:0]  rdata          // 输出到Bridge
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            rdata <= 32'd0;
        else
            rdata <= {27'd0, button_input};
    end

endmodule
