-------------------------------------------------------------------------------------------------------------------
--
-- File: alu_control_tb.vhd (Testbench para a Unidade de Controle da ALU)
--
-- Descrição: Este testbench verifica a funcionalidade da unidade de controle da ALU
--            para um processador RISC-V de 32 bits (RV32I). Ele aplica uma
--            série de combinações de ALUOp, funct3 e funct7, e verifica se o
--            sinal de controle gerado corresponde ao valor esperado.
--
-------------------------------------------------------------------------------------------------------------------

-- Inclusão dos módulos necessários
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_pkg.all;

-- A entidade de um testbench é sempre vazia.
entity alu_control_tb is
end entity alu_control_tb;

-- A arquitetura do testbench contém a instância do DUT e o processo de estímulo.
architecture test of alu_control_tb is

-------------------------------------------------------------------------------------------------------------------
    -- 1. Declaração do Componente sob Teste (DUT - Device Under Test)
-------------------------------------------------------------------------------------------------------------------

    component alu_control is
        port (
            ALUOp_i      : in  std_logic_vector(1 downto 0);
            Funct3_i     : in  std_logic_vector(2 downto 0);
            Funct7_i     : in  std_logic_vector(6 downto 0);
            ALUControl_o : out std_logic_vector(3 downto 0)
        );
    end component alu_control;

-------------------------------------------------------------------------------------------------------------------
    -- 2. Sinais para o Teste
-------------------------------------------------------------------------------------------------------------------

    -- Sinais para conectar ao DUT
    signal s_aluop_i      : std_logic_vector(1 downto 0);
    signal s_funct3_i     : std_logic_vector(2 downto 0);
    signal s_funct7_i     : std_logic_vector(6 downto 0);
    signal s_alucontrol_o : std_logic_vector(3 downto 0);

begin

------------------------------------------------------------------------------------------------------------------
    -- 3. Instanciação do Componente sob Teste (DUT)
-------------------------------------------------------------------------------------------------------------------

    DUT: entity work.alu_control
        port map (
            ALUOp_i      => s_aluop_i,
            Funct3_i     => s_funct3_i,
            Funct7_i     => s_funct7_i,
            ALUControl_o => s_alucontrol_o
        );

-------------------------------------------------------------------------------------------------------------------
    -- 4. Processo de Estímulo e Verificação Automática
-------------------------------------------------------------------------------------------------------------------

    stimulus_proc: process is
    begin

        -- Mensagem inicial indicando o início dos testes
        report "INICIANDO VERIFICACAO DO ALU_CONTROL..." severity note;

        -- Teste 1: ALUOp="00" (LW/SW/ADDI) deve gerar ADD
        report "TESTE: ALUOp='00' (LW/SW/ADDI)" severity note;
        s_aluop_i  <= "00";
        s_funct3_i <= "---"; -- Irrelevante
        s_funct7_i <= "-------"; -- Irrelevante
        wait for 1 ns;
        ASSERT s_alucontrol_o = C_ALU_ADD REPORT "ERRO [ALUOp 00]: Nao gerou comando ADD!" SEVERITY error;

        -- Teste 2: ALUOp="01" (Branch) deve gerar SUB 
        report "TESTE: ALUOp='01' (Branch)" severity note;
        s_aluop_i  <= "01";
        wait for 1 ns;
        ASSERT s_alucontrol_o = C_ALU_SUB REPORT "ERRO [ALUOp 01]: Nao gerou comando SUB!" SEVERITY error;

        -- Teste 3: ALUOp="10" (R-Type)
        report "TESTE: ALUOp='10' (R-Type)" severity note;
        s_aluop_i <= "10";
        
        -- Teste R-Type ADD
        report " -> Sub-teste R-Type: ADD" severity note;
        s_funct3_i <= "000";
        s_funct7_i <= "0000000";
        wait for 1 ns;
        ASSERT s_alucontrol_o = C_ALU_ADD REPORT "ERRO [R-Type]: Falha no ADD!" SEVERITY error;
        
        -- Teste R-Type SUB
        report " -> Sub-teste R-Type: SUB" severity note;
        s_funct3_i <= "000";
        s_funct7_i <= "0100000";
        wait for 1 ns;
        ASSERT s_alucontrol_o = C_ALU_SUB REPORT "ERRO [R-Type]: Falha no SUB!" SEVERITY error;
        
        -- Teste R-Type SLL
        report " -> Sub-teste R-Type: SLL" severity note;
        s_funct3_i <= "001";
        s_funct7_i <= "0000000";
        wait for 1 ns;
        ASSERT s_alucontrol_o = C_ALU_SLL REPORT "ERRO [R-Type]: Falha no SLL!" SEVERITY error;
        
        -- Teste R-Type SLT
        report " -> Sub-teste R-Type: SLT" severity note;
        s_funct3_i <= "010";
        wait for 1 ns;
        ASSERT s_alucontrol_o = C_ALU_SLT REPORT "ERRO [R-Type]: Falha no SLT!" SEVERITY error;
        
        -- Teste R-Type SLTU
        report " -> Sub-teste R-Type: SLTU" severity note;
        s_funct3_i <= "011";
        wait for 1 ns;
        ASSERT s_alucontrol_o = C_ALU_SLTU REPORT "ERRO [R-Type]: Falha no SLTU!" SEVERITY error;
        
        -- Teste R-Type XOR
        report " -> Sub-teste R-Type: XOR" severity note;
        s_funct3_i <= "100";
        wait for 1 ns;
        ASSERT s_alucontrol_o = C_ALU_XOR REPORT "ERRO [R-Type]: Falha no XOR!" SEVERITY error;

        -- Teste R-Type SRL
        report " -> Sub-teste R-Type: SRL" severity note;
        s_funct3_i <= "101";
        s_funct7_i <= "0000000";
        wait for 1 ns;
        ASSERT s_alucontrol_o = C_ALU_SRL REPORT "ERRO [R-Type]: Falha no SRL!" SEVERITY error;
        
        -- Teste R-Type SRA
        report " -> Sub-teste R-Type: SRA" severity note;
        s_funct3_i <= "101";
        s_funct7_i <= "0100000";
        wait for 1 ns;
        ASSERT s_alucontrol_o = C_ALU_SRA REPORT "ERRO [R-Type]: Falha no SRA!" SEVERITY error;

        -- Teste R-Type OR
        report " -> Sub-teste R-Type: OR" severity note;
        s_funct3_i <= "110";
        s_funct7_i <= "0000000";
        wait for 1 ns;
        ASSERT s_alucontrol_o = C_ALU_OR REPORT "ERRO [R-Type]: Falha no OR!" SEVERITY error;
        
        -- Teste R-Type AND
        report " -> Sub-teste R-Type: AND" severity note;
        s_funct3_i <= "111";
        wait for 1 ns;
        ASSERT s_alucontrol_o = C_ALU_AND REPORT "ERRO [R-Type]: Falha no AND!" SEVERITY error;

        -- Mensagem final indicando que todos os testes finalizaram
        report "VERIFICACAO DO ALU_CONTROL CONCLUIDA ---" severity note;
        
        -- Para a simulação para não rodar para sempre.
        std.env.stop;
        
    end process stimulus_proc;

end architecture test;