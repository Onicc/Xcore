# SRV32I
A RISC-V CPU

## 日志
2021.08.19
第一次提交
添加指令：
    I addi
    I slti
    I sltiu
    I xori
    I ori
    I andi
    I slli
    I srli
    I srai
    R add 
    R sub
    R sll
    R slt 
    R sltu
    R xor
    R srl
    R sra 
    R or
    R and

2021.08.20
添加指令：
    I lb
    I lh
    I lw
    I lbu
    I lhu 
    S sb 
    S sh 
    S sw
    U lui
    U auipc
添加模块：
    ram.v

2021.09.13
添加指令：
    B beq
    B bne 
    B blt
    B bge 
    B bltu 
    B bgeu
添加模块：
    ctrl.v
Q：跳转指令跳转时是执行到了ex，下一条流水线已经取址了，因此需要暂停流水线