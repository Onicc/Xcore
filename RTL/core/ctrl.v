/*
 * 控制模块，跳转，控制流水线暂停标标志、跳转标志和跳转地址。
 */
`include "defines.v"

module ctrl (
    input wire rst,

    // 来自ex
    input wire ex_jump_flag,
    input wire [`InstAddrBus] ex_jump_addr,
    input wire ex_hold_flag,

    // 来自clint
    input wire clint_hold_flag,

    // 来自rib
    input wire rib_hold_flag,

    // 给pc, if, id
    output reg [`HoldFlagBus] hold_flag,

    // 给pc寄存器
    output reg pc_jump_flag,
    output reg [`InstAddrBus] pc_jump_addr
);

    always @(*) begin
        if(rst == `RstEnable) begin
            hold_flag <= `HoldNone;
            pc_jump_flag <= `JumpDisable;
            pc_jump_addr <= `InstAddrNop;
        end else begin
            pc_jump_addr <= ex_jump_addr;
            pc_jump_flag <= ex_jump_flag;
            // 跳转指令暂停取址和译码
            if(ex_jump_flag == `JumpEnable || ex_hold_flag == `HoldEnable || clint_hold_flag == `HoldEnable) begin
                hold_flag <= `HoldIf | `HoldId;
            end else if(rib_hold_flag == `HoldEnable) begin
                hold_flag <= `HoldPc;
            end else begin
                hold_flag <= `HoldNone;
            end
        end
    end
    
endmodule