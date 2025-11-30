-------------------------------------------------------------------------------------------------------------------
--
-- File: store_unit_tb.vhd (Testbench para a Unidade de Armazenamento)
--
-- Descrição: Este testbench autoverificável testa a Unidade de Armazenamento (Store Unit).
--            Simula as diferentes instruções de 'store' (sw, sb, sh) com diferentes alinhamentos de endereço,
--            para garantir que o byte ou meia-palavra correta seja armazenado corretamente.
--
-------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_pkg.all;

-- A entidade de um testbench é sempre vazia.
entity store_unit_tb is
end entity store_unit_tb;

architecture test of store_unit_tb is

-------------------------------------------------------------------------------------------------------------------
    -- 1. Declaração do Componente sob Teste (DUT)
-------------------------------------------------------------------------------------------------------------------

    component store_unit is
        port (
            Data_from_DMEM_i : in  std_logic_vector(31 downto 0);
            WriteData_i      : in  std_logic_vector(31 downto 0);
            Addr_LSB_i       : in  std_logic_vector(1 downto 0);
            Funct3_i         : in  std_logic_vector(2 downto 0);
            Data_o           : out std_logic_vector(31 downto 0)
        );
    end component store_unit;

-------------------------------------------------------------------------------------------------------------------
    -- 2. Sinais para o Teste
-------------------------------------------------------------------------------------------------------------------

    -- Sinais
    signal s_data_from_dmem_i : std_logic_vector(31 downto 0);
    signal s_write_data_i     : std_logic_vector(31 downto 0);
    signal s_addr_lsb_i       : std_logic_vector(1 downto 0);
    signal s_funct3_i         : std_logic_vector(2 downto 0);
    signal s_data_o           : std_logic_vector(31 downto 0);

begin

-------------------------------------------------------------------------------------------------------------------
    -- 3. Instanciação do DUT
-------------------------------------------------------------------------------------------------------------------

    DUT: entity work.store_unit
        port map (
            Data_from_DMEM_i => s_data_from_dmem_i,
            WriteData_i => s_write_data_i,
            Addr_LSB_i  => s_addr_lsb_i,
            Funct3_i    => s_funct3_i,
            Data_o      => s_data_o
        );

-------------------------------------------------------------------------------------------------------------------
    -- 4. Processo de Estímulo e Verificação Automática
-------------------------------------------------------------------------------------------------------------------

    STIMULUS: process is
    begin
        
        report "INICIANDO VERIFICACAO DA STORE UNIT (v2)..." severity note;

        -- Valor que simulamos já existir na memória
        s_data_from_dmem_i <= x"AAAAAAAA";
        -- Valor que queremos escrever
        s_write_data_i <= x"12345678";
        wait for 1 ns;

        -- Teste 1: SW (Store Word) - Deve sobrescrever tudo
        report "TESTE: SW" severity note;
        s_funct3_i <= c_SW;
        s_addr_lsb_i <= "00";
        wait for 1 ns;
        ASSERT s_data_o = x"12345678" REPORT "ERRO [SW]: Nao sobrescreveu a palavra inteira." SEVERITY error;

        -- Teste 2: SH (Store Half-word) - Deve preservar a metade superior
        report "TESTE: SH (Addr LSB = 0)" severity note;
        s_funct3_i <= c_SH;
        s_addr_lsb_i <= "00";
        wait for 1 ns;
        -- Esperado: AAAA5678
        ASSERT s_data_o = x"AAAA5678" REPORT "ERRO [SH pos 0]: Nao preservou a metade superior." SEVERITY error;

        -- Teste 3: SB (Store Byte) - Deve preservar os outros 3 bytes
        report "TESTE: SB (Addr LSB = 1)" severity note;
        s_funct3_i <= c_SB;
        s_addr_lsb_i <= "01";
        wait for 1 ns;
        -- Esperado: AA AA 78 AA
        ASSERT s_data_o = x"AAAA78AA" REPORT "ERRO [SB pos 1]: Nao preservou os outros bytes." SEVERITY error;

        report "VERIFICACAO DA STORE UNIT CONCLUIDA." severity note;
        std.env.stop;

    end process STIMULUS;

end architecture test;