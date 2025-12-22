# =====================================================================================================
# File: test_uart_tx.py
# =====================================================================================================
#
# >>> Descrição: Testbench para o Transmissor UART (TX).
#       Verifica a serialização correta dos dados realizando amostragem da linha TX 
#       e comparando com o byte enviado.
#
# =====================================================================================================

import cocotb                                   # Biblioteca principal do cocotb
from cocotb.clock import Clock                  # Para gerar clock
from cocotb.triggers import RisingEdge, Timer   # Para aguardar borda de clock e temporizações

# Utilitários compartilhados entre testbenches
from test_utils import log_header, log_info, log_success, log_error, log_console

# =====================================================================================================
# GOLDEN MODEL – UART Receiver (Sniffer)
# =====================================================================================================
#
# Def. Formal: Para todo (a, b, opcode) ∈ Domínio_Especificado:
#    RTL(a, b, opcode) == GoldenModel(a, b, opcode)
#
# Trata-se da implementação de um modelo comportamental de referência, utilizado como oráculo de 
# verificação funcional.

async def sniff_uart_byte(dut, cycles_per_bit, clk_period_ns):
    """
    Monitora a saída serial e reconstrói o byte enviado (Bit-banging reverso).
    Retorna o byte (int) ou None em caso de erro de protocolo.
    """
    
    # 1. Espera a linha cair (Start Bit detection)
    while dut.tx_serial.value == 1:
        await RisingEdge(dut.clk)
    
    # 2. Pula metade do bit para amostrar no centro do Start Bit
    half_bit_time = (cycles_per_bit / 2) * clk_period_ns
    await Timer(half_bit_time, unit="ns")
    
    # Validação do Start Bit (deve permanecer 0)
    if int(dut.tx_serial.value) != 0:
        log_error("Glitch detectado no Start Bit (linha voltou para 1 muito rápido)")
        return None

    # 3. Amostragem dos Dados (8 bits, LSB primeiro)
    full_bit_time = cycles_per_bit * clk_period_ns
    received_byte = 0
    
    for i in range(8):
        await Timer(full_bit_time, unit="ns")
        bit = int(dut.tx_serial.value)
        received_byte |= (bit << i)
        
    # 4. Verificação do Stop Bit
    await Timer(full_bit_time, unit="ns")
    stop_bit = int(dut.tx_serial.value)
    if stop_bit != 1:
        log_error(f"Erro de Framing: Stop Bit não detectado (Lido: {stop_bit})")
    
    # 5. Retorna o byte recebido
    return received_byte

# =====================================================================================================
# TESTE PRINCIPAL
# =====================================================================================================

@cocotb.test()
async def test_uart_tx(dut):

    # Teste do Transmissor UART (TX) 

    log_header("Teste do Transmissor UART (TX)")

    # Clock (100 MHz = 10ns de período)
    CLK_PERIOD_NS = 10

    # Inicializa o clock
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

    # Parâmetros & Vetores de Teste
    # Baud Rate: 115200 @ 100MHz => ~868 clocks por bit
    CYCLES_PER_BIT = 868 
    
    # Vetores de Teste (bytes a serem enviados)
    test_vectors = [
        0x41, # 'A' (Padrão simples)
        0x55, # 01010101 (Máxima frequência de transição)
        0x00, # 00000000 (Linha low por muito tempo)
        0xFF, # 11111111 (Linha high, difícil distinguir do Idle se não houver start/stop)
        0x7E  # '~' (Borda de transição mista)
    ]

    # Reset
    log_info("Aplicando Reset...")
    dut.rst.value = 1
    dut.tx_start.value = 0
    dut.tx_data.value = 0
    
    # Aguarda alguns ciclos de clock
    for _ in range(5):
        await RisingEdge(dut.clk)
    
    # Libera Reset
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    log_info("Reset liberado. Iniciando transações...")

    # Loop de Teste
    for byte_to_send in test_vectors:
        
        log_console(f"Enviando: 0x{byte_to_send:02X}")

        # 1. Drive dos Inputs (Pulso de Start)
        dut.tx_data.value = byte_to_send
        dut.tx_start.value = 1
        await RisingEdge(dut.clk)
        dut.tx_start.value = 0 # Pulso dura 1 ciclo
        
        # 2. Monitoramento (Sniffer)
        # O sniffer roda enquanto o hardware transmite
        received_val = await sniff_uart_byte(dut, CYCLES_PER_BIT, CLK_PERIOD_NS)
        
        # 3. Verificação do Dado
        if received_val != byte_to_send:
            log_error("FALHA na Transmissão UART")
            log_error(f"Enviado : 0x{byte_to_send:02X}")
            log_error(f"Recebido: 0x{received_val:02X}")
            assert False, f"Mismatch UART"
        else:
            log_info(f"Sucesso: 0x{received_val:02X} recebido corretamente")

        # 4. Sincronização de Encerramento (Handshake)

        # Calcula metade do tempo de um bit em ns
        half_bit_time_ns = (CYCLES_PER_BIT / 2) * CLK_PERIOD_NS
        
        # Espera o resto do Stop Bit acabar
        await Timer(half_bit_time_ns, unit="ns")
        
        # Dá mais alguns clocks para a FSM do VHDL transitar para IDLE
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        
        # Agora sim, verifica se o busy baixou
        if dut.tx_busy.value != 0:
            log_error(f"Sinal tx_busy travado em 1 após tempo total de transmissão ({dut.tx_busy.value})")
            assert False

        # Pequeno delay entre caracteres (Idle time)
        await Timer(1000, unit="ns")

    log_success(f"Transmissão UART validada com sucesso ({len(test_vectors)} vetores).")