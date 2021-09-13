`include "defines.v"

// CSR寄存器模块
module csr_reg(

    input wire clk,
    input wire rst,

    // 从ex传过来
    input wire ex_we,                       // ex模块写寄存器标志
    input wire [`RegBus] ex_raddr,           // ex模块读寄存器地址
    input wire [`RegBus] ex_waddr,           // ex模块写寄存器地址
    input wire [`RegBus] ex_wdata,           // ex模块写寄存器数据

    // 从clint传过来
    input wire clint_we,                    // clint模块写寄存器标志
    input wire [`RegBus] clint_raddr,        // clint模块读寄存器地址
    input wire [`RegBus] clint_waddr,        // clint模块写寄存器地址
    input wire [`RegBus] clint_wdata,        // clint模块写寄存器数据

    output reg global_int_en,              // 全局中断使能标志

    // 传给ex
    output reg [`RegBus] ex_rdata,           // ex模块读寄存器数据

    // 传给clint
    output reg [`RegBus] clint_rdata         // clint模块读寄存器数据
    output reg [`RegBus] clint_csr_mtvec,    // mtvec
    output reg [`RegBus] clint_csr_mepc,     // mepc
    output reg [`RegBus] clint_csr_mstatus   // mstatus
);

    reg [`DoubleRegBus] cycle;      // 用于计数
    reg [`RegBus] mtvec;            // 机器模式异常入口基地址寄存器，进入异常的程序PC地址
    reg [`RegBus] mcause;           // 机器模式异常原因寄存器，反映进入异常的原因
    reg [`RegBus] mtval;            // 机器模式异常值寄存器，反映异常的信息
    reg [`RegBus] mepc;             // 机器模式异常PC寄存器，用于保存异常的返回值
    reg [`RegBus] mstatus;          // 机器模式状态寄存器，该寄存器中的MIE域和MPIE域用于反映中断全局使能
    reg [`RegBus] mie;              // 机器模式中断使能寄存器，用于控制不同类型中断的局部使能    
    reg [`RegBus] mip;
    reg [`RegBus] mscratch;

    // 全局中断更新
    always @(*) begin
        global_int_en <= (mstatus[3] == 1'b1)? 1'b1: 1'b0;
    end

    // cycle计数
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            cycle <= {`RegNop, `RegNop};
        end else begin
            cycle <= cycle + 1'b1;
        end
    end

    // 写寄存器
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            mtvec <= `RegNop;
            mcause <= `RegNop;
            mtval <= `RegNop;
            mepc <= `RegNop;
            mstatus <= `RegNop;
            mie <= `RegNop;
            mip <= `RegNop;
            mscratch <= `RegNop;
        end else begin
            if(ex_we == `WriteEnable) begin
                case(ex_waddr[11:0])
                    `CSR_MTVEC: begin
                        mtvec <= ex_wdata;
                    end
                    `CSR_MCAUSE: begin
                        mcause <= ex_wdata;
                    end
                    `CSR_MTVAL: begin
                        mtval <= ex_wdata;
                    end
                    `CSR_MEPC: begin
                        mepc <= ex_wdata;
                    end
                    `CSR_MSTATUS: begin
                        mstatus <= ex_wdata;
                    end
                    `CSR_MIE: begin
                        mie <= ex_wdata;
                    end
                    `CSR_MIP: begin
                        mip <= ex_wdata;
                    end
                    `CSR_MSCRATCH: begin
                        mscratch <= ex_wdata;
                    end
                    default: begin
                    end
                endcase
            end else if(clint_we == `WriteEnable) begin
                case(clint_waddr[11:0])
                    `CSR_MTVEC: begin
                        mtvec <= clint_wdata;
                    end
                    `CSR_MCAUSE: begin
                        mcause <= clint_wdata;
                    end
                    `CSR_MTVAL: begin
                        mtval <= clint_wdata;
                    end
                    `CSR_MEPC: begin
                        mepc <= clint_wdata;
                    end
                    `CSR_MSTATUS: begin
                        mstatus <= clint_wdata;
                    end
                    `CSR_MIE: begin
                        mie <= clint_wdata;
                    end
                    `CSR_MIP: begin
                        mip <= clint_wdata;
                    end
                    `CSR_MSCRATCH: begin
                        mscratch <= clint_wdata;
                    end
                    default: begin
                    end
                endcase
            end else begin
            end
        end
    end

    // ex读寄存器
    always @(*) begin
        if((ex_waddr[11:0] == ex_raddr[11:0]) && (ex_we == `WriteEnable)) begin
            ex_rdata = ex_wdata;
        end else begin
            case(ex_raddr[11:0])
                `CSR_CYCLE: begin
                    ex_rdata <= cycle[31:0];
                end
                `CSR_CYCLEH: begin
                    ex_rdata <= cycle[63:32];
                end
                `CSR_MTVEC: begin
                    ex_rdata <= mtvec;
                end
                `CSR_MCAUSE: begin
                    ex_rdata <= mcause;
                end
                `CSR_MTVAL: begin
                    ex_rdata <= mtval;
                end
                `CSR_MEPC: begin
                    ex_rdata <= mepc;
                end
                `CSR_MSTATUS: begin
                    ex_rdata <= mstatus;
                end
                `CSR_MIE: begin
                    ex_rdata <= mie;
                end
                `CSR_MIP: begin
                    ex_rdata <= mip;
                end
                `CSR_MSCRATCH: begin
                    ex_rdata <= mscratch;
                end
                default: begin
                    ex_rdata <= `RegNop;
                end
            endcase
        end
    end

    // clint读寄存器
    always @(*) begin
        clint_csr_mtvec <= mtvec;
        clint_csr_mepc <= mepc;
        clint_csr_mstatus <= mstatus;

        if((clint_waddr[11:0] == clint_raddr[11:0]) && (clint_we == `WriteEnable)) begin
            clint_rdata = clint_wdata;
        end else begin
            case(clint_raddr[11:0])
                `CSR_CYCLE: begin
                    clint_rdata <= cycle[31:0];
                end
                `CSR_CYCLEH: begin
                    clint_rdata <= cycle[63:32];
                end
                `CSR_MTVEC: begin
                    clint_rdata <= mtvec;
                end
                `CSR_MCAUSE: begin
                    clint_rdata <= mcause;
                end
                `CSR_MTVAL: begin
                    clint_rdata <= mtval;
                end
                `CSR_MEPC: begin
                    clint_rdata <= mepc;
                end
                `CSR_MSTATUS: begin
                    clint_rdata <= mstatus;
                end
                `CSR_MIE: begin
                    clint_rdata <= mie;
                end
                `CSR_MIP: begin
                    clint_rdata <= mip;
                end
                `CSR_MSCRATCH: begin
                    clint_rdata <= mscratch;
                end
                default: begin
                    clint_rdata <= `RegNop;
                end
            endcase
        end
    end

endmodule
