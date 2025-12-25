# ============================================================================================================================================================
# File: test_store_unit.py
# ============================================================================================================================================================
#
# >>> Descrição: Testbench para a Unidade de Armazenamento (Store Unit).
#     Verifica a correta inserção de Bytes, Half-words e Words na palavra de memória.
#     Valida a preservação dos bytes não modificados (Read-Modify-Write lógico).
#
# ============================================================================================================================================================

import cocotb   # Biblioteca principal do cocotb
import random   # Para gerar valores aleatórios nos testes

# Importa utilitários compartilhados entre testbenches
from test_utils import log_header, log_info, log_success, log_error, settle

# =====================================================================================================================
# CONSTANTES (RISC-V STORE FUNCT3)
# =====================================================================================================================

F3_SB = 0b000
F3_SH = 0b001
F3_SW = 0b010

NAMES = {
    F3_SB: "SB", F3_SH: "SH", F3_SW: "SW"
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

def model_store_unit(mem_data, write_data, addr_lsb, funct3):
    """
    Simula o hardware Store Unit.
    
    Args:
        mem_data (int): Dado original lido da memória (32 bits).
        write_data (int): Dado a ser escrito (32 bits, vindo do registrador RS2).
        addr_lsb (int): 2 bits menos significativos do endereço (alinhamento).
        funct3 (int): Tipo da instrução de store.
        
    Returns:
        int: Nova palavra de 32 bits a ser escrita na memória.
    """
    
    # SW: Store Word - Sobrescreve tudo (LSBs ignorados para Word Aligned)
    if funct3 == F3_SW:
        return write_data & 0xFFFFFFFF

    # SH: Store Half - Escreve 16 bits, preserva os outros 16
    elif funct3 == F3_SH:
        # Pega os 16 bits inferiores do dado de escrita
        half_to_write = write_data & 0xFFFF
        
        if (addr_lsb & 0b10) == 0: 
            # Escreve na metade inferior [15:0], preserva superior [31:16]
            return (mem_data & 0xFFFF0000) | half_to_write
        else:
            # Escreve na metade superior [31:16], preserva inferior [15:0]
            return (mem_data & 0x0000FFFF) | (half_to_write << 16)

    # SB: Store Byte - Escreve 8 bits, preserva os outros 24
    elif funct3 == F3_SB:
        # Pega os 8 bits inferiores do dado de escrita
        byte_to_write = write_data & 0xFF
        
        shift = addr_lsb * 8
        mask  = 0xFF << shift
        
        # Limpa o byte alvo no dado da memória e insere o novo byte
        mem_cleared = mem_data & (~mask)
        new_val     = byte_to_write << shift
        
        return (mem_cleared | new_val) & 0xFFFFFFFF

    return 0 # Indefinido

# =====================================================================================================================
# FUNÇÃO DE VERIFICAÇÃO
# =====================================================================================================================

async def verify_store(dut, mem_data, write_data, addr_lsb, funct3, expected_val, case_desc):
    """
    Aplica estímulos e verifica a saída da Store Unit.
    """
    
    # Aplica estímulos
    dut.Data_from_DMEM_i.value = mem_data
    dut.WriteData_i.value      = write_data
    dut.Addr_LSB_i.value       = addr_lsb
    dut.Funct3_i.value         = funct3
    
    await settle()
    
    # Leitura da saída
    current_val = int(dut.Data_o.value)
    
    # Comparação
    if current_val != expected_val:
        log_error(f"FALHA: {case_desc}")
        log_error(f"Inputs  : Mem={hex(mem_data)}, WrData={hex(write_data)}, LSB={bin(addr_lsb)}, F3={NAMES.get(funct3, 'UNK')}")
        log_error(f"Esperado: {hex(expected_val)} (0x{expected_val:08X})")
        log_error(f"Recebido: {hex(current_val)} (0x{current_val:08X})")
        assert False, f"Falha no caso: {case_desc}"

# =====================================================================================================================
# TESTES
# =====================================================================================================================

@cocotb.test()
async def run_directed_tests(dut):

    # Reproduz os testes manuais do store_unit_tb.vhd
    
    log_header("Testes Dirigidos - Store Unit")
    
    # Dados de teste
    MEM_VAL = 0xAAAAAAAA
    WR_VAL  = 0x12345678
    
    # 1. SW (Store Word) -> Deve ser 0x12345678
    await verify_store(dut, MEM_VAL, WR_VAL, 0b00, F3_SW, 0x12345678, "SW Full Word")
    log_success("SW OK")

    # 2. SH (Store Half) no LSB=00 -> Deve preservar metade superior
    # Esperado: 0xAAAA (original) | 0x5678 (novo lower half) -> 0xAAAA5678
    await verify_store(dut, MEM_VAL, WR_VAL, 0b00, F3_SH, 0xAAAA5678, "SH Low Half (LSB=00)")
    log_success("SH OK")

    # 3. SB (Store Byte) no LSB=01 -> Deve preservar bytes 3, 2, 0
    # Byte a escrever: 0x78 (LSB de WrData)
    # Posição 1 (bits 15:8)
    # Original: AA AA AA AA
    # Novo:     AA AA 78 AA -> 0xAAAA78AA
    await verify_store(dut, MEM_VAL, WR_VAL, 0b01, F3_SB, 0xAAAA78AA, "SB Byte 1 (LSB=01)")
    log_success("SB OK")

@cocotb.test()
async def stress_test_randomized(dut):
    
    # Gera dados e endereços aleatórios para validar o Golden Model.
    
    # Número de iterações aleatórias
    NUM_ITERATIONS = 5000

    # Contador de hits por tipo de instrução
    hits = {}
    
    # Escreve cabeçalho do teste
    log_header(f"Stress Test Randomized ({NUM_ITERATIONS} iterações)")
    
    # Lista de funct3 válidos para Store Unit
    valid_ops = [F3_SB, F3_SH, F3_SW]
    
    # Loop de iterações aleatórias 
    for i in range(NUM_ITERATIONS):

        # Gera entradas aleatórias de 32 bits
        mem_data   = random.randint(0, 0xFFFFFFFF)
        write_data = random.randint(0, 0xFFFFFFFF)
        addr_lsb   = random.randint(0, 3)
        funct3     = random.choice(valid_ops)
        
        # Calcula esperado pelo modelo
        expected = model_store_unit(mem_data, write_data, addr_lsb, funct3)
        
        # Verifica DUT
        await verify_store(dut, mem_data, write_data, addr_lsb, funct3, expected, f"Iter {i}")
        
        # Estatísticas
        op_name = NAMES[funct3]
        hits[op_name] = hits.get(op_name, 0) + 1

    # Relatório de cobertura de operações
    for op, count in sorted(hits.items()):
        log_info(f"{op:<5}: {count} vezes")
    
    # Escreve mensagem de sucesso do teste
    log_success(f"{NUM_ITERATIONS} Vetores Aleatórios Verificados com Sucesso")