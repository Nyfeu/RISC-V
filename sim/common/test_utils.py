# ==============================================================================
# alu_test_utils.py - Módulo Compartilhado de Utilidades para Testes da ALU
# ==============================================================================
#
# Este módulo centraliza tudo que é COMUM entre diferentes testbenches:
# - Configuração de logging e cores
# - Constantes de operação
# - Funções auxiliares
#
# ==============================================================================

import cocotb
from cocotb.triggers import Timer
import logging

# ==============================================================================
# CONFIGURAÇÃO DE LOGGING E VISUAL
# ==============================================================================

# Suprime logs irrelevantes do GHDL/GPI (Generic Programming Interface)
logging.getLogger("gpi").setLevel(logging.ERROR)

class Colors:
    """Códigos ANSI para colorir o terminal
    
    ANSI = American National Standards Institute
    São códigos especiais que terminais entendem para colorir texto
    Exemplo: \033[92m ativa verde, \033[0m desativa cores
    """
    HEADER = '\033[96m'   # Ciano - para cabeçalhos
    SUCCESS = '\033[92m'  # Verde - para sucesso
    INFO = '\033[94m'     # Azul - para informações
    ENDC = '\033[0m'      # Fim - desativa cores
    BOLD = '\033[1m'      # Negrito

def log_info(msg):
    """Escreve uma mensagem informativa"""
    cocotb.log.info(f"{Colors.INFO}{msg}{Colors.ENDC}")

def log_header(msg):
    """Escreve uma mensagem de cabeçalho em ciano e negrito
    cocotb.log = sistema de logs do cocotb que mostra no terminal
    """
    cocotb.log.info(f"{Colors.HEADER}{Colors.BOLD}>>> {msg}{Colors.ENDC}")

def log_success(msg):
    """Escreve uma mensagem de sucesso em verde com um checkmark (✔)"""
    cocotb.log.info(f"{Colors.SUCCESS}✅ {msg}{Colors.ENDC}")

# ==============================================================================
# CONSTANTES - Códigos de Operação da ALU
# ==============================================================================
#
# Estas constantes definem os CÓDIGOS que a ALU entende
# Cada código (como 0b0000) representa uma operação diferente.
#

ALU_ADD  = 0b0000  # Adição: 10 + 32 = 42
ALU_SUB  = 0b1000  # Subtração: 10 - 32 = -22
ALU_SLL  = 0b0001  # Shift Left Lógico: move bits para esquerda (multiplica por 2)
ALU_SLT  = 0b0010  # Set Less Than (comparação com sinal)
ALU_SLTU = 0b0011  # Set Less Than Unsigned (comparação sem sinal)
ALU_XOR  = 0b0100  # OU Exclusivo: operação lógica
ALU_SRL  = 0b0101  # Shift Right Lógico: move bits para direita (divide por 2)
ALU_SRA  = 0b1101  # Shift Right Aritmético: shift direita preservando sinal
ALU_OR   = 0b0110  # OU lógico
ALU_AND  = 0b0111  # E lógico

def to_signed(val, bits=32):
    """Converte um número para SINALIZADO (pode ser negativo)
    
    Exemplo: 0xFFFFFFFF em 32 bits = -1 (em representação com sinal)
    
    Como funciona:
    1. val & ((1 << bits) - 1): Pega apenas os 'bits' menos significativos
    2. Se o bit mais significativo é 1, o número é negativo
    3. Nesse caso, subtraímos 2^bits para obter o valor negativo correto
    """
    val = val & ((1 << bits) - 1)
    if val & (1 << (bits - 1)):
        val -= (1 << bits)
    return val

def to_unsigned(val, bits=32):
    """Converte um número para NÃO SINALIZADO (sempre positivo)
    
    Exemplo: -1 em 32 bits = 0xFFFFFFFF
    
    Simplesmente máscara para pegar apenas os 'bits' bits menos significativos
    """
    return val & ((1 << bits) - 1)

# ==============================================================================
# FUNÇÕES AUXILIARES
# ==============================================================================

async def settle():
    """Função auxiliar para aguardar um ciclo de simulação
    
    'async' = assíncrono (não bloqueia, permite que simulador continue)
    'await' = espera por algo acontecer
    Timer(1, unit="ns") = espera 1 nanosegundo de tempo de simulação
    
    Após mudar um sinal de entrada, precisamos aguardar a lógica VHDL calcular 
    a saída. Sem isso, seria lido o valor antigo que ainda não foi atualizado!
    """
    await Timer(1, unit="ns")

# ==============================================================================