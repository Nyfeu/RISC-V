.section .text
.globl _start

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

# ---------------------------------------------------------------------
# Loop infinito para o caso de 'main' retornar (o que não deve acontecer).
# ---------------------------------------------------------------------
hang:
    j hang
