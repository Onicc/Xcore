/* 
 * 暂存取址的指令和地址，在下一个时钟传递到译码阶段
 */
`include "defines.v"

module if_id (
    input wire clk,
    input wire rst,

    // 取址的指令地址和指令
    input wire [`InstAddrBus] if_pc,
    input wire [`InstBus] if_inst,

    input wire [`HoldFlagBus] hold_flag,

    // 发送给译码的地址和指令，是一样的
    output reg [`InstAddrBus] id_pc,
    output reg [`InstBus] id_inst
);
    
    always @(posedge clk) begin
        if(rst == `RstEnable | (hold_flag & `HoldIf == `HoldIf)) begin
            id_pc <= `InstAddrNop;
            id_inst <= `InstNop;
        end else begin
            id_pc <= if_pc;
            id_inst <= if_inst;
        end
    end
endmodule
