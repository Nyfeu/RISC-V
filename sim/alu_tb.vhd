-------------------------------------------------------------------------------------------------------------------
--
-- File: alu_tb.vhd (Testbench para a ULA)
--
-- Descrição: Este testbench autoverificável aplica um conjunto de vetores
--            de teste à ULA e usa a instrução ASSERT para validar
--            automaticamente se os resultados estão corretos.
--
-------------------------------------------------------------------------------------------------------------------

-- Inclusão dos módulos necessários
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- A entidade de um testbench é sempre vazia.
entity alu_tb is
end entity alu_tb;

-- A arquitetura do testbench contém a instância do DUT e o processo de estímulo.
architecture test of alu_tb is

-------------------------------------------------------------------------------------------------------------------
    -- 1. Declaração do Componente sob Teste (DUT - Device Under Test)
-------------------------------------------------------------------------------------------------------------------

    component alu is
        port (
            A_i          : in  std_logic_vector(31 downto 0);
            B_i          : in  std_logic_vector(31 downto 0);
            ALUControl_i : in  std_logic_vector(3 downto 0);
            Result_o     : out std_logic_vector(31 downto 0);
            Zero_o       : out std_logic
        );
    end component alu;

-------------------------------------------------------------------------------------------------------------------
    -- 2. Constantes e Sinais para o Teste
-------------------------------------------------------------------------------------------------------------------

    -- Constantes para os códigos de operação (devem ser os mesmos do alu.vhd)
    constant c_ALU_ADD  : std_logic_vector(3 downto 0) := "0000";
    constant c_ALU_SUB  : std_logic_vector(3 downto 0) := "1000";
    constant c_ALU_SLT  : std_logic_vector(3 downto 0) := "0010";
    constant c_ALU_SLTU : std_logic_vector(3 downto 0) := "0011";
    constant c_ALU_XOR  : std_logic_vector(3 downto 0) := "0100";
    constant c_ALU_OR   : std_logic_vector(3 downto 0) := "0110";
    constant c_ALU_AND  : std_logic_vector(3 downto 0) := "0111";
    constant c_ALU_SLL  : std_logic_vector(3 downto 0) := "0001";
    constant c_ALU_SRL  : std_logic_vector(3 downto 0) := "0101";
    constant c_ALU_SRA  : std_logic_vector(3 downto 0) := "1101";

    -- Sinais para conectar ao nosso componente ULA
    signal s_A       : std_logic_vector(31 downto 0);
    signal s_B       : std_logic_vector(31 downto 0);
    signal s_ALUOp   : std_logic_vector(3 downto 0);
    signal s_Result  : std_logic_vector(31 downto 0);
    signal s_Zero    : std_logic;

begin

-------------------------------------------------------------------------------------------------------------------
    -- 3. Instanciação do Componente sob Teste (DUT)
-------------------------------------------------------------------------------------------------------------------

    -- Conecta os sinais locais às portas do componente alu
    DUT: entity work.alu
        port map (
            A_i          => s_A,
            B_i          => s_B,
            ALUControl_i => s_ALUOp,
            Result_o     => s_Result,
            Zero_o       => s_Zero
        );

-------------------------------------------------------------------------------------------------------------------
    -- 4. Processo de Estímulo e Verificação Automática
-------------------------------------------------------------------------------------------------------------------

    STIMULUS: process 

        -- Variável para armazenar o resultado esperado
        variable v_expected_result : std_logic_vector(31 downto 0);
    
    begin

        --- Mensagem inicial
        report "INICIANDO VERIFICACAO DA ALU...";

        -- Aguarda um instante para começar
        wait for 1 ns; 

        -- Caso de Teste 1: ADD (5 + 10 = 15) ---
        report "TESTE: ADD (5 + 10)" severity note;
        s_A     <= std_logic_vector(to_signed(5, 32));
        s_B     <= std_logic_vector(to_signed(10, 32));
        s_ALUOp <= c_ALU_ADD;
        v_expected_result := std_logic_vector(to_signed(15, 32));
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [ADD]: Resultado incorreto!" SEVERITY error;
        ASSERT s_Zero   = '0'               REPORT "ERRO [ADD]: Flag Zero incorreta!" SEVERITY error;

        -- Caso de Teste 2: SUB (10 - 10 = 0) ---
        report "TESTE: SUB (10 - 10)" severity note;
        s_A     <= std_logic_vector(to_signed(10, 32));
        s_B     <= std_logic_vector(to_signed(10, 32));
        s_ALUOp <= c_ALU_SUB;
        v_expected_result := x"00000000";
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [SUB/ZERO]: Resultado incorreto!" SEVERITY error;
        ASSERT s_Zero   = '1'               REPORT "ERRO [SUB/ZERO]: Flag Zero incorreta!" SEVERITY error;

        -- Caso de Teste 3: SLT (-5 < 10) -> TRUE (1) ---
        report "TESTE: SLT (-5 < 10)" severity note;
        s_A     <= std_logic_vector(to_signed(-5, 32));
        s_B     <= std_logic_vector(to_signed(10, 32));
        s_ALUOp <= c_ALU_SLT;
        v_expected_result := std_logic_vector(to_unsigned(1, 32));
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [SLT]: Resultado incorreto!" SEVERITY error;

        -- Caso de Teste 4: AND (lógico) ---
        report "TESTE: AND (0xFF00FF00 AND 0x0000FFFF)" severity note;
        s_A     <= x"FF00FF00";
        s_B     <= x"0000FFFF";
        s_ALUOp <= c_ALU_AND;
        v_expected_result := x"0000FF00";
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [AND]: Resultado incorreto!" SEVERITY error;

        -- Caso de Teste 5: SLL (Shift Left) ---
        report "TESTE: SLL (x00000001 << 5)" severity note;
        s_A     <= x"00000001";
        s_B     <= std_logic_vector(to_unsigned(5, 32));
        s_ALUOp <= c_ALU_SLL;
        v_expected_result := x"00000020";
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [SLL]: Resultado incorreto!" SEVERITY error;

        -- Caso de Teste 6: SRA (Shift Right Arithmetic) ---
        report "TESTE: SRA (xFFFFFFF0 >> 4)" severity note;
        s_A     <= x"FFFFFFF0"; -- Número -16
        s_B     <= std_logic_vector(to_unsigned(4, 32));
        s_ALUOp <= c_ALU_SRA;
        v_expected_result := x"FFFFFFFF"; -- Número -1
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [SRA]: Resultado incorreto!" SEVERITY error;

        -- Caso de Teste 7: OR (lógico) ---
        report "TESTE: OR (0xF0F00000 OR 0x00F0F0F0)" severity note;
        s_A     <= x"F0F00000";
        s_B     <= x"00F0F0F0";
        s_ALUOp <= C_ALU_OR;
        v_expected_result := x"F0F0F0F0";
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [OR]: Resultado incorreto!" SEVERITY error;

        -- Caso de Teste 8: XOR (inversão de bits) ---
        report "TESTE: XOR (0xF0F0A5A5 XOR 0xFFFFFFFF)" severity note;
        s_A     <= x"F0F0A5A5";
        s_B     <= x"FFFFFFFF"; -- Máscara de XOR para inverter todos os bits
        s_ALUOp <= C_ALU_XOR;
        v_expected_result := x"0F0F5A5A"; -- O inverso de s_A
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [XOR]: Resultado incorreto!" SEVERITY error;

        -- Caso de Teste 9: SLTU (teste crítico sem sinal) ---
        -- Compara 2 (pequeno positivo) com -1 (grande positivo sem sinal)
        report "TESTE: SLTU (2 < -1)" severity note;
        s_A     <= std_logic_vector(to_unsigned(2, 32));
        s_B     <= std_logic_vector(to_signed(-1, 32)); -- -1 em 32 bits é 0xFFFFFFFF
        s_ALUOp <= C_ALU_SLTU;
        v_expected_result := std_logic_vector(to_unsigned(1, 32)); -- Esperado TRUE, pois 2 < 4294967295
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [SLTU]: Resultado incorreto!" SEVERITY error;
        
        -- Caso de Teste 10: SRL (Shift Right Logical com MSB=1) ---
        report "TESTE: SRL (x80000000 >> 4)" severity note;
        s_A     <= x"80000000"; -- MSB é '1'
        s_B     <= std_logic_vector(to_unsigned(4, 32));
        s_ALUOp <= C_ALU_SRL;
        v_expected_result := x"08000000"; -- Deve preencher com zeros à esquerda
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [SRL]: Resultado incorreto!" SEVERITY error;

        -- Caso de Teste 11: Overflow Aritmético (Maior Positivo + 1) ---
        report "TESTE: ADD (0x7FFFFFFF + 1)" severity note;
        s_A     <= x"7FFFFFFF"; -- Maior número positivo
        s_B     <= std_logic_vector(to_signed(1, 32));
        s_ALUOp <= C_ALU_ADD;
        v_expected_result := x"80000000"; -- Deve virar o menor número negativo
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [LIMITE-OVERFLOW]: Falha no overflow de ADD!" SEVERITY error;

        -- Caso de Teste 12: Underflow Aritmético (Menor Negativo - 1) ---
        report "TESTE: SUB (0x80000000 - 1)" severity note;
        s_A     <= x"80000000"; -- Menor número negativo
        s_B     <= std_logic_vector(to_signed(1, 32));
        s_ALUOp <= C_ALU_SUB;
        v_expected_result := x"7FFFFFFF"; -- Deve virar o maior número positivo
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [LIMITE-UNDERFLOW]: Falha no underflow de SUB!" SEVERITY error;

        -- Caso de Teste 13: Shift por Zero ---
        report "TESTE: SLL (valor << 0)" severity note;
        s_A     <= x"12345678";
        s_B     <= std_logic_vector(to_unsigned(0, 32)); -- Shift de 0
        s_ALUOp <= C_ALU_SLL;
        v_expected_result := x"12345678"; -- O resultado deve ser o próprio número
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [LIMITE-SHIFT]: Falha no shift por zero!" SEVERITY error;

        -- Caso de Teste 14: Shift por Valor > 31 ---
        report "TESTE: SLL (valor << 33)" severity note;
        s_A     <= x"00000001";
        s_B     <= std_logic_vector(to_unsigned(33, 32)); -- Shift de 33
        s_ALUOp <= C_ALU_SLL;
        v_expected_result := x"00000002"; -- Deve ser o mesmo que shift por 1 (33 mod 32)
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [LIMITE-SHIFT]: Falha no shift com valor > 31!" SEVERITY error;

        -- Caso de Teste 15: Comparação de número com ele mesmo ---
        report "TESTE: SLT (A < A)" severity note;
        s_A     <= std_logic_vector(to_signed(-100, 32));
        s_B     <= std_logic_vector(to_signed(-100, 32));
        s_ALUOp <= C_ALU_SLT;
        v_expected_result := x"00000000"; -- Deve ser FALSO
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [LIMITE-SLT]: Falha na auto-comparacao!" SEVERITY error;

        -- Caso de Teste 16: Comparação Crítica SLT vs SLTU ---
        report "TESTE: SLT/SLTU (0x7FFFFFFF vs 0x80000000)" severity note;
        s_A     <= x"7FFFFFFF"; -- Maior positivo (com sinal), pequeno (sem sinal)
        s_B     <= x"80000000"; -- Menor negativo (com sinal), grande (sem sinal)
        
        -- Teste com SLT (com sinal): 0x7FFFFFFF > 0x80000000. Esperado FALSO.
        s_ALUOp <= C_ALU_SLT;
        v_expected_result := x"00000000";
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [LIMITE-SLT]: Falha na comparacao de limites com sinal!" SEVERITY error;
        
        -- Teste com SLTU (sem sinal): 0x7FFFFFFF < 0x80000000. Esperado VERDADEIRO.
        s_ALUOp <= C_ALU_SLTU;
        v_expected_result := x"00000001";
        wait for 1 ns;
        ASSERT s_Result = v_expected_result REPORT "ERRO [LIMITE-SLTU]: Falha na comparacao de limites sem sinal!" SEVERITY error;

        -- Mensagem final indicando que todos os testes finalizaram
        report "VERIFICACAO DA ALU CONCLUIDA!" severity note;

        -- Para a simulação para não rodar para sempre.
        std.env.stop;

    end process STIMULUS;

end architecture test;

-------------------------------------------------------------------------------------------------------------------