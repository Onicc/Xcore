`timescale 1ns/1ps

module xcore_tb ();
    reg clk;
    reg rst;

    // 50MHz时钟
    always #10 clk = ~clk;

    // 系统复位
    initial begin
        clk = 1'b0;
        rst = 1'b0;
        #100
        rst = 1'b1;
    end

    // 加载指令数据到rom
    initial begin
        $readmemh ("./TB/inst_rom.data", u_xcore.u_inst_rom.inst_mem);
    end

    // 延时1ms，如果程序没有先停止说明出现问题，这里强行停止
    initial begin
        #1000000
        $display("Time Out.");
        $finish;
    end

    // generate wave file, use by gtkwave
    initial begin
        $dumpfile("xcore_tb.vcd");
        $dumpvars(0, xcore_tb);
    end

    xcore u_xcore(
        .clk(clk),
        .rst(rst)
    );
    
endmodule
