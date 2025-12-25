OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
  /* SoC: RAM mapeada em 0x80000000 (16KB) */
  ram (rwx) : ORIGIN = 0x80000000, LENGTH = 16K
}

SECTIONS
{
    .text : {
        *(.text*)
    } > ram

    .rodata : {
        *(.rodata*)
    } > ram

    .data : {
        *(.data*)
    } > ram

    .bss : {
        *(.bss*)
        *(COMMON)
    } > ram

    /* Define um símbolo no final da RAM. O topo da pilha começará aqui. */
    _stack_start = ORIGIN(ram) + LENGTH(ram);
}
