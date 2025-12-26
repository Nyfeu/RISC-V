# ==========================================================================================
#                             RISC-V PROJECT CONFIGURATION
# ==========================================================================================
# Este makefile coordena a compilação de hardware (VHDL), software (C/ASM) e testes (COCOTB)
# ==========================================================================================

# ==========================================================================================
#                                 ESTRUTURA DE DIRETÓRIOS
# ==========================================================================================

# Diretório de Build (saídas de compilação)
BUILD_DIR          = build

# Estrutura de Hardware (RTL)
PKG_DIR            = pkg
RTL_DIR            = rtl
CORE_DIR           = $(RTL_DIR)/core
SOC_DIR            = $(RTL_DIR)/soc
PERIPS_DIR         = $(RTL_DIR)/perips
CORE_COMMON        = $(CORE_DIR)/common

# Estrutura de Simulação (Testbenches e Wrappers)
SIM_DIR            = sim
SIM_CORE_DIR       = $(SIM_DIR)/core
SIM_CORE_COMMON    = $(SIM_CORE_DIR)/common
SIM_PERIPS_DIR     = $(SIM_DIR)/perips
SIM_SOC_DIR        = $(SIM_DIR)/soc
SIM_COMMON_DIR     = $(SIM_DIR)/common

# Estrutura de Software (Apps e Bootloader)
SW_DIR             = sw
SW_APPS_DIR        = $(SW_DIR)/apps
SW_BOOT_DIR        = $(SW_DIR)/platform/bootloader
SW_LINKER_DIR      = $(SW_DIR)/platform/linker
SW_STARTUP_DIR     = $(SW_DIR)/platform/startup

# ==========================================================================================
#                                  FERRAMENTAS E COMPILADORES
# ==========================================================================================

# RISC-V GCC Toolchain
CC                 = riscv32-unknown-elf-gcc
OBJCOPY            = riscv32-unknown-elf-objcopy

# Compilação C/Assembly
CFLAGS             = -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles
OBJCOPY_FLAGS      = -O verilog

# Simulação e Visualização
GTKWAVE            = gtkwave
PYTHON             = python3

# COCOTB - CoSimulation Testbench Framework
COCOTB_SIM         = ghdl
COCOTB_SIMULATOR   = $(COCOTB_SIM)
COCOTB_BUILD       = $(BUILD_DIR)/cocotb
COCOTB_PYTHONPATH  = $(SIM_CORE_DIR):$(SIM_SOC_DIR):$(SIM_PERIPS_DIR):$(SIM_COMMON_DIR)

# ==========================================================================================
#                              SELEÇÃO DINÂMICA DE CORE
# ==========================================================================================

# Seleciona a arquitetura do processador (CORE)
# Valores válidos: single_cycle, multi_cycle ou qualquer subdiretório em rtl/core/
CORE ?= single_cycle

# Valida se o diretório do CORE existe
CORE_PATH           = $(CORE_DIR)/$(CORE)
CORE_EXISTS         = $(wildcard $(CORE_PATH))
ifeq ($(CORE_EXISTS),)
    $(error Arquitetura '$(CORE)' inválida! O diretório $(CORE_PATH) não existe.)
endif

# Caminhos dinâmicos baseados no CORE selecionado
CORE_CURRENT        = $(CORE_PATH)
SIM_CORE_CURRENT    = $(SIM_CORE_DIR)/$(CORE)
BUILD_CORE_DIR      = $(COCOTB_BUILD)/$(CORE)

# ==========================================================================================
#                                FONTES VHDL (Automático)
# ==========================================================================================

# Pacotes VHDL (compilados primeiro - Dependências)
PKG_SRCS           = $(wildcard $(PKG_DIR)/*.vhd) $(CORE_CURRENT)/riscv_uarch_pkg.vhd

# RTLs comuns a todos os designs (CORE/common)
COMMON_SRCS        = $(wildcard $(CORE_COMMON)/*/*.vhd) $(wildcard $(CORE_COMMON)/*.vhd)

# RTLs específicas da arquitetura selecionada (CORE/<arquitetura>)
CORE_SRCS          = $(wildcard $(CORE_CURRENT)/*.vhd)

# SoC RTL (Barramentos, Memórias, Integração de componentes)
SOC_SRCS           = $(wildcard $(SOC_DIR)/*.vhd)

# Periféricos RTL (UART, etc - em subdiretórios)
PERIPS_SRCS        = $(wildcard $(PERIPS_DIR)/*/*.vhd)

# Wrappers de Simulação - comuns
SIM_WRAPPERS_COMMON = $(wildcard $(SIM_CORE_DIR)/wrappers/*.vhd)

# Wrappers de Simulação - específicos da arquitetura
SIM_WRAPPERS_CORE  = $(wildcard $(SIM_CORE_CURRENT)/wrappers/*.vhd)

# Wrappers de SoC
SIM_WRAPPERS_SOC   = $(wildcard $(SIM_SOC_DIR)/wrappers/*.vhd)

# Todos os wrappers
SIM_WRAPPERS       = $(SIM_WRAPPERS_COMMON) $(SIM_WRAPPERS_CORE) $(SIM_WRAPPERS_SOC)

# Todos os fontes VHDL (ordem importa: Packages → Common → Core → SoC → Periféricos → Wrappers)
ALL_RTL_SRCS       = $(PKG_SRCS) $(COMMON_SRCS) $(CORE_SRCS) $(SOC_SRCS) $(PERIPS_SRCS) $(SIM_WRAPPERS)

# ==========================================================================================
#                               TARGETS PADRÃO E AJUDA
# ==========================================================================================

.PHONY: all
all:
	@echo " "
	@echo " "
	@echo "     ██████╗ ██╗███████╗ ██████╗ ██╗   ██╗    "
	@echo "     ██╔══██╗██║██╔════╝██╔════╝ ██║   ██║    "
	@echo "     ██████╔╝██║███████╗██║█████╗██║   ██║    "
	@echo "     ██╔══██╗██║╚════██║██║╚════╝╚██╗ ██╔╝    "
	@echo "     ██║  ██║██║███████║╚██████╗  ╚████╔╝     "
	@echo "     ╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝   ╚═══╝      "
	@echo " "
	@echo "========================================================================================================="
	@echo "                        RISC-V Project Build System                      "
	@echo "========================================================================================================="
	@echo " "
	@echo " 📦 SOFTWARE COMPILATION"
	@echo " ────────────────────────────────────────────────────────────────────────────────────────────────────────"
	@echo "   make sw SW=<prog>                                            Compilar aplicação C/ASM (em sw/apps)"
	@echo "   make boot                                                    Compilar bootloader (em sw/bootloader)"
	@echo "   make list-apps                                               Listar aplicações disponíveis"
	@echo " "
	@echo " 🧪 HARDWARE TESTING & SIMULATION"
	@echo " ────────────────────────────────────────────────────────────────────────────────────────────────────────"
	@echo "   make cocotb [CORE=<core>] TEST=<test> TOP=<top> [SW=<prog>]  Rodar teste COCOTB"
	@echo "   make cocotb TEST=<test> TOP=<top>                            Teste de componente (unit)"
	@echo "   make list-tests [CORE=<core>]                                Listar testes disponíveis"
	@echo " "
	@echo " 📊 VISUALIZATION & DEBUG"
	@echo " ────────────────────────────────────────────────────────────────────────────────────────────────────────"
	@echo "   make view TEST=<test>                                        Abrir ondas (VCD) no GTKWave"
	@echo " "
	@echo " 🧹 MAINTENANCE"
	@echo " ────────────────────────────────────────────────────────────────────────────────────────────────────────"
	@echo "   make clean                                                   Limpar diretório de build"
	@echo " "
	@echo "========================================================================================================="
	@echo " "
	@echo " CONFIGURAÇÃO PADRÃO:"
	@echo " ────────────────────────────────────────────────────────────────────────────────────────────────────────"
	@echo "   CORE = $(CORE)  (Alterar com CORE=<nome>)"
	@echo "   Arquiteturas disponíveis: single_cycle, multi_cycle"
	@echo " "
	@echo " EXEMPLOS DE USO:"
	@echo " ────────────────────────────────────────────────────────────────────────────────────────────────────────"
	@echo "   # Compilar aplicação hello"
	@echo "   $$ make sw SW=hello"
	@echo " "
	@echo "   # Compilar e rodar teste do datapath com single_cycle"
	@echo "   $$ make cocotb CORE=single_cycle TEST=test_datapath TOP=datapath_wrapper"
	@echo " "
	@echo "   # Compilar e rodar teste do datapath com multi_cycle"
	@echo "   $$ make cocotb CORE=multi_cycle TEST=test_datapath TOP=datapath_wrapper"
	@echo " "
	@echo "   # Rodar teste com software carregado na memória"
	@echo "   $$ make cocotb CORE=single_cycle TEST=test_processor TOP=processor_top SW=hello"
	@echo " "
	@echo "   # Visualizar ondas da última simulação"
	@echo "   $$ make view TEST=test_datapath"
	@echo " "
	@echo "========================================================================================================="
	@echo " "

# ==========================================================================================
#                            SOFTWARE COMPILATION TARGETS
# ==========================================================================================

.PHONY: sw boot list-apps

# Compilação de Apps (C e Assembly) --------------------------------------------------------

$(BUILD_DIR)/sw/%.hex: $(SW_APPS_DIR)/%.s
	@mkdir -p $(@D)
	@echo ">>> 🔨 [SW] Compilando Assembly: $<"
	@$(CC) $(CFLAGS) -T $(LINK_SCRIPT) -o $(patsubst %.hex,%.elf,$(@)) $<
	@echo ">>> 📦 [SW] Gerando HEX: $@"
	@$(OBJCOPY) $(OBJCOPY_FLAGS) $(patsubst %.hex,%.elf,$(@)) $(@)

$(BUILD_DIR)/sw/%.hex: $(SW_APPS_DIR)/%.c
	@mkdir -p $(@D)
	@echo ">>> 🔨 [SW] Compilando C: $<"
	@$(CC) $(CFLAGS) -T $(LINK_SCRIPT) -o $(patsubst %.hex,%.elf,$(@)) $(SW_STARTUP_DIR)/crt0.s $<
	@echo ">>> 📦 [SW] Gerando HEX: $@"
	@$(OBJCOPY) $(OBJCOPY_FLAGS) $(patsubst %.hex,%.elf,$(@)) $(@)
	@echo ">>> 💾 [SW] Gerando BIN: $(patsubst %.hex,%.bin,$(@))"
	@$(OBJCOPY) -O binary $(patsubst %.hex,%.elf,$(@)) $(patsubst %.hex,%.bin,$(@))

sw: $(BUILD_DIR)/sw/$(SW).hex

# Compilação do Bootloader (silenciosa para dependências)
boot-quiet:
	@$(MAKE) -s boot

# Compilação do Bootloader (verbose)
boot:
	@mkdir -p $(BUILD_DIR)/boot
	@echo ">>> 🔨 [BOOT] Compilando bootloader..."
	@$(CC) $(CFLAGS) -T $(SW_LINKER_DIR)/boot.ld -o $(BUILD_DIR)/boot/bootloader.elf \
		$(SW_BOOT_DIR)/boot.c $(SW_STARTUP_DIR)/start.s
	@echo ">>> 📦 [BOOT] Extraindo binário puro..."
	@$(OBJCOPY) -O binary $(BUILD_DIR)/boot/bootloader.elf $(BUILD_DIR)/boot/bootloader.bin
	@echo ">>> 💾 [BOOT] Gerando HEX (32-bit word aligned)..."
	@od -An -t x4 -v -w4 $(BUILD_DIR)/boot/bootloader.bin > $(BUILD_DIR)/boot/bootloader.hex

# Listar aplicações disponíveis
list-apps:
	@echo " "
	@echo "📱 Aplicações disponíveis em $(SW_APPS_DIR):"
	@echo "────────────────────────────────────────────"
	@ls -1 $(SW_APPS_DIR) | sed 's/\.[^.]*$$//' | sort | uniq | sed 's/^/  • /'
	@echo " "

# ==========================================================================================
#                          COCOTB SIMULATION TARGETS
# ==========================================================================================

# Valores padrão (podem ser sobrescritos na linha de comando)
TOP  ?= processor_top
TEST ?= test_processor

# Detectar qual linker script usar baseado no TOP/TEST
# Se for SoC (soc_top, test_soc_top, test_boot_rom, test_bus_interconnect, etc), usar link_soc.ld
# Senão, usar link.ld para processor_top
ifeq ($(filter soc% boot% bus_interconnect% dual_port_ram% memory_system%,$(TOP)$(TEST)),)
    LINK_SCRIPT = $(SW_LINKER_DIR)/link.ld
else
    LINK_SCRIPT = $(SW_LINKER_DIR)/link_soc.ld
endif

.PHONY: cocotb test-datapath test-all list-tests

# Target genérico para COCOTB
# Se SW está definido, compila o software antes
# Se TOP/TEST menciona boot, compila o bootloader também
cocotb: $(if $(SW),$(BUILD_DIR)/sw/$(SW).hex) $(if $(filter boot%,$(TOP)$(TEST)),boot-quiet)
	@mkdir -p $(BUILD_CORE_DIR)
	@echo " "
	@echo "======================================================================"
	@echo ">>> 🧪 COCOTB - Iniciando Testes Automatizados"
	@echo "======================================================================"
	@echo " "
	@echo ">>> 🏗️  Arquitetura  :   $(CORE)"
	@echo ">>> 🎯 Top Level    :   $(TOP)"
	@echo ">>> 📂 Testbench    :   $(TEST)"
	@echo ">>> 💾 Software     :   $(if $(SW),$(SW).hex,nenhum)"
	@echo " "
	@echo "======================================================================"
	@echo " "
	@export COCOTB_ANSI_OUTPUT=1; \
	export COCOTB_RESULTS_FILE=$(BUILD_CORE_DIR)/results.xml; \
	export PROGRAM_PATH=$(if $(SW),$(BUILD_DIR)/sw/$(SW).hex,); \
	$(MAKE) -s -f $(shell cocotb-config --makefiles)/Makefile.sim \
		SIM=$(COCOTB_SIMULATOR) \
		TOPLEVEL_LANG=vhdl \
		TOPLEVEL=$(TOP) \
		COCOTB_TEST_MODULES=$(TEST) \
		WORKDIR=$(BUILD_CORE_DIR) \
		VHDL_SOURCES="$(ALL_RTL_SRCS)" \
		GHDL_ARGS="-fsynopsys" \
		PYTHONPATH=$(COCOTB_PYTHONPATH):$(SIM_CORE_COMMON):$(SIM_CORE_CURRENT) \
		SIM_ARGS="--vcd=$(BUILD_CORE_DIR)/wave-$(TEST).vcd --ieee-asserts=disable-at-0" \
		SIM_BUILD=$(BUILD_CORE_DIR) \
		2>&1 | grep -v "vpi_iterate returned NULL"
	@echo " "
	@echo ">>> ✅ Teste concluído"
	@echo ">>> 🌊 Ondas salvas em: $(BUILD_CORE_DIR)/wave-$(TEST).vcd"
	@echo ">>> 📋 Resultados em:   $(BUILD_CORE_DIR)/results.xml"
	@echo " "

# Listar testes disponíveis
list-tests:
	@echo "🔎 Testes disponíveis em $(SIM_CORE_CURRENT):"
	@echo "────────────────────────────────────────────"
	@ls -1 $(SIM_CORE_CURRENT)/test_*.py 2>/dev/null | sed 's/.*\///; s/\.py$$//' | sed 's/^/  • /'
	@echo " "
	@echo "🧪 Testes disponíveis em $(SIM_PERIPS_DIR):"
	@echo "────────────────────────────────────────────"
	@ls -1 $(SIM_PERIPS_DIR)/test_*.py 2>/dev/null | sed 's/.*\///; s/\.py$$//' | sed 's/^/  • /'
	@echo " "
	@echo "🎯 Testes disponíveis em $(SIM_SOC_DIR):"
	@echo "────────────────────────────────────────────"
	@ls -1 $(SIM_SOC_DIR)/test_*.py 2>/dev/null | sed 's/.*\///; s/\.py$$//' | sed 's/^/  • /'
	@echo " "

# ==========================================================================================
#                        VISUALIZATION & DEBUG TARGETS
# ==========================================================================================

.PHONY: view

view:
	@echo ">>> 📊 Abrindo GTKWave..."
	@if [ -f $(BUILD_CORE_DIR)/wave-$(TEST).vcd ]; then \
		echo ">>> 🌊 Arquivo: $(BUILD_CORE_DIR)/wave-$(TEST).vcd"; \
		$(GTKWAVE) $(BUILD_CORE_DIR)/wave-$(TEST).vcd 2>/dev/null; \
	else \
		echo ">>> ❌ Erro: Nenhuma onda VCD encontrada para TEST=$(TEST) e CORE=$(CORE)"; \
		echo ">>> 💡 Dica: Execute 'make cocotb CORE=$(CORE) TEST=$(TEST)' primeiro"; \
	fi

# ==========================================================================================
#                           CLEANUP & MAINTENANCE
# ==========================================================================================

.PHONY: clean distclean

clean:
	@echo ">>> 🧹 Limpando diretório de build..."
	@rm -rf $(BUILD_DIR) *.cf
	@echo ">>> ✅ Limpeza concluída"

distclean: clean
	@echo ">>> 🗑️  Removendo todos os artefatos de simulação..."
	@find . -name "*.vcd" -delete
	@find . -name "*.vvp" -delete
	@find . -name "work" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo ">>> ✅ Limpeza completa concluída"

# ==========================================================================================
#                                  PHONY TARGETS
# ==========================================================================================

.PHONY: all cocotb sw boot clean list-apps list-tests view

# ==========================================================================================