# =====================================================================================================
# File: test_bus_interconnect.py
# =====================================================================================================
#
# >>> Descrição:
#     Testbench para o Interconectador de Barramento (Bus Interconnect).
#     Verifica:
#       1. Roteamento de Dados (DMem): Endereços, Write Enables (Vetores) e Mux de Leitura.
#       2. Roteamento de Instruções (IMem): Mux de Instrução entre ROM e RAM.
#
# =====================================================================================================

import cocotb   # Biblioteca principal do cocotb

# Utilitários compartilhados entre os testbenches
from test_utils import log_header, log_info, log_success, log_error, log_console, settle

# =====================================================================================================
# CHECK: ROTA DE DADOS (Load/Store)
# =====================================================================================================

async def check_data_route(dut, addr, we_vec, name, expected_sel_bits, expected_data_val=0):
    """
    Verifica o caminho de DADOS (DMem).
    expected_sel_bits: [ROM_SEL_B, UART_SEL, RAM_SEL_B]
    we_vec: Inteiro representando o vetor de 4 bits (ex: 0xF para escrita full word)
    """
    
    # 1. Aplica Estímulos (DMem Side)
    dut.dmem_addr_i.value = addr
    dut.dmem_we_i.value   = we_vec
    
    # Simula dados presentes nas portas de leitura dos escravos (Porta B para memórias)
    dut.rom_data_b_i.value = 0x11111111
    dut.uart_data_i.value  = 0x22222222
    dut.ram_data_b_i.value = 0x88888888
    
    await settle()

    # 2. Captura Saídas
    rom_sel  = int(dut.rom_sel_b_o.value)
    uart_sel = int(dut.uart_sel_o.value)
    ram_sel  = int(dut.ram_sel_b_o.value)
    data_out = int(dut.dmem_data_o.value)
    
    # Captura Write Enables de Saída
    try: ram_we_out = int(dut.ram_we_b_o.value)
    except: ram_we_out = 0
    
    uart_we_out = int(dut.uart_we_o.value)

    log_console(f"CHECK DATA  | {name:8} | Addr: 0x{addr:08X} | WE: 0x{we_vec:X} | SELs: {rom_sel}{uart_sel}{ram_sel}")

    # 3. Validação de Seleção
    if [rom_sel, uart_sel, ram_sel] != expected_sel_bits:
        log_error(f"FALHA na seleção para {name}")
        log_error(f"Esperado [ROM, UART, RAM]: {expected_sel_bits} | Obtido: {[rom_sel, uart_sel, ram_sel]}")
        assert False

    # 4. Validação de Write Enables (Propagação)
    
    # RAM: O vetor de escrita deve ser repassado integralmente se selecionada
    if ram_sel == 1:
        if ram_we_out != we_vec:
            log_error(f"FALHA: RAM Write Enable incorreto. Esperado: 0x{we_vec:X}, Obtido: 0x{ram_we_out:X}")
            assert False
    else:
        if ram_we_out != 0:
            log_error("FALHA: RAM WE ativo sem seleção.")
            assert False

    # UART: Deve ser 1 se houver *qualquer* bit ativo no vetor de entrada (Reduction OR)
    if uart_sel == 1:
        is_writing = 1 if we_vec > 0 else 0
        if uart_we_out != is_writing:
            log_error(f"FALHA: UART Write Enable incorreto. Esperado: {is_writing}, Obtido: {uart_we_out}")
            assert False
    else:
        if uart_we_out != 0:
            log_error("FALHA: UART WE ativo sem seleção.")
            assert False
            
    # 5. Validação de Dados de Leitura (Mux de Retorno)
    # Apenas validamos se não estivermos escrevendo (embora o mux funcione sempre)
    if we_vec == 0:
        if data_out != expected_data_val:
            log_error(f"FALHA no roteamento de dados para {name}")
            log_error(f"Esperado: 0x{expected_data_val:08X} | Obtido: 0x{data_out:08X}")
            assert False

# =====================================================================================================
# CHECK: ROTA DE INSTRUÇÃO (Fetch)
# =====================================================================================================

async def check_instr_route(dut, addr, name, expected_val):
    """
    Verifica o caminho de INSTRUÇÃO (IMem).
    Valida se o endereço seleciona a ROM (Porta A) ou RAM (Porta A) corretamente.
    """
    dut.imem_addr_i.value = addr
    
    # Simula dados nas portas A
    dut.rom_data_a_i.value = 0xAAAA0000 # Valor simulado da ROM
    dut.ram_data_a_i.value = 0xBBBB0000 # Valor simulado da RAM
    
    await settle()
    
    inst_out = int(dut.imem_data_o.value)
    
    log_console(f"CHECK INSTR | {name:8} | Addr: 0x{addr:08X} | Data: 0x{inst_out:08X}")
    
    if inst_out != expected_val:
        log_error(f"FALHA no Fetch de instrução para {name}")
        log_error(f"Esperado: 0x{expected_val:08X} | Obtido: 0x{inst_out:08X}")
        assert False

# =====================================================================================================
# TESTE PRINCIPAL
# =====================================================================================================

@cocotb.test()
async def test_bus_interconnect(dut):
    
    log_header("Iniciando Teste do Bus Interconnect (Harvard Split + Byte Enables)")

    # Inicializa sinais não testados imediatamente para evitar 'X'
    dut.imem_addr_i.value = 0
    dut.dmem_addr_i.value = 0
    dut.dmem_we_i.value   = 0
    dut.dmem_data_i.value = 0
    
    # -------------------------------------------------------------------------
    # 1. TESTES DE DADOS (Load / Store)
    # -------------------------------------------------------------------------
    log_info(">>> Testando Barramento de DADOS (DMem)")

    # ROM Read (0x0...)
    await check_data_route(dut, 0x00000000, 0x0, "ROM_RD", [1, 0, 0], 0x11111111)

    # RAM Write Word (0x8..., we=1111)
    await check_data_route(dut, 0x80000000, 0xF, "RAM_WW", [0, 0, 1], 0x88888888)
    
    # RAM Write Byte (0x8..., we=0001)
    await check_data_route(dut, 0x80000004, 0x1, "RAM_WB", [0, 0, 1], 0x88888888)

    # UART Write (0x1..., we=1111) -> UART espera we de 1 bit
    await check_data_route(dut, 0x10000000, 0xF, "UART_WR", [0, 1, 0], 0x22222222)
    
    # UART Read (0x1..., we=0000)
    await check_data_route(dut, 0x10000004, 0x0, "UART_RD", [0, 1, 0], 0x22222222)

    # Endereço Inválido (0x2...) -> Deve retornar 0
    await check_data_route(dut, 0x20000000, 0x0, "VOID_RD", [0, 0, 0], 0x00000000)

    # -------------------------------------------------------------------------
    # 2. TESTES DE INSTRUÇÃO (Fetch)
    # -------------------------------------------------------------------------
    log_info(">>> Testando Barramento de INSTRUÇÕES (IMem)")
    
    # Fetch da ROM (0x0...) -> Espera 0xAAAA0000
    await check_instr_route(dut, 0x00000000, "ROM_FTCH", 0xAAAA0000)
    
    # Fetch da RAM (0x8...) -> Espera 0xBBBB0000
    await check_instr_route(dut, 0x80000100, "RAM_FTCH", 0xBBBB0000)
    
    # Fetch Inválido (0x5...) -> Espera 0
    await check_instr_route(dut, 0x50000000, "INV_FTCH", 0x00000000)

    log_success("Barramento validado com sucesso!")