`include "defines.v"

module inst_rom (
    input wire ce,
    input wire [`InstAddrBus] addr,     // 指令地址,32位
    output reg [`InstBus] inst          // 指令本体，32位指令
);

    reg [`InstBus] inst_mem[0:`InstMemNum-1];    // 定义2^17个32位长到数组，用于存放指令

    always @(*) begin
        if(ce == `ChipDisable) begin
            inst <= 32'h0;                                  // 失能时返回空指令
        end else begin
            // `InstMemNumLog2+1:2 表示大端存储
            // addr为32为，但inst_rom只有17位，如果按字节寻址，addr的范围位2^17*4=2^19
            // 也就是addr中只有19位被使用了，并且使用字节寻址，因此19位需要除4，即右移两位，因此
            // 因此19位中的高17位才是对应inst_mem寻址的地址，因此取[18:2]的部分
            inst <= inst_mem[addr[`InstMemNumLog2+1:2]];    // 使能时返回相应地址的指令
        end
    end
    
endmodule