-------------------------------------------------------------------------------------------------------------------
--
-- File: load_unit_tb.vhd (Testbench para a Unidade de Carga)
--
-- Descrição: Este testbench autoverificável testa a Unidade de Carga (Load Unit).
--            Ele fornece uma palavra de 32 bits e simula diferentes instruções de
--            'load' (lw, lb, lbu, lh, lhu) com diferentes alinhamentos de endereço
--            para garantir que o byte ou meia-palavra correta seja extraído e
--            estendido para 32 bits.
--
-------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- A entidade de um testbench é sempre vazia.
entity load_unit_tb is
end entity load_unit_tb;

architecture test of load_unit_tb is

-------------------------------------------------------------------------------------------------------------------
    -- 1. Declaração do Componente sob Teste (DUT)
-------------------------------------------------------------------------------------------------------------------
    component load_unit is
        port (
            DMem_data_i  : in  std_logic_vector(31 downto 0);
            Addr_LSB_i   : in  std_logic_vector(1 downto 0);
            Funct3_i     : in  std_logic_vector(2 downto 0);
            Data_o       : out std_logic_vector(31 downto 0)
        );
    end component load_unit;

-------------------------------------------------------------------------------------------------------------------
    -- 2. Constantes e Sinais para o Teste
-------------------------------------------------------------------------------------------------------------------
    -- Sinais para conectar ao DUT
    signal s_dmem_data_i : std_logic_vector(31 downto 0);
    signal s_addr_lsb_i  : std_logic_vector(1 downto 0);
    signal s_funct3_i    : std_logic_vector(2 downto 0);
    signal s_data_o      : std_logic_vector(31 downto 0);

    -- Constantes para os valores de funct3
    constant c_LB  : std_logic_vector(2 downto 0) := "000";
    constant c_LH  : std_logic_vector(2 downto 0) := "001";
    constant c_LW  : std_logic_vector(2 downto 0) := "010";
    constant c_LBU : std_logic_vector(2 downto 0) := "100";
    constant c_LHU : std_logic_vector(2 downto 0) := "101";

begin
-------------------------------------------------------------------------------------------------------------------
    -- 3. Instanciação do DUT
-------------------------------------------------------------------------------------------------------------------
    DUT: entity work.load_unit
        port map (
            DMem_data_i  => s_dmem_data_i,
            Addr_LSB_i   => s_addr_lsb_i,
            Funct3_i     => s_funct3_i,
            Data_o       => s_data_o
        );

-------------------------------------------------------------------------------------------------------------------
    -- 4. Processo de Estímulo e Verificação Automática
-------------------------------------------------------------------------------------------------------------------
    STIMULUS: process is

        variable v_expected : std_logic_vector(31 downto 0);

    begin

        -- Mensagem inicial indicando o início dos testes
        report "INICIANDO VERIFICACAO DA LOAD UNIT..." severity note;

        -- Dado de teste principal (little-endian: 0x1122AA80)
        -- Byte 3: 0x11
        -- Byte 2: 0x22
        -- Byte 1: 0xAA (negativo, MSB=1)
        -- Byte 0: 0x80 (negativo, MSB=1)
        s_dmem_data_i <= x"1122AA80";
        wait for 1 ns;

        -- Teste 1: LW (Load Word)
        report "TESTE: LW" severity note;
        s_funct3_i <= c_LW;
        s_addr_lsb_i <= "00"; -- LSBs irrelevantes para LW
        v_expected := x"1122AA80";
        wait for 1 ns;
        ASSERT s_data_o = v_expected REPORT "ERRO [LW]: Falha ao carregar a palavra inteira!" SEVERITY error;

        -- Teste 2: LB (Load Byte com sinal)
        report "TESTE: LB (Byte 0, negativo: 0x80)" severity note;
        s_funct3_i <= c_LB;
        s_addr_lsb_i <= "00";
        v_expected := x"FFFFFF80"; -- 0x80 estendido com sinal
        wait for 1 ns;
        ASSERT s_data_o = v_expected REPORT "ERRO [LB pos 0]: Falha na extensao de sinal!" SEVERITY error;
        
        report "TESTE: LB (Byte 1, negativo: 0xAA)" severity note;
        s_addr_lsb_i <= "01";
        v_expected := x"FFFFFFAA"; -- 0xAA estendido com sinal
        wait for 1 ns;
        ASSERT s_data_o = v_expected REPORT "ERRO [LB pos 1]: Falha na extensao de sinal!" SEVERITY error;

        report "TESTE: LB (Byte 2, positivo: 0x22)" severity note;
        s_addr_lsb_i <= "10";
        v_expected := x"00000022"; -- 0x22 estendido com sinal (que é zero)
        wait for 1 ns;
        ASSERT s_data_o = v_expected REPORT "ERRO [LB pos 2]: Falha na extensao de sinal!" SEVERITY error;

        -- Teste 3: LBU (Load Byte sem sinal)
        report "TESTE: LBU (Byte 0, 0x80)" severity note;
        s_funct3_i <= c_LBU;
        s_addr_lsb_i <= "00";
        v_expected := x"00000080"; -- 0x80 estendido com zero
        wait for 1 ns;
        ASSERT s_data_o = v_expected REPORT "ERRO [LBU pos 0]: Falha na extensao de zero!" SEVERITY error;

        report "TESTE: LBU (Byte 1, 0xAA)" severity note;
        s_addr_lsb_i <= "01";
        v_expected := x"000000AA"; -- 0xAA estendido com zero
        wait for 1 ns;
        ASSERT s_data_o = v_expected REPORT "ERRO [LBU pos 1]: Falha na extensao de zero!" SEVERITY error;

        -- Teste 4: LH (Load Half-word com sinal)
        report "TESTE: LH (Half 0, negativo: 0xAA80)" severity note;
        s_funct3_i <= c_LH;
        s_addr_lsb_i <= "00"; -- Endereço LSB(1) = 0
        v_expected := x"FFFFAA80"; -- 0xAA80 estendido com sinal
        wait for 1 ns;
        ASSERT s_data_o = v_expected REPORT "ERRO [LH pos 0]: Falha na extensao de sinal!" SEVERITY error;

        report "TESTE: LH (Half 1, positivo: 0x1122)" severity note;
        s_addr_lsb_i <= "10"; -- Endereço LSB(1) = 1
        v_expected := x"00001122";
        wait for 1 ns;
        ASSERT s_data_o = v_expected REPORT "ERRO [LH pos 1]: Falha na extensao de sinal!" SEVERITY error;

        -- Teste 5: LHU (Load Half-word sem sinal)
        report "TESTE: LHU (Half 0, 0xAA80)" severity note;
        s_funct3_i <= c_LHU;
        s_addr_lsb_i <= "00"; -- Endereço LSB(1) = 0
        v_expected := x"0000AA80"; -- 0xAA80 estendido com zero
        wait for 1 ns;
        ASSERT s_data_o = v_expected REPORT "ERRO [LHU pos 0]: Falha na extensao de zero!" SEVERITY error;

        -- Mensagem final indicando que todos os testes finalizaram
        report "VERIFICACAO DA LOAD UNIT CONCLUIDA ---" severity note;
        
        -- Para a simulação para não rodar para sempre.
        std.env.stop;

    end process STIMULUS;

end architecture test;