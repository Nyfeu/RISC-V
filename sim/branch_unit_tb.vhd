-------------------------------------------------------------------------------------------------------------------
--
-- File: branch_unit_tb.vhd (Testbench para a Branch Unit)
--
-- Descrição: Este testbench verifica a funcionalidade da unidade de decisão de
--            desvio (branch unit). Ele aplica uma série de combinações de flags
--            da ALU e tipos de branch (funct3) para garantir que a decisão de
--            tomar ou não o desvio seja gerada corretamente.
--
-------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- A entidade de um testbench é sempre vazia.
entity branch_unit_tb is
end entity branch_unit_tb;

-- A arquitetura do testbench contém a instância do DUT e o processo de estímulo.
architecture test of branch_unit_tb is

-------------------------------------------------------------------------------------------------------------------
    -- 1. Declaração do Componente sob Teste (DUT)
-------------------------------------------------------------------------------------------------------------------
    component branch_unit is
        port (
            Branch_i       : in  std_logic;
            Funct3_i       : in  std_logic_vector(2 downto 0);
            ALU_Zero_i     : in  std_logic;
            ALU_Negative_i : in  std_logic;
            BranchTaken_o  : out std_logic
        );
    end component branch_unit;

-------------------------------------------------------------------------------------------------------------------
    -- 2. Sinais para o Teste
-------------------------------------------------------------------------------------------------------------------
    -- Sinais para conectar ao DUT
    signal s_branch_i       : std_logic;
    signal s_funct3_i       : std_logic_vector(2 downto 0);
    signal s_alu_zero_i     : std_logic;
    signal s_alu_negative_i : std_logic;
    signal s_branch_taken_o : std_logic;

    -- Constantes para os valores de funct3
    constant c_FUNCT3_BEQ  : std_logic_vector(2 downto 0) := "000";
    constant c_FUNCT3_BNE  : std_logic_vector(2 downto 0) := "001";
    constant c_FUNCT3_BLT  : std_logic_vector(2 downto 0) := "100";
    constant c_FUNCT3_BGE  : std_logic_vector(2 downto 0) := "101";
    constant c_FUNCT3_BLTU : std_logic_vector(2 downto 0) := "110";
    constant c_FUNCT3_BGEU : std_logic_vector(2 downto 0) := "111";

begin

-------------------------------------------------------------------------------------------------------------------
    -- 3. Instanciação do DUT
-------------------------------------------------------------------------------------------------------------------
    DUT: entity work.branch_unit
        port map (
            Branch_i       => s_branch_i,
            Funct3_i       => s_funct3_i,
            ALU_Zero_i     => s_alu_zero_i,
            ALU_Negative_i => s_alu_negative_i,
            BranchTaken_o  => s_branch_taken_o
        );

-------------------------------------------------------------------------------------------------------------------
    -- 4. Processo de Estímulo e Verificação Automática
-------------------------------------------------------------------------------------------------------------------
    STIMULUS: process is
    begin
        report "INICIANDO VERIFICACAO DA BRANCH UNIT..." severity note;

        -- Teste 1: Não é uma instrução de branch
        report "TESTE: Branch_i = '0'" severity note;
        s_branch_i <= '0';
        s_funct3_i <= "---"; -- Irrelevante
        s_alu_zero_i <= '1'; -- Irrelevante
        s_alu_negative_i <= '1'; -- Irrelevante
        wait for 1 ns;
        ASSERT s_branch_taken_o = '0' REPORT "ERRO: Desvio tomado quando Branch_i='0'!" SEVERITY error;

        -- Habilita o sinal de Branch para os próximos testes
        s_branch_i <= '1';

        -- Teste 2: BEQ (Branch if Equal)
        report "TESTE: BEQ (Z=1)" severity note;
        s_funct3_i <= c_FUNCT3_BEQ;
        s_alu_zero_i <= '1';
        wait for 1 ns;
        ASSERT s_branch_taken_o = '1' REPORT "ERRO [BEQ taken]: Desvio não foi tomado!" SEVERITY error;

        report "TESTE: BEQ (Z=0)" severity note;
        s_alu_zero_i <= '0';
        wait for 1 ns;
        ASSERT s_branch_taken_o = '0' REPORT "ERRO [BEQ not taken]: Desvio foi tomado indevidamente!" SEVERITY error;

        -- Teste 3: BNE (Branch if Not Equal)
        report "TESTE: BNE (Z=0)" severity note;
        s_funct3_i <= c_FUNCT3_BNE;
        s_alu_zero_i <= '0';
        wait for 1 ns;
        ASSERT s_branch_taken_o = '1' REPORT "ERRO [BNE taken]: Desvio não foi tomado!" SEVERITY error;

        report "TESTE: BNE (Z=1)" severity note;
        s_alu_zero_i <= '1';
        wait for 1 ns;
        ASSERT s_branch_taken_o = '0' REPORT "ERRO [BNE not taken]: Desvio foi tomado indevidamente!" SEVERITY error;

        -- Teste 4: BLT (Branch if Less Than)
        report "TESTE: BLT (N=1)" severity note;
        s_funct3_i <= c_FUNCT3_BLT;
        s_alu_negative_i <= '1';
        wait for 1 ns;
        ASSERT s_branch_taken_o = '1' REPORT "ERRO [BLT taken]: Desvio não foi tomado!" SEVERITY error;

        report "TESTE: BLT (N=0)" severity note;
        s_alu_negative_i <= '0';
        wait for 1 ns;
        ASSERT s_branch_taken_o = '0' REPORT "ERRO [BLT not taken]: Desvio foi tomado indevidamente!" SEVERITY error;

        -- Teste 5: BGE (Branch if Greater or Equal)
        report "TESTE: BGE (N=0)" severity note;
        s_funct3_i <= c_FUNCT3_BGE;
        s_alu_negative_i <= '0';
        wait for 1 ns;
        ASSERT s_branch_taken_o = '1' REPORT "ERRO [BGE taken]: Desvio não foi tomado!" SEVERITY error;

        report "TESTE: BGE (N=1)" severity note;
        s_alu_negative_i <= '1';
        wait for 1 ns;
        ASSERT s_branch_taken_o = '0' REPORT "ERRO [BGE not taken]: Desvio foi tomado indevidamente!" SEVERITY error;

        -- Mensagem final
        report "VERIFICACAO DA BRANCH UNIT CONCLUIDA." severity note;
        std.env.stop;
    end process STIMULUS;

end architecture test;