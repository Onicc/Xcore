`include "defines.v"

module gpio(
    input wire clk,
	input wire rst,

    input wire we,
    input wire[31:0] wraddr,
    input wire[31:0] wdata,

    output reg[31:0] rdata,

    // *** 添加GPIO个数需修改 *** //
    input wire[1:0] gpio,
    output wire[31:0] reg_ctrl,
    output wire[31:0] reg_data
);
    // 因为写数据的地址以四位为一个单位
    // GPIO控制寄存器
    localparam GPIO_CTRL = 4'h0;
    // GPIO数据寄存器
    localparam GPIO_DATA = 4'h4;

    // 每2位控制1个IO的模式，最多支持16个IO
    // 0: 高阻，1：输出，2：输入
    // gpio_ctrl为32位，每隔两位控制控制一个io，分别为00\01\10，分别为高阻\输出\输入
    reg[31:0] gpio_ctrl;
    // 输入输出数据
    reg[31:0] gpio_data;


    assign reg_ctrl = gpio_ctrl;
    assign reg_data = gpio_data;

    // gpio[0] = (gpio_ctrl[1:0] == 2'b01)? gpio_data[0]: 1'bz;
    // io_pin的个数表示有多少个gpio口
    // gpio[i]表示第i个io口的状态，在输出模式为0和1，在非输出模式为z高阻态

    // 写寄存器
    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            gpio_data <= 32'h0;
            gpio_ctrl <= 32'h0;
        end else begin
            if (we == 1'b1) begin
                // wraddr的最低位为0表示修改gpio_ctrl寄存器
                // wraddr的最低位为1表示修改gpio_data寄存器
                case (wraddr[3:0])
                    GPIO_CTRL: begin
                        gpio_ctrl <= wdata;
                    end
                    GPIO_DATA: begin
                        gpio_data <= wdata;
                    end
                endcase
            end else begin
                // 防止在写GPIO输出时修改了数据的io的data
                // *** 添加GPIO个数需修改 *** //
                // 否则如果GPIO0为输出状态就维持输出
                if (gpio_ctrl[1:0] == 2'b10) begin
                    gpio_data[0] <= gpio[0];
                end
                // *** 添加GPIO个数需修改 *** //
                // 否则如果GPIO1为输出状态就维持输出
                if (gpio_ctrl[3:2] == 2'b10) begin
                    gpio_data[1] <= gpio[1];
                end
            end
        end
    end

    // 读寄存器
    always @ (*) begin
        if (rst == 1'b0) begin
            rdata = 32'h0;
        end else begin
            // wraddr的最低位为0表示读gpio_ctrl寄存器
            // wraddr的最低位为1表示读gpio_data寄存器
            case (wraddr[3:0])
                GPIO_CTRL: begin
                    rdata = gpio_ctrl;
                end
                GPIO_DATA: begin
                    rdata = gpio_data;
                end
                default: begin
                    rdata = 32'h0;
                end
            endcase
        end
    end

endmodule
