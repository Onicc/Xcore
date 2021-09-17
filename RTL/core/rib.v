`include "defines.v"


// RIB总线模块
module rib(

    input wire clk,
    input wire rst,

    // master 0 interface
    input wire[`MemAddrBus] m0_wraddr,     // 主设备0读、写地址
    input wire[`MemBus] m0_wdata,         // 主设备0写数据
    output reg[`MemBus] m0_rdata,         // 主设备0读取到的数据
    input wire m0_req,                   // 主设备0访问请求标志
    input wire m0_we,                    // 主设备0写标志

    // master 1 interface
    input wire[`MemAddrBus] m1_wraddr,     // 主设备1读、写地址
    input wire[`MemBus] m1_wdata,         // 主设备1写数据
    output reg[`MemBus] m1_rdata,         // 主设备1读取到的数据
    input wire m1_req,                   // 主设备1访问请求标志
    input wire m1_we,                    // 主设备1写标志

    // slave 0 interface
    output reg[`MemAddrBus] s0_wraddr,     // 从设备0读、写地址
    output reg[`MemBus] s0_wdata,         // 从设备0写数据
    input wire[`MemBus] s0_rdata,         // 从设备0读取到的数据
    output reg s0_we,                    // 从设备0写标志

    // slave 1 interface
    output reg[`MemAddrBus] s1_wraddr,     // 从设备1读、写地址
    output reg[`MemBus] s1_wdata,         // 从设备1写数据
    input wire[`MemBus] s1_rdata,         // 从设备1读取到的数据
    output reg s1_we,                    // 从设备1写标志

    output reg hold_flag                 // 暂停流水线标志
);

    // 访问地址的最高4位决定要访问的是哪一个从设备
    // 因此最多支持16个从设备
    parameter [3:0]slave_0 = 4'b0000;
    parameter [3:0]slave_1 = 4'b0001;

    parameter [1:0]grant0 = 2'h0;
    parameter [1:0]grant1 = 2'h1;
    parameter [1:0]grant2 = 2'h2;
    parameter [1:0]grant3 = 2'h3;

    wire[3:0] req;
    reg[1:0] grant;

    // 主设备请求信号
    assign req = {m1_req, m0_req};

    // 仲裁逻辑
    // 固定优先级仲裁机制
    // 优先级由高到低：主设备3，主设备0，主设备2，主设备1
    always @ (*) begin
        if (req[1]) begin
            grant = grant1;
            hold_flag = `HoldEnable;
        end else begin
            grant = grant0;
            hold_flag = `HoldDisable;
        end
    end

    // 根据仲裁结果，选择(访问)对应的从设备
    always @ (*) begin
        m0_rdata = `ZeroWord;
        m1_rdata = `InstNop;

        s0_wraddr = `ZeroWord;
        s1_wraddr = `ZeroWord;
        s0_wdata = `ZeroWord;
        s1_wdata = `ZeroWord;
        s0_we = `WriteDisable;
        s1_we = `WriteDisable;
        
        case (grant)
            grant0: begin
                case (m0_wraddr[31:28])
                    slave_0: begin
                        s0_we = m0_we;
                        s0_wraddr = {{4'h0}, {m0_wraddr[27:0]}};
                        s0_wdata = m0_wdata;
                        m0_rdata = s0_rdata;
                    end
                    slave_1: begin
                        s1_we = m0_we;
                        s1_wraddr = {{4'h0}, {m0_wraddr[27:0]}};
                        s1_wdata = m0_wdata;
                        m0_rdata = s1_rdata;
                    end
                    default: begin

                    end
                endcase
            end

            grant1: begin
                case (m1_wraddr[31:28])
                    slave_0: begin
                        s0_we = m1_we;
                        s0_wraddr = {{4'h0}, {m1_wraddr[27:0]}};
                        s0_wdata = m1_wdata;
                        m1_rdata = s0_rdata;
                    end
                    slave_1: begin
                        s1_we = m1_we;
                        s1_wraddr = {{4'h0}, {m1_wraddr[27:0]}};
                        s1_wdata = m1_wdata;
                        m1_rdata = s1_rdata;
                    end
                    default: begin

                    end
                endcase
            end

            default: begin

            end
        endcase
    end

endmodule
