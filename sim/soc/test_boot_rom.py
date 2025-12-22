# =====================================================================================================
# File: test_boot_rom.py
# =====================================================================================================
#
# >>> Descrição:
#     Testbench para a Boot ROM.
#     Compara palavra a palavra o conteúdo da ROM com o arquivo HEX original.
#     Considera ROM síncrona com latência de 1 ciclo.
#
# =====================================================================================================

import cocotb                               # Biblioteca principal do cocotb
from cocotb.clock import Clock              # Para gerar clock
from cocotb.triggers import RisingEdge      # Para aguardar borda de clock
import os                                   # Para manipulação de arquivos e caminhos

# Utilitários compartilhados (mesmo padrão do Load Unit)
from test_utils import log_header, log_info, log_success, log_error, log_console

# =====================================================================================================
# GOLDEN MODEL – Boot ROM
# =====================================================================================================
#
# Def. Formal: Para todo (a, b, opcode) ∈ Domínio_Especificado:
#    RTL(a, b, opcode) == GoldenModel(a, b, opcode)
#
# Trata-se da implementação de um modelo comportamental de referência, utilizado como oráculo de 
# verificação funcional.

def load_boot_rom_hex(filepath):
    """
    Carrega o arquivo HEX da Boot ROM para um dicionário indexado por palavra.
    """
    rom = {}

    try:
        with open(filepath, "r") as f:
            for idx, line in enumerate(f):
                line = line.strip()
                if line:
                    rom[idx] = int(line, 16)
    except FileNotFoundError:
        return None

    return rom

# =====================================================================================================
# FUNÇÃO DE VERIFICAÇÃO
# =====================================================================================================

async def verify_rom_word(dut, addr_word, expected_val):
    """
    Aplica endereço na ROM e verifica o dado retornado (1 ciclo depois).
    """

    # Calcula endereço em bytes
    byte_addr = addr_word * 4

    # Aplica endereço
    dut.addr_i.value = byte_addr

    # Aguarda ciclo de leitura síncrona
    await RisingEdge(dut.clk)

    # Lê saída
    actual_val = dut.data_o.value.to_unsigned()

    # Logging para debug dos dados lidos
    log_console(f"ROM Addr=0x{byte_addr:08X} | Exp=0x{expected_val:08X} | Got=0x{actual_val:08X}")

    # Comparação
    if actual_val != expected_val:
        log_error(f"FALHA na ROM")
        log_error(f"Endereço : 0x{byte_addr:08X}")
        log_error(f"Esperado : 0x{expected_val:08X}")
        log_error(f"Recebido : 0x{actual_val:08X}")
        assert False, "Divergência no conteúdo da Boot ROM"

# =====================================================================================================
# TESTE PRINCIPAL
# =====================================================================================================

@cocotb.test()
async def test_boot_rom(dut):

    # Teste da Boot ROM que compara o conteúdo da ROM com o arquivo HEX original

    log_header("Teste da Boot ROM")

    # Clock
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # Startup
    log_info("Aguardando inicialização da ROM...")
    for _ in range(5):
        await RisingEdge(dut.clk)

    # Localiza arquivo HEX
    hex_path = os.environ.get("HEX_PATH_FOR_TEST", "build/boot/bootloader.hex")

    if not os.path.exists(hex_path):
        hex_path = os.path.join(os.getcwd(), "../boot/bootloader.hex")

    rom_ref = load_boot_rom_hex(hex_path)

    if not rom_ref:
        log_error(f"Arquivo HEX não encontrado ou vazio: {hex_path}")
        assert False

    log_info(f"{len(rom_ref)} palavras carregadas do HEX")

    # Primeira leitura inválida
    dut.addr_i.value = 0
    await RisingEdge(dut.clk)

    # Verificação palavra a palavra
    for word_idx in range(len(rom_ref)):

        # A leitura retornada corresponde ao endereço anterior
        if word_idx > 0:
            expected_prev = rom_ref[word_idx - 1]
            await verify_rom_word(dut, word_idx, expected_prev)
        else:
            # Primeira palavra apenas preenche pipeline
            dut.addr_i.value = 0
            await RisingEdge(dut.clk)

    log_success("Boot ROM validada com sucesso")
