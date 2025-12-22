# ============================================================================================================================================================
# File: test_load_unit.py
# ============================================================================================================================================================
#
# >>> Descrição: Testbench para a Unidade de Carga (Load Unit).
#     Verifica a extração correta de Bytes, Half-words e Words da memória.
#     Valida extensão de sinal (LB, LH) vs extensão de zero (LBU, LHU).
#
# ============================================================================================================================================================

import cocotb   # Biblioteca principal do cocotb
import random   # Para gerar valores aleatórios nos testes

# Importa utilitários compartilhados entre testbenches
from test_utils import log_header, log_info, log_success, log_error, settle, sign_extend

# =====================================================================================================================
# CONSTANTES (RISC-V LOAD FUNCT3)
# =====================================================================================================================

F3_LB  = 0b000
F3_LH  = 0b001
F3_LW  = 0b010
F3_LBU = 0b100
F3_LHU = 0b101

NAMES = {
    F3_LB: "LB", F3_LH: "LH", F3_LW: "LW", 
    F3_LBU: "LBU", F3_LHU: "LHU"
}

# =====================================================================================================================
# GOLDEN MODEL - Modelo de referência em Python
# =====================================================================================================================
#
# Def. Formal: Para todo (a, b, opcode) ∈ Domínio_Especificado:
#    RTL(a, b, opcode) == GoldenModel(a, b, opcode)
#
# Trata-se da implementação de um modelo comportamental de referência, utilizado como oráculo de 
# verificação funcional.

def model_load_unit(mem_data, addr_lsb, funct3):
    """
    Simula o hardware Load Unit.
    
    Args:
        mem_data (int): Palavra de 32 bits vinda da memória (raw).
        addr_lsb (int): 2 bits menos significativos do endereço (alinhamento).
        funct3 (int): Tipo da instrução de carga.
        
    Returns:
        int: Valor de 32 bits (signed) a ser escrito no registrador.
    """
    
    # LW: Carrega a palavra inteira
    if funct3 == F3_LW:
        return sign_extend(mem_data, 32)
        
    # Byte Operations (LB, LBU)
    elif funct3 in [F3_LB, F3_LBU]:
        # Em Little Endian:
        # LSB=00 -> bits [7:0]
        # LSB=01 -> bits [15:8]
        # LSB=10 -> bits [23:16]
        # LSB=11 -> bits [31:24]
        shift = addr_lsb * 8
        byte_val = (mem_data >> shift) & 0xFF
        
        if funct3 == F3_LB:
            return sign_extend(byte_val, 8)
        else:
            return byte_val # Zero extend implícito

    # Half-word Operations (LH, LHU)
    elif funct3 in [F3_LH, F3_LHU]:
        # Em Little Endian:
        # LSB[1]=0 (00 ou 01) -> bits [15:0]
        # LSB[1]=1 (10 ou 11) -> bits [31:16]
        if (addr_lsb & 0b10) == 0:
            half_val = mem_data & 0xFFFF
        else:
            half_val = (mem_data >> 16) & 0xFFFF
            
        if funct3 == F3_LH:
            return sign_extend(half_val, 16)
        else:
            return half_val # Zero extend implícito

    return 0 # Indefinido

# =====================================================================================================================
# FUNÇÃO DE VERIFICAÇÃO
# =====================================================================================================================

async def verify_load(dut, mem_data, addr_lsb, funct3, expected_val, case_desc):
    """
    Aplica estímulos e verifica a saída da Load Unit.
    """
    
    # Aplica estímulos
    dut.DMem_data_i.value = mem_data
    dut.Addr_LSB_i.value  = addr_lsb
    dut.Funct3_i.value    = funct3
    
    # Aguarda estabilização dos sinais
    await settle()
    
    # Leitura da saída (como inteiro sinalizado)
    current_val = dut.Data_o.value.to_signed()
    
    # Comparação
    if current_val != expected_val:
        log_error(f"FALHA: {case_desc}")
        log_error(f"Inputs  : Data={hex(mem_data)}, LSB={bin(addr_lsb)}, F3={NAMES.get(funct3, 'UNK')}")
        log_error(f"Esperado: {hex(expected_val & 0xFFFFFFFF)} ({expected_val})")
        log_error(f"Recebido: {hex(current_val & 0xFFFFFFFF)} ({current_val})")
        assert False, f"Falha no caso: {case_desc}"

# =====================================================================================================================
# TESTES
# =====================================================================================================================

@cocotb.test()
async def run_directed_tests(dut):

    # Reproduz os testes manuais da unidade de carga

    log_header("Testes Dirigidos - Load Unit")
    
    # Dado de teste principal (Little Endian)
    # Byte 0: 0x80 (Negativo em 8 bits)
    # Byte 1: 0xAA (Negativo em 8 bits)
    # Byte 2: 0x22 (Positivo)
    # Byte 3: 0x11 (Positivo)
    TEST_DATA = 0x1122AA80
    
    # 1. LW (Load Word)
    await verify_load(dut, TEST_DATA, 0b00, F3_LW, 0x1122AA80, "LW Full Word")
    log_success("LW OK")

    # 2. LB (Load Byte Signed)
    # Byte 0 (0x80) -> sign ext -> 0xFFFFFF80 (-128)
    await verify_load(dut, TEST_DATA, 0b00, F3_LB, -128, "LB Byte 0 (0x80 -> Neg)")
    
    # Byte 1 (0xAA) -> sign ext -> 0xFFFFFFAA (-86)
    await verify_load(dut, TEST_DATA, 0b01, F3_LB, -86,  "LB Byte 1 (0xAA -> Neg)")
    
    # Byte 2 (0x22) -> sign ext -> 0x00000022 (+34)
    await verify_load(dut, TEST_DATA, 0b10, F3_LB, 34,   "LB Byte 2 (0x22 -> Pos)")
    log_success("LB OK")

    # 3. LBU (Load Byte Unsigned)
    # Byte 0 (0x80) -> zero ext -> 0x00000080 (+128)
    await verify_load(dut, TEST_DATA, 0b00, F3_LBU, 128, "LBU Byte 0 (0x80 -> Pos)")
    
    # Byte 1 (0xAA) -> zero ext -> 0x000000AA (+170)
    await verify_load(dut, TEST_DATA, 0b01, F3_LBU, 170, "LBU Byte 1 (0xAA -> Pos)")
    log_success("LBU OK")

    # 4. LH (Load Half Signed)
    # Half 0 (0xAA80) -> sign ext -> 0xFFFFAA80 (-21888)
    await verify_load(dut, TEST_DATA, 0b00, F3_LH, -21888, "LH Half 0 (0xAA80 -> Neg)")
    
    # Half 1 (0x1122) -> sign ext -> 0x00001122 (+4386)
    await verify_load(dut, TEST_DATA, 0b10, F3_LH, 4386,   "LH Half 1 (0x1122 -> Pos)")
    log_success("LH OK")

    # 5. LHU (Load Half Unsigned)
    # Half 0 (0xAA80) -> zero ext -> 0x0000AA80 (+43648)
    await verify_load(dut, TEST_DATA, 0b00, F3_LHU, 43648, "LHU Half 0 (0xAA80 -> Pos)")
    log_success("LHU OK")

@cocotb.test()
async def stress_test_randomized(dut):

    # Gera dados e endereços aleatórios para validação com o Golden Model.

    # Número de iterações aleatórias
    NUM_ITERATIONS = 5000

    # Contador de hits por tipo de instrução
    hits = {}
    
    # Escreve cabeçalho do teste
    log_header(f"Stress Test Randomized ({NUM_ITERATIONS} iterações)")
    
    # Lista de funct3 válidos para Load Unit
    valid_ops = [F3_LB, F3_LH, F3_LW, F3_LBU, F3_LHU]
    
    # Loop de iterações aleatórias 
    for i in range(NUM_ITERATIONS):

        # Gera entradas aleatórias
        mem_data = random.randint(0, 0xFFFFFFFF)
        addr_lsb = random.randint(0, 3)
        funct3   = random.choice(valid_ops)
        
        # Calcula esperado pelo modelo
        expected = model_load_unit(mem_data, addr_lsb, funct3)
        
        # Verifica DUT
        await verify_load(dut, mem_data, addr_lsb, funct3, expected, f"Iter {i}")
        
        # Estatísticas
        op_name = NAMES[funct3]
        hits[op_name] = hits.get(op_name, 0) + 1

    # Relatório de cobertura de operações
    for op, count in sorted(hits.items()):
        log_info(f"{op:<5}: {count} vezes")
    
    # Escreve mensagem de sucesso do teste
    log_success(f"{NUM_ITERATIONS} Vetores Aleatórios Verificados com Sucesso")