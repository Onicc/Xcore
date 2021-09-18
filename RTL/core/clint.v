`include "defines.v"

// 中断管理
module clint (
    input wire clk,
    input wire rst,

    input wire [`IntBus] int_flag,      // 外设中断信号

    // 来自id
    input wire [`InstAddrBus] id_pc,
    input wire [`InstBus] id_inst,

    // 来自ex
    input wire ex_jump_flag,
    input wire [`InstAddrBus] ex_jump_addr,

    // 来自csr_reg 
    input wire [`CsrBus] csr_mtvec,     // mtvec
    input wire [`CsrBus] csr_mepc,      // mepc
    input wire [`CsrBus] csr_mstatus,   // mstatus
    input wire csr_global_int_en,       // 全局中断使能标志

    // ctrl
    output reg clint_hold_flag,

    // csr_reg
    output wire csr_we,                     // clint模块写寄存器标志
    output wire [`CsrAddrBus] csr_waddr,        // clint模块写寄存器地址
    output wire [`CsrBus] csr_wdata,        // clint模块写寄存器数据

    // ex
    output wire [`InstAddrBus] int_addr,    // 中断入口地址
    output wire int_assert                  // 中断标志
);
    
    // localparam的作用域仅仅限于当前module，不能作为参数传递的接口
    // 中断状态定义
    localparam INT_IDLE            = 4'b0001;     // 中断空闲
    localparam INT_SYNC_ASSERT     = 4'b0010;     // 同步中断 ecall和ebreak产生
    localparam INT_ASYNC_ASSERT    = 4'b0100;     // 异步中断 外设产生
    localparam INT_MRET            = 4'b1000;     // 中断返回

    // 写CSR寄存器状态定义
    localparam CSR_IDLE            = 5'b00001;  // 中断空闲
    localparam CSR_MSTATUS         = 5'b00010;  // 关闭全局中断
    localparam CSR_MEPC            = 5'b00100;  // 中断产生
    localparam CSR_MSTATUS_MRET    = 5'b01000;  // 中断返回
    localparam CSR_MCAUSE          = 5'b10000;  // 中断原因

    reg [3:0] int_state;        // 中断状态
    reg [4:0] csr_state;        // csr寄存器的状态
    reg [`InstAddrBus] pc;      // 产生中断后的pc地址
    reg [`CsrAddrBus] cause;   // 零时异常寄存器，反映进入异常的原因


    // 中断仲裁，根据中断情况更改int_state
    always @(*) begin
        if(rst == `RstEnable) begin
            int_state <= INT_IDLE;
        end else begin
            // 当int_state和csr_state非空闲时流水线暂停
            clint_hold_flag <= ((int_state != INT_IDLE) | (csr_state != CSR_IDLE))? `HoldEnable: `HoldDisable;
            if(id_inst == `INST_ECALL || id_inst == `INST_EBREAK) begin
                // 如果收到ecall和ebreak指令
                int_state <= INT_SYNC_ASSERT;
            end else if(int_flag != `INT_NONE && csr_global_int_en == `IntEnable) begin
                // 如果没有外设中断，并且开启了全局中断
                int_state <= INT_ASYNC_ASSERT;
            end else if(id_inst == INST_MRET) begin
                // 中断返回，将 pc 设置为 CSRs[mepc], 将特权级设置成 CSRs[mstatus].MPP, CSRs[mstatus].MIE 置成 CSRs[mstatus].MPIE, 并且将 CSRs[mstatus].MPIE 为 1;并且，如果支持用户模式，则将 CSR [mstatus].MPP 设置为 0。
                int_state <= INT_MRET;
            end else begin
                int_state <= INT_IDLE;
            end
        end
    end

    // 根据中断情况更改csr_state
    always @(posedge) begin
        if(rst == `RstEnable) begin
            csr_state <= CSR_IDLE;
            cause <= `CsrNop;
            pc <= `InstAddrNop;
        end else begin
            // 同步中断：CSR_IDLE -> CSR_MEPC -> CSR_MSTATUS -> CSR_MCAUSE -> CSR_IDLE
            // 异步中断：CSR_IDLE -> CSR_MEPC -> CSR_MSTATUS -> CSR_MCAUSE -> CSR_IDLE
            // 中断返回：CSR_IDLE -> CSR_MSTATUS_MRET -> CSR_IDLE
            case (csr_state)
                // 从没有中断进来，判断中断类型，并且更改csr_state，下次进来执行相应代码
                CSR_IDLE: begin
                    // 如果发生了同步中断，更新csr_state
                    if(int_state == INT_SYNC_ASSERT) begin
                        csr_state <= CSR_MEPC;
                        // 如果跳转使能了,在中断处理函数里会将中断返回地址加4,所以这里减回来,否则取译码的pc地址
                        if(ex_jump_flag == `JumpEnable) begin
                            pc <= ex_jump_addr - 4'h4;
                        end else begin
                            pc <= id_pc;
                        end
                        // 更新零时异常寄存器，反映进入异常的原因
                        case (id_inst)
                            `INST_ECALL: begin
                                cause <= 32'd11;
                            end
                            `INST_EBREAK: begin
                                cause <= 32'd3;
                            end
                            default: begin
                                cause <= 32'd10;
                            end
                        endcase
                    // 异步中断
                    end else if(int_state == INT_ASYNC_ASSERT) begin
                        // 定时器中断
                        cause <= 32'h80000004;
                        // 更新csr_state
                        csr_state <= CSR_MEPC;
                        // 如果发生跳转改变pc地址
                        if(ex_jump_flag == `JumpEnable) begin
                            pc <= ex_jump_addr;
                        end else begin
                            pc <= id_pc;
                        end
                    // 中断返回
                    end else if(int_state == INT_MRET) begin
                        csr_state <= CSR_MSTATUS_MRET;
                    end
                end
                // 已经触发中断，包括同步和异步，下一步关闭全局中断
                CSR_MEPC: begin
                    csr_state <= CSR_MSTATUS;   // ?
                end
                // 关闭全局中断，下一步写中断产生原因
                CSR_MSTATUS: begin
                    csr_state <= CSR_MCAUSE;   // ?
                end
                // 写了中断产生原因后中断结束
                CSR_MCAUSE: begin
                    csr_state <= CSR_IDLE;   // 中断结束
                end
                // 写了中断返回后中断结束
                CSR_MSTATUS_MRET: begin
                    csr_state <= CSR_IDLE;   // 中断结束
                end
                default: begin
                    csr_state <= CSR_IDLE;   // 中断结束
                end
            endcase
        end
    end

    // 写csr寄存器
    always @(posedge) begin
        if (rst == `RstEnable) begin
            csr_we <= `WriteDisable;
            csr_waddr <= `CsrAddrNop;
            csr_wdata <= `CsrNop;
        end else begin
            case (csr_state)
                // 往mepc寄存器写入当前指令地址
                CSR_MEPC: begin
                    csr_we <= `WriteEnable;
                    csr_waddr <= {20'h0, `CSR_MEPC};
                    csr_wdata <= pc;
                end
                // 往mcause寄存器写入中断产生原因
                CSR_MCAUSE: begin
                    csr_we <= `WriteEnable;
                    csr_waddr <= {20'h0, `CSR_MCAUSE};
                    csr_wdata <= cause;
                end
                // 往mstatus写关闭全局中断
                CSR_MSTATUS: begin
                    csr_we <= `WriteEnable;
                    csr_waddr <= {20'h0, `CSR_MSTATUS};
                    // 只修改csr_mstatus寄存器的中断使能部分
                    csr_wdata <= {csr_mstatus[31:4], 1'b0, csr_mstatus[2:0]};
                end
                // 往mstatus写中断返回
                CSR_MSTATUS_MRET: begin
                    csr_we <= `WriteEnable;
                    csr_waddr <= {20'h0, `CSR_MSTATUS};
                    csr_wdata <= {csr_mstatus[31:4], csr_mstatus[7], csr_mstatus[2:0]};
                end
                default: begin
                    csr_we <= `WriteDisable;
                    csr_waddr <= `CsrAddrNop;
                    csr_wdata <= `CsrNop;
                end
            endcase
        end
    end

    // 发送中断信号给ex模块
    always @(posedge) begin
        if (rst == `RstEnable) begin
            int_assert <= `IntDeassert;
            int_addr <= `InstAddrNop;
        end else begin
            case (csr_state)
                // 本应该在CSR_MEPC阶段发生中断信号，但是在CSR_MEPC阶段csr_mcause还没被写入，因此在CSR_MCAUSE发送中断信号
                CSR_MCAUSE: begin
                    int_assert <= `IntAssert;
                    int_addr <= csr_mtvec;  // 机器模式异常入口基地址寄存器，进入异常的程序PC地址
                end 
                // 发送中断返回信号
                CSR_MSTATUS_MRET: begin
                    int_assert <= `IntAssert;
                    int_addr <= csr_mepc;  // 机器模式异常PC寄存器，用于保存异常的返回值
                end
                default: begin
                int_assert <= `IntDeassert;
                int_addr <= `InstAddrNop;
                end 
            endcase
        end
    end

endmodule