/* 
 * 译码阶段，对指令进行译码然后返回其指令对应的运算类型、运算操作数
 * regfile模块：负责读取两个寄存器写一个寄存器的功能
 */
`include "defines.v"

module regfile (
    input wire clk,
    input wire rst,

    input wire we,
    input wire [`RegAddrBus] waddr,
    input wire [`RegBus] wdata,

    input wire re1,
    input wire [`RegAddrBus] raddr1,
    output reg [`RegBus] rdata1,

    input wire re2,
    input wire [`RegAddrBus] raddr2,
    output reg [`RegBus] rdata2
);
    reg [`RegBus] regs[0:`RegNum-1];

    // 写寄存器
    always @(posedge clk) begin
        if(rst == `RstDisable && we == `WriteEnable && wdata != `RegNumLog2'h0) begin
            regs[waddr] <= wdata;
        end
    end

    // 读寄存器1
    always @(*) begin
        if(rst == `RstEnable) begin
            rdata1 <= `ZeroWord;
        end else if(raddr1 == `RegNumLog2'h0) begin
            rdata1 <= `ZeroWord;
        end else if((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable)) begin
            rdata1 <= wdata;
        end else if(re1 == `ReadEnable) begin
            rdata1 <= regs[raddr1];
        end else begin
            rdata1 <= `ZeroWord; 
        end
    end

    // 读寄存器2
    always @(*) begin
        if(rst == `RstEnable) begin
            rdata2 <= `ZeroWord;
        end else if(raddr2 == `RegNumLog2'h0) begin
            rdata2 <= `ZeroWord;
        end else if((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable)) begin
            rdata2 <= wdata;
        end else if(re2 == `ReadEnable) begin
            rdata2 <= regs[raddr2];
        end else begin
            rdata2 <= `ZeroWord; 
        end
    end
endmodule
