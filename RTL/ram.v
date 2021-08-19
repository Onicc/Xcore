`include "defines.v"

module ram (
    input wire clk,
    input wire rst,

    input wire we,
    input wire [`MemAddrBus] wraddr,     // 地址读写共用
    input wire [`MemBus] wdata,

    output reg [`MemBus] rdara
);
    reg [`MemBus] _ram[0:`MemNum - 1];

    always @(posedge clk) begin
        if(rst == `RstDisable && we == `WriteEnable) begin
            // wraddr/8才是对应的哪一个
            _ram[wraddr[31:2]] <= wdata;
        end
    end

    always @() begin
        if(rst == `RstEnable) begin
            rdara <= `ZeroWord;
        end else if(we == `WriteDisable) begin
            rdara <= _ram[wraddr[31:2]]; 
        end else begin
            rdara <= `ZeroWord;
        end
    end

endmodule