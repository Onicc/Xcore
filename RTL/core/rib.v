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

    // master 2 interface
    input wire[`MemAddrBus] m2_wraddr,     // 主设备2读、写地址
    input wire[`MemBus] m2_wdata,         // 主设备2写数据
    output reg[`MemBus] m2_rdata,         // 主设备2读取到的数据
    input wire m2_req,                   // 主设备2访问请求标志
    input wire m2_we,                    // 主设备2写标志

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

    // slave 2 interface
    output reg[`MemAddrBus] s2_wraddr,     // 从设备2读、写地址
    output reg[`MemBus] s2_wdata,         // 从设备2写数据
    input wire[`MemBus] s2_rdata,         // 从设备2读取到的数据
    output reg s2_we,                    // 从设备2写标志

    // slave 3 interface
    output reg[`MemAddrBus] s3_wraddr,     // 从设备3读、写地址
    output reg[`MemBus] s3_wdata,         // 从设备3写数据
    input wire[`MemBus] s3_rdata,         // 从设备3读取到的数据
    output reg s3_we,                    // 从设备3写标志

    output reg hold_flag                 // 暂停流水线标志
);

    // 访问地址的最高4位决定要访问的是哪一个从设备
    // 因此最多支持16个从设备
    parameter [3:0] slave_0 = 4'b0000;      // ROM  基地址  0x00000000
    parameter [3:0] slave_1 = 4'b0001;      // RAM  基地址  0x10000000
    parameter [3:0] slave_2 = 4'b0010;      // GPIO 基地址  0x20000000
    parameter [3:0] slave_3 = 4'b0011;      // GPIO 基地址  0x30000000



    parameter [1:0] grant0 = 2'h0;
    parameter [1:0] grant1 = 2'h1;
    parameter [1:0] grant2 = 2'h2;
    parameter [1:0] grant3 = 2'h3;

    wire[3:0] req;
    reg[1:0] grant;

    // 主设备请求信号 串口debug 读写RAM 读写ROM
    assign req = {m2_req, m1_req, m0_req};

    // 仲裁逻辑
    // 固定优先级仲裁机制
    // 优先级由高到低：主设备3，主设备0，主设备2，主设备1
    always @ (*) begin
        if (req[2]) begin
            grant = grant2;
            hold_flag = `HoldEnable;
        end else if (req[1]) begin
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
        m2_rdata = `ZeroWord;

        s0_wraddr = `ZeroWord;
        s1_wraddr = `ZeroWord;
        s2_wraddr = `ZeroWord;
        s3_wraddr = `ZeroWord;

        s0_wdata = `ZeroWord;
        s1_wdata = `ZeroWord;
        s2_wdata = `ZeroWord;
        s3_wdata = `ZeroWord;

        s0_we = `WriteDisable;
        s1_we = `WriteDisable;
        s2_we = `WriteDisable;
        s3_we = `WriteDisable;
        
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
                    slave_2: begin
                        s2_we = m0_we;
                        s2_wraddr = {{4'h0}, {m0_wraddr[27:0]}};
                        s2_wdata = m0_wdata;
                        m0_rdata = s2_rdata;
                    end
                    slave_3: begin
                        s3_we = m0_we;
                        s3_wraddr = {{4'h0}, {m0_wraddr[27:0]}};
                        s3_wdata = m0_wdata;
                        m0_rdata = s3_rdata;
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
                    slave_2: begin
                        s2_we = m1_we;
                        s2_wraddr = {{4'h0}, {m1_wraddr[27:0]}};
                        s2_wdata = m1_wdata;
                        m1_rdata = s2_rdata;
                    end
                    slave_3: begin
                        s3_we = m1_we;
                        s3_wraddr = {{4'h0}, {m1_wraddr[27:0]}};
                        s3_wdata = m1_wdata;
                        m1_rdata = s3_rdata;
                    end
                    default: begin

                    end
                endcase
            end

            grant2: begin
                case (m2_wraddr[31:28])
                    slave_0: begin
                        s0_we = m2_we;
                        s0_wraddr = {{4'h0}, {m2_wraddr[27:0]}};
                        s0_wdata = m2_wdata;
                        m2_rdata = s0_rdata;
                    end
                    slave_1: begin
                        s1_we = m2_we;
                        s1_wraddr = {{4'h0}, {m2_wraddr[27:0]}};
                        s1_wdata = m2_wdata;
                        m2_rdata = s1_rdata;
                    end
                    slave_2: begin
                        s2_we = m2_we;
                        s2_wraddr = {{4'h0}, {m2_wraddr[27:0]}};
                        s2_wdata = m2_wdata;
                        m2_rdata = s2_rdata;
                    end
                    slave_3: begin
                        s3_we = m2_we;
                        s3_wraddr = {{4'h0}, {m2_wraddr[27:0]}};
                        s3_wdata = m2_wdata;
                        m2_rdata = s3_rdata;
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
