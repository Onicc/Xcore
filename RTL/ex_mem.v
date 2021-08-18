/* 
 * 把ex模块返回的目标值、是否写入寄存器和写入哪个寄存器在下个时钟传给mem来访存
 */
`include "defines.v"

module ex_mem (
    input wire clk,
    input wire rst,

    // 从ex中传过来的
    input wire [`RegAddrBus] ex_waddr,     // 待写的寄存器的地址
    input wire [`RegBus] ex_wdata,         // 待写的寄存器的数据
    input wire ex_we,                       // 写使能

    // 传给mem
    output reg [`RegAddrBus] mem_waddr,     // 待写的寄存器的地址
    output reg [`RegBus] mem_wdata,         // 待写的寄存器的数据
    output reg mem_we                       // 写使能
);

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            mem_waddr <= 5'b00000;
            mem_wdata <= `ZeroWord;
            mem_we <= `WriteDisable;
        end else begin
            mem_waddr <= ex_waddr;
            mem_wdata <= ex_wdata;
            mem_we <= ex_we;
        end
    end


endmodule