/* 
 * 把ex_mem模块返回的目标值、是否写入寄存器和写入哪个寄存器在任意时刻作用输出
 */
`include "defines.v"

module mem (
    input wire clk,
    input wire rst,

    // 从ex_mem中传过来的
    input wire [`RegAddrBus] mem_waddr,     // 待写的寄存器的地址
    input wire [`RegBus] mem_wdata,         // 待写的寄存器的数据
    input wire mem_we,                       // 写使能

    // 传给mem
    output reg [`RegAddrBus] mem_waddr_o,     // 待写的寄存器的地址
    output reg [`RegBus] mem_wdata_o,         // 待写的寄存器的数据
    output reg mem_we_o                       // 写使能
);

    always @(*) begin
        if(rst == `RstEnable) begin
            mem_waddr_o <= 5'b00000;
            mem_wdata_o <= `ZeroWord;
            mem_we_o <= `WriteDisable;
        end else begin
            mem_waddr_o <= mem_waddr;
            mem_wdata_o <= mem_wdata;
            mem_we_o <= mem_we;
        end
    end


endmodule