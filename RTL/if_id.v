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

    // 发送给译码的地址和指令，是一样的
    output reg [`InstAddrBus] id_pc,
    output reg [`InstBus] id_inst
);
    
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            id_pc <= 32'h0000;
            id_inst <= 32'h0000;
        end else begin
            id_pc <= if_pc;
            id_inst <= if_inst;
        end
    end
endmodule
