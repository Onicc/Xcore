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


`define InstAddrBus     31:0                // 指令地址总线宽度,可查询2^32条指令
`define InstAddrNop     32'h00000000

`define InstBus         31:0                // 指令数据总线宽度,每条指令是32位
`define InstMemNum      131072              // 存放指令的ROM可存储的最大指令数
`define InstMemNumLog2  17                  // ROM的位数，即地址宽度
`define InstNop         32'h00000000

// hold
`define HoldFlagBus     2:0
`define HoldNone       3'b000
`define HoldPc         3'b001              // pc暂停
`define HoldIf         3'b010              // 取址暂停
`define HoldId         3'b100              // 译码暂停

// reg
`define RegNum          32                  // 共32个通用寄存器
`define RegNumLog2      5
`define RegAddrBus      4:0                 // 共32个通用寄存器，因此寄存器地址为5位
`define RegBus          31:0                // 寄存器位宽32位
`define RegAddrNop      5'b00000            // 空寄存器地址
`define RegNop          32'h00000000        // 空寄存器

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
`define OP_JAL          7'b1101111          // 跳转并链接
`define OP_JALR         7'b1100111          // 跳转并寄存器链接