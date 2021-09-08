`include "defines.v"

module ram (
    input wire clk,
    input wire rst,

    input wire we,
    input wire [`MenSelBus] sel,                // 写第几个Byte的数据
    input wire [`MemAddrBus] wraddr,    // 地址读写共用
    input wire [`MemBus] wdata,

    output reg [`MemBus] rdata
);
    // reg [`MemBus] _ram[0:`MemNum - 1];
    
    // 四个Byte组成一个字，ram3对应高位
    reg [`ByteWidth] ram0[0:`MemNum - 1];
    reg [`ByteWidth] ram1[0:`MemNum - 1];
    reg [`ByteWidth] ram2[0:`MemNum - 1];
    reg [`ByteWidth] ram3[0:`MemNum - 1];

    always @(posedge clk) begin
        if(rst == `RstDisable && we == `WriteEnable) begin
            // wraddr/8才是对应的哪一个
            // _ram[wraddr[31:2]] <= wdata;
            if (sel[3] == 1'b1) begin
                ram3[wraddr[31:2]] <= wdata[31:24];
            end
            if (sel[2] == 1'b1) begin
                ram2[wraddr[31:2]] <= wdata[23:16];
            end
            if (sel[1] == 1'b1) begin
                ram1[wraddr[31:2]] <= wdata[15:8];
            end
            if (sel[0] == 1'b1) begin
                ram0[wraddr[31:2]] <= wdata[7:0];
            end	
        end
    end

    always @(*) begin
        if(rst == `RstEnable) begin
            rdata <= `ZeroWord;
        end else if(we == `WriteDisable) begin
            // rdata <= _ram[wraddr[31:2]]; 
		    rdata <= {ram3[wraddr[31:2]],
		              ram2[wraddr[31:2]],
		              ram1[wraddr[31:2]],
		              ram0[wraddr[31:2]]};
        end else begin
            rdata <= `ZeroWord;
        end
    end

endmodule