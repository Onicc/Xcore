`include "defines.v"

// CSR寄存器模块
// id从本模块读取寄存器值
// wb从本模块写寄存器值
module csr_reg(

    input wire clk,
    input wire rst,

    input wire [`CsrAddrBus] id_raddr,           // id模块读寄存器地址

    // 从wb传过来
    input wire wb_we,                       // wb模块写寄存器标志
    input wire [`CsrAddrBus] wb_waddr,           // wb模块写寄存器地址
    input wire [`CsrBus] wb_wdata,           // wb模块写寄存器数据

    // 从clint传过来
    input wire clint_we,                    // clint模块写寄存器标志
    input wire [`CsrAddrBus] clint_raddr,        // clint模块读寄存器地址
    input wire [`CsrAddrBus] clint_waddr,        // clint模块写寄存器地址
    input wire [`CsrBus] clint_wdata,        // clint模块写寄存器数据

    output reg global_int_en,              // 全局中断使能标志

    // 传给id
    output reg [`CsrBus] id_rdata,           // id模块读寄存器数据

    // 传给clint
    output reg [`CsrBus] clint_rdata,         // clint模块读寄存器数据
    output reg [`CsrBus] clint_csr_mtvec,    // mtvec
    output reg [`CsrBus] clint_csr_mepc,     // mepc
    output reg [`CsrBus] clint_csr_mstatus   // mstatus
);

    reg [`DoubleCsrBus] cycle;      // 用于计数
    reg [`CsrBus] mtvec;            // 机器模式异常入口基地址寄存器，进入异常的程序PC地址
    reg [`CsrBus] mcause;           // 机器模式异常原因寄存器，反映进入异常的原因
    reg [`CsrBus] mtval;            // 机器模式异常值寄存器，反映异常的信息
    reg [`CsrBus] mepc;             // 机器模式异常PC寄存器，用于保存异常的返回值
    reg [`CsrBus] mstatus;          // 机器模式状态寄存器，该寄存器中的MIE域和MPIE域用于反映中断全局使能
    reg [`CsrBus] mie;              // 机器模式中断使能寄存器，用于控制不同类型中断的局部使能    
    reg [`CsrBus] mip;
    reg [`CsrBus] mscratch;

    // 全局中断更新
    always @(*) begin
        global_int_en = (mstatus[3] == 1'b1)? 1'b1: 1'b0;
    end

    // cycle计数
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            cycle <= {`CsrNop, `CsrNop};
        end else begin
            cycle <= cycle + 1'b1;
        end
    end

    // 写寄存器
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            mtvec <= `CsrNop;
            mcause <= `CsrNop;
            mtval <= `CsrNop;
            mepc <= `CsrNop;
            mstatus <= `CsrNop;
            mie <= `CsrNop;
            mip <= `CsrNop;
            mscratch <= `CsrNop;
        end else begin
            if(wb_we == `WriteEnable) begin
                case(wb_waddr[11:0])
                    `CSR_MTVEC: begin
                        mtvec <= wb_wdata;
                    end
                    `CSR_MCAUSE: begin
                        mcause <= wb_wdata;
                    end
                    `CSR_MTVAL: begin
                        mtval <= wb_wdata;
                    end
                    `CSR_MEPC: begin
                        mepc <= wb_wdata;
                    end
                    `CSR_MSTATUS: begin
                        mstatus <= wb_wdata;
                    end
                    `CSR_MIE: begin
                        mie <= wb_wdata;
                    end
                    `CSR_MIP: begin
                        mip <= wb_wdata;
                    end
                    `CSR_MSCRATCH: begin
                        mscratch <= wb_wdata;
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

    // id读寄存器
    always @(*) begin
        // 防止流水线在id和wb发送冲突
        if((wb_waddr[11:0] == id_raddr[11:0]) && (wb_we == `WriteEnable)) begin
            id_rdata = wb_wdata;
        end else begin
            case(id_raddr[11:0])
                `CSR_CYCLE: begin
                    id_rdata = cycle[31:0];
                end
                `CSR_CYCLEH: begin
                    id_rdata = cycle[63:32];
                end
                `CSR_MTVEC: begin
                    id_rdata = mtvec;
                end
                `CSR_MCAUSE: begin
                    id_rdata = mcause;
                end
                `CSR_MTVAL: begin
                    id_rdata = mtval;
                end
                `CSR_MEPC: begin
                    id_rdata = mepc;
                end
                `CSR_MSTATUS: begin
                    id_rdata = mstatus;
                end
                `CSR_MIE: begin
                    id_rdata = mie;
                end
                `CSR_MIP: begin
                    id_rdata = mip;
                end
                `CSR_MSCRATCH: begin
                    id_rdata = mscratch;
                end
                default: begin
                    id_rdata = `CsrNop;
                end
            endcase
        end
    end

    // clint读寄存器
    always @(*) begin
        clint_csr_mtvec = mtvec;
        clint_csr_mepc = mepc;
        clint_csr_mstatus = mstatus;

        if((clint_waddr[11:0] == clint_raddr[11:0]) && (clint_we == `WriteEnable)) begin
            clint_rdata = clint_wdata;
        end else begin
            case(clint_raddr[11:0])
                `CSR_CYCLE: begin
                    clint_rdata = cycle[31:0];
                end
                `CSR_CYCLEH: begin
                    clint_rdata = cycle[63:32];
                end
                `CSR_MTVEC: begin
                    clint_rdata = mtvec;
                end
                `CSR_MCAUSE: begin
                    clint_rdata = mcause;
                end
                `CSR_MTVAL: begin
                    clint_rdata = mtval;
                end
                `CSR_MEPC: begin
                    clint_rdata = mepc;
                end
                `CSR_MSTATUS: begin
                    clint_rdata = mstatus;
                end
                `CSR_MIE: begin
                    clint_rdata = mie;
                end
                `CSR_MIP: begin
                    clint_rdata = mip;
                end
                `CSR_MSCRATCH: begin
                    clint_rdata = mscratch;
                end
                default: begin
                    clint_rdata = `CsrNop;
                end
            endcase
        end
    end

endmodule
