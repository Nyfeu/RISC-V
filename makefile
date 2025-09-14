# --- Configuração da Ferramenta VHDL ---
# Define o comando para o GHDL e as flags padrão (usando a versão 2008 do VHDL)
GHDL      = ghdl
GHDLFLAGS = --std=08

# --- Configuração dos Diretórios do Projeto ---
# Define os nomes dos nossos diretórios para manter o Makefile organizado
BUILD_DIR = build
RTL_DIR   = rtl
SIM_DIR   = sim

# --- Descoberta Automática de Arquivos VHDL ---
# Encontra todos os arquivos .vhd no diretório rtl e os armazena na variável RTL_SRCS
RTL_SRCS := $(wildcard $(RTL_DIR)/*.vhd)

# --- Alvo Principal (o que acontece se você digitar apenas 'make') ---
.PHONY: all
all:
	@echo "Makefile pronto. Alvos disponiveis:"
	@echo "  make compile-rtl -> Compila todo o hardware da pasta rtl/"
	@echo "  make sim TB=<nome_do_testbench> -> Roda uma simulacao"
	@echo "  make clean -> Apaga todos os arquivos gerados"

# --- Alvo para Compilar todo o Hardware ---
# Este alvo garante que todo o seu código em rtl/ seja analisado pelo GHDL
.PHONY: compile-rtl
compile-rtl:
	@mkdir -p $(BUILD_DIR)/rtl
	@echo ">>> Compilando fontes VHDL de hardware..."
	@$(GHDL) -a $(GHDLFLAGS) -P$(BUILD_DIR)/rtl --workdir=$(BUILD_DIR)/rtl $(RTL_SRCS)

# --- Alvo Principal de Simulação ---
# Este é o comando que você mais usará.
# Uso: make sim TB=<nome_do_testbench_sem_extensão>
# Exemplo: make sim TB=alu_tb
.PHONY: sim
sim: compile-rtl
	@echo ">>> Preparando simulacao para o testbench: $(TB)"
	# Analisa o arquivo do testbench especifico
	@$(GHDL) -a $(GHDLFLAGS) -P$(BUILD_DIR)/rtl --workdir=$(BUILD_DIR)/rtl $(SIM_DIR)/$(TB).vhd
	# Elabora (monta) o design a partir do testbench
	@$(GHDL) -e $(GHDLFLAGS) -P$(BUILD_DIR)/rtl --workdir=$(BUILD_DIR)/rtl $(TB)
	# Roda a simulacao e gera o arquivo de onda
	@echo ">>> Rodando simulacao de $(TB)..."
	@$(GHDL) -r $(GHDLFLAGS) -P$(BUILD_DIR)/rtl --workdir=$(BUILD_DIR)/rtl $(TB) --wave=$(BUILD_DIR)/wave-$(TB).ghw
	@echo ">>> Simulacao concluida. Arquivo de onda: $(BUILD_DIR)/wave-$(TB).ghw"

# --- Alvo para Limpar o Projeto ---
# Essencial para garantir que você está sempre trabalhando com uma compilação limpa
.PHONY: clean
clean:
	@echo ">>> Limpando diretorio de build..."
	@rm -rf $(BUILD_DIR) *.cf