# test_addi.s
# Programa de teste mínimo para o processador RV32I.

.section .text
.global _start

_start:
    # A instrução que queremos testar:
    # Carrega o valor 42 (0x2A) no registrador a0 (x10).
    # O registrador 'zero' é o x0.
    addi a0, zero, 42

    # Loop infinito para impedir que o processador
    # continue executando lixo da memória após o fim do programa.
    
loop:
    jal zero, loop
