OUTPUT_ARCH("riscv")
ENTRY(start)

MEMORY
{
    IMEM : ORIGIN = 0x00000000, LENGTH = 8K
    DMEM : ORIGIN = 0x10000000, LENGTH = 8K
}

SECTIONS
{
    .text : {
        *(.text)
        *(.text.*)
        *(.rodata*)
    } > IMEM

    .data : {
        _sdata = .;
        *(.data*)
        _edata = .;
    } > DMEM AT > IMEM
    
    _sidata = LOADADDR(.data);

    .bss : {
        _sbss = .;
        *(.bss*)
        *(COMMON)
        _ebss = .;
    } > DMEM

    _sp = ORIGIN(DMEM) + LENGTH(DMEM);
    __global_pointer$ = _sdata + 0x800;
}