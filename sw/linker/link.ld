/* Script de Linker Mínimo */
ENTRY(_start)
SECTIONS
{
    . = 0x00000000;
    .text : { *(.text) }
}