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

    // csr
    input wire id_csr_we,
    input wire [`CsrAddrBus] id_csr_waddr,

    input wire [`HoldFlagBus] hold_flag,

    // 本模块的主要输出
    output reg [`InstAddrBus] ex_pc,
    output reg [`InstBus] ex_inst,
    output reg [`RegBus] ex_reg1,
    output reg [`RegBus] ex_reg2,
    output reg [`RegBus] ex_imm,
    output reg [`RegAddrBus] ex_reg_waddr, // 从指令中解析出来的，用于下一个模块计算完成后存放
    output reg ex_reg_we,                   // 是否需要存放至目的寄存器，因为有得指令不需要存储目的值

    output reg ex_csr_we,                       // ex模块写寄存器标志
    output reg [`CsrAddrBus] ex_csr_waddr           // ex模块写寄存器地址
);

    always @(posedge clk) begin
        if(rst == `RstEnable || (hold_flag & `HoldId) == `HoldId) begin
            ex_pc <= `InstAddrNop;
            ex_inst <= `InstNop;
            ex_reg1 <= `RegNop;
            ex_reg2 <= `RegNop;
            ex_imm <= `ZeroWord;
            ex_reg_waddr <= `RegAddrNop;
            ex_reg_we <= `WriteDisable;
            // csr
            ex_csr_we <= `WriteDisable;
            ex_csr_waddr <= `CsrAddrNop;
        end else begin
            ex_pc <= id_pc;
            ex_inst <= id_inst;
            ex_reg1 <= id_reg1;
            ex_reg2 <= id_reg2;
            ex_imm <= id_imm;
            ex_reg_waddr <= id_reg_waddr;
            ex_reg_we <= id_reg_we;
            // csr
            ex_csr_we <= id_csr_we;
            ex_csr_waddr <= id_csr_waddr;
        end
    end

endmodule