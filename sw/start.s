.section .text
.globl _start

# Endereço de MMIO para sinalizar o fim da simulação
.equ HALT_MMIO, 0x10000008

_start:

    # -----------------------------------------------------------------
    # Inicializa o Stack Pointer (sp) para um local seguro na memória.
    # 0x1000 (4096) é o topo da nossa pilha de 4KB.
    # A pilha cresce para baixo, então este é o endereço mais alto.
    # -----------------------------------------------------------------

    li sp, 0x1000

    # -----------------------------------------------------------------
    # Pula para a função 'main' em C.
    # -----------------------------------------------------------------

    call main

    # -----------------------------------------------------------------
    # A simulação terminará quando a instrução abaixo for executada.
    # Isso garante que a simulação pare após o retorno de 'main'.
    # -----------------------------------------------------------------

    li a0, 1
    li t0, HALT_MMIO
    sw a0, 0(t0)

# ---------------------------------------------------------------------
# Loop infinito para o caso de 'main' retornar (o que não deve acontecer).
# ---------------------------------------------------------------------
hang:
    j hang
