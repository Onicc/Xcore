/* 
 * 把id_ex模块得到的运算类型、运算子类型、操作数、目标地址、是否写入目标地址
 * 根据运算计算出目标值，返回目标值、是否写入寄存器和写入哪个寄存器
 */
`include "defines.v"

module ex (
    input wire clk,
    input wire rst,

    // 从id_ex中传过来的
    input wire [`InstBus] inst,
    input wire [`RegBus] reg1,
    input wire [`RegBus] reg2,
    input wire [`RegAddrBus] reg_waddr, // 从指令中解析出来的，用于下一个模块计算完成后存放
    input wire reg_we,                   // 是否需要存放至目的寄存器，因为有得指令不需要存储目的值

    // 执行的结果
    output reg [`RegAddrBus] waddr,     // 待写的寄存器的地址
    output reg [`RegBus] wdata,         // 待写的寄存器的数据
    output reg we                       // 写使能
);

    wire [6:0] op = inst[6:0];
    wire [2:0] funct3 = inst[14:12];
    wire [6:0] funct7 = inst[31:25];

    always @(*) begin
        if(rst == `RstEnable) begin
            wdata <= `ZeroWord;
        end else begin
            we <= reg_we;
            waddr <= reg_waddr;
            case (op)
                `OP_R: begin
                    if((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin
                        case (funct3)
                            `FUNC3_R_ADD, `FUNC3_R_SUB: begin
                                if(inst[30] == 1'b0) begin
                                    // add
                                    wdata <= reg1 + reg2;
                                end else begin
                                    // sub
                                    wdata <= reg1 - reg2;
                                end
                            end
                            `FUNC3_R_SLL: begin
                                wdata <= reg1 << reg2[4:0];
                            end
                            `FUNC3_R_SLT: begin
                                wdata <= {32{$signed(reg1) < $signed(reg2)}} & 32'h1;
                            end
                            `FUNC3_R_SLTU: begin
                                wdata <= {32{reg1 < reg2}} & 32'h1;
                            end
                            `FUNC3_R_XOR: begin
                                wdata <= reg1 ^ reg2;
                            end
                            `FUNC3_R_SRL, `FUNC3_R_SRA: begin
                                if(inst[30] == 1'b0) begin
                                    // srl
                                    wdata <= reg1 >> reg2[4:0];
                                end else begin
                                    // sra
                                    wdata <= (reg1 >> reg2[4:0]) | ({32{reg1[31]}} & (~(32'hffffffff >> reg2[4:0])));
                                end
                            end
                            `FUNC3_R_OR: begin
                                wdata <= reg1 | reg2;
                            end
                            `FUNC3_R_AND: begin
                                wdata <= reg1 & reg2;
                            end
                            default: begin
                                wdata <= `ZeroWord;
                            end
                        endcase
                    end else begin
                        // 留空，后面会用
                    end
                end

                `OP_I: begin
                    case (funct3)
                        `FUNC3_I_ADDI: begin
                            wdata <= reg1 + reg2;
                        end
                        `FUNC3_I_SLTI: begin
                            // Set if Less Than Immediate
                           wdata <= {32{$signed(reg1) < $signed(reg2)}} & 32'h1;
                        end
                        `FUNC3_I_SLTIU: begin
                            // Set if Less Than Immediate, Unsigned
                            wdata <= {32{reg1 < reg2}} & 32'h1;
                        end
                        `FUNC3_I_XORI: begin
                            wdata <= reg1 ^ reg2;
                        end
                        `FUNC3_I_ORI: begin
                            wdata <= reg1 | reg2;
                        end
                        `FUNC3_I_ANDI: begin
                            wdata <= reg1 & reg2;
                        end
                        `FUNC3_I_SLLI: begin
                            // Shift Left Logical Immediate
                            wdata <= reg1 << reg2[4:0];
                        end
                        `FUNC3_I_SRLI, `FUNC3_I_SRAI: begin
                            // Shift Right Logical Immediate
                            // Shift Right Arithmetic Immediate
                            if(inst[30] == 1'b0) begin
                                // FUNC3_I_SRLI
                                wdata <= reg1 >> reg2[4:0];
                            end else begin
                                // FUNC3_I_SRAI
                                // 算术右移，高位按照符号位补
                                wdata <= (reg1 >> reg2[4:0]) | ({32{reg1[31]}} & (~(32'hffffffff >> reg2[4:0])));
                            end
                        end
                        default: begin
                            wdata <= `ZeroWord;
                        end
                    endcase
                end
                
                `OP_S: begin
                end

                `OP_B: begin
                end

                `OP_L: begin
                    case(funct3)
                        `FUNC3_L_LB: begin
                        end
                        `FUNC3_L_LH: begin
                        end
                        `FUNC3_L_LW: begin
                        end
                        `FUNC3_L_LBU: begin
                        end
                        `FUNC3_L_LHU: begin
                        end
                        default: begin
                        end
                    endcase
                end

                // 一些指令
                `OP_LUI: begin
                    wdata <= reg1;
                end
                `OP_AUIPC: begin
                    wdata <= reg1;
                end
                `OP_JAL: begin
                    
                end

                default: begin
                end
            endcase
        end
    end

endmodule