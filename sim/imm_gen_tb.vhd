-------------------------------------------------------------------------------------------------------------------
--
-- File: imm_gen_tb.vhd (Testbench para o Gerador de Imediatos)
--
-- Descrição: Este testbench verifica a funcionalidade do gerador de imediatos
--            para os formatos I, S, B, U e J do conjunto de instruções RISC-V.
--            Ele aplica uma série de instruções de teste e verifica se o
--            imediato gerado corresponde ao valor esperado.
--
-------------------------------------------------------------------------------------------------------------------

-- Inclusão dos módulos necessários
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- A entidade de um testbench é sempre vazia.
entity imm_gen_tb is
end entity imm_gen_tb;

-- A arquitetura do testbench contém a instância do DUT e o processo de estímulo.
architecture test of imm_gen_tb is

-------------------------------------------------------------------------------------------------------------------
    -- 1. Declaração do Componente sob Teste (DUT - Device Under Test)
-------------------------------------------------------------------------------------------------------------------

    -- Componente a ser testado
    component imm_gen is
        port (
            Instruction_i    : in  std_logic_vector(31 downto 0);
            Immediate_o      : out std_logic_vector(31 downto 0)
        );
    end component imm_gen;

-------------------------------------------------------------------------------------------------------------------
    -- 2. Constantes e Sinais para o Teste
-------------------------------------------------------------------------------------------------------------------

    -- Sinais para conectar ao DUT
    signal s_instruction     : std_logic_vector(31 downto 0);
    signal s_immediate       : std_logic_vector(31 downto 0);

    -- Constantes para campos de instrução comuns
    constant c_OPCODE_IMM    : std_logic_vector(6 downto 0) := "0010011";
    constant c_OPCODE_STORE  : std_logic_vector(6 downto 0) := "0100011";
    constant c_OPCODE_BRANCH : std_logic_vector(6 downto 0) := "1100011";
    constant c_OPCODE_LUI    : std_logic_vector(6 downto 0) := "0110111";
    constant c_OPCODE_JAL    : std_logic_vector(6 downto 0) := "1101111";
    
    -- Constantes para registradores
    constant c_RD_X5         : std_logic_vector(4 downto 0) := "00101";
    constant c_RS1_X6        : std_logic_vector(4 downto 0) := "00110";
    constant c_RS2_X7        : std_logic_vector(4 downto 0) := "00111";

    -- Constantes para funct3
    constant c_FUNCT3_SW     : std_logic_vector(2 downto 0) := "010";
    constant c_FUNCT3_BEQ    : std_logic_vector(2 downto 0) := "000";
    constant c_FUNCT3_ADDI   : std_logic_vector(2 downto 0) := "000";

begin

-------------------------------------------------------------------------------------------------------------------
    -- 3. Instanciação do Componente sob Teste (DUT)
-------------------------------------------------------------------------------------------------------------------

    DUT: entity work.imm_gen port map (
        Instruction_i => s_instruction,
        Immediate_o   => s_immediate
    );

-------------------------------------------------------------------------------------------------------------------
    -- 4. Processo de Estímulo e Verificação Automática
-------------------------------------------------------------------------------------------------------------------

    stimulus_proc: process is

        -- Variável para o imediato esperado
        variable v_expected_imm      : std_logic_vector(31 downto 0);
        
        -- Constantes de valor (signed)
        constant c_IMM_I_NEG_s       : signed(11 downto 0) := to_signed( -100, 12);
        constant c_IMM_S_NEG_s       : signed(11 downto 0) := to_signed(   -4, 12);
        constant c_IMM_B_NEG_s       : signed(12 downto 0) := to_signed(  -32, 13);      
        constant c_IMM_J_NEG_s       : signed(20 downto 0) := to_signed( -512, 21);    
        constant c_IMM_I_MAX_POS     : signed(11 downto 0) := to_signed( 2047, 12);
        constant c_IMM_I_MIN_NEG     : signed(11 downto 0) := to_signed(-2048, 12);
        constant c_IMM_B_MAX_POS     : signed(12 downto 0) := to_signed( 4094, 13);
        
        -- Constantes de valor (std_logic_vector)
        constant c_IMM_I_NEG_slv     : std_logic_vector(11 downto 0) := std_logic_vector(  c_IMM_I_NEG_s);
        constant c_IMM_S_NEG_slv     : std_logic_vector(11 downto 0) := std_logic_vector(  c_IMM_S_NEG_s);
        constant c_IMM_B_NEG_slv     : std_logic_vector(12 downto 0) := std_logic_vector(  c_IMM_B_NEG_s);
        constant c_IMM_J_NEG_slv     : std_logic_vector(20 downto 0) := std_logic_vector(  c_IMM_J_NEG_s);
        constant c_IMM_B_MAX_POS_slv : std_logic_vector(12 downto 0) := std_logic_vector(c_IMM_B_MAX_POS);

    begin

        -- Mensagem inicial indicando o início dos testes
        report "INICIANDO VERIFICACAO DO GERADOR DE IMEDIATOS..." severity note;
        wait for 1 ns;

        -- Teste I-Type (addi x5, x6, -100)
        report "TESTE: Formato I (imm=-100)" severity note;
        s_instruction  <= c_IMM_I_NEG_slv & c_RS1_X6 & c_FUNCT3_ADDI & 
            c_RD_X5 & c_OPCODE_IMM;
        v_expected_imm := std_logic_vector(to_signed(-100, 32));
        wait for 1 ns;
        ASSERT s_immediate = v_expected_imm REPORT "ERRO [I-Type]" SEVERITY error;

        -- Teste S-Type (sw x7, -4(x6))
        report "TESTE: Formato S (imm=-4)" severity note;
        s_instruction  <= c_IMM_S_NEG_slv(11 downto 5) & c_RS2_X7 & 
            c_RS1_X6 & c_FUNCT3_SW & c_IMM_S_NEG_slv(4 downto 0) & 
            c_OPCODE_STORE;
        v_expected_imm := std_logic_vector(to_signed(-4, 32));
        wait for 1 ns;
        ASSERT s_immediate = v_expected_imm REPORT "ERRO [S-Type]" SEVERITY error;

        -- Teste B-Type (beq x6, x7, -32)
        report "TESTE: Formato B (imm=-32)" severity note;
        s_instruction  <= c_IMM_B_NEG_slv(12) & c_IMM_B_NEG_slv(10 downto 5) & 
            c_RS2_X7 & c_RS1_X6 & c_FUNCT3_BEQ & 
            c_IMM_B_NEG_slv(4 downto 1) & c_IMM_B_NEG_slv(11) & 
            c_OPCODE_BRANCH;
        v_expected_imm := std_logic_vector(to_signed(-32, 32));
        wait for 1 ns;
        ASSERT s_immediate = v_expected_imm REPORT "ERRO [B-Type]" SEVERITY error;
        
        -- Teste U-Type (lui x5, 0xABCDE)
        report "TESTE: Formato U (imm=0xABCDE)" severity note;
        s_instruction  <= x"ABCDE" & c_RD_X5 & c_OPCODE_LUI;
        v_expected_imm := x"ABCDE000";
        wait for 1 ns;
        ASSERT s_immediate = v_expected_imm REPORT "ERRO [U-Type]" SEVERITY error;

        -- Teste J-Type (jal x5, -512)
        report "TESTE: Formato J (imm=-512)" severity note;
        s_instruction  <= c_IMM_J_NEG_slv(20) & c_IMM_J_NEG_slv(10 downto 1) & 
            c_IMM_J_NEG_slv(11) & c_IMM_J_NEG_slv(19 downto 12) & 
            c_RD_X5 & c_OPCODE_JAL;
        v_expected_imm := std_logic_vector(to_signed(-512, 32));
        wait for 1 ns;
        ASSERT s_immediate = v_expected_imm REPORT "ERRO [J-Type]" SEVERITY error;

        -- Teste: Formato I (Máximo Positivo: +2047)
        report "TESTE: Formato I (imm=+2047)" severity note;
        s_instruction  <= std_logic_vector(c_IMM_I_MAX_POS) & c_RS1_X6 & c_FUNCT3_ADDI & c_RD_X5 & c_OPCODE_IMM;
        v_expected_imm := std_logic_vector(resize(c_IMM_I_MAX_POS, 32));
        wait for 1 ns;
        ASSERT s_immediate = v_expected_imm REPORT "ERRO [LIMITE-I-POS]" SEVERITY error;

        -- Teste: Formato I (Mínimo Negativo: -2048) 
        report "TESTE: Formato I (imm=-2048)" severity note;
        s_instruction  <= std_logic_vector(c_IMM_I_MIN_NEG) & c_RS1_X6 & c_FUNCT3_ADDI & c_RD_X5 & c_OPCODE_IMM;
        v_expected_imm := std_logic_vector(resize(c_IMM_I_MIN_NEG, 32));
        wait for 1 ns;
        ASSERT s_immediate = v_expected_imm REPORT "ERRO [LIMITE-I-NEG]" SEVERITY error;

        -- Teste: Formato B (Máximo Positivo: +4094)
        report "TESTE: Formato B (imm=+4094)" severity note;
        s_instruction <= c_IMM_B_MAX_POS_slv(12) & c_IMM_B_MAX_POS_slv(10 downto 5) & 
                c_RS2_X7 & c_RS1_X6 & c_FUNCT3_BEQ & 
                c_IMM_B_MAX_POS_slv(4 downto 1) & c_IMM_B_MAX_POS_slv(11) & 
                c_OPCODE_BRANCH;
        v_expected_imm := std_logic_vector(resize(c_IMM_B_MAX_POS, 32));
        wait for 1 ns;
        ASSERT s_immediate = v_expected_imm REPORT "ERRO [LIMITE-B-POS]" SEVERITY error;

        -- Mensagem final indicando que todos os testes finalizaram
        report "--- VERIFICACAO DO IMM_GEN CONCLUIDA ---" severity note;
        
        -- Para a simulação para não rodar para sempre.
        std.env.stop;
        
    end process stimulus_proc;

end architecture test;