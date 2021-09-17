/* 
 * 把ex模块返回的目标值、是否写入寄存器和写入哪个寄存器在下个时钟传给mem来访存
 */
`include "defines.v"

module ex_mem (
    input wire clk,
    input wire rst,

    // 从ex中传过来的
    // reg
    input wire [`RegAddrBus] ex_waddr,     // 待写的寄存器的地址
    input wire [`RegBus] ex_wdata,         // 待写的寄存器的数据
    input wire ex_we,                       // 写使能
    // csr
    input wire ex_csr_we,                       // ex模块写寄存器标志
    input wire [`CsrAddrBus] ex_csr_waddr,           // ex模块写寄存器地址
    input wire [`CsrBus] ex_csr_wdata,         // 待写的寄存器的数据

    // 传给mem
    // reg
    output reg [`RegAddrBus] mem_waddr,     // 待写的寄存器的地址
    output reg [`RegBus] mem_wdata,         // 待写的寄存器的数据
    output reg mem_we,                       // 写使能
    // csr
    output reg mem_csr_we,                       // ex模块写寄存器标志
    output reg [`CsrAddrBus] mem_csr_waddr,           // ex模块写寄存器地址
    output reg [`CsrBus] mem_csr_wdata         // 待写的寄存器的数据
);

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            mem_waddr <= `RegAddrNop;
            mem_wdata <= `RegNop;
            mem_we <= `WriteDisable;
            mem_csr_we <= `WriteDisable;
            mem_csr_waddr <= `CsrAddrNop;
            mem_csr_wdata <= `CsrNop;
        end else begin
            mem_waddr <= ex_waddr;
            mem_wdata <= ex_wdata;
            mem_we <= ex_we;
            mem_csr_we <= ex_csr_we;
            mem_csr_waddr <= ex_csr_waddr;
            mem_csr_wdata <= ex_csr_wdata;
        end
    end


endmodule