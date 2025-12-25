# =====================================================================================================================
# File: test_memory_system.py
# =====================================================================================================================
#
# >>> Descrição: Testbench robusto para o Wrapper do Sistema de Memória.
#     Verifica a integração entre Bus Interconnect, Boot ROM e RAM.
#     Valida a arquitetura Harvard (acesso simultâneo IMem e DMem).
#
# =====================================================================================================================

import cocotb                                      # Biblioteca principal do cocotb
import random                                      # Para gerar valores aleatórios nos testes
from cocotb.clock import Clock                     # Para gerar clock de sincronização dos componentes
from cocotb.triggers import RisingEdge, Timer      # Gerenciamento de clock e atrasos

# Importa as utilidades compartilhadas entre testbenches
from test_utils import log_header, log_info, log_success, log_error, settle

# =====================================================================================================================
# CONSTANTES DO MAPA DE MEMÓRIA
# =====================================================================================================================

# Endereço base dos comoponentes de memória (definidos em app.ld e boot.ld)

ROM_BASE   = 0x00000000       # ROM inicia a execução com PC = 0x00000000
UART_BASE  = 0x10000000       # UART via MMIO no endereço 0x10000000
RAM_BASE   = 0x80000000       # RAM acessível no endereço 0x80000000 

# Tamanho de endereçamento dos componentes

RAM_SIZE   = 4096             # 16KB (4096 words de 32-bits) - conforme ADDR_WIDTH => 12 bits
ROM_SIZE   = 1024             #  4KB (1024 words de 32-bits) - conforme ADDR_WIDTH => 10 bits

# =====================================================================================================================
# MODELO DE REFERÊNCIA (RAM STATE)
# =====================================================================================================================

# Simula o estado esperado da RAM para verificação em tempo real.
ram_model = {} 

def get_expected_ram(addr):
    # Retorna o valor do modelo ou 0 se nunca escrito
    return ram_model.get(addr, 0x00000000)

# =====================================================================================================================
# UTILITÁRIOS DE ACESSO
# =====================================================================================================================

async def reset_dut(dut):
    dut.reset_i.value = 1
    dut.dmem_we_i.value = 0
    dut.imem_addr_i.value = 0
    dut.dmem_addr_i.value = 0
    await Timer(20, unit="ns")
    dut.reset_i.value = 0
    await RisingEdge(dut.clk_i)

async def dmem_write(dut, addr, data):
    dut.dmem_addr_i.value = addr
    dut.dmem_data_i.value = data
    dut.dmem_we_i.value = 1
    await RisingEdge(dut.clk_i)
    dut.dmem_we_i.value = 0
    if (addr & 0xF0000000) == RAM_BASE:
        ram_model[addr] = data

async def verify_system(dut, i_addr, d_addr, exp_i, exp_d, case_desc):
    """Verifica simultaneamente o barramento de Instrução e Dados"""
    dut.imem_addr_i.value = i_addr
    dut.dmem_addr_i.value = d_addr
    
    await RisingEdge(dut.clk_i) # IMPORTANTE: Memórias síncronas precisam de 1 ciclo (como a BRAM da FPGA)
    await settle()
    
    got_i = int(dut.imem_data_o.value)
    got_d = int(dut.dmem_data_o.value)
    
    failed = False
    if got_i != exp_i:
        log_error(f"FALHA IMem: {case_desc} | Addr: 0x{i_addr:08X} | Exp: 0x{exp_i:08X}, Got: 0x{got_i:08X}")
        failed = True
    if got_d != exp_d:
        log_error(f"FALHA DMem: {case_desc} | Addr: 0x{d_addr:08X} | Exp: 0x{exp_d:08X}, Got: 0x{got_d:08X}")
        failed = True
    
    if failed:
        assert False

# =====================================================================================================================
# TESTES DIRECIONADOS
# =====================================================================================================================

@cocotb.test()
async def test_directed_memory(dut):

    log_header("Iniciando Testes Dirigidos de Memória")

    # Inicia o clock da simulação
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())

    # Aplica sinal de reset
    await reset_dut(dut)

    # Como a ROM já tem código (0xFE010113...), vamos ler o valor inicial 
    # para usar como referência nos testes.
    dut.imem_addr_i.value = ROM_BASE
    await RisingEdge(dut.clk_i)
    await settle()
    rom_boot_val = int(dut.imem_data_o.value)
    log_info(f"Código de Boot detectado na ROM: 0x{rom_boot_val:08X}")

    # 1. Teste de Escrita e Persistência na RAM
    log_info("Verificando Escrita/Leitura na RAM...")
    addr_test = RAM_BASE + 0x100
    val_test  = 0xABCDE001
    await dmem_write(dut, addr_test, val_test)
    # Agora usamos rom_boot_val em vez de 0 para a expectativa da IMem
    await verify_system(dut, ROM_BASE, addr_test, rom_boot_val, val_test, "RAM Load/Store")
    
    # 2. Teste de Acesso Harvard (Fetch e Load simultâneos)
    log_info("Verificando Arquitetura Harvard (Acesso Simultâneo)...")
    addr_code = RAM_BASE + 0x20
    addr_data = RAM_BASE + 0x40
    await dmem_write(dut, addr_code, 0x11111111)
    await dmem_write(dut, addr_data, 0x22222222)
    # Verifica se consegue ler o código na RAM e os dados na RAM ao mesmo tempo
    await verify_system(dut, addr_code, addr_data, 0x11111111, 0x22222222, "Harvard RAM Access")

    # 3. Teste de Endereço Inválido (Isolamento)
    log_info("Verificando Isolamento de Endereços Inválidos...")
    # Endereços não mapeados no bus_interconnect devem retornar 0
    await verify_system(dut, 0x50000000, 0x60000000, 0, 0, "Invalid Address Returns Zero")

    # Escreve mensagem de sucesso do teste
    log_success("Testes Dirigidos Concluídos!")

# =====================================================================================================================
# STRESS TEST ALEATÓRIO
# =====================================================================================================================

@cocotb.test()
async def test_memory_stress(dut):
    
    # Gera tráfego massivo e aleatório de Load/Store e Fetch
    log_header(f"Iniciando Stress Test (LOAD/STORE e FETCH)")
    
    # Número de iterações para teste
    NUM_ITERATIONS = 2000

    # Inicia o clock da simulação
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())

    # Aplica sinal de reset
    await reset_dut(dut)

    # Loop de iteração
    for i in range(NUM_ITERATIONS):

        # Escolhe um offset aleatório dentro da RAM (alinhado a word de 4 bytes)
        offset_i = random.randint(0, RAM_SIZE - 1) * 4
        offset_d = random.randint(0, RAM_SIZE - 1) * 4
        
        # Calcula o endereço com offsets
        addr_i = RAM_BASE + offset_i
        addr_d = RAM_BASE + offset_d
        
        # Decide se vai escrever nesta rodada
        do_write = random.random() < 0.3 # 30% de chance de escrita
        
        if do_write:
            new_val = random.getrandbits(32)
            await dmem_write(dut, addr_d, new_val)
        
        # Verifica se o que está lá (DMem e IMem) bate com o modelo
        exp_i = get_expected_ram(addr_i)
        exp_d = get_expected_ram(addr_d)
        
        # Compara
        await verify_system(dut, addr_i, addr_d, exp_i, exp_d, f"Stress Iter {i}")

    # Escreve mensagem de sucesso do teste
    log_success(f"Stress Test finalizado: {NUM_ITERATIONS} acessos verificados sem corrupção.")

@cocotb.test()
async def test_rom_stress(dut):
    
    # Realiza um estresse avançado na ROM verificando imutabilidade, 
    # concorrência Harvard e isolamento contra escritas.
    log_header("Iniciando Stress Test Sofisticado da ROM")

    # Inicia o clock da simulação
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())

    # Aplica sinal de reset
    await reset_dut(dut)

    # 1. MAPEAMENTO INICIAL (Profiling)
    # Lendo os primeiros 64 words da ROM para criar um modelo local de comparação
    rom_content = {}
    log_info("Mapeando conteúdo inicial da ROM para referência...")
    for i in range(64):
        addr = ROM_BASE + (i * 4)
        dut.dmem_addr_i.value = addr
        await RisingEdge(dut.clk_i)
        await settle()
        rom_content[addr] = int(dut.dmem_data_o.value)

    # 2. TENTATIVA DE ESCRITA NA ROM
    log_info("Ataque de Escrita: Verificando se a ROM é imutável...")
    for addr in list(rom_content.keys())[:10]:
        original_val = rom_content[addr]
        # Tenta escrever o inverso do valor original
        await dmem_write(dut, addr, (~original_val) & 0xFFFFFFFF)
        
        # Lê de volta para garantir que não mudou
        dut.dmem_addr_i.value = addr
        await RisingEdge(dut.clk_i)
        await settle()
        current_val = int(dut.dmem_data_o.value)
        
        if current_val != original_val:
            log_error(f"CORRUPÇÃO NA ROM: Escrita em 0x{addr:08X} alterou valor!")
            assert False
    log_success("ROM protegida contra escritas (Read-Only OK)")

    # 3. CONCORRÊNCIA HARVARD E ISOLAMENTO DE RAM
    log_info("Estresse de Concorrência: ROM (IMem/DMem) + Escrita em RAM simultânea")
    
    # Endereços fixos para o teste de interferência
    target_rom_addr_i = ROM_BASE + 0x00  # Onde está o boot code
    target_rom_addr_d = ROM_BASE + 0x04  # Próxima instrução
    target_ram_addr   = RAM_BASE + 0x500
    
    expected_rom_i = rom_content[target_rom_addr_i]
    expected_rom_d = rom_content[target_rom_addr_d]

    for i in range(1000):

        # Gera dado aleatório para "sujar" o barramento via RAM
        garbage_data = random.getrandbits(32)
        
        # Setup: IMem e DMem apontando para ROM, mas DMem tentando escrever na RAM
        dut.imem_addr_i.value = target_rom_addr_i
        dut.dmem_addr_i.value = target_ram_addr # Alvo da escrita na RAM
        dut.dmem_data_i.value = garbage_data
        dut.dmem_we_i.value   = 1 # Ativa escrita (deve ir para RAM, não ROM)

        # Avança um ciclo de clock
        await RisingEdge(dut.clk_i)
        
        # No ciclo de estabilização da leitura (que é síncrona), 
        # verificamos se a leitura da ROM via IMem foi limpa.
        # Simultaneamente, mudamos DMem para ler outra posição da ROM.
        dut.dmem_we_i.value   = 0
        dut.dmem_addr_i.value = target_rom_addr_d
        
        # Aguarda estabilização
        await settle()
        
        # Captura valor
        got_i = int(dut.imem_data_o.value)
        if got_i != expected_rom_i:
            log_error(f"Interferência detectada! IMem leu 0x{got_i:08X} durante escrita na RAM")
            assert False

        # Verifica a leitura da porta DMem da ROM no ciclo seguinte
        await RisingEdge(dut.clk_i)
        await settle()
        got_d = int(dut.dmem_data_o.value)
        if got_d != expected_rom_d:
            log_error(f"Interferência detectada! DMem leu 0x{got_d:08X} da ROM")
            assert False

    # Escreve mensagem de sucesso do teste
    log_success("Concorrência e Isolamento validados com 1000 ciclos de estresse")