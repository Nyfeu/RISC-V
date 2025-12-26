# ==============================================================================
# File: test_lsu.py
# Descrição: Testbench para a Load Store Unit (LSU)
# ==============================================================================

import cocotb   # Biblioteca principal do cocotb

# Importa utilitários compartilhados entre testbenches
from test_utils import log_header, log_info, log_success, settle

# Funct3 Constants (Baseado no RISC-V ISA)
F3_LB  = 0b000
F3_LH  = 0b001
F3_LW  = 0b010
F3_LBU = 0b100
F3_LHU = 0b101

F3_SB  = 0b000
F3_SH  = 0b001
F3_SW  = 0b010

# Helper para extensão de sinal (simulando o comportamento do VHDL)
def sign_extend(value, bits):
    sign_bit = 1 << (bits - 1)
    return (value & (sign_bit - 1)) - (value & sign_bit)

@cocotb.test()
async def test_lsu_passthrough(dut):
    
    # Indica o teste sendo realizado
    log_header("Teste 1: Verifica se Endereço e WriteEnable passam direto")
    
    # Escreve mensagem de inicialização
    log_info("Iniciando Teste de Pass-through...")
    
    # Stimulus
    addr = 0x12345678
    we   = 1
    
    # Configura os sinais do DUT
    dut.Addr_i.value      = addr
    dut.MemWrite_i.value  = we
    dut.WriteData_i.value = 0
    dut.Funct3_i.value    = 0
    dut.DMem_data_i.value = 0 

    # Aguarda a estabilização dos sinais
    await settle()
    
    # Checks
    assert dut.DMem_addr_o.value == addr, f"Erro Endereço: {hex(dut.DMem_addr_o.value)} != {hex(addr)}"
    assert dut.DMem_we_o.value   == we,   f"Erro WE: {dut.DMem_we_o.value} != {we}"
    
    # Escreve mensagem de sucesso do teste
    log_success("Pass-through OK!")


@cocotb.test()
async def test_lsu_loads(dut):

    # Indica o teste sendo realizado
    log_header("Teste 2: Verifica a lógica de LOAD (Leitura e Formatação)")
    
    # Escreve mensagem de inicialização
    log_info("Iniciando Teste de Loads...")
    
    # Cenário: Memória contém 0x89ABCDEF
    # Byte 0 (LSB) = EF, Byte 1 = CD, Byte 2 = AB, Byte 3 (MSB) = 89
    mem_val = 0x89ABCDEF
    dut.DMem_data_i.value = mem_val
    dut.MemWrite_i.value  = 0         # Leitura

    # Tabela de Testes: (Funct3, Endereço_LSB, Valor_Esperado, Nome)
    test_cases = [
        # LW (Word) - Endereço alinhado
        (F3_LW,  0b00, 0x89ABCDEF, "LW Alinhado"),
        
        # LB (Byte com Sinal) - 0xEF é negativo em 8 bits? Sim (11101111) -> Extende para FFFFFFEF
        (F3_LB,  0b00, 0xFFFFFFEF, "LB Byte 0 (Neg)"),
        (F3_LB,  0b01, 0xFFFFFFCD, "LB Byte 1 (Neg)"),
        (F3_LB,  0b10, 0xFFFFFFAB, "LB Byte 2 (Neg)"),
        (F3_LB,  0b11, 0xFFFFFF89, "LB Byte 3 (Neg)"),
        
        # LBU (Byte Sem Sinal)
        (F3_LBU, 0b00, 0x000000EF, "LBU Byte 0"),
        (F3_LBU, 0b11, 0x00000089, "LBU Byte 3"),

        # LH (Half com Sinal) - 0xCDEF (Neg), 0x89AB (Neg)
        (F3_LH,  0b00, 0xFFFFCDEF, "LH Half 0"),
        (F3_LH,  0b10, 0xFFFF89AB, "LH Half 1"),

        # LHU (Half Sem Sinal)
        (F3_LHU, 0b00, 0x0000CDEF, "LHU Half 0"),
    ]

    # Loop de iteração do vetor de testes
    for f3, addr_lsb, expected, name in test_cases:

        # Configura os sinais no DUT
        dut.Funct3_i.value = f3
        dut.Addr_i.value   = addr_lsb # Só importa os 2 bits LSB
        
        # Aguarda estabilização
        await settle()
        
        # Captura resultado
        got = int(dut.LoadData_o.value)
        
        # Ajuste para lidar com números negativos no Python se necessário, 
        # mas comparando com hex hardcoded é seguro.
        if got != expected and expected < 0: 
             # Se o esperado fosse definido como signed int no python
             pass 
        
        # Mas aqui definimos expected como unsigned 32-bit representação (ex: 0xFF...)
        # O cocotb lê como unsigned por padrão a menos que especificado.
        assert got == expected, f"FALHA {name}: Esperado {hex(expected)}, Obtido {hex(got)}"

        # Escreve mensagem de sucesso do teste
        log_info(f"OK: {name}")

    log_success("Vetor de testes realizado com sucesso!")


@cocotb.test()
async def test_lsu_stores(dut):

    # Indica o teste sendo realizado
    log_header("Teste 3: Verifica a lógica de STORE (Read-Modify-Write)")
    
    # Escreve mensagem de inicialização
    log_info("Iniciando Teste de Stores...")
    
    # Dado existente na "Memória" (simulado na entrada)
    # Vamos tentar escrever 0x11223344 (novo) sobre 0xAAAAAAAA (velho)
    old_mem = 0xAAAAAAAA
    new_val = 0x11223344
    
    # Configura os sinais no DUT
    dut.DMem_data_i.value = old_mem
    dut.WriteData_i.value = new_val
    dut.MemWrite_i.value  = 1

    # Define o vetor de testes
    test_cases = [
        # SW: Deve sobrescrever tudo
        (F3_SW, 0b00, 0x11223344, "SW Full"),
        
        # SH: Sobrescreve Half, preserva o resto
        # End 00: Write 3344, Keep AAAA (upper) -> AAAA3344
        (F3_SH, 0b00, 0xAAAA3344, "SH Lower"),
        # End 10: Write 3344 (pega os 16 bits LSB do reg), Keep AAAA (lower) -> 3344AAAA
        (F3_SH, 0b10, 0x3344AAAA, "SH Upper"),
        
        # SB: Sobrescreve Byte, preserva resto
        # End 00: Write 44, Keep AAAAAA -> AAAAAA44
        (F3_SB, 0b00, 0xAAAAAA44, "SB Byte 0"),
        # End 01: Write 44, Keep AAAA..AA -> AAAA44AA
        (F3_SB, 0b01, 0xAAAA44AA, "SB Byte 1"),
    ]

    # Loop de iteração do vetor de testes
    for f3, addr_lsb, expected, name in test_cases:
        
        # Configura os sinais no DUT
        dut.Funct3_i.value = f3
        dut.Addr_i.value   = addr_lsb
        
        # Aguarda estabilização
        await settle()
        
        # Captura resultado
        got = int(dut.DMem_data_o.value)

        # Comparação
        assert got == expected, f"FALHA {name}: Esperado {hex(expected)}, Obtido {hex(got)}"

        # Escreve mensagem de sucesso do teste
        log_info(f"OK: {name}")
    
    log_success("Vetor de testes realizado com sucesso!")