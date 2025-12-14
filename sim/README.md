# 🧪 Simulação e Testbenches

## Tipos de Testbench

### 1. Testes de Unidade (`sim/core/`)

Testam blocos isolados do processador.

- `alu_tb.vhd`: Testa operações matemáticas.
- `decoder_tb.vhd`: Testa a decodificação de instruções.
- [...]

### 2. Teste do Sistema (`sim/soc/`)

Testa o SoC completo (`soc_tb.vhd`).

1. Instancia o soc_top.

2. Carrega um programa real (.hex) na memória RAM simulada.

3. Simula periféricos (ex: imprime saída da UART no terminal do GHDL).

## Como Rodar

Utilize o **makefile** na raiz:

```bash
make sim TB=soc_tb SW=hello
```

Isso compilará o software `hello`, carregará na RAM simulada e executará o sistema.