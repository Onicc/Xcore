import os, sys
import random
import binascii

file_name = "/Users/xc/Library/Mobile Documents/com~apple~CloudDocs/Documents/IC/MIPS/TB/inst_rom.data"
inst_num_log2 = 17
inst_log2 = 32
# hexAscii = binascii.unhexlify(hex(randomInt))
# print(hexAscii)
with open(file_name, 'w') as f:
    for i in range(pow(2, inst_num_log2)):
        randomInt = random.randint(0,pow(2, inst_log2)-1)
        f.write("{:08X}".format(randomInt))
        # f.write(hex(randomInt))
        f.write('\n')