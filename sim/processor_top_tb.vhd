-- sim/processor_top_tb.vhd (versão atualizada)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.prog_pkg.all;

entity processor_top_tb is
    generic (
        PROGRAM_PATH : string := "program.hex"
    );
end entity processor_top_tb;

architecture test of processor_top_tb is

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

    -- -----------------------
    -- Funções utilitárias
    -- -----------------------
    -- detecta se existe metavalue em um std_logic_vector
    function is_defined(v : std_logic_vector) return boolean is
    begin
        for i in v'range loop
            if v(i) = 'U' or v(i) = 'X' or v(i) = 'Z' or v(i) = '-' then
                return false;
            end if;
        end loop;
        return true;
    end function;

    -- converte de forma segura para integer; se indefinido, retorna 0
    function safe_to_integer(v : std_logic_vector) return integer is
    begin
        if is_defined(v) then
            return to_integer(unsigned(v));
        else
            return 0;
        end if;
    end function;

    -- opcional: garanta que indice esteja no range 0..(1023)
    function safe_mem_index(v : std_logic_vector) return integer is
        variable idx : integer;
    begin
        idx := safe_to_integer(v);
        if idx < 0 then
            return 0;
        elsif idx > 1023 then
            return 1023;
        else
            return idx;
        end if;
    end function;

    -- sinais
    signal s_clk               : std_logic := '0';
    signal s_reset             : std_logic := '1'; -- mantenha reset ativo no tempo 0
    signal s_imem_addr         : std_logic_vector(31 downto 0) := (others => '0');
    signal s_imem_data         : std_logic_vector(31 downto 0) := (others => '0');
    signal s_dmem_addr         : std_logic_vector(31 downto 0) := (others => '0');
    signal s_dmem_data_read    : std_logic_vector(31 downto 0) := (others => '0');
    signal s_dmem_data_write   : std_logic_vector(31 downto 0) := (others => '0');
    signal s_dmem_write_enable : std_logic := '0';

    -- memória (carrega o prog_mem do package)
    signal s_memory : t_mem_array := prog_mem;

    constant CLK_PERIOD : time := 10 ns;

begin

    -- DUT
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

    -- clock
    s_clk <= not s_clk after CLK_PERIOD / 2;

    -- lógica da memória (usa índices seguros)
    -- se o endereço vier undefined, safe_mem_index retorna 0
    s_imem_data <= s_memory(safe_mem_index(s_imem_addr(11 downto 2)));
    s_dmem_data_read <= s_memory(safe_mem_index(s_dmem_addr(11 downto 2)));

    MEM_WRITE_PROC: process(s_clk)
        variable idx : integer;
    begin
        if rising_edge(s_clk) then
            if s_dmem_write_enable = '1' then
                idx := safe_mem_index(s_dmem_addr(11 downto 2));
                s_memory(idx) <= s_dmem_data_write;
            end if;
        end if;
    end process MEM_WRITE_PROC;

    -- estímulo (aplica reset por alguns ciclos desde t=0)
    stimulus_proc: process is
    begin
        report "INICIANDO SIMULACAO DO PROCESSADOR COMPLETO..." severity note;

        -- reset ativo no começo (já inicializado como '1'), aguarda alguns ciclos
        wait for CLK_PERIOD * 2;
        s_reset <= '0';  -- desativa reset após 2 ciclos

        -- espera 10 ciclos de clock para inspeção (ajuste se necessário)
        wait for CLK_PERIOD * 10;

        report "SIMULACAO CONCLUIDA." severity note;
        report "Fim da simulacao apos 10 ciclos para inspecao." severity note;
        std.env.stop;
        wait;
    end process stimulus_proc;

end architecture test;
