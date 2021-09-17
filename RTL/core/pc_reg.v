/* 
 * 来个时钟信号pc寄存器加4个字节，指向下一个指令的地址
 */
`include "defines.v"

module pc_reg (
    input wire clk,
    input wire rst,

    input wire jump_flag,
    input wire [`InstAddrBus] jump_addr,
    input wire [`HoldFlagBus] hold_flag,

    output reg [`InstAddrBus] pc       // pc指令的地址,InstAddrBus = 31:0,如果按字节取址,可以查询2^32/4条指令
);

    always @(posedge clk) begin
        // 复位
        if(rst == `RstEnable) begin
            pc <= `InstAddrNop;         // 失能状态返回0地址
        // 跳转
        end else if(jump_flag == `JumpEnable) begin
            pc <= jump_addr;
        // 暂停
        end else if(hold_flag & `HoldPc == `HoldPc) begin
            pc <= pc;
        // 正常
        end else begin
            pc <= pc + 4'h4;            // 使能状态返回下一个pc寄存器的地址，因为一个pc地址为32位，如果按字节取址(即pc的移动单位为4位)，因此下一个pc地址需移动四个字节
        end
    end
    
endmodule