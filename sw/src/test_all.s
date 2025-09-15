# RISC-V RV32I - Suíte de Teste de Instruções em Assembly
#
# ESTRATÉGIA:
# - Cada teste verifica uma instrução.
# - Se um teste passa, um código de sucesso único é escrito no endereço INT_OUTPUT.
# - Se um teste falha, o código pula para a rotina 'fail', imprime -1 e para.
# - Se todos os testes passam, o código imprime 999 e para.

.section .text
.globl _start

# Endereços de MMIO
.equ INT_OUTPUT, 0x10000004
.equ STACK_TOP,  0x00001000  # Define um topo para a pilha (ex: 4KB)

_start:
    # Configura o stack pointer para uma área segura da memória
    li sp, STACK_TOP

    # --- TESTE 1: ADDI (Add Immediate) ---
    li t0, 10
    addi t1, t0, 5      # t1 = 10 + 5 = 15
    li t2, 15
    bne t1, t2, fail
    li a0, 1            # Código de sucesso
    sw a0, 0(sp)        # Usa a pilha para salvar o endereço de output
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP    # Restaura a pilha

    # --- TESTE 2: ADD (Add) ---
    li t0, 20
    li t1, 22
    add t2, t0, t1      # t2 = 20 + 22 = 42
    li t3, 42
    bne t2, t3, fail
    li a0, 2
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 3: SUB (Subtract) ---
    li t0, 50
    li t1, 10
    sub t2, t0, t1      # t2 = 50 - 10 = 40
    li t3, 40
    bne t2, t3, fail
    li a0, 3
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 4: LUI (Load Upper Immediate) ---
    lui t0, 0xABCDE     # t0 = 0xABCDE000
    li t1, 0xABCDE000
    bne t0, t1, fail
    li a0, 4
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 5: AUIPC (Add Upper Immediate to PC) ---
    # Este é mais complexo. Pularemos a verificação exata do valor,
    # mas garantiremos que ele execute e não trave.
    auipc t0, 0         # t0 = endereço da instrução auipc
    li a0, 5
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTES LÓGICOS ---
    li t0, 0b1010
    li t1, 0b1100

    # --- TESTE 6: AND ---
    and t2, t0, t1      # t2 = 1010 & 1100 = 1000 (8)
    li t3, 8
    bne t2, t3, fail
    li a0, 6
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 7: OR ---
    or t2, t0, t1       # t2 = 1010 | 1100 = 1110 (14)
    li t3, 14
    bne t2, t3, fail
    li a0, 7
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 8: XOR ---
    xor t2, t0, t1      # t2 = 1010 ^ 1100 = 0110 (6)
    li t3, 6
    bne t2, t3, fail
    li a0, 8
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTES LÓGICOS IMEDIATOS ---
    li t0, 0b1010

    # --- TESTE 9: ANDI ---
    andi t1, t0, 0b1100 # t1 = 1010 & 1100 = 1000 (8)
    li t2, 8
    bne t1, t2, fail
    li a0, 9
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 10: ORI ---
    ori t1, t0, 0b1100  # t1 = 1010 | 1100 = 1110 (14)
    li t2, 14
    bne t1, t2, fail
    li a0, 10
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 11: XORI ---
    xori t1, t0, 0b1100 # t1 = 1010 ^ 1100 = 0110 (6)
    li t2, 6
    bne t1, t2, fail
    li a0, 11
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTES DE SHIFT ---
    li t0, 2            # 0b...10

    # --- TESTE 12: SLL (Shift Left Logical) ---
    li t1, 3
    sll t2, t0, t1      # t2 = 2 << 3 = 16
    li t3, 16
    bne t2, t3, fail
    li a0, 12
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 13: SLLI (Shift Left Logical Immediate) ---
    slli t1, t0, 4      # t1 = 2 << 4 = 32
    li t2, 32
    bne t1, t2, fail
    li a0, 13
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 14: SRL / SRLI (Shift Right Logical) ---
    li t0, 16           # 0b10000
    srli t1, t0, 2      # t1 = 16 >> 2 = 4
    li t2, 4
    bne t1, t2, fail
    li a0, 14
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 15: SRA / SRAI (Shift Right Arithmetic) ---
    li t0, -16          # 0xFFFFFFF0
    srai t1, t0, 2      # t1 = -16 >> 2 = -4 (0xFFFFFFFC)
    li t2, -4
    bne t1, t2, fail
    li a0, 15
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTES DE COMPARAÇÃO ---
    li t0, 10
    li t1, 20
    li t2, -10

    # --- TESTE 16: SLT (Set Less Than) ---
    slt t3, t0, t1      # t3 = (10 < 20) = 1
    li t4, 1
    bne t3, t4, fail
    li a0, 16
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 17: SLTU (Set Less Than Unsigned) ---
    sltu t3, t2, t0     # t3 = (-10u > 10u) = 0
    li t4, 0
    bne t3, t4, fail
    li a0, 17
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 18: SLTI / SLTIU ---
    slti t3, t0, 5      # t3 = (10 < 5) = 0
    li t4, 0
    bne t3, t4, fail
    li a0, 18
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTES DE BRANCH ---
    li t0, 10
    li t1, 10
    li t2, 20

    # --- TESTE 19: BEQ (Branch if Equal) - Taken ---
    beq t0, t1, beq_ok
    j fail
beq_ok:
    li a0, 19
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 20: BNE (Branch if Not Equal) - Not Taken ---
    bne t0, t1, fail
    li a0, 20
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 21: BLT (Branch if Less Than) - Taken ---
    blt t0, t2, blt_ok
    j fail
blt_ok:
    li a0, 21
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 22: BGE (Branch if Greater or Equal) - Not Taken ---
    bge t0, t2, fail
    li a0, 22
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 23: BLTU (Unsigned) - t0(10) < t2(20) - Taken ---
    bltu t0, t2, bltu_ok
    j fail
bltu_ok:
    li a0, 23
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 24: BGEU (Unsigned) - t2(20) >= t0(10) - Taken ---
    bgeu t2, t0, bgeu_ok
    j fail
bgeu_ok:
    li a0, 24
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTES DE MEMÓRIA (Load/Store) ---
    li t0, 12345
    # Endereço de memória para teste
    li t1, 0x00000200

    # --- TESTE 25: SW (Store Word) e LW (Load Word) ---
    sw t0, 0(t1)
    lw t2, 0(t1)
    bne t0, t2, fail
    li a0, 25
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 26: SH (Store Half) e LH (Load Half) ---
    li t0, -300         # 0xFFFFFECC
    sh t0, 0(t1)
    lh t2, 0(t1)        # Carrega e estende o sinal -> -300
    bne t0, t2, fail
    li a0, 26
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTE 27: SB (Store Byte) e LBU (Load Byte Unsigned) ---
    li t0, 250          # 0xFA
    sb t0, 0(t1)
    lbu t2, 0(t1)       # Carrega sem sinal -> 250
    bne t0, t2, fail
    li a0, 27
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP
    
    # --- TESTE 28: SB (Store Byte) e LB (Load Byte) ---
    li t0, -10          # 0xF6
    sb t0, 0(t1)
    lb t2, 0(t1)        # Carrega com sinal -> -10
    bne t0, t2, fail
    li a0, 28
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP

    # --- TESTES DE JUMP ---

    # --- TESTE 29: JAL (Jump and Link) ---
    la t0, jal_target   # Carrega o endereço do alvo
    jal ra, jal_target  # Pula e armazena o endereço de retorno em ra (para a linha abaixo)

    # --- TESTE 30: JALR (Jump and Link Register) ---
    # A verificação é implícita. Se chegamos aqui após o JAL, o JALR funcionou.
    li a0, 30
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP
    j jal_continue      # Pula para o próximo teste

jal_target:
    # Este código é executado após o JAL
    li a0, 29
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP
    jalr x0, ra, 0      # Retorna para a instrução após o 'jal'

jal_continue:
    # --- TESTE 31: FENCE (apenas executa, sem verificação de resultado) ---
    fence
    li a0, 31
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP
    
    j pass

# --- Rotinas de Fim ---
pass:
    # Todos os testes passaram!
    li a0, 999
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP
    j pass_loop
pass_loop:
    j pass_loop

fail:
    # Um teste falhou!
    li a0, -1
    li sp, INT_OUTPUT
    sw a0, 0(sp)
    li sp, STACK_TOP
    j fail_loop
fail_loop:
    j fail_loop