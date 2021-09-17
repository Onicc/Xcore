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
    // mem
    input wire mem_csr_we,                       // ex模块写寄存器标志
    input wire [`CsrAddrBus] mem_csr_waddr,           // ex模块写寄存器地址
    input wire [`CsrBus] mem_csr_wdata,         // 待写的寄存器的数据

    // 传给wb
    output reg [`RegAddrBus] wb_waddr,     // 待写的寄存器的地址
    output reg [`RegBus] wb_wdata,         // 待写的寄存器的数据
    output reg wb_we,                       // 写使能
    // csr
    output reg wb_csr_we,                       // ex模块写寄存器标志
    output reg [`CsrAddrBus] wb_csr_waddr,           // ex模块写寄存器地址
    output reg [`CsrBus] wb_csr_wdata         // 待写的寄存器的数据
);

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            wb_waddr <= `RegAddrNop;
            wb_wdata <= `RegNop;
            wb_we <= `WriteDisable;
            wb_csr_we <= `WriteDisable;
            wb_csr_waddr <= `CsrAddrNop;
            wb_csr_wdata <= `CsrNop;
        end else begin
            wb_waddr <= mem_waddr;
            wb_wdata <= mem_wdata;
            wb_we <= mem_we;
            wb_csr_we <= mem_csr_we;
            wb_csr_waddr <= mem_csr_waddr;
            wb_csr_wdata <= mem_csr_wdata;
        end
    end


endmodule