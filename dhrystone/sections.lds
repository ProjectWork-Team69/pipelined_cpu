OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    /* Unified memory - 256KB starting at 0x00000000 */
    RAM : ORIGIN = 0x00000000, LENGTH = 256K
}

SECTIONS
{
    /* Code section */
    .text : {
        . = ALIGN(4);
        *(.text.start)
        *(.text)
        *(.text.*)
        . = ALIGN(4);
    } > RAM
    
    /* Read-only data */
    .rodata : {
        . = ALIGN(4);
        *(.rodata)
        *(.rodata.*)
        . = ALIGN(4);
    } > RAM
    
    /* Initialized data */
    .data : {
        . = ALIGN(4);
        _sdata = .;
        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)
        . = ALIGN(4);
        _edata = .;
    } > RAM
    
    _sidata = LOADADDR(.data);
    
    /* Uninitialized data */
    .bss : {
        . = ALIGN(4);
        _sbss = .;
        *(.bss)
        *(.bss.*)
        *(.sbss)
        *(.sbss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > RAM
    
    /* Heap and stack */
    .heap : {
        . = ALIGN(4);
        _heap_start = .;
        . = . + 32K;  /* 32KB heap */
        _heap_end = .;
    } > RAM
    
    /* Stack at the end of RAM */
    _sp = ORIGIN(RAM) + LENGTH(RAM);
    _end = .;
    
    /* Global pointer (for relaxation) */
    __global_pointer$ = _sdata + 0x800;

}

PROVIDE(__bss_start = _sbss);
PROVIDE(__bss_end   = _ebss);
PROVIDE(__data_start = _sdata);
PROVIDE(__data_end   = _edata);

