/* 
 * 把mem模块返回的目标值、是否写入寄存器和写入哪个寄存器在下个时钟传给回写写入
 */
`include "defines.v"

module mem_wb (
    input wire clk,
    input wire rst,

    // 从mem中传过来的
    input wire [`RegAddrBus] mem_waddr,     // 待写的寄存器的地址
    input wire [`RegBus] mem_wdata,         // 待写的寄存器的数据
    input wire mem_we,                       // 写使能

    // 传给wb
    output reg [`RegAddrBus] wb_waddr,     // 待写的寄存器的地址
    output reg [`RegBus] wb_wdata,         // 待写的寄存器的数据
    output reg wb_we                       // 写使能
);

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            wb_waddr <= 5'b00000;
            wb_wdata <= `ZeroWord;
            wb_we <= `WriteDisable;
        end else begin
            wb_waddr <= mem_waddr;
            wb_wdata <= mem_wdata;
            wb_we <= mem_we;
        end
    end


endmodule