/* 
 * 对指令进行译码，得到运算类型、子类型、源操作数1寄存器地址、源操作数2寄存器地址、写入目的寄存器地址
 * XOI 
 */
`include "defines.v"

module id (
    input wire rst,

    // 由id_id模块发送过来的指令地址和指令
    input wire [`InstAddrBus] pc,
    input wire [`InstBus] inst,

    // 与regfile模块相连，取出源操作寄存器的值
    output reg reg1_re,
    output reg [`RegAddrBus] reg1_raddr,
    input wire [`RegBus] reg1_rdata,

    output reg reg2_re,
    output reg [`RegAddrBus] reg2_raddr,
    input wire [`RegBus] reg2_rdata,

    // 当指令相邻时，相邻指令读取同一个寄存器，不能从regfile取，需要从执行阶段取到的运算结果
    input wire [`RegAddrBus] ex_waddr,     // 待写的寄存器的地址
    input wire [`RegBus] ex_wdata,         // 待写的寄存器的数据
    input wire ex_we,                      // 写使能

    // 当指令相邻2时，相邻2的指令读取同一个寄存器，不能从regfile取，需要从访存阶段取到的运算结果
    // 这里的mem为访存的mem
    input wire [`RegAddrBus] mem_waddr,     // 待写的寄存器的地址
    input wire [`RegBus] mem_wdata,         // 待写的寄存器的数据
    input wire mem_we,                      // 写使能

    // 本模块的主要输出
    output reg [`InstAddrBus] pc_o,
    output reg [`InstBus] inst_o,
    output reg [`RegBus] reg1,          // 与reg1_rdata相同，不过这里是输出
    output reg [`RegBus] reg2,          // 与reg2_rdata相同，不过这里是输出
    output reg [`RegBus] imm,           // 立即数
    output reg [`RegAddrBus] reg_waddr, // 从指令中解析出来的，用于下一个模块计算完成后存放
    output reg reg_we                   // 是否需要存放至目的寄存器，因为有得指令不需要存储目的值
);
    wire [6:0] op = inst[6:0];
    wire [2:0] funct3 = inst[14:12];
    wire [6:0] funct7 = inst[31:25];
    wire [4:0] shamt = inst[24:20];

    always @(*) begin
        if(rst == `RstEnable) begin
            pc_o <= `InstAddrNop;
            inst_o <= `ZeroWord;
            imm <= `ZeroWord;
            reg1_re <= `ReadDisable;
            reg2_re <= `ReadDisable;
            reg_we <= `WriteDisable;
            reg1_raddr <= `RegAddrNop;
            reg2_raddr <= `RegAddrNop;
            reg_waddr <= `RegAddrNop;
        end else begin
            // 按照理论值初始化
            pc_o <= pc;
            inst_o <= inst;
            imm <= `ZeroWord;
            reg1_re <= `ReadDisable;
            reg2_re <= `ReadDisable;
            reg_we <= `WriteDisable;
            reg1_raddr <= inst[19:15];
            reg2_raddr <= inst[24:20];
            reg_waddr <= inst[11:7];

            // 解析指令释放使能，获取地址
            case (op)
                `OP_R: begin
                    case (funct3)
                        `FUNC3_R_ADD, `FUNC3_R_SUB, `FUNC3_R_SLL, `FUNC3_R_SLT, `FUNC3_R_SLTU, `FUNC3_R_XOR, `FUNC3_R_SRL, `FUNC3_R_SRA, `FUNC3_R_OR, `FUNC3_R_AND: begin
                            reg1_re <= `ReadEnable;
                            reg2_re <= `ReadEnable;
                            reg_we <= `WriteEnable;
                        end
                        default: begin
                            reg1_re <= `ReadDisable;
                            reg2_re <= `ReadDisable;
                            reg_we <= `WriteDisable;
                        end
                    endcase
                end

                `OP_I: begin
                    case (funct3)
                        `FUNC3_I_ADDI, `FUNC3_I_SLTI, `FUNC3_I_SLTIU, `FUNC3_I_XORI, `FUNC3_I_ORI, `FUNC3_I_ANDI: begin
                            imm <= {{20{inst[31]}}, inst[31:20]};
                            reg1_re <= `ReadEnable;
                            reg_we <= `WriteEnable;
                        end
                        `FUNC3_I_SLLI, `FUNC3_I_SRLI, `FUNC3_I_SRAI: begin
                            imm[4:0] <= shamt;
                            reg1_re <= `ReadEnable;
                            reg_we <= `WriteEnable;
                        end
                        default: begin
                            imm <= `ZeroWord;
                            reg1_re <= `ReadDisable;
                            reg_we <= `WriteDisable;
                        end
                    endcase
                end

                `OP_S: begin
                    case (funct3)
                        `FUNC3_S_SB, `FUNC3_S_SH, `FUNC3_S_SW: begin
                            imm <= {{20{inst[31]}}, inst[31:25], inst[11:7]};
                            reg1_re <= `ReadEnable;
                            reg2_re <= `ReadEnable;
                        end
                        default: begin
                            imm <= `ZeroWord;
                            reg1_re <= `ReadDisable;
                            reg2_re <= `ReadDisable;
                        end
                    endcase
                end

                `OP_B: begin
                    case (funct3)
                        `FUNC3_B_BEQ, `FUNC3_B_BNE, `FUNC3_B_BLT, `FUNC3_B_BGE, `FUNC3_B_BLTU, `FUNC3_B_BGEU: begin
                            // input: rs1, rs2, -rd-, imm, pc
                            imm <= {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
                            reg1_re <= `ReadEnable;
                            reg2_re <= `ReadEnable;
                        end
                        default: begin
                            imm <= `ZeroWord;
                            reg1_re <= `ReadDisable;
                            reg2_re <= `ReadDisable;
                        end
                    endcase
                end

                `OP_L: begin
                    case (funct3)
                        `FUNC3_L_LB, `FUNC3_L_LH, `FUNC3_L_LW, `FUNC3_L_LBU, `FUNC3_L_LHU: begin
                            imm <= {{20{inst[31]}}, inst[31:20]};
                            reg1_re <= `ReadEnable;
                            reg_we <= `WriteEnable;
                        end
                        default: begin
                            imm <= `ZeroWord;
                            reg1_re <= `ReadDisable;
                            reg_we <= `WriteDisable;
                        end
                    endcase
                end

                // 一些指令
                `OP_LUI: begin
                    imm <= {inst[31:12], 12'b0};
                    reg_we <= `WriteEnable;
                end
                `OP_AUIPC: begin
                    imm <= {inst[31:12], 12'b0};
                    reg_we <= `WriteEnable;
                end
                `OP_JAL: begin
                    
                end

                default: begin
                end
            endcase
        end
    end

    // 读源操作数1
    always @(*) begin
        if(rst == `RstEnable) begin
            reg1 <= `ZeroWord;
        end else if(reg1_re == `ReadEnable) begin
            if(ex_we == `WriteEnable && ex_waddr == reg1_raddr) begin
                // 当发现执行阶段运算的结果保存的位置和现在要读的位置相同时，读取执行阶段的结果
                reg1 <= ex_wdata;
            end else if(mem_we == `WriteEnable && mem_waddr == reg1_raddr) begin
                // 当发现访存阶段运算的结果保存的位置和现在要读的位置相同时，读取执行阶段的结果
                reg1 <= mem_wdata;
            end else begin
                // 以上都不满足才读当前地址对应寄存器的值
                reg1 <= reg1_rdata;
            end
        end else begin
            reg1 <= `ZeroWord;
        end
    end

    // 读源操作数2
    always @(*) begin
        if(rst == `RstEnable) begin
            reg2 <= `ZeroWord;
        end else if(reg2_re == `ReadEnable) begin
            if(ex_we == `WriteEnable && ex_waddr == reg2_raddr) begin
                // 当发现执行阶段运算的结果保存的位置和现在要读的位置相同时，读取执行阶段的结果
                reg2 <= ex_wdata;
            end else if(mem_we == `WriteEnable && mem_waddr == reg2_raddr) begin
                // 当发现访存阶段运算的结果保存的位置和现在要读的位置相同时，读取执行阶段的结果
                reg2 <= mem_wdata;
            end else begin
                // 以上都不满足才读当前地址对应寄存器的值
                reg2 <= reg2_rdata;
            end
        end else begin
            reg2 <= `ZeroWord;
        end
    end

endmodule