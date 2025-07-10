`timescale 1ns / 1ps

`include "defines.vh"

module miniLA_SoC (
    input  wire         fpga_rstn,   // Low active
    input  wire         fpga_clk,

    input  wire [15:0]  sw,
    input  wire [ 4:0]  button,
    output wire [ 7:0]  dig_en,
    output wire         DN_A0, DN_A1,
    output wire         DN_B0, DN_B1,
    output wire         DN_C0, DN_C1,
    output wire         DN_D0, DN_D1,
    output wire         DN_E0, DN_E1,
    output wire         DN_F0, DN_F1,
    output wire         DN_G0, DN_G1,
    output wire         DN_DP0, DN_DP1,
    output wire [15:0]  led

`ifdef RUN_TRACE
    ,// Debug Interface
    output wire         debug_wb_have_inst, // 当前时钟周期是否有指令写回 (对单周期CPU，可在复位后恒置1)
    output wire [31:0]  debug_wb_pc,        // 当前写回的指令的PC (若wb_have_inst=0，此项可为任意值)
    output              debug_wb_ena,       // 指令写回时，寄存器堆的写使能 (若wb_have_inst=0，此项可为任意值)
    output wire [ 4:0]  debug_wb_reg,       // 指令写回时，写入的寄存器号 (若wb_ena或wb_have_inst=0，此项可为任意值)
    output wire [31:0]  debug_wb_value      // 指令写回时，写入寄存器的值 (若wb_ena或wb_have_inst=0，此项可为任意值)
`endif
);

    wire        pll_lock;
    wire        pll_clk;
    wire        cpu_clk;

    // Interface between CPU and IROM
`ifdef RUN_TRACE
    wire [15:0] inst_addr;
`else
    wire [13:0] inst_addr;
`endif
    wire [31:0] inst;

    // Interface between CPU and Bridge
    wire [31:0] Bus_rdata;
    wire [31:0] Bus_addr;
    wire        Bus_we;
    wire [31:0] Bus_wdata;
    
    // Interface between bridge and DRAM
    // wire         rst_bridge2dram;
    wire         clk_bridge2dram;
    wire [31:0]  addr_bridge2dram;
    wire [31:0]  rdata_dram2bridge;
    wire         we_bridge2dram;
    wire [31:0]  wdata_bridge2dram;
    
    // Interface between bridge and peripherals
    // TODO: 在此定义总线桥与外设I/O接口电路模块的连接信号
    //



    assign DN_A1 = DN_A0;
    assign DN_B1 = DN_B0;
    assign DN_C1 = DN_C0;
    assign DN_D1 = DN_D0;
    assign DN_E1 = DN_E0;
    assign DN_F1 = DN_F0;
    assign DN_G1 = DN_G0;
    assign DN_DP1 = DN_DP0;
    

    
`ifdef RUN_TRACE
    // Trace调试时，直接使用外部输入时钟
    assign cpu_clk = fpga_clk;
`else
    // 下板时，使用PLL分频后的时钟
    assign cpu_clk = pll_clk & pll_lock;
    cpuclk Clkgen (
        // .resetn     (fpga_rstn),
        .clk_in1    (fpga_clk),
        .clk_out1   (pll_clk),
        .locked     (pll_lock)
    );
`endif
    
    myCPU Core_cpu (
        .cpu_rst            (!fpga_rstn),
        .cpu_clk            (cpu_clk),

        // Interface to IROM
        .inst_addr          (inst_addr),
        .inst               (inst),

        // Interface to Bridge
        .Bus_addr           (Bus_addr),
        .Bus_rdata          (Bus_rdata),
        .Bus_we             (Bus_we),
        .Bus_wdata          (Bus_wdata)

`ifdef RUN_TRACE
        ,// Debug Interface
        .debug_wb_have_inst (debug_wb_have_inst),
        .debug_wb_pc        (debug_wb_pc),
        .debug_wb_ena       (debug_wb_ena),
        .debug_wb_reg       (debug_wb_reg),
        .debug_wb_value     (debug_wb_value)
`endif
    );
    
    IROM Mem_IROM (
        .a          (inst_addr),
        .spo        (inst)
    );
    
    Bridge Bridge (       
        // Interface to CPU
        .rst_from_cpu       (!fpga_rstn),
        .clk_from_cpu       (cpu_clk),
        .addr_from_cpu      (Bus_addr),
        .we_from_cpu        (Bus_we),
        .wdata_from_cpu     (Bus_wdata),
        .rdata_to_cpu       (Bus_rdata),
        
        // Interface to DRAM
        // .rst_to_dram    (rst_bridge2dram),
        .clk_to_dram        (clk_bridge2dram),
        .addr_to_dram       (addr_bridge2dram),
        .rdata_from_dram    (rdata_dram2bridge),
        .we_to_dram         (we_bridge2dram),
        .wdata_to_dram      (wdata_bridge2dram),
        
        // Interface to 7-seg digital LEDs
        .rst_to_dig         (/* TODO */),
        .clk_to_dig         (/* TODO */),
        .addr_to_dig        (/* TODO */),
        .we_to_dig          (/* TODO */),
        .wdata_to_dig       (/* TODO */),

        // Interface to LEDs
        .rst_to_led         (/* TODO */),
        .clk_to_led         (/* TODO */),
        .addr_to_led        (/* TODO */),
        .we_to_led          (/* TODO */),
        .wdata_to_led       (/* TODO */),

        // Interface to switches
        .rst_to_sw          (/* TODO */),
        .clk_to_sw          (/* TODO */),
        .addr_to_sw         (/* TODO */),
        .rdata_from_sw      (/* TODO */),

        // Interface to buttons
        .rst_to_btn         (/* TODO */),
        .clk_to_btn         (/* TODO */),
        .addr_to_btn        (/* TODO */),
        .rdata_from_btn     (/* TODO */)
    );

    DRAM Mem_DRAM (
        .clk        (clk_bridge2dram),
        .a          (addr_bridge2dram[15:2]),
        .spo        (rdata_dram2bridge),
        .we         (we_bridge2dram),
        .d          (wdata_bridge2dram)
    );
    
    // TODO: 在此实例化你的外设I/O接口电路模块
    //


endmodule
