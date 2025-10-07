# Makefile for Dhrystone on RISC-V

USE_MYSTDLIB = 0
OBJS = dhry_1.o dhry_2.o stdlib.o
CFLAGS = -MD -O3 -mabi=ilp32 -march=rv32i -DTIME -DRISCV
TOOLCHAIN_PREFIX = $(HOME)/riscv32/bin/riscv32-unknown-elf-
LINKER_SCRIPT = sections.lds

ifeq ($(USE_MYSTDLIB),1)
CFLAGS += -DUSE_MYSTDLIB -ffreestanding -nostdlib
OBJS += start.o
else
OBJS += syscalls.o
endif

# Default target
test: testbench.vvp dhry.hex
	vvp -N testbench.vvp

# Run with trace
test_trace: testbench.vvp dhry.hex
	vvp -N $< +trace
	python3 ./showtrace.py testbench.trace dhry.elf > testbench.ins

# Compile testbench
testbench.vvp: testbench.v ../src/riscv_cpu.v ../src/components/*.v
	iverilog -g2012 -o testbench.vvp testbench.v ../src/riscv_cpu.v ../src/components/*.v
	chmod -x testbench.vvp

# Generate hex file
dhry.hex: dhry.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@

# Link ELF
ifeq ($(USE_MYSTDLIB),1)
dhry.elf: $(OBJS) $(LINKER_SCRIPT)
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,$(LINKER_SCRIPT),-Map,dhry.map,--strip-debug -o $@ $(OBJS) -lgcc
	chmod -x $@
	$(TOOLCHAIN_PREFIX)size $@
else
dhry.elf: $(OBJS) $(LINKER_SCRIPT)
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,$(LINKER_SCRIPT),-Map,dhry.map,--strip-debug -o $@ $(OBJS) -lgcc -lc
	chmod -x $@
	$(TOOLCHAIN_PREFIX)size $@
endif

# Generate raw binary file
dhry.bin: dhry.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@

dhry.mem: dhry.bin
	hexdump -ve '1/4 "%08x\n"' $< > $@

# Compile C files
%.o: %.c
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

# Assemble assembly files
%.o: %.S
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

# Suppress warnings for dhrystone legacy code
dhry_1.o dhry_2.o: CFLAGS += -Wno-implicit-int -Wno-implicit-function-declaration

# Generate disassembly
dump: dhry.elf
	$(TOOLCHAIN_PREFIX)objdump -D $< > dhry.dump

# Clean build artifacts
clean:
	rm -rf *.o *.d dhry.elf dhry.map dhry.hex dhry.mem dhry.bin dhry.dump testbench.vvp testbench.vcd testbench.trace testbench.ins

.PHONY: test test_trace dump clean

-include *.d
