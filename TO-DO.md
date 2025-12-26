# Implementação RISC-V Multi-Cycle Modular

Esta seção guia a refatoração da arquitetura Single-Cycle para Multi-Cycle (RV32I), com foco na modularização e isolamento de componentes.

## 1. 🏗️ Preparação e Estrutura
- [ ] **Limpeza Inicial**:
    - [ ] Garantir que a pasta `rtl/core/multi_cycle/` esteja limpa (fazer backup do que já existe se necessário).
- [ ] **Revisão de Dependências Comuns**:
    - [ ] Confirmar que `rtl/core/common/` contém: `alu.vhd`, `reg_file.vhd`, `imm_gen.vhd` (não precisamos reescrever estes).

## 2. 🔌 Modificações no Datapath (`datapath.vhd`)
*O Datapath Multi-Cycle precisa de registradores "invisíveis" ao programador para guardar dados entre os estados do clock.*

- [ ] **Instanciar Registradores Internos (Barreiras)**:
    - [ ] **IR (Instruction Register)**: Guarda a instrução lida na fase de Fetch. (Enable controlado por `IRWrite`).
    - [ ] **MDR (Memory Data Register)**: Guarda o dado vindo da memória (Load).
    - [ ] **Reg A e Reg B**: Guardam os valores lidos do Banco de Registradores (`rs1` e `rs2`).
    - [ ] **ALUOut**: Guarda o resultado da ALU para ser usado no próximo ciclo (ex: endereço de memória ou WriteBack).
- [ ] **Atualizar Multiplexadores (MUXs)**:
    - [ ] **MUX A (Entrada A da ALU)**: Adicionar opção para selecionar `PC` (para cálculo de branch/jal) ou `Reg A`.
    - [ ] **MUX B (Entrada B da ALU)**: Adicionar opções para `Reg B`, `4` (incremento PC), `Imediato`, ou `Shifts`.
    - [ ] **MUX MemToReg**: Agora deve selecionar entre `ALUOut` (resultados R-Type/I-Type) ou `MDR` (Loads).
- [ ] **Lógica do PC**:
    - [ ] Alterar o PC para ser um registrador com *Enable* (`PCWrite` ou `PCWriteCond` vindo do controle).

## 3. 🧠 Controle Modular (`control_unit/`)
*Em vez de um arquivo gigante, vamos dividir a FSM em três entidades menores conectadas por um wrapper.*

### 3.1. `main_fsm.vhd` (Máquina de Estados)
*Responsável apenas pelas transições de estados, sem gerar os sinais finais de controle.*
- [ ] Definir os Estados (Enum):
    - `S_FETCH`, `S_DECODE`
    - `S_EXEC_R`, `S_EXEC_I`, `S_JAL`, `S_JALR`, `S_BRANCH`
    - `S_MEM_ADDR`, `S_MEM_READ`, `S_MEM_WRITE`, `S_WB`
- [ ] Implementar Lógica de Próximo Estado (Process Combinacional):
    - Ler `Opcode`.
    - Transitar de `FETCH` -> `DECODE` -> [Execução Específica] -> [Memória/WB] -> `FETCH`.
- [ ] Implementar Lógica Sequencial:
    - Atualizar `CurrentState` na borda de subida do Clock.

### 3.2. `control_decoder.vhd` (Decodificador de Sinais)
*Recebe o Estado Atual e gera os sinais de controle para o Datapath.*
- [ ] Mapear saídas baseadas no **Estado Atual**:
    - [ ] **Estados de Busca**: Em `S_FETCH`, ligar `IRWrite`, `ALUSrcA=PC`, `ALUSrcB=4`, `PCWrite`.
    - [ ] **Estados de Execução**: Em `S_EXEC_R`, ligar `ALUSrcA=RegA`, `ALUSrcB=RegB`, etc.
    - [ ] **Estados de Memória**: Em `S_MEM_READ`, garantir que `IorD` (Instruction or Data) selecione o endereço da ALUOut.
    - [ ] **Estados de WriteBack**: Controlar `RegWrite` e `MemToReg`.

### 3.3. `alu_decoder.vhd` (ALU Control)
*Pode ser reutilizado ou adaptado do Single-Cycle, mas deve estar separado.*
- [ ] Receber `ALUOp` (gerado pelo `control_decoder`) e campos `Funct3/Funct7`.
- [ ] Gerar `ALUControl` (4 bits) para a ALU.

### 3.4. `control_top.vhd` (Wrapper)
- [ ] Instanciar e conectar: `main_fsm`, `control_decoder` e `alu_decoder`.
- [ ] Expor apenas as portas necessárias para o Datapath.

## 4. 🔗 Top Level (`processor_top.vhd`)
- [ ] Conectar o novo `control_top` ao `datapath` modificado.
- [ ] **Gerenciamento de Memória**:
    - [ ] Implementar MUX externo (ou interno ao Datapath) para unificar o barramento de endereços, já que a maioria das implementações Multi-Cycle usa uma memória unificada (Princeton) ou arbitra o acesso.
    - *Nota: Se mantivermos IMem e DMem separadas no testbench, o MUX seleciona qual endereço vai para qual porta baseado no estado.*

## 5. 🧪 Verificação Passo-a-Passo
- [ ] **Teste 1: Fetch & Decode**:
    - Rodar simulação curta. Verificar se `IR` carrega a instrução correta e se a FSM vai de `FETCH` para `DECODE`.
- [ ] **Teste 2: Instruções Tipo-R (ALU)**:
    - Testar `ADD`, `SUB`. Verificar se os registradores `A`, `B` e `ALUOut` capturam os dados corretamente nos ciclos intermediários.
- [ ] **Teste 3: Loads e Stores**:
    - Verificar se o endereço é calculado num ciclo, a memória acessada no outro e o WB feito no terceiro.
- [ ] **Teste 4: Branches e Jumps**:
    - Verificar se o PC é atualizado corretamente (não esquecer de `PCWriteCond` para branches).
- [ ] **Teste Final**:
    - Rodar `fibonacci` e `hello_world`.

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
- [x] Atualizar Linker Script (`sw/common/link_soc.ld`) para apontar RAM para `0x80000000`.

## 3. Implementação de Hardware (RTL)

### SoC Infrastructure (`rtl/soc/`)

- [x] Implementar `bus_interconnect.vhd`:
    - Decodificar endereços (`0x0`, `0x1`, `0x8`).

    | Endereço Inicial | Tamanho | Dispositivo | Descrição |
    | :-: | :-: | :-: | :-- |
    | `0x00000000` | 4 KB | Boot ROM | Código de inicialização (Read-Only) | 
    | `0x10000000` | 4 KB | Periféricos | Registradores de IO (UART, LEDs) | 
    | `0x80000000` | 4 KB | Main RAM | Memória de Instrução e Dados do Usuário | 

    - Roteamento de sinais `We`, `Addr`, `Data`.
- [x] Implementar `dual_port_ram.vhd`:
    - Porta A (Instrução), Porta B (Dados).
- [x] Implementar `boot_rom.vhd`:
    - Array constante com o código do **bootloader**.
    - Capacidade de carregar a memória RAM.

### Periféricos (`rtl/perips/`)

- [ ] Implementar `gpio_controller.vhd` (para LEDs).
- [x] Implementar `uart_controller.vhd` (Tx e Rx simples).

### Top Level

- [ ] Criar soc_top.vhd:
    - Instanciar `processor_top` (Core).
    - Instanciar `bus_interconnect`.
    - Instanciar Memorias e Periféricos.
    - Mux no barramento de instrução (BootROM vs RAM).

## 4. Software e Firmware

- [x] Escrever `sw/bootloader/bootloader.s`:
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
- [ ] Criar arquivo de automatização para sintetização e upload `build.tcl`.
- [ ] Adicionar FPGA ao workflow (`makefile`)
- [ ] Gravar e testar na placa.