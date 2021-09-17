`include "defines.v"

module xcore_top (
    input wire clk,
    input wire rst
);

    wire [`MenSelBus] ram_sel;

    // master 0 interface
    wire[`MemAddrBus] m0_addr_i;
    wire[`MemBus] m0_data_i;
    wire[`MemBus] m0_data_o;
    wire m0_req_i;
    wire m0_we_i;

    // master 1 interface
    wire[`MemAddrBus] m1_addr_i;
    wire[`MemBus] m1_data_i;
    wire[`MemBus] m1_data_o;
    wire m1_req_i;
    wire m1_we_i;

    // slave 0 interface
    wire[`MemAddrBus] s0_addr_o;
    wire[`MemBus] s0_data_o;
    wire[`MemBus] s0_data_i;
    wire s0_we_o;

    // slave 1 interface
    wire[`MemAddrBus] s1_addr_o;
    wire[`MemBus] s1_data_o;
    wire[`MemBus] s1_data_i;
    wire s1_we_o;

    // rib
    wire rib_hold_flag;

    xcore u_xcore(
        .clk(clk),
        .rst(rst),

        .rib_rom_pc_wraddr(m0_addr_i),
        .rib_rom_pc_rdata(m0_data_o),

        .rib_ram_wraddr(m1_addr_i),
        .rib_ram_wdata(m1_data_i),
        .rib_ram_rdata(m1_data_o),
        .rib_ram_req(m1_req_i),
        .rib_ram_we(m1_we_i),
        .ram_sel(ram_sel),   // 特殊

        .rib_hold_flag(rib_hold_flag)
    );

    // ROM
    rom u_rom(
        .clk(clk),
        .rst(rst),

        .we(s0_we_o),
        .wraddr(s0_addr_o),
        .wdata(s0_data_o),
        .rdata(s0_data_i)
    );

    // RAM
    ram u_ram(
        .clk(clk),
        .rst(rst),

        .we(s1_we_o),
        .sel(ram_sel),
        .wraddr(s1_addr_o),
        .wdata(s1_data_o),
        .rdata(s1_data_i)
    );

    // rib
    rib u_rib(
        .clk(clk),
        .rst(rst),

        // master 0 interface
        .m0_addr_i(m0_addr_i),
        .m0_data_i(`ZeroWord),
        .m0_data_o(m0_data_o),
        .m0_req_i(`RIB_REQ),
        .m0_we_i(`WriteDisable),

        // master 1 interface
        .m1_addr_i(m1_addr_i),
        .m1_data_i(m1_data_i),
        .m1_data_o(m1_data_o),
        .m1_req_i(m1_req_i),
        .m1_we_i(m1_we_i),

        // slave 0 interface
        .s0_addr_o(s0_addr_o),
        .s0_data_o(s0_data_o),
        .s0_data_i(s0_data_i),
        .s0_we_o(s0_we_o),

        // slave 1 interface
        .s1_addr_o(s1_addr_o),
        .s1_data_o(s1_data_o),
        .s1_data_i(s1_data_i),
        .s1_we_o(s1_we_o),

        .hold_flag_o(rib_hold_flag)
    );

endmodule