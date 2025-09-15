-- sim/processor_top_tb.vhd (versão final com correção para warnings)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library work;
use work.memory_loader_pkg.all;

entity processor_top_tb is
    generic (
        PROGRAM_PATH : string := "program.hex"
    );
end entity processor_top_tb;

architecture test of processor_top_tb is
    -- Componente processor_top (sem alterações)
    component processor_top is
        port (
            CLK_i              : in  std_logic;
            Reset_i            : in  std_logic;
            IMem_addr_o        : out std_logic_vector(31 downto 0);
            IMem_data_i        : in  std_logic_vector(31 downto 0);
            DMem_addr_o        : out std_logic_vector(31 downto 0);
            DMem_data_i        : in  std_logic_vector(31 downto 0);
            DMem_data_o        : out std_logic_vector(31 downto 0);
            DMem_writeEnable_o : out std_logic
        );
    end component;

    -- Sinais
    signal s_clk               : std_logic := '0';
    signal s_reset             : std_logic := '1';
    signal s_imem_addr         : std_logic_vector(31 downto 0) := (others => '0');
    signal s_imem_data         : std_logic_vector(31 downto 0) := (others => '0');
    signal s_dmem_addr         : std_logic_vector(31 downto 0) := (others => '0');
    signal s_dmem_data_read    : std_logic_vector(31 downto 0) := (others => '0');
    signal s_dmem_data_write   : std_logic_vector(31 downto 0) := (others => '0');
    signal s_dmem_write_enable : std_logic := '0';
    
    signal s_memory : t_mem_array := init_mem_from_hex(PROGRAM_PATH);
    
    constant CLK_PERIOD : time := 10 ns;

begin
    -- DUT (sem alterações)
    DUT: entity work.processor_top port map (
        CLK_i              => s_clk,
        Reset_i            => s_reset,
        IMem_addr_o        => s_imem_addr,
        IMem_data_i        => s_imem_data,
        DMem_addr_o        => s_dmem_addr,
        DMem_data_i        => s_dmem_data_read,
        DMem_data_o        => s_dmem_data_write,
        DMem_writeEnable_o => s_dmem_write_enable
    );

    s_clk <= not s_clk after CLK_PERIOD / 2;

    -- >> CORREÇÃO: Mover a lógica de leitura para dentro de um processo <<
    -- Este processo é sensível a mudanças nos endereços e no reset.
    MEMORY_READ_PROC: process(s_reset, s_imem_addr, s_dmem_addr)
    begin
        -- Se o processador está em reset, a memória retorna '0'
        if s_reset = '1' then
            s_imem_data      <= (others => '0');
            s_dmem_data_read <= (others => '0');
        -- Somente se o reset estiver inativo, fazemos a leitura real
        else
            s_imem_data      <= s_memory(to_integer(unsigned(s_imem_addr(11 downto 2))));
            s_dmem_data_read <= s_memory(to_integer(unsigned(s_dmem_addr(11 downto 2))));
        end if;
    end process MEMORY_READ_PROC;

    MEM_WRITE_PROC: process(s_clk)
    begin
        if rising_edge(s_clk) then
            if s_dmem_write_enable = '1' then
                s_memory(to_integer(unsigned(s_dmem_addr(11 downto 2)))) <= s_dmem_data_write;
            end if;
        end if;
    end process MEM_WRITE_PROC;

    -- Estímulo (sem alterações)
    stimulus_proc: process is
    begin
        report "INICIANDO SIMULACAO DO PROCESSADOR COMPLETO..." severity note;
        wait for CLK_PERIOD * 2;
        s_reset <= '0';
        wait for CLK_PERIOD * 200;
        report "SIMULACAO CONCLUIDA." severity note;
        std.env.stop;
        wait;
    end process stimulus_proc;

end architecture test;