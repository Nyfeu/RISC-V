# =====================================================================================================
# File: test_uart_rx.py
# =====================================================================================================
#
# >>> Descrição:
#     Testbench para o Receptor UART (RX).
#     Atua como um Transmissor Virtual (Driver) que injeta sinais na porta 'rx_serial'
#     e verifica se o módulo decodifica o byte corretamente e pulsa 'rx_dv'.
#
# =====================================================================================================

import cocotb                                          # Biblioteca principal do cocotb
from cocotb.clock import Clock                         # Para gerar clock
from cocotb.triggers import RisingEdge, Timer, First   # Para aguardar borda de clock e temporizações

# Utilitários compartilhados entre testbenches
from test_utils import log_header, log_info, log_success, log_error, log_console

# =====================================================================================================
# GOLDEN MODEL – UART Transmitter (Driver)
# =====================================================================================================
#
# Def. Formal: Para todo (a, b, opcode) ∈ Domínio_Especificado:
#    RTL(a, b, opcode) == GoldenModel(a, b, opcode)
#
# O modelo gera a forma de onda exata que um dispositivo externo enviaria:
# Idle(1) -> Start(0) -> D0..D7 -> Stop(1)

async def drive_uart_byte(dut, byte_val, cycles_per_bit, clk_period_ns):
    """
    Envia um byte serialmente para o pino rx_serial do DUT.
    """
    bit_time_ns = cycles_per_bit * clk_period_ns

    # 1. Start Bit (Linha em Low)
    dut.rx_serial.value = 0
    await Timer(bit_time_ns, unit="ns")

    # 2. Dados (8 bits, LSB primeiro)
    for i in range(8):
        bit = (byte_val >> i) & 1
        dut.rx_serial.value = bit
        await Timer(bit_time_ns, unit="ns")

    # 3. Stop Bit (Linha em High)
    dut.rx_serial.value = 1
    await Timer(bit_time_ns, unit="ns")

# =====================================================================================================
# TESTE PRINCIPAL
# =====================================================================================================

@cocotb.test()
async def test_uart_rx(dut):

    # Testebench para o Receptor UART (RX)

    log_header("Teste do Receptor UART (RX)")

    # Configuração
    CLK_PERIOD_NS = 10
    CYCLES_PER_BIT = 868 # 100MHz / 115200

    # Inicia o Clock
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

    # Vetores de Teste
    test_vectors = [
        0x41, # 'A'
        0x55, # Padrão alternado
        0xFF, # Tudo 1 (exceto start bit)
        0x00, # Tudo 0 (exceto stop bit)
        0x7B, # '{'
    ]

    # Reset e Inicialização
    log_info("Inicializando...")
    
    # Importante: A linha serial deve começar em IDLE (High) antes do Reset
    dut.rx_serial.value = 1 
    dut.rst.value = 1
    
    # Aguarda alguns ciclos de clock
    for _ in range(5):
        await RisingEdge(dut.clk)
        
    # Libera o Reset
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    log_info("Reset liberado. Linha RX em Idle.")

    # Loop de Teste
    for byte_to_send in test_vectors:
        
        # Indicação do Byte Enviado
        log_console(f"Injetando Byte: 0x{byte_to_send:02X}")

        # 1. Inicia o Driver em paralelo (Environment)
        # O driver vai manipular o pino rx_serial enquanto o teste observa a saída
        driver_task = cocotb.start_soon(drive_uart_byte(dut, byte_to_send, CYCLES_PER_BIT, CLK_PERIOD_NS))

        # 2. Monitoramento (Scoreboard)
        # Aguardamos o sinal 'rx_dv' (Data Valid) subir.
        # Adicionamos um Timeout para garantir que o teste não trave se o RX falhar.
        
        # O tempo esperado é aprox: (1 Start + 8 Data + 1 Stop) * bit_time
        # Damos uma margem de segurança de +20%
        expected_time_ns = 10 * CYCLES_PER_BIT * CLK_PERIOD_NS
        timeout_ns = int(expected_time_ns * 1.5)

        # Usamos triggers para esperar DV ou Timeout
        trig_dv = RisingEdge(dut.rx_dv)
        trig_timeout = Timer(timeout_ns, unit="ns")

        result = await First(trig_dv, trig_timeout)

        # 3. Verificação
        if result == trig_timeout:
            log_error("TIMEOUT: O sinal rx_dv não subiu dentro do tempo esperado.")
            log_error("Possível causa: Baud rate incorreto ou máquina de estados travada.")
            assert False, "Timeout esperando rx_dv"
        
        else:
            # Se chegou aqui, rx_dv subiu. Vamos ler o dado.
            # Nota: O dado deve estar estável enquanto rx_dv é 1.
            received_data = int(dut.rx_data.value)
            
            if received_data != byte_to_send:
                log_error("DIVERGÊNCIA DE DADOS")
                log_error(f"Enviado (Driver): 0x{byte_to_send:02X}")
                log_error(f"Decodificado (RX): 0x{received_data:02X}")
                assert False, "Mismatch de dados no RX"
            else:
                log_info(f"Sucesso: 0x{received_data:02X} capturado corretamente")

        # 4. Aguarda o fim da transmissão física (Driver) e um tempo de guarda
        await driver_task
        await Timer(2000, unit="ns") 

    log_success(f"Receptor UART validado com sucesso ({len(test_vectors)} vetores).")