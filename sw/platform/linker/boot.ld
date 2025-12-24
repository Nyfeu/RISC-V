OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
  rom (rx) : ORIGIN = 0x00000000, LENGTH = 1K
  ram (rwx) : ORIGIN = 0x80000000, LENGTH = 16K 
}

SECTIONS {
    .text : { *(.text*) } > rom
    .data : { *(.data*) } > ram
    .bss  : { *(.bss*)  } > ram
    
    /* Stack no final da RAM */
    _stack_start = ORIGIN(ram) + LENGTH(ram);
}