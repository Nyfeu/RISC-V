# 💻 FPGA Implementation

Arquivos específicos para síntese em hardware físico (usando Nexys 4).

## Conteúdo

- `constraints/`: Arquivos de pinagem.
    - `pins.xdc` (Nexys 4 - Xilinx Vivado)
    - Aqui são mapeados os sinais CLK, RESET, UART_TX, UART_RX e LEDs para os pinos físicos da placa.

- `scripts/`: Scripts TCL para automatizar a síntese e upload na FPGA.
