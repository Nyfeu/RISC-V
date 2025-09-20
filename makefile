# ========================================================================================
#    Ferramentas
# ========================================================================================
GHDL      = ghdl
GHDLFLAGS = --std=08

CC        = riscv32-unknown-elf-gcc
CFLAGS    = -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -T sw/linker/link.ld
OBJCOPY   = riscv32-unknown-elf-objcopy
OBJFLAGS  = -O verilog

GTKWAVE   = gtkwave

# ========================================================================================
#    Diretórios
# ========================================================================================
BUILD_DIR  = build
RTL_DIR    = rtl
SIM_DIR    = sim
SW_SRC_DIR = sw/src
SW_DIR     = sw

# ========================================================================================
# Fontes VHDL
# ========================================================================================
RTL_SRCS := \
  $(RTL_DIR)/alu.vhd \
  $(RTL_DIR)/alu_control.vhd \
  $(RTL_DIR)/imm_gen.vhd \
  $(RTL_DIR)/reg_file.vhd \
  $(RTL_DIR)/load_unit.vhd \
  $(RTL_DIR)/decoder.vhd \
  $(RTL_DIR)/control.vhd \
  $(RTL_DIR)/datapath.vhd \
  $(RTL_DIR)/processor_top.vhd


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
	@echo "==============================================================="
	@echo "           Ambiente de Projeto RISC-V   "
	@echo "==============================================================="
	@echo " "
	@echo " make sw SW=<prog>        -> compilar software (.s/.c)"
	@echo " make sim TB=<tb> [SW=..] -> simular processador"
	@echo " make comp TB=<tb_comp>   -> simular testbench de componente"
	@echo " make view TB=<tb>        -> abrir GTKWave do último .ghw"
	@echo " make clean               -> limpar build"
	@echo " "
	@echo "==============================================================="
	@echo " "

# ========================================================================================
#    Compilação de Software
# ========================================================================================
.PHONY: sw
sw: $(BUILD_DIR)/sw/$(SW).hex

$(BUILD_DIR)/sw/%.hex: $(SW_SRC_DIR)/%.s
	@mkdir -p $(@D)
	@echo ">>> Compilando Assembly: $<"
	@$(CC) $(CFLAGS) -o $(patsubst %.hex,%.elf,$(@)) $<
	@echo ">>> Gerando HEX: $@"
	@$(OBJCOPY) $(OBJFLAGS) $(patsubst %.hex,%.elf,$(@)) $(@)

$(BUILD_DIR)/sw/%.hex: $(SW_SRC_DIR)/%.c
	@mkdir -p $(@D)
	@echo ">>> Compilando C: $<"
	@$(CC) $(CFLAGS) -o $(patsubst %.hex,%.elf,$(@)) sw/start.s $<
	@echo ">>> Gerando HEX: $@"
	@$(OBJCOPY) $(OBJFLAGS) $(patsubst %.hex,%.elf,$(@)) $(@)

# ========================================================================================
#    Simulação do Processador Completo
# ========================================================================================
.PHONY: sim
sim:
	@mkdir -p $(BUILD_DIR)/rtl $(BUILD_DIR)/sw
	$(if $(SW), $(MAKE) sw SW=$(SW), )

	@echo ">>> Analisando e compilando VHDL..."
	@$(GHDL) -a $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl \
		$(RTL_SRCS) \
		$(wildcard $(SIM_DIR)/*.vhd)

	@echo ">>> Elaborando $(TB)..."
	@$(GHDL) -e $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl $(TB)

	@echo ">>> Rodando simulação..."
	@$(GHDL) -r $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl $(TB) \
		--wave=$(BUILD_DIR)/wave-$(TB).ghw \
		$(if $(SW), -gPROGRAM_PATH=$(BUILD_DIR)/sw/$(SW).hex, )
	@echo " "
	@echo ">>> Simulação concluída. Onda: $(BUILD_DIR)/wave-$(TB).ghw"
	@echo " "

# ========================================================================================
#    Simulação de Componentes
# ========================================================================================
.PHONY: comp
comp:
	@mkdir -p $(BUILD_DIR)/rtl
	@echo ">>> Analisando e compilando componente..."
	@$(GHDL) -a $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl \
		$(RTL_SRCS) \
		$(SIM_DIR)/$(TB).vhd

	@echo ">>> Elaborando $(TB)..."
	@$(GHDL) -e $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl $(TB)

	@echo ">>> Rodando simulação..."
	@$(GHDL) -r $(GHDLFLAGS) --workdir=$(BUILD_DIR)/rtl $(TB) \
		--wave=$(BUILD_DIR)/wave-$(TB).ghw
	@echo ">>> Simulação concluída. Onda: $(BUILD_DIR)/wave-$(TB).ghw"

# ========================================================================================
#    Visualização com GTKWave
# ========================================================================================
.PHONY: view
view:
	@echo ">>> Abrindo GTKWave em $(BUILD_DIR)/wave-$(TB).ghw"
	@$(GTKWAVE) $(BUILD_DIR)/wave-$(TB).ghw 2>/dev/null &

# ========================================================================================
#    Limpeza
# ========================================================================================
.PHONY: clean
clean:
	@echo ">>> Limpando..."
	@rm -rf $(BUILD_DIR) *.cf
