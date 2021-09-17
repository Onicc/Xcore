`include "defines.v"


// RIB总线模块
module rib(

    input wire clk,
    input wire rst,

    // master 0 interface
    input wire[`MemAddrBus] m0_addr_i,     // 主设备0读、写地址
    input wire[`MemBus] m0_data_i,         // 主设备0写数据
    output reg[`MemBus] m0_data_o,         // 主设备0读取到的数据
    input wire m0_req_i,                   // 主设备0访问请求标志
    input wire m0_we_i,                    // 主设备0写标志

    // master 1 interface
    input wire[`MemAddrBus] m1_addr_i,     // 主设备1读、写地址
    input wire[`MemBus] m1_data_i,         // 主设备1写数据
    output reg[`MemBus] m1_data_o,         // 主设备1读取到的数据
    input wire m1_req_i,                   // 主设备1访问请求标志
    input wire m1_we_i,                    // 主设备1写标志

    // slave 0 interface
    output reg[`MemAddrBus] s0_addr_o,     // 从设备0读、写地址
    output reg[`MemBus] s0_data_o,         // 从设备0写数据
    input wire[`MemBus] s0_data_i,         // 从设备0读取到的数据
    output reg s0_we_o,                    // 从设备0写标志

    // slave 1 interface
    output reg[`MemAddrBus] s1_addr_o,     // 从设备1读、写地址
    output reg[`MemBus] s1_data_o,         // 从设备1写数据
    input wire[`MemBus] s1_data_i,         // 从设备1读取到的数据
    output reg s1_we_o,                    // 从设备1写标志

    output reg hold_flag_o                 // 暂停流水线标志

    );

    // 根据仲裁结果，选择(访问)对应的从设备
    always @ (*) begin
        m0_data_o = `ZeroWord;
        m1_data_o = `InstNop;

        s0_addr_o = `ZeroWord;
        s1_addr_o = `ZeroWord;
        s0_data_o = `ZeroWord;
        s1_data_o = `ZeroWord;
        s0_we_o = `WriteDisable;
        s1_we_o = `WriteDisable;
        
        if(m1_req_i == 1'b1) begin
            s1_we_o = m1_we_i;
            s1_addr_o = m1_addr_i;
            s1_data_o = m1_data_i;
            m1_data_o = s1_data_i;
            hold_flag_o = `HoldEnable;
        end else begin
            s0_we_o = m0_we_i;
            s0_addr_o = m0_addr_i;
            s0_data_o = m0_data_i;
            m0_data_o = s0_data_i;
            hold_flag_o = `HoldDisable;
        end
    end

endmodule
