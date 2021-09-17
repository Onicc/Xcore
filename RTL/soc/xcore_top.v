`include "defines.v"

module xcore_top (
    input wire clk,
    input wire rst,

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

    // slave 1 interface
    wire [`MemAddrBus] s2_wraddr;
    wire [`MemBus] s2_wdata;
    wire [`MemBus] s2_rdata;
    wire s2_we;

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

endmodule