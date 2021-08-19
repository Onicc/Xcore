/* 
 * 把id模块得到的运算类型、运算子类型、操作数、目标地址、是否写入目标地址在下一个时钟周期传给ex模块
 */
`include "defines.v"

module id_ex (
    input wire clk,
    input wire rst,

    // 从id中传过来的
    input wire [`InstAddrBus] id_pc,
    input wire [`InstBus] id_inst,
    input wire [`RegBus] id_reg1,
    input wire [`RegBus] id_reg2,
    input wire [`RegBus] id_imm,          // 立即数
    input wire [`RegAddrBus] id_reg_waddr, // 从指令中解析出来的，用于下一个模块计算完成后存放
    input wire id_reg_we,                   // 是否需要存放至目的寄存器，因为有得指令不需要存储目的值

    // 本模块的主要输出
    output reg [`InstAddrBus] ex_pc,
    output reg [`InstBus] ex_inst,
    output reg [`RegBus] ex_reg1,
    output reg [`RegBus] ex_reg2,
    output reg [`RegBus] ex_imm,
    output reg [`RegAddrBus] ex_reg_waddr, // 从指令中解析出来的，用于下一个模块计算完成后存放
    output reg ex_reg_we                   // 是否需要存放至目的寄存器，因为有得指令不需要存储目的值
);

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            ex_pc <= `InstAddrNop;
            ex_inst <= `ZeroWord;
            ex_reg1 <= `ZeroWord;
            ex_reg2 <= `ZeroWord;
            ex_imm <= `ZeroWord;
            ex_reg_waddr <= 5'b00000;
            ex_reg_we <= `WriteDisable;
        end else begin
            ex_pc <= id_pc;
            ex_inst <= id_inst;
            ex_reg1 <= id_reg1;
            ex_reg2 <= id_reg2;
            ex_imm <= id_imm;
            ex_reg_waddr <= id_reg_waddr;
            ex_reg_we <= id_reg_we;
        end
    end

endmodule