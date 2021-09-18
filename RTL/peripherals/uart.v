
// 波特率：每秒传输的比特数
// 115200即每秒传输115200位
// 即周期为1/115200=             0.000008680555556
// 假设主频最高1G，能精确的最小时间为0.000000001
// 即精确的最高周期为0.000008680
// 分频系数为0.000008680x主频，假设主频最高50MHz，分频系数为434

// 串口模块(默认: 115200, 8 N 1)
// 波特率: 115200
// 数据位：8
// 校验位：无
// 停止位：1
module uart(
    input wire clk,
    input wire rst,

    input wire we,
    input wire [31:0] wraddr,
    input wire [31:0] wdata,

    output reg [31:0] rdata,
	output wire tx_pin,
    input wire rx_pin
);

    // 50MHz时钟，波特率115200bps对应的分频系数
    // 默认为115200，可以通过汇编指令修改
    localparam BAUD_115200 = 32'h1B8;

    localparam UART_IDLE       = 4'b0001;   // 空闲
    localparam UART_START      = 4'b0010;   // 开始
    localparam UART_SEND_BYTE  = 4'b0100;   // 发送数据
    localparam UART_STOP       = 4'b1000;   // 停止

    reg tx_data_valid;      // 表示发送的数据已经写入寄存器了
    reg tx_data_ready;

    reg [3:0] state;
    reg [15:0] cycle_cnt;
    reg [3:0] bit_cnt;
    reg [7:0] tx_data;      // 直接发送的数据
    reg tx_reg;             // 一位一位的发送数据

    reg rx_q0;
    reg rx_q1;
    wire rx_negedge;
    reg rx_start;                      // RX使能
    reg [3:0] rx_clk_edge_cnt;          // clk时钟沿的个数
    reg rx_clk_edge_level;             // clk沿电平
    reg rx_done;
    reg [15:0] rx_clk_cnt;
    reg [15:0] rx_div_cnt;
    reg [7:0] rx_data;      // 直接接收的数据
    reg rx_over;

    localparam UART_CTRL    = 8'h0;     // 控制寄存器基地址
    localparam UART_STATUS  = 8'h4;     // 状态寄存器基地址
    localparam UART_BAUD    = 8'h8;     // 波特率寄存器基地址
    localparam UART_TXDATA  = 8'hc;     // 发送数据寄存器基地址
    localparam UART_RXDATA  = 8'h10;    // 接受数据寄存器基地址

    // addr: 0x00
    // rw. bit[0]: tx enable, 1 = enable, 0 = disable
    // rw. bit[1]: rx enable, 1 = enable, 0 = disable
    // 控制寄存器，每两位控制一个uart，低位控制tx使能，高位控制rx使能
    reg [31:0] uart_ctrl;

    // addr: 0x04
    // ro. bit[0]: tx busy, 1 = busy, 0 = idle
    // rw. bit[1]: rx over, 1 = over, 0 = receiving
    // must check this bit before tx data
    // 状态寄存器，每两位反映一个uart的状态
    reg [31:0] uart_status;

    // addr: 0x08
    // rw. clk div
    // 波特率寄存器，存放分频系数
    reg [31:0] uart_baud;

    // addr: 0x10
    // ro. rx data
    // 数据接受寄存器，存放接收的数据
    reg [31:0] uart_rx;

    assign tx_pin = tx_reg;


    // 写寄存器
    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            uart_ctrl <= 32'h0;
            uart_status <= 32'h0;
            uart_rx <= 32'h0;
            uart_baud <= BAUD_115200;
            tx_data_valid <= 1'b0;
        end else begin
            // 写使能打开说明可能需要发送数据
            if (we == 1'b1) begin
                // 通过底八位地址确定写入的是哪个寄存器
                case (wraddr[7:0])
                    UART_CTRL: begin
                        uart_ctrl <= wdata;
                    end
                    UART_BAUD: begin
                        uart_baud <= wdata;
                    end
                    UART_STATUS: begin
                        uart_status[1] <= wdata[1];
                    end
                    UART_TXDATA: begin
                        // 如果串口0的发送使能并且处于发送空闲状态时，将数据写入发送寄存器，并且修改发送状态为繁忙，并且将tx_data_valid置为1
                        if (uart_ctrl[0] == 1'b1 && uart_status[0] == 1'b0) begin
                            tx_data <= wdata[7:0];
                            uart_status[0] <= 1'b1;
                            tx_data_valid <= 1'b1;
                        end
                    end
                endcase
            // 否则，接受数据
            end else begin
                // 将发送数据的标识位清空
                tx_data_valid <= 1'b0;
                if (tx_data_ready == 1'b1) begin
                    uart_status[0] <= 1'b0;
                end
                // 如果接收使能了
                if (uart_ctrl[1] == 1'b1) begin
                    // 如果接收完成了，将接收的状态设为接收完成，并且取出接收的数据写入寄存器
                    if (rx_over == 1'b1) begin
                        uart_status[1] <= 1'b1;
                        uart_rx <= {24'h0, rx_data};
                    end
                end
            end
        end
    end

    // 读寄存器
    always @ (*) begin
        if (rst == 1'b0) begin
            rdata = 32'h0;
        end else begin
            case (wraddr[7:0])
                UART_CTRL: begin
                    rdata = uart_ctrl;
                end
                UART_STATUS: begin
                    rdata = uart_status;
                end
                UART_BAUD: begin
                    rdata = uart_baud;
                end
                UART_RXDATA: begin
                    rdata = uart_rx;
                end
                default: begin
                    rdata = 32'h0;
                end
            endcase
        end
    end

    // *************************** TX发送 ****************************

    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            state <= UART_IDLE;
            cycle_cnt <= 16'd0;
            tx_reg <= 1'b0;
            bit_cnt <= 4'd0;
            tx_data_ready <= 1'b0;
        end else begin
            if (state == UART_IDLE) begin
                tx_reg <= 1'b1;
                tx_data_ready <= 1'b0;
                if (tx_data_valid == 1'b1) begin
                    state <= UART_START;
                    cycle_cnt <= 16'd0;
                    bit_cnt <= 4'd0;
                    tx_reg <= 1'b0;
                end
            end else begin
                cycle_cnt <= cycle_cnt + 16'd1;
                if (cycle_cnt == uart_baud[15:0]) begin
                    cycle_cnt <= 16'd0;
                    case (state)
                        UART_START: begin
                            tx_reg <= tx_data[bit_cnt];
                            state <= UART_SEND_BYTE;
                            bit_cnt <= bit_cnt + 4'd1;
                        end
                        UART_SEND_BYTE: begin
                            bit_cnt <= bit_cnt + 4'd1;
                            if (bit_cnt == 4'd8) begin
                                state <= UART_STOP;
                                tx_reg <= 1'b1;
                            end else begin                
                                tx_reg <= tx_data[bit_cnt];
                            end
                        end
                        UART_STOP: begin
                            tx_reg <= 1'b1;
                            state <= UART_IDLE;
                            tx_data_ready <= 1'b1;
                        end
                    endcase
                end
            end
        end
    end

    // *************************** RX接收 ****************************

    // 下降沿检测(检测起始信号)
    assign rx_negedge = rx_q1 && ~rx_q0;


    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            rx_q0 <= 1'b0;
            rx_q1 <= 1'b0;	
        end else begin
            rx_q0 <= rx_pin;
            rx_q1 <= rx_q0;
        end
    end

    // 开始接收数据信号，接收期间一直有效
    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            rx_start <= 1'b0;
        end else begin
            if (uart_ctrl[1]) begin
                if (rx_negedge) begin
                    rx_start <= 1'b1;
                end else if (rx_clk_edge_cnt == 4'd9) begin
                    rx_start <= 1'b0;
                end
            end else begin
                rx_start <= 1'b0;
            end
        end
    end

    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            rx_div_cnt <= 16'h0;
        end else begin
            // 第一个时钟沿只需波特率分频系数的一半
            if (rx_start == 1'b1 && rx_clk_edge_cnt == 4'h0) begin
                rx_div_cnt <= {1'b0, uart_baud[15:1]};
            end else begin
                rx_div_cnt <= uart_baud[15:0];
            end
        end
    end

    // 对时钟进行计数
    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            rx_clk_cnt <= 16'h0;
        end else if (rx_start == 1'b1) begin
            // 计数达到分频值
            if (rx_clk_cnt == rx_div_cnt) begin
                rx_clk_cnt <= 16'h0;
            end else begin
                rx_clk_cnt <= rx_clk_cnt + 1'b1;
            end
        end else begin
            rx_clk_cnt <= 16'h0;
        end
    end

    // 每当时钟计数达到分频值时产生一个上升沿脉冲
    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            rx_clk_edge_cnt <= 4'h0;
            rx_clk_edge_level <= 1'b0;
        end else if (rx_start == 1'b1) begin
            // 计数达到分频值
            if (rx_clk_cnt == rx_div_cnt) begin
                // 时钟沿个数达到最大值
                if (rx_clk_edge_cnt == 4'd9) begin
                    rx_clk_edge_cnt <= 4'h0;
                    rx_clk_edge_level <= 1'b0;
                end else begin
                    // 时钟沿个数加1
                    rx_clk_edge_cnt <= rx_clk_edge_cnt + 1'b1;
                    // 产生上升沿脉冲
                    rx_clk_edge_level <= 1'b1;
                end
            end else begin
                rx_clk_edge_level <= 1'b0;
            end
        end else begin
            rx_clk_edge_cnt <= 4'h0;
            rx_clk_edge_level <= 1'b0;
        end
    end

    // bit序列
    always @ (posedge clk) begin
        if (rst == 1'b0) begin
            rx_data <= 8'h0;
            rx_over <= 1'b0;
        end else begin
            if (rx_start == 1'b1) begin
                // 上升沿
                if (rx_clk_edge_level == 1'b1) begin
                    case (rx_clk_edge_cnt)
                        // 起始位
                        1: begin

                        end
                        // 数据位
                        2, 3, 4, 5, 6, 7, 8, 9: begin
                            rx_data <= rx_data | (rx_pin << (rx_clk_edge_cnt - 2));
                            // 最后一位接收完成，置位接收完成标志
                            if (rx_clk_edge_cnt == 4'h9) begin
                                rx_over <= 1'b1;
                            end
                        end
                    endcase
                end
            end else begin
                rx_data <= 8'h0;
                rx_over <= 1'b0;
            end
        end
    end

endmodule
