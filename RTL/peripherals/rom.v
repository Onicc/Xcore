`include "defines.v"


module rom(
    input wire clk,
    input wire rst,

    input wire we,                      // write enable
    input wire [`MemAddrBus] wraddr,    // addr
    input wire [`MemBus] wdata,

    output reg [`MemBus] rdata         // read data
);

    reg[`MemBus] _rom[0:`RomNum - 1];

    always @ (posedge clk) begin
        if (we == `WriteEnable) begin
            _rom[wraddr[31:2]] <= wdata;
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            rdata = `ZeroWord;
        end else begin
            rdata = _rom[wraddr[31:2]];
        end
    end

endmodule
