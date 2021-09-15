`include "defines.v"

module xcore (
    input wire clk,
    input wire rst
);
    // ROM
    wire [`InstBus] inst;
    wire [`InstAddrBus] pc;
    wire rom_ce;
    inst_rom u_inst_rom(
        .ce(rom_ce),
        .addr(pc),
        .inst(inst)
    );

    // RAM
    wire ram_we;
    wire [`MenSelBus] ram_sel;
    wire [`MemAddrBus] ram_wraddr;
    wire [`MemBus] ram_wdata;
    wire [`MemBus] ram_rdata;
    ram u_ram(
        .clk(clk),
        .rst(rst),

        .we(ram_we),
        .sel(ram_sel),
        .wraddr(ram_wraddr),
        .wdata(ram_wdata),
        .rdata(ram_rdata)
    );

    // ctrl
    wire ex_jump_flag;
    wire [`InstAddrBus] ex_jump_addr;
    wire ex_hold_flag;
    wire clint_hold_flag;
    wire [`HoldFlagBus] hold_flag;    //  给pc、if_id和id_ex
    wire jump_flag;
    wire [`InstAddrBus] jump_addr;
    ctrl u_ctrl(
        .rst(rst),
        .ex_jump_flag(ex_jump_flag),
        .ex_jump_addr(ex_jump_addr),
        .ex_hold_flag(ex_hold_flag),
        .clint_hold_flag(clint_hold_flag),

        .hold_flag(hold_flag),
        .pc_jump_flag(jump_flag),
        .pc_jump_addr(jump_addr)
    );

    // pc
    pc_reg u_pc_reg(
        .clk(clk),
        .rst(rst),
        .jump_flag(jump_flag),
        .jump_addr(jump_addr),
        .hold_flag(hold_flag),

        .pc(pc),
        .ce(rom_ce)
    );

    // csr_reg
    wire [`CsrAddrBus] id_csr_raddr;
    wire wb_csr_we;
    wire [`CsrAddrBus] wb_csr_waddr;
    wire [`CsrBus] wb_csr_wdata;
    wire clint_csr_we;
    wire [`CsrAddrBus] clint_csr_raddr;
    wire [`CsrAddrBus] clint_csr_waddr;
    wire [`CsrBus] clint_csr_wdata;
    wire global_int_en;              // 全局中断使能标志
    wire [`CsrBus] id_csr_rdata;           // id模块读寄存器数据
    wire [`CsrBus] clint_csr_rdata;         // clint模块读寄存器数据
    wire [`CsrBus] clint_csr_mtvec;    // mtvec
    wire [`CsrBus] clint_csr_mepc;     // mepc
    wire [`CsrBus] clint_csr_mstatus;   // mstatus

    wire [`InstAddrBus] id_pc;
    wire [`InstBus] id_inst;
    if_id u_if_id(
        .clk(clk),
        .rst(rst),
        
        .if_pc(pc),
        .if_inst(inst),

        .hold_flag(hold_flag),

        .id_pc(id_pc),
        .id_inst(id_inst)
    );

    // regfile
    wire we;
    wire [`RegAddrBus] waddr;
    wire [`RegBus] wdata;
    wire re1;
    wire [`RegAddrBus] raddr1;
    wire [`RegBus] rdata1;
    wire re2;
    wire [`RegAddrBus] raddr2;
    wire [`RegBus] rdata2;

    wire [`InstAddrBus] id_pc_o;
    wire [`InstBus] id_inst_o;
    wire [`RegBus] id_reg1;          // 与reg1_rdata相同，不过这里是输出
    wire [`RegBus] id_reg2;          // 与reg2_rdata相同，不过这里是输出
    wire [`RegBus] id_imm;          // 与reg2_rdata相同，不过这里是输出
    wire [`RegAddrBus] id_reg_waddr; // 从指令中解析出来的，用于下一个模块计算完成后存放
    wire id_reg_we;                   // 是否需要存放至目的寄存器，因为有得指令不需要存储目的值
    wire id_csr_we;
    wire [`CsrAddrBus] id_csr_waddr;
    id u_id(
        .rst(rst),
        .pc(id_pc),
        .inst(id_inst),

        .reg1_re(re1),
        .reg1_raddr(raddr1),
        .reg1_rdata(rdata1),
        .reg2_re(re2),
        .reg2_raddr(raddr2),
        .reg2_rdata(rdata2),
        // ex 输入过来
        .ex_waddr(ex_waddr),     // 待写的寄存器的地址
        .ex_wdata(ex_wdata),         // 待写的寄存器的数据
        .ex_we(ex_we),                       // 写使能
        // mem 输入过来
        .mem_waddr(mem_waddr_o),     // 待写的寄存器的地址
        .mem_wdata(mem_wdata_o),         // 待写的寄存器的数据
        .mem_we(mem_we_o),                       // 写使能
        .csr_rdata(id_csr_rdata),       // 与csr寄存器直接相连，获取读取的寄存器数据

        // 输出
        .pc_o(id_pc_o),
        .inst_o(id_inst_o),
        .reg1(id_reg1),   
        .reg2(id_reg2),  
        .imm(id_imm), 
        .reg_waddr(id_reg_waddr), 
        .reg_we(id_reg_we),
        .csr_raddr(id_csr_raddr),   // 与csr寄存器直接相连，发送需要读取寄存器的地址
        .ex_csr_we(id_csr_we),      // 由id模块产生发送至ex模块
        .ex_csr_waddr(id_csr_waddr)
    );

    wire [`InstAddrBus] ex_pc;
    wire [`InstBus] ex_inst;
    wire [`RegBus] ex_reg1;
    wire [`RegBus] ex_reg2;
    wire [`RegBus] ex_imm;
    wire [`RegAddrBus] ex_reg_waddr; // 从指令中解析出来的，用于下一个模块计算完成后存放
    wire ex_reg_we;
    wire ex_csr_we;
    wire [`CsrAddrBus] ex_csr_waddr;
    id_ex u_id_ex(
        .clk(clk),
        .rst(rst),

        // 从id中传过来的
        .id_pc(id_pc_o),
        .id_inst(id_inst),
        .id_reg1(id_reg1),
        .id_reg2(id_reg2),
        .id_imm(id_imm),
        .id_reg_waddr(id_reg_waddr),
        .id_reg_we(id_reg_we),
        .id_csr_we(id_csr_we),
        .id_csr_waddr(id_csr_waddr),

        .hold_flag(hold_flag),      

        // 本模块的主要输出
        .ex_pc(ex_pc),
        .ex_inst(ex_inst),
        .ex_reg1(ex_reg1),
        .ex_reg2(ex_reg2),
        .ex_imm(ex_imm),
        .ex_reg_waddr(ex_reg_waddr),
        .ex_reg_we(ex_reg_we),
        .ex_csr_we(ex_csr_we),
        .ex_csr_waddr(ex_csr_waddr)
    );

    wire [`RegAddrBus] ex_waddr;     // 待写的寄存器的地址
    wire [`RegBus] ex_wdata;         // 待写的寄存器的数据
    wire ex_we;                       // 写使能
    wire ex_csr_we_o;                       // ex模块执行后的写寄存器标志
    wire [`CsrAddrBus] ex_csr_waddr_o;           // ex模块写寄存器地址
    wire [`CsrBus] ex_csr_wdata_o;         // 待写的寄存器的数据
    ex u_ex(
        .clk(clk),
        .rst(rst),

        // 从id_ex中传过来的
        .pc(ex_pc),
        .inst(ex_inst),
        .reg1(ex_reg1),
        .reg2(ex_reg2),
        .imm(ex_imm),
        .reg_waddr(ex_reg_waddr),
        .reg_we(ex_reg_we),
        .ram_rdata(ram_rdata),
        .id_csr_we(ex_csr_we),
        .id_csr_waddr(ex_csr_waddr),

        // ram
        .ram_we(ram_we),
        .ram_sel(ram_sel),
        .ram_wraddr(ram_wraddr),
        .ram_wdata(ram_wdata),

        // ctrl
        .ctrl_jump_flag(ex_jump_flag),
        .ctrl_jump_addr(ex_jump_addr),

        // 执行的结果
        .waddr(ex_waddr),     // 待写的寄存器的地址
        .wdata(ex_wdata),         // 待写的寄存器的数据
        .we(ex_we),                       // 写使能
        .mem_csr_we(ex_csr_we_o),
        .mem_csr_waddr(ex_csr_waddr_o),
        .mem_csr_wdata(ex_csr_wdata_o)
    );

    wire [`RegAddrBus] mem_waddr;     // 待写的寄存器的地址
    wire [`RegBus] mem_wdata;         // 待写的寄存器的数据
    wire mem_we;                       // 写使能
    wire mem_csr_we;                       // ex模块执行后的写寄存器标志
    wire [`CsrAddrBus] mem_csr_waddr;           // ex模块写寄存器地址
    wire [`CsrBus] mem_csr_wdata;         // 待写的寄存器的数据
    ex_mem u_ex_mem(
        .clk(clk),
        .rst(rst),

        // 从ex中传过来的
        .ex_waddr(ex_waddr),     // 待写的寄存器的地址
        .ex_wdata(ex_wdata),         // 待写的寄存器的数据
        .ex_we(ex_we),                       // 写使能
        .ex_csr_we(ex_csr_we_o),
        .ex_csr_waddr(ex_csr_waddr_o),
        .ex_csr_wdata(ex_csr_wdata_o),

        // 传给mem
        .mem_waddr(mem_waddr),     // 待写的寄存器的地址
        .mem_wdata(mem_wdata),         // 待写的寄存器的数据
        .mem_we(mem_we),                       // 写使能
        .mem_csr_we(mem_csr_we),
        .mem_csr_waddr(mem_csr_waddr),
        .mem_csr_wdata(mem_csr_wdata)
    );

    wire [`RegAddrBus] mem_waddr_o;     // 待写的寄存器的地址
    wire [`RegBus] mem_wdata_o;         // 待写的寄存器的数据
    wire mem_we_o;                       // 写使能
    wire mem_csr_we_o;                       // ex模块写寄存器标志
    wire [`CsrAddrBus] mem_csr_waddr_o;           // ex模块写寄存器地址
    wire [`CsrBus] mem_csr_wdata_o;         // 待写的寄存器的数据
    mem u_mem(
        .clk(clk),
        .rst(rst),

        // 从ex_mem中传过来的
        .ex_waddr(mem_waddr),     // 待写的寄存器的地址
        .ex_wdata(mem_wdata),         // 待写的寄存器的数据
        .ex_we(mem_we),                       // 写使能
        .ex_csr_we(mem_csr_we),
        .ex_csr_waddr(mem_csr_waddr),
        .ex_csr_wdata(mem_csr_wdata),

        // 传给mem
        .mem_waddr(mem_waddr_o),     // 待写的寄存器的地址
        .mem_wdata(mem_wdata_o),         // 待写的寄存器的数据
        .mem_we(mem_we_o),                       // 写使能
        .mem_csr_we(mem_csr_we_o),
        .mem_csr_waddr(mem_csr_waddr_o),
        .mem_csr_wdata(mem_csr_wdata_o)
    );

    mem_wb u_mem_wb(
        .clk(clk),
        .rst(rst),

        // 从mem中传过来的
        .mem_waddr(mem_waddr_o),     // 待写的寄存器的地址
        .mem_wdata(mem_wdata_o),         // 待写的寄存器的数据
        .mem_we(mem_we_o),                       // 写使能
        .mem_csr_we(mem_csr_we_o),
        .mem_csr_waddr(mem_csr_waddr_o),
        .mem_csr_wdata(mem_csr_wdata_o),

        .wb_waddr(waddr),     // 待写的寄存器的地址
        .wb_wdata(wdata),         // 待写的寄存器的数据
        .wb_we(we),                       // 写使能
        .wb_csr_we(wb_csr_we),                       // ex模块写寄存器标志
        .wb_csr_waddr(wb_csr_waddr),           // ex模块写寄存器地址
        .wb_csr_wdata(wb_csr_wdata)         // 待写的寄存器的数据
    );

    regfile u_regfile(
        .clk(clk),
        .rst(rst),

        .we(we),
        .waddr(waddr),
        .wdata(wdata),

        .re1(re1),
        .raddr1(raddr1),
        .rdata1(rdata1),

        .re2(re2),
        .raddr2(raddr2),
        .rdata2(rdata2)
    );

    csr_reg u_csr_reg(
        .clk(clk),
        .rst(rst),
        .id_raddr(id_csr_raddr),
        .wb_we(wb_csr_we),
        .wb_waddr(wb_csr_waddr),
        .wb_wdata(wb_csr_wdata),
        .clint_we(clint_csr_we),
        .clint_raddr(clint_csr_raddr),
        .clint_waddr(clint_csr_waddr),
        .clint_wdata(clint_csr_wdata),

        .global_int_en(global_int_en),
        .id_rdata(id_csr_rdata),
        .clint_rdata(clint_csr_rdata),
        .clint_csr_mtvec(clint_csr_mtvec),
        .clint_csr_mepc(clint_csr_mepc),
        .clint_csr_mstatus(clint_csr_mstatus)
    );
    
endmodule