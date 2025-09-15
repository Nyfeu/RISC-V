SECTIONS
{
    /* Código na flash/ROM, começa em 0x0 */
    . = 0x00000000;

    .text : {
        *(.text*)
    }

    .rodata : {
        *(.rodata*)
    }

    /* Dados na RAM */
    .data : {
        *(.data*)
    }

    .bss : {
        *(COMMON)
    }
}