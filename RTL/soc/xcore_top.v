`include "defines.v"

module xcore_top (
    input wire clk,
    input wire rst,

    input wire uart_debug_pin,
    output wire uart_tx_pin, // UART发送引脚
    input wire uart_rx_pin,  // UART接收引脚

    inout wire [1:0] gpio    // GPIO引脚
);

    wire [`MenSelBus] ram_sel;

    // master 0 interface
    wire [`MemAddrBus] m0_wraddr;
    wire [`MemBus] m0_wdata;
    wire [`MemBus] m0_rdata;
    wire m0_req;
    wire m0_we;

    // master 1 interface
    wire [`MemAddrBus] m1_wraddr;
    wire [`MemBus] m1_wdata;
    wire [`MemBus] m1_rdata;
    wire m1_req;
    wire m1_we;

    // master 2 interface
    wire [`MemAddrBus] m2_wraddr;
    wire [`MemBus] m2_wdata;
    wire [`MemBus] m2_rdata;
    wire m2_req;
    wire m2_we;

    // slave 0 interface
    wire [`MemAddrBus] s0_wraddr;
    wire [`MemBus] s0_wdata;
    wire [`MemBus] s0_rdata;
    wire s0_we;

    // slave 1 interface
    wire [`MemAddrBus] s1_wraddr;
    wire [`MemBus] s1_wdata;
    wire [`MemBus] s1_rdata;
    wire s1_we;

    // slave 2 interface
    wire [`MemAddrBus] s2_wraddr;
    wire [`MemBus] s2_wdata;
    wire [`MemBus] s2_rdata;
    wire s2_we;

    // slave 3 interface
    wire [`MemAddrBus] s3_wraddr;
    wire [`MemBus] s3_wdata;
    wire [`MemBus] s3_rdata;
    wire s3_we;

    // rib
    wire rib_hold_flag;

    // gpio
    wire [`MemBus] gpio_ctrl;
    wire [`MemBus] gpio_data;

    xcore u_xcore(
        .clk(clk),
        .rst(rst),

        .rib_rom_pc_wraddr(m0_wraddr),
        .rib_rom_pc_rdata(m0_rdata),

        .rib_ram_wraddr(m1_wraddr),
        .rib_ram_wdata(m1_wdata),
        .rib_ram_rdata(m1_rdata),
        .rib_ram_req(m1_req),
        .rib_ram_we(m1_we),
        .ram_sel(ram_sel),   // 特殊

        .rib_hold_flag(rib_hold_flag)
    );

    // ROM
    rom u_rom(
        .clk(clk),
        .rst(rst),

        .we(s0_we),
        .wraddr(s0_wraddr),
        .wdata(s0_wdata),
        .rdata(s0_rdata)
    );

    // RAM
    ram u_ram(
        .clk(clk),
        .rst(rst),

        .we(s1_we),
        .sel(ram_sel),
        .wraddr(s1_wraddr),
        .wdata(s1_wdata),
        .rdata(s1_rdata)
    );

    assign gpio[0] = (gpio_ctrl[1:0] == 2'b01)? gpio_data[0]: 1'bz;
    assign gpio[1] = (gpio_ctrl[3:2] == 2'b01)? gpio_data[1]: 1'bz;
    // GPIO
    gpio u_gpio(
        .clk(clk),
        .rst(rst),

        .we(s2_we),
        .wraddr(s2_wraddr),
        .wdata(s2_wdata),
        .rdata(s2_rdata),

        .gpio(gpio),
        .reg_ctrl(gpio_ctrl),
        .reg_data(gpio_data)
    );

    uart u_uart(
        .clk(clk),
        .rst(rst),

        .we(s3_we),
        .wraddr(s3_wraddr),
        .wdata(s3_wdata),
        .rdata(s3_rdata),

        .tx_pin(uart_tx_pin),
        .rx_pin(uart_rx_pin)
    );

    // rib
    rib u_rib(
        .clk(clk),
        .rst(rst),

        // master 0 interface   ROM控制器
        .m0_wraddr(m0_wraddr),
        .m0_wdata(`ZeroWord),
        .m0_rdata(m0_rdata),
        .m0_req(`RIB_REQ),
        .m0_we(`WriteDisable),

        // master 1 interface   RAM控制器
        .m1_wraddr(m1_wraddr),
        .m1_wdata(m1_wdata),
        .m1_rdata(m1_rdata),
        .m1_req(m1_req),
        .m1_we(m1_we),

        // slave 0 interface    ROM
        .s0_wraddr(s0_wraddr),
        .s0_wdata(s0_wdata),
        .s0_rdata(s0_rdata),
        .s0_we(s0_we),

        // slave 1 interface    RAM
        .s1_wraddr(s1_wraddr),
        .s1_wdata(s1_wdata),
        .s1_rdata(s1_rdata),
        .s1_we(s1_we),

        // slave 2 interface    GPIO
        .s2_wraddr(s2_wraddr),
        .s2_wdata(s2_wdata),
        .s2_rdata(s2_rdata),
        .s2_we(s2_we),

        .hold_flag(rib_hold_flag)
    );

    uart_debug u_uart_debug(
        .clk(clk),
        .rst(rst),

        .debug_en(uart_debug_pin), 

        .req(m2_req),
        .we(m2_we),
        .wraddr(m2_wdata),
        .wdata(m2_wdata),
        .rdata(m2_rdata)
    );

endmodule