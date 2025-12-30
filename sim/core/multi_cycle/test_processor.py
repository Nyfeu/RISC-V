# ================================================================================================================
# File: test_processor.py
# ================================================================================================================
#
# >>> Descrição: Testbench para o Processador RISC-V (RV32I).
#     Este módulo simula o ambiente externo ao processador, atuando como:
#      1. Memória Principal (RAM de Instruções e Dados unificada).
#      2. Controlador de Periféricos (MMIO) para Console e Controle de Simulação.
#
# ================================================================================================================

# Importações COCOTB
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Event, with_timeout, FallingEdge

# Importação módulo os do sistema operacional para manipulação de arquivos
import os

# Importa utilitários compartilhados (logs customizados, funções de delay, etc.)
from test_utils import (
    log_header, log_info, log_success, log_console, log_error, 
    log_int, settle
)

# ================================================================================================================
# MAPA DE MEMÓRIA (Memory Map)
# ================================================================================================================

# Define os endereços reservados para interação com o ambiente de simulação.
# O processador escreve nestes endereços usando instruções SW (Store Word).

MMIO_CONSOLE_ADDR = 0x10000000  # Escrita de char: Imprime caractere no terminal
MMIO_INT_ADDR     = 0x10000004  # Escrita de int:  Imprime valor numérico (debug)
MMIO_HALT_ADDR    = 0x10000008  # Escrita de flag: Encerra a simulação com sucesso (HALT)

# ================================================================================================================
# 1. CARREGADOR DE PROGRAMA (HEX LOADER)
# ================================================================================================================

def load_hex_program(filepath):
    """
    Lê o arquivo .hex gerado e carrega em um dicionário.
    
    Args:
        filepath (str): Caminho para o arquivo .hex
        
    Returns:
        dict: Mapa {endereço_inteiro: valor_palavra_32bits} representando a RAM.
    """

    mem_dict = {}
    current_addr = 0
    buffer_bytes = []
    
    log_info(f"Loader: carregando software {filepath}...")
    
    try:
        with open(filepath, 'r') as f:
            for line in f:
                line = line.strip()
                if not line: continue
                
                # O formato gerado pelo objcopy -O verilog usa @ADDR para pular endereços
                if line.startswith('@'):
                    # Se havia bytes pendentes do bloco anterior, salva-os antes de mudar o endereço
                    if buffer_bytes:
                        flush_buffer_to_mem(mem_dict, current_addr, buffer_bytes)
                        buffer_bytes = []
                    # Define novo endereço base (remove o @ e converte de hex)
                    current_addr = int(line[1:], 16)
                else:
                    # Lê bytes de dados (ex: "13 00 00 00")
                    parts = line.split()
                    for byte_str in parts:
                        buffer_bytes.append(int(byte_str, 16))
                        # A cada 4 bytes, formamos uma palavra de 32 bits (RISC-V Word)
                        if len(buffer_bytes) == 4:
                            flush_buffer_to_mem(mem_dict, current_addr, buffer_bytes)
                            current_addr += 4
                            buffer_bytes = []
                            
        # Flush final caso o arquivo termine com bytes pendentes
        if buffer_bytes:
            flush_buffer_to_mem(mem_dict, current_addr, buffer_bytes)
            
    except Exception as e:
        log_error(f"Falha crítica no Loader: {e}")
        return {}
        
    return mem_dict

def flush_buffer_to_mem(mem, addr, bytes_list):
    """
    Converte uma lista de até 4 bytes para uma palavra de 32 bits (Little Endian).
    RISC-V é Little Endian: o byte menos significativo fica no menor endereço.
    """
    # Preenche com zeros se a última palavra estiver incompleta
    while len(bytes_list) < 4: 
        bytes_list.append(0)
    
    # Montagem da palavra: Byte3 << 24 | Byte2 << 16 | Byte1 << 8 | Byte0
    val = (bytes_list[3] << 24) | (bytes_list[2] << 16) | (bytes_list[1] << 8) | bytes_list[0]
    
    # Armazena no dicionário de memória (alinhado por endereço de byte)
    mem[addr] = val

# ================================================================================================================
# 2. CONTROLADOR DE MEMÓRIA E PERIFÉRICOS (Modelo BRAM Síncrono)
# ================================================================================================================

async def memory_and_mmio_controller(dut, mem_data, halt_event):
    """
    Simula Memória BRAM Síncrona Robusta.
    Amostra sinais na borda de descida (FallingEdge) para garantir estabilidade
    e escreve/lê na borda de subida (RisingEdge).
    """
    log_info("Controlador de Memória (Síncrono/Falling Sample) Ativo.")
    console_buffer = ""

    # Registradores de Pipeline (Latch)
    latched_i_addr = 0
    latched_d_addr = 0
    latched_d_we   = 0
    latched_d_data = 0

    while True:
        # ------------------------------------------------------------------
        # 1. BORDA DE SUBIDA (Rising Edge): Ação da Memória
        # ------------------------------------------------------------------
        await RisingEdge(dut.CLK_i)

        # [LEITURA] Entrega o dado correspondente ao endereço amostrado no ciclo anterior
        # (Simula latência de 1 ciclo da BRAM)
        dut.IMem_data_i.value = mem_data.get(latched_i_addr & 0xFFFFFFFC, 0)
        dut.DMem_data_i.value = mem_data.get(latched_d_addr & 0xFFFFFFFC, 0)

        # [ESCRITA] Efetiva a escrita se foi solicitada no ciclo anterior
        if latched_d_we > 0:
            
            # MMIO: Console
            if latched_d_addr == MMIO_CONSOLE_ADDR:
                char = chr(latched_d_data & 0xFF)
                if char == '\n':
                    log_console(f"{console_buffer}")
                    console_buffer = ""
                else:
                    console_buffer += char
            
            # MMIO: Halt
            elif latched_d_addr == MMIO_HALT_ADDR:
                log_success("Sinal de HALT recebido via MMIO!")
                halt_event.set()
                break # Encerra o loop do controlador

            # MMIO: Debug Int
            elif latched_d_addr == MMIO_INT_ADDR:
                val_signed = latched_d_data if latched_d_data < 0x80000000 else latched_d_data - 0x100000000
                log_int(f"{val_signed}")
            
            # RAM Store
            else:
                aligned_addr = latched_d_addr & 0xFFFFFFFC
                current_word = mem_data.get(aligned_addr, 0)
                new_word = current_word
                
                if (latched_d_we & 0x1): new_word = (new_word & 0xFFFFFF00) | (latched_d_data & 0x000000FF)
                if (latched_d_we & 0x2): new_word = (new_word & 0xFFFF00FF) | (latched_d_data & 0x0000FF00)
                if (latched_d_we & 0x4): new_word = (new_word & 0xFF00FFFF) | (latched_d_data & 0x00FF0000)
                if (latched_d_we & 0x8): new_word = (new_word & 0x00FFFFFF) | (latched_d_data & 0xFF000000)
                mem_data[aligned_addr] = new_word

        # ------------------------------------------------------------------
        # 2. BORDA DE DESCIDA (Falling Edge): Amostragem (Setup)
        # ------------------------------------------------------------------
        await FallingEdge(dut.CLK_i)

        # Amostra os sinais agora que estão estáveis (meio do ciclo)
        try:
            latched_i_addr = int(dut.IMem_addr_o.value)
        except ValueError: latched_i_addr = 0

        try:
            latched_d_addr = int(dut.DMem_addr_o.value)
            latched_d_data = int(dut.DMem_data_o.value)
            latched_d_we   = int(dut.DMem_writeEnable_o.value)
        except ValueError:
            latched_d_addr = 0
            latched_d_data = 0
            latched_d_we   = 0

# ================================================================================================================
# 3. TESTE PRINCIPAL (Main Test)
# ================================================================================================================

@cocotb.test()
async def test_processor_execution(dut):
    
    # Testbench Principal:
    # 1. Carrega o software compilado (.hex).
    # 2. Inicializa Clock e Reset.
    # 3. Monitora a execução até receber o sinal de HALT ou estourar o tempo (Timeout).
    
    log_header("INICIANDO SIMULAÇÃO CORE RISC-V (MULTI-CYCLE)")

    # ----------------------------------------------------------------------
    # [FASE 1] Configuração e Carga 
    # ----------------------------------------------------------------------
    
    # Obtém o caminho do arquivo .hex a partir da variável de ambiente
    hex_path = os.environ.get("PROGRAM_PATH")
    if not hex_path or not os.path.exists(hex_path):
        log_error(f"Arquivo HEX não encontrado em: {hex_path}")
        log_error("Verifique se a variável de ambiente PROGRAM_PATH está definida corretamente.")
        return
    
    # Carrega a "imagem" da RAM a partir do arquivo
    ram_image = load_hex_program(hex_path)
    
    # ----------------------------------------------------------------------
    # [FASE 2] Inicialização da Simulação
    # ----------------------------------------------------------------------
    
    # Inicia o Clock (100MHz = 10ns período)
    cocotb.start_soon(Clock(dut.CLK_i, 10, unit="ns").start())
    
    # Cria evento de sincronização para saber quando o processador terminou
    halt_event = Event()
    
    # Inicia o controlador de memória em paralelo (thread secundária)
    cocotb.start_soon(memory_and_mmio_controller(dut, ram_image, halt_event))

    # ----------------------------------------------------------------------
    # [FASE 3] Sequência de Reset
    # ----------------------------------------------------------------------

    # Aplica reset inicial
    log_info("Aplicando Reset ao processador...")
    dut.Reset_i.value = 1
    
    # Inicializa barramentos de entrada para evitar estados indeterminados ('X')
    dut.IMem_data_i.value = 0
    dut.DMem_data_i.value = 0
    
    # Segura o Reset por 2 ciclos de clock
    await RisingEdge(dut.CLK_i)
    await RisingEdge(dut.CLK_i)
    dut.Reset_i.value = 0
    
    # Indica que o processador pode começar a operar
    log_info("Reset liberado. Processador em execução...")

    # ----------------------------------------------------------------------
    # [FASE 4] Aguarda Conclusão
    # ----------------------------------------------------------------------

    # Define um timeout de segurança (de 500ms)
    # Se o processador entrar em loop infinito, o teste falha aqui.

    try:
        await with_timeout(halt_event.wait(), 500, "ms")
        log_success("Simulação concluída com sucesso! Processador executou HALT.")
    except Exception:
        log_error("TIMEOUT: O processador não finalizou no tempo limite (500ms).")
        log_error("Possíveis causas: Loop infinito no software ou falha no hardware.")
        assert False, "Simulation Timeout"