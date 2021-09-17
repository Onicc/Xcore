`define RstEnable       1'b0
`define RstDisable      1'b1
`define ZeroWord        32'h00000000
`define WriteEnable     1'b1
`define WriteDisable    1'b0
`define ReadEnable      1'b1
`define ReadDisable     1'b0
`define InstValid       1'b0
`define InstInvalid     1'b1
`define ChipEnable      1'b1
`define ChipDisable     1'b0
`define ByteWidth       7:0
`define JumpEnable      1'b1
`define JumpDisable     1'b0
`define HoldEnable      1'b1
`define HoldDisable     1'b0
`define IntEnable       1'b1
`define IntDisable      1'b0

`define InstAddrBus     31:0                // 指令地址总线宽度,可查询2^32条指令
`define InstAddrNop     32'h00000000

`define InstBus         31:0                // 指令数据总线宽度,每条指令是32位
`define InstMemNum      131072              // 存放指令的ROM可存储的最大指令数
`define InstMemNumLog2  17                  // ROM的位数，即地址宽度
`define InstNop         32'h00000000

// hold
`define HoldFlagBus     2:0
`define HoldNone        3'b000
`define HoldPc          3'b001              // pc暂停
`define HoldIf          3'b010              // 取址暂停
`define HoldId          3'b100              // 译码暂停

// reg
`define RegNum          32                  // 共32个通用寄存器
`define RegNumLog2      5
`define RegAddrBus      4:0                 // 共32个通用寄存器，因此寄存器地址为5位
`define RegBus          31:0                // 寄存器位宽32位
`define DoubleRegBus    63:0                // 两倍寄存器位宽
`define RegAddrNop      5'b00000            // 空寄存器地址
`define RegNop          32'h00000000        // 空寄存器

`define CsrAddrBus      31:0
`define CsrAddrNop      32'h00000000
`define CsrBus          31:0
`define CsrNop          32'h00000000        // 空寄存器
`define DoubleCsrBus    63:0                // 两倍寄存器位宽

// mem rom
`define RomNum          4096                // 有多少个字 一个字MemBus位 用于存放代码
`define RomNumLog2      12 

// mem ram
`define MemNum          4096                // 有多少个字 一个字MemBus位
`define MemBus          31:0
`define MemNop          32'h00000000
`define MemAddrBus      31:0
`define MemAddrNop      32'h00000000
`define MenSelBus       3:0
`define MenSelNop       4'b0000

// opcode部分
`define OP_R            7'b0110011
`define OP_I            7'b0010011
`define OP_S            7'b0100011
`define OP_B            7'b1100011
`define OP_L            7'b0000011
`define OP_CSR          7'b1110011

// function部分
// R type inst
`define FUNC3_R_ADD     3'b000              // 加法，忽略算术溢出
`define FUNC3_R_SUB     3'b000              // 减法，忽略算术溢出
`define FUNC3_R_SLL     3'b001              // 逻辑左移
`define FUNC3_R_SLT     3'b010              // 小于则置位
`define FUNC3_R_SLTU    3'b011              // 无符号小于则置位
`define FUNC3_R_XOR     3'b100              // 异或
`define FUNC3_R_SRL     3'b101              // 逻辑右移
`define FUNC3_R_SRA     3'b101              // 算术右移
`define FUNC3_R_OR      3'b110              // 或
`define FUNC3_R_AND     3'b111              // 与

// I type inst
`define FUNC3_I_ADDI    3'b000              // 加立即数
`define FUNC3_I_SLTI    3'b010              // 小于立即数则置位
`define FUNC3_I_SLTIU   3'b011              // 无符号小于立即数则置位
`define FUNC3_I_XORI    3'b100              // 异或立即数
`define FUNC3_I_ORI     3'b110              // 或立即数
`define FUNC3_I_ANDI    3'b111              // 与立即数
`define FUNC3_I_SLLI    3'b001              // 立即数逻辑左移
`define FUNC3_I_SRLI    3'b101              // 立即数逻辑右移
`define FUNC3_I_SRAI    3'b101              // 立即数算术右移

// S type inst
`define FUNC3_S_SB      3'b000              // 存字节
`define FUNC3_S_SH      3'b001              // 存半字
`define FUNC3_S_SW      3'b010              // 存字

// B type inst
`define FUNC3_B_BEQ     3'b000              // 相等时分支
`define FUNC3_B_BNE     3'b001              // 不相等时分支
`define FUNC3_B_BLT     3'b100              // 小于时分支
`define FUNC3_B_BGE     3'b101              // 大于等于时分支
`define FUNC3_B_BLTU    3'b110              // 无符号小于时分支
`define FUNC3_B_BGEU    3'b111              // 无符号大于等于时分支

// L type inst
`define FUNC3_L_LB      3'b000              // 字节加载 8bit
`define FUNC3_L_LH      3'b001              // 半字加载 16bit
`define FUNC3_L_LW      3'b010              // 字加载 32bit
`define FUNC3_L_LBU     3'b100              // 无符号字节加载 8bit
`define FUNC3_L_LHU     3'b101              // 无符号半字加载 16bit

`define OP_LUI          7'b0110111          // 高位立即数加载
`define OP_AUIPC        7'b0010111          // PC 加立即数
`define OP_JAL          7'b1101111          // 跳转并链接, 把下一条指令的地址(pc+4)保存到目的寄存器，然后把 pc 设置为当前值加上符号位扩展的offset
`define OP_JALR         7'b1100111          // 跳转并寄存器链接, 把 pc 设置为 x[rs1] + sign-extend(offset)，把计算出的地址的最低有效位设为 0，并将原 pc+4的值写入 f[rd]

// 中断异常相关
`define OP_FENCE        7'b0001111
`define INST_ECALL      32'h73              // 通过引发环境调用异常来请求执行环境
`define INST_EBREAK     32'h00100073        // 通过抛出断点异常的方式请求调试器
`define INST_MRET       32'h30200073        // 机器模式异常返回

// CSR inst
`define FUNC3_CSRRW     3'b001              // 记控制状态寄存器csr中的值为 t。把寄存器 x[rs1]的值写入 csr，再把 t 写入 x[rd]。
`define FUNC3_CSRRS     3'b010              // 记控制状态寄存器csr中的值为 t。把 t 和寄存器 x[rs1]按位或的结果写入 csr，再把 t 写入 x[rd]。
`define FUNC3_CSRRC     3'b011              // 记控制状态寄存器csr中的值为 t。把 t 和寄存器 x[rs1]取反后按位与的结果写入 csr，再把 t 写入 x[rd]。
`define FUNC3_CSRRWI    3'b101              // 把控制状态寄存器csr中的值拷贝到 x[rd]中，再把五位的零扩展的立即数 zimm 的值写入 csr。
`define FUNC3_CSRRSI    3'b110              // 记控制状态寄存器csr中的值为 t。把 t 和五位的零扩展的立即数 zimm 按位或的结果写入 csr，再把 t 写入 x[rd](csr 寄存器的第 5 位及更高位不变)。
`define FUNC3_CSRRCI    3'b111              // 记控制状态寄存器csr中的值为 t。把 t 和五位的零扩展的立即数 zimm 按位与的结果写入 csr，再把 t 写入 x[rd](csr 寄存器的第 5 位及更高位不变)。

// CSR reg addr
`define CSR_CYCLE       12'hc00
`define CSR_CYCLEH      12'hc80
`define CSR_MTVEC       12'h305
`define CSR_MCAUSE      12'h342
`define CSR_MTVAL       12'h343
`define CSR_MEPC        12'h341
`define CSR_MSTATUS     12'h300
`define CSR_MIE         12'h304
`define CSR_MIP         12'h344
`define CSR_MSCRATCH    12'h340

`define IntBus          7:0
`define INT_NONE        8'h0
`define IntAssert       1'b1
`define IntDeassert     1'b0

`define RIB_REQ 1'b1
`define RIB_NREQ 1'b0
// `define INT_RET 8'hff
// `define INT_TIMER0 8'b00000001
// `define INT_TIMER0_ENTRY_ADDR 32'h4

// FUNC3_CSRRW
// 读后写控制状态寄存器 (Control and Status Register Read and Write). I-type, RV32I and RV64I. 
// 记控制状态寄存器csr中的值为 t。把寄存器 x[rs1]的值写入 csr，再把 t 写入 x[rd]。
// FUNC3_CSRRS
// 读后置位控制状态寄存器 (Control and Status Register Read and Set). I-type, RV32I and RV64I. 
// 记控制状态寄存器csr中的值为 t。把 t 和寄存器 x[rs1]按位或的结果写入 csr，再把 t 写入 x[rd]。
// FUNC3_CSRRC
// 立即数读后清除控制状态寄存器 (Control and Status Register Read and Clear Immediate). I- type, RV32I and RV64I.
// 记控制状态寄存器csr中的值为 t。把 t 和五位的零扩展的立即数 zimm 按位与的结果写入 csr，再把 t 写入 x[rd](csr 寄存器的第 5 位及更高位不变)。
// FUNC3_CSRRWI
// 立即数读后写控制状态寄存器 (Control and Status Register Read and Write Immediate). I-type, RV32I and RV64I.
// 把控制状态寄存器csr中的值拷贝到 x[rd]中，再把五位的零扩展的立即数 zimm 的值写入 csr。
// FUNC3_CSRRSI
// 立即数读后设置控制状态寄存器 (Control and Status Register Read and Set Immediate). I-type, RV32I and RV64I.
// 记控制状态寄存器csr中的值为 t。把 t 和五位的零扩展的立即数 zimm 按位或的结果写入 csr，再把 t 写入 x[rd](csr 寄存器的第 5 位及更高位不变)。
// FUNC3_CSRRCI
// 立即数读后清除控制状态寄存器 (Control and Status Register Read and Clear Immediate). I- type, RV32I and RV64I.
// 记控制状态寄存器csr中的值为 t。把 t 和五位的零扩展的立即数 zimm 按位与的结果写入 csr，再把 t 写入 x[rd](csr 寄存器的第 5 位及更高位不变)。
