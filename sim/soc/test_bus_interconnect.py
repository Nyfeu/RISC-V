# =====================================================================================================
# File: test_bus_interconnect.py
# =====================================================================================================
#
# >>> Descrição:
#     Testbench para o Interconectador de Barramento (Bus Interconnect).
#     Verifica se o roteamento de endereços e o multiplexador de dados 
#     estão operando conforme o Memory Map definido.
#
# =====================================================================================================

import cocotb   # Biblioteca principal do cocotb

# Utilitários compartilhados entre os testbenches
from test_utils import (
    log_header, log_info, log_success, log_error, log_console, settle
)

# =====================================================================================================
# FUNÇÃO DE VERIFICAÇÃO DE ROTA
# =====================================================================================================

async def check_route(dut, addr, we, name, expected_sel_bits, expected_data_val=0):
    """
    Aplica um endereço e verifica se os sinais de seleção e dados estão corretos.
    expected_sel_bits: [ROM_SEL, UART_SEL, RAM_SEL]
    """
    
    # Aplica estímulos
    dut.addr_i.value = addr
    dut.we_i.value   = we
    
    # Simula dados vindos dos componentes
    dut.rom_data_i.value  = 0x11111111
    dut.uart_data_i.value = 0x22222222
    dut.ram_data_i.value  = 0x88888888
    
    await settle()

    # Captura saídas reais
    rom_sel  = int(dut.rom_sel_o.value)
    uart_sel = int(dut.uart_sel_o.value)
    ram_sel  = int(dut.ram_sel_o.value)
    data_out = int(dut.data_o.value)

    log_console(f"Testando {name:8} | Addr: 0x{addr:08X} | SELs: [{rom_sel},{uart_sel},{ram_sel}] | Data: 0x{data_out:08X}")

    # 1. Validação de Seleção
    if [rom_sel, uart_sel, ram_sel] != expected_sel_bits:
        log_error(f"FALHA na seleção para {name}")
        log_error(f"Esperado: {expected_sel_bits} | Obtido: {[rom_sel, uart_sel, ram_sel]}")
        assert False

    # 2. Validação de Sinais de Escrita (WE) qualificados
    if we == 1:
        # Se UART selecionada, uart_we_o deve ser 1. Caso contrário, 0.
        if uart_sel == 1 and int(dut.uart_we_o.value) != 1:
            log_error(f"FALHA: uart_we_o não ativado em escrita para {name}")
            assert False
        
        # Se RAM selecionada, ram_we_o deve ser 1. Caso contrário, 0.
        if ram_sel == 1 and int(dut.ram_we_o.value) != 1:
            log_error(f"FALHA: ram_we_o não ativado em escrita para {name}")
            assert False
            
    # 3. Validação de Dados (apenas se for leitura, we=0)
    if we == 0 and data_out != expected_data_val:
        log_error(f"FALHA no roteamento de dados para {name}")
        log_error(f"Esperado: 0x{expected_data_val:08X} | Obtido: 0x{data_out:08X}")
        assert False

# =====================================================================================================
# TESTE PRINCIPAL
# =====================================================================================================

@cocotb.test()
async def test_bus_interconnect(dut):
    
    # Teste do barramento cobrindo ROM, RAM, UART e Endereços Inválidos.

    log_header("Iniciando Teste do Bus Interconnect")

    # 1. Teste da Boot ROM (Faixa 0x0...)
    log_info("Verificando Rota: Boot ROM")
    await check_route(dut, 0x00000000, 0, "ROM_START", [1, 0, 0], 0x11111111)
    await check_route(dut, 0x00000FFF, 0, "ROM_END",   [1, 0, 0], 0x11111111)

    # 2. Teste da UART (Faixa 0x1...)
    log_info("Verificando Rota: UART")
    await check_route(dut, 0x10000000, 1, "UART_WR",   [0, 1, 0])
    await check_route(dut, 0x10000004, 0, "UART_RD",   [0, 1, 0], 0x22222222)
    
    # 3. Teste da RAM (Faixa 0x8...)
    log_info("Verificando Rota: RAM")
    await check_route(dut, 0x80000000, 1, "RAM_WR",    [0, 0, 1])
    await check_route(dut, 0x80003FFF, 0, "RAM_RD",    [0, 0, 1], 0x88888888)

    # 4. Teste de Endereços fora do Mapa
    log_info("Verificando Rota: Endereço Inválido")
    await check_route(dut, 0x20000000, 0, "INVALID",   [0, 0, 0], 0x00000000)
    await check_route(dut, 0xFFFFFFFF, 0, "INVALID",   [0, 0, 0], 0x00000000)

    log_success("Barramento validado com sucesso!")