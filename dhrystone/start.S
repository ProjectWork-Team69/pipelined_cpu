# start.S - Minimal RISC-V startup code for Dhrystone

.section .text
.globl start
.globl _start

start:
_start:
    # Initialize global pointer
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop
    
    # Initialize stack pointer
    la sp, _sp
    
    # Clear BSS section
    la t0, _sbss
    la t1, _ebss
    beq t0, t1, skip_bss
clear_bss:
    sw zero, 0(t0)
    addi t0, t0, 4
    blt t0, t1, clear_bss
skip_bss:
    
    # Copy data section from ROM to RAM
    la t0, _sidata
    la t1, _sdata
    la t2, _edata
    beq t1, t2, skip_data
copy_data:
    lw t3, 0(t0)
    sw t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    blt t1, t2, copy_data
skip_data:
    
    # Call main
    call main
    
    # Exit loop (halt)
exit_loop:
    j exit_loop

# Dummy interrupt/exception handler
.align 2
trap_handler:
    j trap_handler