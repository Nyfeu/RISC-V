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

# Estrutura de Simulação (Testbenches e Wrappers)
SIM_DIR            = sim
SIM_CORE_DIR       = $(SIM_DIR)/core
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
#                                FONTES VHDL (Automático)
# ==========================================================================================

# Pacotes VHDL (compilados primeiro - Dependências)
PKG_SRCS           = \
	$(PKG_DIR)/riscv_pkg.vhd \
	$(PKG_DIR)/memory_loader_pkg.vhd

# Core RTL (Processador RISC-V - Caminho de dados, Controle, ALU, etc)
CORE_SRCS          = \
	$(CORE_DIR)/alu.vhd \
	$(CORE_DIR)/alu_control.vhd \
	$(CORE_DIR)/imm_gen.vhd \
	$(CORE_DIR)/reg_file.vhd \
	$(CORE_DIR)/load_unit.vhd \
	$(CORE_DIR)/store_unit.vhd \
	$(CORE_DIR)/decoder.vhd \
	$(CORE_DIR)/branch_unit.vhd \
	$(CORE_DIR)/control.vhd \
	$(CORE_DIR)/datapath.vhd \
	$(CORE_DIR)/processor_top.vhd

# SoC RTL (Barramentos, Memórias, Integração de componentes)
SOC_SRCS           = $(wildcard $(SOC_DIR)/*.vhd)

# Periféricos RTL (UART, etc - em subdiretórios)
PERIPS_SRCS        = $(wildcard $(PERIPS_DIR)/*/*.vhd)

# Wrappers de Simulação (Adaptadores para testbenches COCOTB)
SIM_WRAPPERS       = $(wildcard $(SIM_CORE_DIR)/wrappers/*.vhd)

# Todos os fontes VHDL (ordem importa: Packages → Core → SoC → Periféricos → Wrappers)
ALL_RTL_SRCS       = $(PKG_SRCS) $(CORE_SRCS) $(SOC_SRCS) $(PERIPS_SRCS) $(SIM_WRAPPERS)

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
	@echo "============================================================================================"
	@echo "                        RISC-V Project Build System                      "
	@echo "============================================================================================"
	@echo " "
	@echo " 📦 SOFTWARE COMPILATION"
	@echo " ─────────────────────────────────────────────────────────────────────────────────────────"
	@echo "   make sw SW=<prog>                              Compilar aplicação C/ASM (em sw/apps)"
	@echo "   make boot                                      Compilar bootloader (em sw/bootloader)"
	@echo "   make list-apps                                 Listar aplicações disponíveis"
	@echo " "
	@echo " 🧪 HARDWARE TESTING & SIMULATION"
	@echo " ─────────────────────────────────────────────────────────────────────────────────────────"
	@echo "   make cocotb TEST=<test> TOP=<top> [SW=<prog>]  Rodar teste COCOTB"
	@echo "   make cocotb TEST=<test> TOP=<top>              Teste de componente (unit)"
	@echo "   make list-tests                                Listar testes disponíveis"
	@echo " "
	@echo " 📊 VISUALIZATION & DEBUG"
	@echo " ─────────────────────────────────────────────────────────────────────────────────────────"
	@echo "   make view TEST=<test>                          Abrir ondas (VCD) no GTKWave"
	@echo " "
	@echo " 🧹 MAINTENANCE"
	@echo " ─────────────────────────────────────────────────────────────────────────────────────────"
	@echo "   make clean                                     Limpar diretório de build"
	@echo " "
	@echo "============================================================================================"
	@echo " "
	@echo " EXEMPLOS DE USO:"
	@echo " ───────────────────────────────────────────────────────────────────────────────────────────"
	@echo "   # Compilar aplicação hello"
	@echo "   $$ make sw SW=hello"
	@echo " "
	@echo "   # Compilar e rodar teste do datapath"
	@echo "   $$ make cocotb TEST=test_datapath TOP=datapath_wrapper"
	@echo " "
	@echo "   # Rodar teste com software carregado na memória"
	@echo "   $$ make cocotb TEST=test_processor TOP=processor_top SW=hello"
	@echo " "
	@echo "   # Visualizar ondas da última simulação"
	@echo "   $$ make view TEST=test_datapath"
	@echo " "
	@echo "============================================================================================"
	@echo " "

# ==========================================================================================
#                            SOFTWARE COMPILATION TARGETS
# ==========================================================================================

.PHONY: sw boot list-apps

# Compilação de Apps (C e Assembly) --------------------------------------------------------

$(BUILD_DIR)/sw/%.hex: $(SW_APPS_DIR)/%.s
	@mkdir -p $(@D)
	@echo ">>> 🔨 [SW] Compilando Assembly: $<"
	@$(CC) $(CFLAGS) -T $(SW_LINKER_DIR)/link.ld -o $(patsubst %.hex,%.elf,$(@)) $<
	@echo ">>> 📦 [SW] Gerando HEX: $@"
	@$(OBJCOPY) $(OBJCOPY_FLAGS) $(patsubst %.hex,%.elf,$(@)) $(@)

$(BUILD_DIR)/sw/%.hex: $(SW_APPS_DIR)/%.c
	@mkdir -p $(@D)
	@echo ">>> 🔨 [SW] Compilando C: $<"
	@$(CC) $(CFLAGS) -T $(SW_LINKER_DIR)/link.ld -o $(patsubst %.hex,%.elf,$(@)) $(SW_STARTUP_DIR)/crt0.s $<
	@echo ">>> 📦 [SW] Gerando HEX: $@"
	@$(OBJCOPY) $(OBJCOPY_FLAGS) $(patsubst %.hex,%.elf,$(@)) $(@)
	@echo ">>> 💾 [SW] Gerando BIN: $(patsubst %.hex,%.bin,$(@))"
	@$(OBJCOPY) -O binary $(patsubst %.hex,%.elf,$(@)) $(patsubst %.hex,%.bin,$(@))

sw: $(BUILD_DIR)/sw/$(SW).hex

# Compilação do Bootloader
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
TOP                ?= processor_top
TEST               ?= test_processor

.PHONY: cocotb test-datapath test-all list-tests

# Target genérico para COCOTB
cocotb:
	@mkdir -p $(COCOTB_BUILD)
	@echo " "
	@echo "======================================================================"
	@echo ">>> 🧪 COCOTB - Iniciando Testes Automatizados"
	@echo "======================================================================"
	@echo ">>> 🎯 Top Level:     $(TOP)"
	@echo ">>> 📂 Testbench:     $(TEST)"
	@echo ">>> 💾 Software:      $(if $(SW),$(SW).hex,nenhum)"
	@echo "======================================================================"
	@echo " "
	@export COCOTB_ANSI_OUTPUT=1; \
	export COCOTB_RESULTS_FILE=$(COCOTB_BUILD)/results.xml; \
	export PROGRAM_PATH=$(if $(SW),$(BUILD_DIR)/sw/$(SW).hex,); \
	$(MAKE) -s -f $(shell cocotb-config --makefiles)/Makefile.sim \
		SIM=$(COCOTB_SIMULATOR) \
		TOPLEVEL_LANG=vhdl \
		TOPLEVEL=$(TOP) \
		COCOTB_TEST_MODULES=$(TEST) \
		WORKDIR=$(COCOTB_BUILD) \
		VHDL_SOURCES="$(ALL_RTL_SRCS)" \
		GHDL_ARGS="-fsynopsys" \
		PYTHONPATH=$(COCOTB_PYTHONPATH) \
		SIM_ARGS="--vcd=$(COCOTB_BUILD)/wave-$(TEST).vcd --ieee-asserts=disable-at-0" \
		SIM_BUILD=$(COCOTB_BUILD) \
		2>&1 | grep -v "vpi_iterate returned NULL"
	@echo " "
	@echo ">>> ✅ Teste concluído"
	@echo ">>> 🌊 Ondas salvas em: $(COCOTB_BUILD)/wave-$(TEST).vcd"
	@echo ">>> 📋 Resultados em:   $(COCOTB_BUILD)/results.xml"
	@echo " "

# Listar testes disponíveis
list-tests:
	@echo "🔎 Testes disponíveis em $(SIM_CORE_DIR):"
	@echo "────────────────────────────────────────────"
	@ls -1 $(SIM_CORE_DIR)/test_*.py 2>/dev/null | sed 's/.*\///; s/\.py$$//' | sed 's/^/  • /'
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
	@if [ -f $(COCOTB_BUILD)/wave-$(TEST).vcd ]; then \
		echo ">>> 🌊 Arquivo: $(COCOTB_BUILD)/wave-$(TEST).vcd"; \
		$(GTKWAVE) $(COCOTB_BUILD)/wave-$(TEST).vcd 2>/dev/null; \
	else \
		echo ">>> ❌ Erro: Nenhuma onda VCD encontrada para TEST=$(TEST)"; \
		echo ">>> 💡 Dica: Execute 'make cocotb TEST=$(TEST)' primeiro"; \
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