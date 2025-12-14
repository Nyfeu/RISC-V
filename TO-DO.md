# ✅ Checklist do SoC RISC-V

Este documento rastreia o progresso da migração de um **Core** isolado para um **SoC (System-on-Chip)** completo, capaz de bootar via UART.

## 1. Reestruturação do Repositório
- [x] Criar a estrutura de diretórios (`rtl/core`, `rtl/soc`, `rtl/perips`, etc.).

- [x] Mover arquivos `.vhd` do processador antigo para `rtl/core`.

- [x] Mover arquivos de teste unitários para `sim/core`.

- [x] Atualizar o **makefile** para incluir os novos caminhos de fonte.

- [x] Verificar se `make sim TB=processor_top_tb` ainda funciona após a mudança.

## 2. Definição do Sistema (Architecture)

- [ ] Definir mapa de memória em `sw/common/memory_map.h`.
    - `0x00000000`: Boot ROM (bootloader)
    - `0x10000000`: Periféricos (UART, GPIO)
    - `0x80000000`: Main RAM

- [ ] Atualizar Linker Script (`sw/common/link.ld`) para apontar RAM para `0x80000000`.

## 3. Implementação de Hardware (RTL)

### SoC Infrastructure (`rtl/soc/`)

- [ ] Implementar `bus_interconnect.vhd`:
    - Decodificar endereços (`0x0`, `0x1`, `0x8`).

    | Endereço Inicial | Tamanho | Dispositivo | Descrição |
    | :-: | :-: | :-: | :-- |
    | `0x00000000` | 4 KB | Boot ROM | Código de inicialização (Read-Only) | 
    | `0x10000000` | 4 KB | Periféricos | Registradores de IO (UART, LEDs) | 
    | `0x80000000` | 4 KB | Main RAM | Memória de Instrução e Dados do Usuário | 

    - Roteamento de sinais `We`, `Addr`, `Data`.
- [ ] Implementar `dual_port_ram.vhd`:
    - Porta A (Instrução), Porta B (Dados).
    - Capacidade de carregar arquivo `.hex` inicial.
- [ ] Implementar `boot_rom.vhd`:
    - Array constante com o código do **bootloader**.

### Periféricos (`rtl/perips/`)

- [ ] Implementar `gpio_controller.vhd` (para LEDs).
- [ ] Implementar `uart_controller.vhd` (Tx e Rx simples com polling).

### Top Level

- [ ] Criar soc_top.vhd:
    - Instanciar `processor_top` (Core).
    - Instanciar `bus_interconnect`.
    - Instanciar Memorias e Periféricos.
    - Mux no barramento de instrução (BootROM vs RAM).

## 4. Software e Firmware

- [ ] Escrever `sw/bootloader/bootloader.s`:
    - Código que roda em 0x0000.
    - Inicialmente: Apenas pula para `0x8000`.
    - Futuro: Lê da UART e grava na RAM.

- [ ] Atualizar `sw/apps/hello.c` e `test_all.s`:
    - Usar novos endereços de periféricos.
    - Recompilar para gerar HEX compatível com a Main RAM.

## 5. Simulação do Sistema

- [ ] Criar `sim/soc/soc_tb.vhd`:
    - Instanciar `soc_top`.
    - Simular clock e reset.
    - Simular entrada serial (RX) injetando dados de um arquivo.
- [ ] Validar execução do "Hello World" imprimindo no console do simulador via VHDL TextIO.

## 6. FPGA (Síntese)

- [ ] Criar arquivo de constraints (`.xdc`) mapeando pinos (Clock, Reset, LEDs, UART TX/RX).

- [ ] Gerar Bitstream e testar na placa.