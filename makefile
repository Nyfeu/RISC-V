# ========================================================================================
#    Ferramentas
# ========================================================================================

# GHDL - VHDL Simulator ==================================================================

GHDL      = ghdl
GHDLFLAGS = --std=08 -fexplicit

# RISC-V GCC Toolchain ===================================================================

CC        = riscv32-unknown-elf-gcc
OBJCOPY   = riscv32-unknown-elf-objcopy

# Flags de Compilação C
# Nota: Atualizado para buscar o linker script em sw/common/
CFLAGS    = -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -T sw/common/link.ld

# Flags de Geração de HEX
# -O verilog gera um formato hexadecimal legível (tipo @addr data)
OBJFLAGS  = -O verilog

# GTKWave - Waveform Viewer ==============================================================

GTKWAVE   = gtkwave

# COCOTB - Coroutine-based Co-simulation Testbench =======================================

COCOTB_SIM      = ghdl
COCOTB_DIR      = sim
COCOTB_CORE_DIR = sim/core
COCOTB_BUILD    = build/cocotb
PYTHON          = python3

# ========================================================================================
#    Diretórios (NOVA ESTRUTURA)
# ========================================================================================

BUILD_DIR    = build
PKG_DIR      = pkg

# Estrutura de Hardware
RTL_DIR      = rtl
CORE_DIR     = rtl/core
SOC_DIR      = rtl/soc
PERIPS_DIR   = rtl/perips

# Estrutura de Simulação
SIM_DIR      = sim
SIM_CORE_DIR = sim/core
SIM_SOC_DIR  = sim/soc

# Estrutura de Software
SW_DIR       = sw
SW_APPS_DIR  = sw/apps
SW_BOOT_DIR  = sw/bootloader
SW_COMMON_DIR= sw/common

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

# Lista completa de RTL
ALL_RTL_SRCS := $(CORE_SRCS) $(SOC_SRCS) $(PERIPS_SRCS)

# Fontes de Simulação (Todos os testbenches)
ALL_SIM_SRCS := $(wildcard $(SIM_CORE_DIR)/*.vhd) $(wildcard $(SIM_SOC_DIR)/*.vhd)

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
#    Simulação (Core e SoC)
# ========================================================================================

.PHONY: sim
sim:
	@mkdir -p $(BUILD_DIR)/rtl $(BUILD_DIR)/sw
	$(if $(SW), $(MAKE) sw SW=$(SW), )

	@echo ">>> [VHDL] Analisando fontes..."
	
	@$(GHDL) -a $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl $(PKG_SRCS)
	@$(GHDL) -a $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl $(ALL_RTL_SRCS)
	@$(GHDL) -a $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl $(ALL_SIM_SRCS)

	@echo ">>> [VHDL] Elaborando $(TB)..."
	@$(GHDL) -e $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl $(TB)

	@echo ">>> [SIM] Rodando simulação..."
	@$(GHDL) -r $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl $(TB) \
		--wave=$(BUILD_DIR)/wave-$(TB).ghw \
		--ieee-asserts=disable \
		$(if $(SW), -gPROGRAM_PATH=$(BUILD_DIR)/sw/$(SW).hex, )
	
	@echo " "
	@echo ">>> Simulação concluída. Onda gerada em: $(BUILD_DIR)/wave-$(TB).ghw"
	@echo " "

# ========================================================================================
#    Simulação de Componentes (Unitária - Sem Software)
# ========================================================================================

.PHONY: comp
comp:
	@mkdir -p $(BUILD_DIR)/rtl
	@echo ">>> [VHDL] Analisando fontes para componente..."
	
	@$(GHDL) -a $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl $(PKG_SRCS)
	@$(GHDL) -a $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl $(ALL_RTL_SRCS)
	@$(GHDL) -a $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl $(ALL_SIM_SRCS)

	@echo ">>> [VHDL] Elaborando $(TB)..."
	@$(GHDL) -e $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl $(TB)

	@echo ">>> [SIM] Rodando simulação..."
	@$(GHDL) -r $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl $(TB) \
		--wave=$(BUILD_DIR)/wave-$(TB).ghw \
		--ieee-asserts=disable
	
	@echo " "
	@echo ">>> Simulação Unitária concluída. Onda: $(BUILD_DIR)/wave-$(TB).ghw"
	@echo " "

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
#    COCOTB Testbench
# ========================================================================================

.PHONY: cocotb
cocotb:
	@mkdir -p $(COCOTB_BUILD)
	@echo " "
	@echo "======================================================================"
	@echo ">>> 🧪 INICIANDO TESTES AUTOMATIZADOS (COCOTB) "
	@echo ">>> 🎯 TOP LEVEL: $(TOP)"
	@echo ">>> 📂 MÓDULO:    $(TEST)"
	@echo "======================================================================"
	@echo " "
	@export COCOTB_ANSI_OUTPUT=1; \
	export COCOTB_RESULTS_FILE=$(COCOTB_BUILD)/results.xml; \
	$(MAKE) -s -f $(shell cocotb-config --makefiles)/Makefile.sim \
		SIM=$(COCOTB_SIM) \
		TOPLEVEL_LANG=vhdl \
		TOPLEVEL=$(TOP) \
		COCOTB_TEST_MODULES=$(TEST) \
		WORKDIR=$(COCOTB_BUILD) \
		VHDL_SOURCES="$(PKG_SRCS) $(CORE_SRCS)" \
		PYTHONPATH=$(COCOTB_CORE_DIR) \
		SIM_ARGS="--wave=$(COCOTB_BUILD)/wave-$(TEST).ghw" \
		2>&1 | grep -v "vpi_iterate returned NULL"
	@echo " "
	@echo ">>> 🌊 Ondas salvas em: $(COCOTB_BUILD)/wave-$(TEST).ghw"