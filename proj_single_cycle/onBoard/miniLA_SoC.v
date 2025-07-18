`timescale 1ns / 1ps

`include "defines.vh"

module miniLA_SoC (
    input wire         fpga_rstn,   // low active
    //input  wire         fpga_rst,   // high active
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

/*`ifdef RUN_TRACE
    ,// Debug Interface
    output wire         debug_wb_have_inst, // 当前时钟周期是否有指令写回 (对单周期CPU，可在复位后恒置1)
    output wire [31:0]  debug_wb_pc,        // 当前写回的指令的PC (若wb_have_inst=0，此项可为任意值)
    output              debug_wb_ena,       // 指令写回时，寄存器堆的写使能 (若wb_have_inst=0，此项可为任意值)
    output wire [ 4:0]  debug_wb_reg,       // 指令写回时，写入的寄存器号 (若wb_ena或wb_have_inst=0，此项可为任意值)
    output wire [31:0]  debug_wb_value      // 指令写回时，写入寄存器的值 (若wb_ena或wb_have_inst=0，此项可为任意值)
`endif*/
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
    wire [3:0]  Bus_we;          // 改为4-bit
    wire [31:0] Bus_wdata;
    
    // Interface between bridge and DRAM
    // wire         rst_bridge2dram;
    wire         clk_bridge2dram;
    wire [31:0]  addr_bridge2dram;
    wire [31:0]  rdata_dram2bridge;
    wire [3:0]   we_bridge2dram;
    wire [31:0]  wdata_bridge2dram;
    
    // Interface between bridge and peripherals
    wire        rst_to_dig;
    wire        clk_to_dig;
    wire [31:0] addr_to_dig;
    wire        we_to_dig;
    wire [31:0] wdata_to_dig;
    wire [7:0]   dig_dn;

    wire        rst_to_led;
    wire        clk_to_led;
    wire [31:0] addr_to_led;
    wire        we_to_led;
    wire [31:0] wdata_to_led;

    wire        rst_to_sw;
    wire        clk_to_sw;
    wire [31:0] addr_to_sw;
    wire [31:0] rdata_from_sw;

    wire        rst_to_btn;
    wire        clk_to_btn;
    wire [31:0] addr_to_btn;
    wire [31:0] rdata_from_btn;

    wire        rst_to_timer;
    wire        clk_to_timer;
    wire [31:0] addr_to_timer;
    wire        we_to_timer;
    wire [31:0] wdata_to_timer;
    wire [31:0] rdata_from_timer;

    assign DN_A1 = DN_A0;
    assign DN_B1 = DN_B0;
    assign DN_C1 = DN_C0;
    assign DN_D1 = DN_D0;
    assign DN_E1 = DN_E0;
    assign DN_F1 = DN_F0;
    assign DN_G1 = DN_G0;
    assign DN_DP1 = DN_DP0;
    
    // 添加数码管段信号连接
    assign {DN_DP0, DN_G0, DN_F0, DN_E0, DN_D0, DN_C0, DN_B0, DN_A0} = dig_dn;
  
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
        .we_from_cpu        (Bus_we),          // 这里是单bit
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
        .rst_to_dig         (rst_to_dig),
        .clk_to_dig         (clk_to_dig),
        .addr_to_dig        (addr_to_dig),
        .we_to_dig          (we_to_dig),
        .wdata_to_dig       (wdata_to_dig),

        // Interface to LEDs
        .rst_to_led         (rst_to_led),
        .clk_to_led         (clk_to_led),
        .addr_to_led        (addr_to_led),
        .we_to_led          (we_to_led),
        .wdata_to_led       (wdata_to_led),

        // Interface to switches
        .rst_to_sw          (rst_to_sw),
        .clk_to_sw          (clk_to_sw),
        .addr_to_sw         (addr_to_sw),
        .rdata_from_sw      (rdata_from_sw),

        // Interface to buttons
        .rst_to_btn         (rst_to_btn),
        .clk_to_btn         (clk_to_btn),
        .addr_to_btn        (addr_to_btn),
        .rdata_from_btn     (rdata_from_btn),

        // Interface to timer
        .rst_to_timer       (rst_to_timer),
        .clk_to_timer       (clk_to_timer),
        .addr_to_timer      (addr_to_timer),
        .we_to_timer        (we_to_timer),
        .wdata_to_timer     (wdata_to_timer),
        .rdata_from_timer   (rdata_from_timer)
    );

    DRAM Mem_DRAM (
        .clk        (clk_bridge2dram),
        .a          (addr_bridge2dram[15:2]),
        .d          (wdata_bridge2dram),
        .we         (we_bridge2dram),
        .spo        (rdata_dram2bridge)
    );
    
    // TODO: 在此实例化你的外设I/O接口电路模块u_
        // 数码管显示（端口已标准化）
    Digital_LEDs #(.FREQ(50000)) u_Digital_LEDS(
        .dig_clk            (clk_to_dig),
        .dig_rst            (rst_to_dig),
        .dig_addr           (addr_to_dig),
        .dig_we             (we_to_dig),
        .dig_wdata          (wdata_to_dig),
        .dig_en             (dig_en),
        .dig_dn             (dig_dn)
    );


    // LED 灯
    led u_led(
        .rst  (rst_to_led),
        .clk  (clk_to_led),
        .addr (addr_to_led), 
        .we   (we_to_led),      
        .wdata (wdata_to_led),
        .led   (led)                // 16位对接外部
    );

    // 拨码开关
    switch u_switch(
        .rst    (rst_to_sw),
        .clk    (clk_to_sw),
        .addr   (addr_to_sw),
        .switch (sw),
        .rdata  (rdata_from_sw)
    );

    // 按键
    button u_button(
        .rst(rst_to_btn),
        .clk(clk_to_btn),
        .addr(addr_to_btn),
        .button_input (button),
        .rdata(rdata_from_btn)
    );

    // 定时器
    timer u_timer(
        .timer_rst(rst_to_timer),
        .timer_clk(clk_to_timer),
        .timer_addr(addr_to_timer),
        .timer_wen(we_to_timer),
        .timer_raw_wdata(wdata_to_timer),
        .timer_rdata(rdata_from_timer)
    );



endmodule
