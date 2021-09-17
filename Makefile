all: clean compile simulate gtkwave

compile:
	iverilog \
	-I ./RTL/core \
	-I ./RTL/peripherals \
	-I ./RTL/soc \
	-y ./RTL/core \
	-y ./RTL/peripherals \
	-y ./RTL/soc \
	-o ./build/xcore_tb.o ./TB/xcore_tb.v

simulate:
	vvp -n ./build/xcore_tb.o
	mv ./xcore_tb.vcd ./build/xcore_tb.vcd

gtkwave:
	open ./build/xcore_tb.vcd

clean:
	@rm -rf ./build/*

# ./RTL/defines.v \
# ./RTL/pc_reg.v \
# ./RTL/inst_rom.v \
# ./RTL/regs.v \
# ./RTL/xcore.v \
# ./TB/xcore_tb.v