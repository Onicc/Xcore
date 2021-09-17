/* 
 * 把id_ex模块得到的运算类型、运算子类型、操作数、目标地址、是否写入目标地址
 * 根据运算计算出目标值，返回目标值、是否写入寄存器和写入哪个寄存器
 */
`include "defines.v"

module ex (
    input wire clk,
    input wire rst,

    // 从id_ex中传过来的
    input wire [`InstAddrBus] pc,
    input wire [`InstBus] inst,
    input wire [`RegBus] reg1,
    input wire [`RegBus] reg2,
    input wire [`RegBus] imm,
    input wire [`RegAddrBus] reg_waddr, // 从指令中解析出来的，用于下一个模块计算完成后存放
    input wire reg_we,                   // 是否需要存放至目的寄存器，因为有得指令不需要存储目的值
    // csr
    input wire id_csr_we,
    input wire [`CsrAddrBus] id_csr_waddr,

    // 从ram中传过来的
    input wire [`MemBus] ram_rdata,

    // out of ram ram
    output reg ram_we,
    output reg [`MenSelBus] ram_sel,
    output reg [`MemAddrBus] ram_wraddr,
    output reg [`MemBus] ram_wdata,
    output reg ram_req,

    // out of ctrl
    output reg ctrl_jump_flag,
    output reg [`InstAddrBus] ctrl_jump_addr,

    // 执行的结果
    output reg [`RegAddrBus] waddr,     // 待写的寄存器的地址
    output reg [`RegBus] wdata,         // 待写的寄存器的数据
    output reg we,                       // 写使能
    // 写csr
    output reg mem_csr_we,                       // ex模块写寄存器标志
    output reg [`CsrAddrBus] mem_csr_waddr,           // ex模块写寄存器地址
    output reg [`CsrBus] mem_csr_wdata         // 待写的寄存器的数据
);

    wire [6:0] op = inst[6:0];
    wire [2:0] funct3 = inst[14:12];
    wire [6:0] funct7 = inst[31:25];
    wire [4:0] zimm = inst[19:15];

    always @(*) begin
        if(rst == `RstEnable) begin
            // reg
            waddr <= `RegAddrNop;
            wdata <= `RegNop;
            we <= `WriteDisable;
            // ram
            ram_req <= 1'b0;
            ram_we <= `WriteDisable;
            ram_sel <= `MenSelNop;
            ram_wraddr <= `MemAddrNop;
            ram_wdata <= `MemNop;
            // csr
            mem_csr_we <= `WriteDisable;
            mem_csr_waddr <= `CsrAddrNop;
            mem_csr_wdata <= `CsrNop;
            // ctrl
            ctrl_jump_flag <= `JumpDisable;
            ctrl_jump_addr <= `InstAddrNop;

        end else begin
            // reg
            we <= reg_we;
            waddr <= reg_waddr;
            wdata <= `RegNop;
            // csr
            mem_csr_we <= id_csr_we;
            mem_csr_waddr <= id_csr_waddr;
            mem_csr_wdata <= `CsrNop;
            // ram
            // 只有S和L指令需要操作RAM，并且这里是马上读取RAM，因此最好一个时钟周期内只更改一次
            if(op != `OP_S && op != `OP_L) begin   
                ram_req <= 1'b0; 
                ram_we <= `WriteDisable;
                ram_sel <= `MenSelNop;
                ram_wraddr <= `MemAddrNop;
                ram_wdata <= `MemNop;
            end
            // ctrl是任意时刻触发，因此不能重复赋值
            if(op != `OP_B && op != `OP_JAL && op != `OP_JALR) begin
                // ctrl
                ctrl_jump_flag <= `JumpDisable;
                ctrl_jump_addr <= `InstAddrNop;
            end

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
                            wdata <= reg1 + imm;
                        end
                        `FUNC3_I_SLTI: begin
                            // Set if Less Than Immediate
                           wdata <= {32{$signed(reg1) < $signed(imm)}} & 32'h1;
                        end
                        `FUNC3_I_SLTIU: begin
                            // Set if Less Than Immediate, Unsigned
                            wdata <= {32{reg1 < imm}} & 32'h1;
                        end
                        `FUNC3_I_XORI: begin
                            wdata <= reg1 ^ imm;
                        end
                        `FUNC3_I_ORI: begin
                            wdata <= reg1 | imm;
                        end
                        `FUNC3_I_ANDI: begin
                            wdata <= reg1 & imm;
                        end
                        `FUNC3_I_SLLI: begin
                            // Shift Left Logical Immediate
                            wdata <= reg1 << imm[4:0];
                        end
                        `FUNC3_I_SRLI, `FUNC3_I_SRAI: begin
                            // Shift Right Logical Immediate
                            // Shift Right Arithmetic Immediate
                            if(inst[30] == 1'b0) begin
                                // FUNC3_I_SRLI
                                wdata <= reg1 >> imm[4:0];
                            end else begin
                                // FUNC3_I_SRAI
                                // 算术右移，高位按照符号位补
                                wdata <= (reg1 >> imm[4:0]) | ({32{reg1[31]}} & (~(32'hffffffff >> imm[4:0])));
                            end
                        end
                        default: begin
                            wdata <= `ZeroWord;
                        end
                    endcase
                end
                
                `OP_S: begin
                    ram_req <= 1'b1;
                    ram_we <= `WriteEnable;
                    ram_wraddr <= reg1 + imm;    // 改为阻塞赋值，需要先读ram再写ram，因为写必须一次写一个字
                    case(funct3)
                        `FUNC3_S_SB: begin
                            ram_wdata <= {4{reg2[7:0]}};
                            case (ram_wraddr[1:0])
                                2'b00: begin
                                    ram_sel <= 4'b0001;
                                end
                                2'b01: begin
                                    ram_sel <= 4'b0010;
                                end
                                2'b10: begin
                                    ram_sel <= 4'b0100;
                                end
                                2'b11: begin
                                    ram_sel <= 4'b1000;
                                end
                                default: begin
                                    ram_sel <= 4'b0000;
                                end
                            endcase
                        end
                        `FUNC3_S_SH: begin
                            ram_wdata <= {2{reg2[15:0]}};
                            case (ram_wraddr[1:0])
                                2'b00: begin
                                    ram_sel <= 4'b0011;
                                end
                                2'b10: begin
                                    ram_sel <= 4'b1100;
                                end
                                default: begin
                                    ram_sel <= 4'b0000;
                                end
                            endcase
                        end
                        `FUNC3_S_SW: begin
                            ram_wdata <= reg2;
                            ram_sel <= 4'b1111;
                        end
                        default: begin
                            ram_req <= 1'b0;
                            ram_we <= `WriteDisable;
                            ram_wdata <= `ZeroWord;
                            ram_wraddr <= `MemAddrNop;
                        end
                    endcase
                end

                `OP_B: begin
                    case(funct3)
                        `FUNC3_B_BEQ: begin
                            ctrl_jump_flag = (reg1 == reg2) & `JumpEnable;
                            ctrl_jump_addr = {32{ctrl_jump_flag}} & (imm + pc);
                        end
                        `FUNC3_B_BNE: begin
                            ctrl_jump_flag = (reg1 != reg2) & `JumpEnable;
                            ctrl_jump_addr = {32{ctrl_jump_flag}} & (imm + pc); 
                        end
                        `FUNC3_B_BLT: begin
                            ctrl_jump_flag = ($signed(reg1) < $signed(reg2)) & `JumpEnable;
                            ctrl_jump_addr = {32{ctrl_jump_flag}} & (imm + pc); 
                        end
                        `FUNC3_B_BGE: begin
                            ctrl_jump_flag = ($signed(reg1) >= $signed(reg2)) & `JumpEnable;
                            ctrl_jump_addr = {32{ctrl_jump_flag}} & (imm + pc); 
                        end
                        `FUNC3_B_BLTU: begin
                            ctrl_jump_flag = (reg1 < reg2) & `JumpEnable;
                            ctrl_jump_addr = {32{ctrl_jump_flag}} & (imm + pc); 
                        end
                        `FUNC3_B_BGEU: begin
                            ctrl_jump_flag = (reg1 >= reg2) & `JumpEnable;
                            ctrl_jump_addr = {32{ctrl_jump_flag}} & (imm + pc); 
                        end
                        default: begin
                        end
                    endcase
                end

                `OP_L: begin
                    ram_req <= 1'b1;
                    // L指令虽然只用到了ram_wraddr，但是也需要将ram的其他接口清空
                    ram_we <= `WriteDisable;
                    ram_sel <= `MenSelNop;
                    ram_wraddr <= reg1 + imm;
                    ram_wdata <= `MemNop;
                    case(funct3)
                        `FUNC3_L_LB: begin
                            case (ram_wraddr[1:0])
                                2'b00: begin
                                    wdata <= {{24{ram_rdata[7]}}, ram_rdata[7:0]};
                                end
                                2'b01: begin
                                    wdata <= {{24{ram_rdata[15]}}, ram_rdata[15:8]};
                                end
                                2'b10: begin
                                    wdata <= {{24{ram_rdata[23]}}, ram_rdata[23:16]};
                                end
                                2'b11: begin
                                    wdata <= {{24{ram_rdata[31]}}, ram_rdata[31:24]};
                                end
                                default: begin
                                    wdata <= `ZeroWord; 
                                end
                            endcase
                        end
                        `FUNC3_L_LH: begin
                            case (ram_wraddr[1:0])
                                2'b00: begin
                                    wdata <= {{16{ram_rdata[15]}}, ram_rdata[15:0]};
                                end
                                2'b10: begin
                                    wdata <= {{16{ram_rdata[31]}}, ram_rdata[31:16]};
                                end
                                default: begin
                                    wdata <= `ZeroWord; 
                                end
                            endcase
                        end
                        `FUNC3_L_LW: begin
                            wdata <= ram_rdata;
                        end
                        `FUNC3_L_LBU: begin
                            case (ram_wraddr[1:0])
                                2'b00: begin
                                    wdata <= {24'h000000, ram_rdata[7:0]};
                                end
                                2'b01: begin
                                    wdata <= {24'h000000, ram_rdata[15:8]};
                                end
                                2'b10: begin
                                    wdata <= {24'h000000, ram_rdata[23:16]};
                                end
                                2'b11: begin
                                    wdata <= {24'h000000, ram_rdata[31:24]};
                                end
                                default: begin
                                    wdata <= `ZeroWord; 
                                end
                            endcase
                        end
                        `FUNC3_L_LHU: begin
                            case (ram_wraddr[1:0])
                                2'b00: begin
                                    wdata <= {16'h0000, ram_rdata[15:0]};
                                end
                                2'b10: begin
                                    wdata <= {16'h0000, ram_rdata[31:16]};
                                end
                                default: begin
                                    wdata <= `ZeroWord; 
                                end
                            endcase
                        end
                        default: begin
                            ram_req <= 1'b0;
                            wdata <= `ZeroWord;
                            ram_we <= `WriteDisable;
                            ram_wdata <= `ZeroWord;
                            ram_wraddr <= `MemAddrNop;
                        end
                    endcase
                end

                `OP_CSR: begin
                    // CSR寄存器读出的数据在imm内
                    // rs1在reg1内
                    // zimm在inst内
                    case (funct3)
                        `FUNC3_CSRRW: begin
                            mem_csr_wdata <= reg1;
                            wdata <= imm;
                        end
                        `FUNC3_CSRRS: begin
                            mem_csr_wdata <= reg1 | imm;
                            wdata <= imm;
                        end
                        `FUNC3_CSRRC: begin
                            mem_csr_wdata <= (~reg1) & imm;
                            wdata <= imm;
                        end
                        `FUNC3_CSRRWI: begin
                            mem_csr_wdata <= {27'h0, zimm};
                            wdata <= imm;
                        end
                        `FUNC3_CSRRSI: begin
                            mem_csr_wdata <= {27'h0, zimm} | imm;
                            wdata <= imm;
                        end
                        `FUNC3_CSRRCI: begin
                            mem_csr_wdata <= (~{27'h0, zimm}) | imm;
                            wdata <= imm;
                        end
                        default: begin
                            mem_csr_wdata <= `CsrNop;
                            wdata <= `CsrNop;
                        end
                    endcase
                end

                // 一些指令
                `OP_LUI: begin
                    wdata <= imm;
                end
                `OP_AUIPC: begin
                    wdata <= imm + pc;
                end
                `OP_JAL: begin
                    wdata <= pc + 32'h4;
                    ctrl_jump_flag = `JumpEnable;
                    ctrl_jump_addr = {32{ctrl_jump_flag}} & (imm + pc);
                end
                `OP_JALR: begin
                    wdata <= pc + 32'h4;
                    ctrl_jump_flag = `JumpEnable;
                    ctrl_jump_addr = {32{ctrl_jump_flag}} & (reg1 + imm) & 32'hfffffffe;
                end

                default: begin
                end
            endcase
        end
    end

endmodule