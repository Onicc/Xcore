/* 
 * 来个时钟信号pc寄存器加4个字节，指向下一个指令的地址
 */
`include "defines.v"

module pc_reg (
    input wire clk,
    input wire rst,

    output reg [`InstAddrBus] pc,       // pc指令的地址,InstAddrBus = 31:0,如果按字节取址,可以查询2^32/4条指令
    output reg ce                       // 指令存储器的使能，当复位时失能，结束复位时使能
);

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            ce <= `ChipDisable;         // 复位状态，失能pc寄存器的读出
        end else begin
            ce <= `ChipEnable;          // 非复位状态，使能pc寄存器的读出
        end
    end

    always @(posedge clk) begin
        if(ce == `ChipDisable) begin
            pc <= 32'h00000000;         // 失能状态返回0地址
        end else begin
            pc <= pc + 4'h4;            // 使能状态返回下一个pc寄存器的地址，因为一个pc地址为32位，如果按字节取址(即pc的移动单位为4位)，因此下一个pc地址需移动四个字节
        end
    end
    
endmodule