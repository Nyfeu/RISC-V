# ========================================================================================
#    Diretórios
# ========================================================================================

BUILD_DIR      = build
PKG_DIR        = pkg

# Estrutura de Hardware
RTL_DIR        = rtl
CORE_DIR       = $(RTL_DIR)/core
SOC_DIR        = $(RTL_DIR)/soc
PERIPS_DIR     = $(RTL_DIR)/perips

# Estrutura de Simulação
SIM_DIR        = sim
SIM_CORE_DIR   = $(SIM_DIR)/core
SIM_SOC_DIR    = $(SIM_DIR)/soc
SIM_COMMON_DIR = $(SIM_DIR)/common

# Estrutura de Software
SW_DIR         = sw
SW_APPS_DIR    = $(SW_DIR)/apps
SW_BOOT_DIR    = $(SW_DIR)/bootloader
SW_COMMON_DIR  = $(SW_DIR)/common

# ========================================================================================
#    Ferramentas
# ========================================================================================

# RISC-V GCC Toolchain ===================================================================

CC        = riscv32-unknown-elf-gcc
OBJCOPY   = riscv32-unknown-elf-objcopy

# Flags de Compilação C

CFLAGS    = -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -T sw/common/link.ld

# Flags de Geração de HEX

OBJFLAGS  = -O verilog

# GTKWave - Waveform Viewer ==============================================================

GTKWAVE   = gtkwave

# COCOTB - Coroutine-based Co-simulation Testbench =======================================

COCOTB_SIM        = ghdl
COCOTB_DIR        = $(SIM_DIR)
COCOTB_CORE_DIR   = $(SIM_CORE_DIR)
COCOTB_SOC_DIR    = $(SIM_SOC_DIR)
COCOTB_COMMON_DIR = $(SIM_COMMON_DIR)
COCOTB_BUILD      = $(BUILD_DIR)/cocotb
PYTHON            = python3

# ========================================================================================
# Fontes VHDL (Busca Automática)
# ========================================================================================

# Pacotes VHDL (Compilados primeiro)
PKG_SRCS := \
	$(PKG_DIR)/riscv_pkg.vhd \
	$(PKG_DIR)/memory_loader_pkg.vhd \
	#$(PKG_DIR)/soc_pkg.vhd 

# RTL Core (Processador) 
CORE_SRCS := \
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

# RTL SoC (Barramentos e Memórias)
SOC_SRCS  := $(wildcard $(SOC_DIR)/*.vhd)

# RTL Periféricos (Busca em subpastas, ex: rtl/perips/uart/file.vhd)
PERIPS_SRCS := $(wildcard $(PERIPS_DIR)/*/*.vhd)

# RTL Wrappers (para simulação)
SIM_WRAPPERS := $(SIM_CORE_DIR)/decoder_wrapper.vhd

# Lista completa de RTL
ALL_RTL_SRCS := $(CORE_SRCS) $(SOC_SRCS) $(PERIPS_SRCS) $(SIM_WRAPPERS) $(PKG_SRCS)

# ========================================================================================
#    Ajuda
# ========================================================================================

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
	@echo " "
	@echo "===================================================================="
	@echo "           Ambiente de Projeto RISC-V   "
	@echo "===================================================================="
	@echo " "
	@echo " make sw SW=<prog>        -> Compilar app de usuário (em sw/apps)"
	@echo " make boot                -> Compilar bootloader (em sw/bootloader)"
	@echo " make sim TB=<tb> [SW=..] -> Simular SoC (compila SW se definido)"
	@echo " make comp TB=<tb>        -> Simular Componente Unitário (sem SW)"
	@echo " make view TB=<tb>        -> Abrir ondas no GTKWave"
	@echo " make clean               -> Limpar diretório build"
	@echo " "
	@echo "===================================================================="

# ========================================================================================
#    Compilação de Software (APPS)
# ========================================================================================

.PHONY: sw
sw: $(BUILD_DIR)/sw/$(SW).hex

# Compilação de Assembly (.s)
$(BUILD_DIR)/sw/%.hex: $(SW_APPS_DIR)/%.s
	@mkdir -p $(@D)
	@echo ">>> [SW] Compilando Assembly: $<"
	@$(CC) $(CFLAGS) -o $(patsubst %.hex,%.elf,$(@)) $<
	@echo ">>> [SW] Gerando HEX: $@"
	@$(OBJCOPY) $(OBJFLAGS) $(patsubst %.hex,%.elf,$(@)) $(@)

# Compilação de C (.c) - Inclui start.s
$(BUILD_DIR)/sw/%.hex: $(SW_APPS_DIR)/%.c
	@mkdir -p $(@D)
	@echo ">>> [SW] Compilando C: $<"
	@$(CC) $(CFLAGS) -o $(patsubst %.hex,%.elf,$(@)) $(SW_APPS_DIR)/../start.s $<
	@echo ">>> [SW] Gerando HEX: $@"
	@$(OBJCOPY) $(OBJFLAGS) $(patsubst %.hex,%.elf,$(@)) $(@)

# ========================================================================================
#    Compilação do Bootloader (ZSBL)
# ========================================================================================

.PHONY: boot
boot:
	@echo ">>> Compilando Bootloader (TODO: Configurar flags de bootloader)"

# ========================================================================================
#    Visualização
# ========================================================================================

.PHONY: view
view:
	@echo ">>> Abrindo GTKWave..."
	@$(GTKWAVE) $(BUILD_DIR)/wave-$(TB).ghw 2>/dev/null &

# ========================================================================================
#    Limpeza
# ========================================================================================

.PHONY: clean
clean:
	@echo ">>> Limpando build..."
	@rm -rf $(BUILD_DIR) *.cf

# ========================================================================================
#    COCOTB Testbench (Integrado com SW)
# ========================================================================================

# Valores padrão caso não sejam informados na linha de comando
TOP  ?= processor_top
TEST ?= test_processor

.PHONY: cocotb
cocotb:
	$(if $(SW), @echo ">>> 🔨 Compilando Software: $(SW)"; $(MAKE) sw SW=$(SW), )
	@mkdir -p $(COCOTB_BUILD)
	@echo " "
	@echo "======================================================================"
	@echo ">>> 🧪 INICIANDO TESTES AUTOMATIZADOS (COCOTB) "
	@echo ">>> 🎯 TOP LEVEL: $(TOP)"
	@echo ">>> 📂 MÓDULO:    $(TEST)"
	@echo ">>> 💾 SOFTWARE:  $(if $(SW),$(SW).hex,nenhum)"
	@echo "======================================================================"
	@echo " "
	@export COCOTB_ANSI_OUTPUT=1; \
	export COCOTB_RESULTS_FILE=$(COCOTB_BUILD)/results.xml; \
	export PROGRAM_PATH=$(if $(SW),$(BUILD_DIR)/sw/$(SW).hex,); \
	$(MAKE) -s -f $(shell cocotb-config --makefiles)/Makefile.sim \
		SIM=$(COCOTB_SIM) \
		TOPLEVEL_LANG=vhdl \
		TOPLEVEL=$(TOP) \
		MODULE=$(TEST) \
		WORKDIR=$(COCOTB_BUILD) \
		VHDL_SOURCES="$(ALL_RTL_SRCS)" \
		PYTHONPATH=$(COCOTB_CORE_DIR):$(COCOTB_SOC_DIR):$(COCOTB_COMMON_DIR) \
		SIM_ARGS="--wave=$(COCOTB_BUILD)/wave-$(TEST).ghw --ieee-asserts=disable-at-0" \
		SIM_BUILD=$(COCOTB_BUILD) \
		2>&1 | grep -v "vpi_iterate returned NULL"
	@echo " "
	@echo ">>> 🌊 Ondas salvas em: $(COCOTB_BUILD)/wave-$(TEST).ghw"