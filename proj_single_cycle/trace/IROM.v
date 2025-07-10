`timescale 1ns / 1ps

module IROM (
    input  wire [31:0] adr,     // 地址输入（来自 PC）
    output wire [31:0] inst     // 指令输出
);

    // 地址范围：0x00000000 ~ 0x00000FFF（可调）
    // ROM 深度：4096 字，每字 32 位
    reg [31:0] rom [0:1023];  // 4KB ROM，每行一个指令

    // 指令输出：adr[11:2] 表示字地址，忽略低 2 位字节偏移
    assign inst = rom[adr[11:2]];

    // 初始化 ROM 内容
    initial begin
        $readmemh("inst_rom.coe", rom);  // 使用 .coe 文件初始化
    end

endmodule
