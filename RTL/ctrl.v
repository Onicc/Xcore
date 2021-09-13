/*
 * 控制模块，跳转
 */
`include "defines.v"

module ctrl (
    input wire rst,

    // 来自ex
    input wire ex_jump_flag,
    input wire [`InstAddrBus] ex_jump_addr,

    // 给pc, if, id
    output reg [`HoldFlagBus] hold_flag,

    // 给pc寄存器
    output reg pc_jump_flag,
    output reg [`InstAddrBus] pc_jump_addr
);

    always @(*) begin
        pc_jump_addr <= ex_jump_addr;
        pc_jump_flag <= ex_jump_flag;
        // 跳转指令暂停取址和译码
        if(ex_jump_flag == `JumpEnable) begin
            hold_flag <= `HoldIf | `HoldId;
        end else begin
            hold_flag <= `HoldNone;
        end
    end
    
endmodule