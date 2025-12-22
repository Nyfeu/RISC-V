library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity boot_rom is
    generic (
        INIT_FILE  : string  := "build/boot/bootloader.hex";
        ADDR_WIDTH : integer := 10 -- 1 KB = 256 words
    );
    port (
        clk    : in  std_logic;
        addr_i : in  std_logic_vector(31 downto 0);
        data_o : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of boot_rom is

    -- (Types e Functions permanecem iguais...)
    type t_rom is array (0 to (2**ADDR_WIDTH)-1) of std_logic_vector(31 downto 0);
    
    impure function init_rom_from_file(file_name : string) return t_rom is
        -- (Sua função init_rom_from_file continua aqui...)
        file     f       : text open read_mode is file_name;
        variable l       : line;
        variable v_data  : std_logic_vector(31 downto 0);
        variable v_rom   : t_rom := (others => (others => '0'));
    begin
        for i in 0 to (2**ADDR_WIDTH)-1 loop
            exit when endfile(f);
            readline(f, l);
            hread(l, v_data);
            v_rom(i) := v_data;
        end loop;
        return v_rom;
    end function;

    signal rom_content : t_rom := init_rom_from_file(INIT_FILE);

    -- ATRIBUTO PARA FORÇAR BRAM (Sintaxe Xilinx/Vivado)
    attribute ram_style : string;
    attribute ram_style of rom_content : signal is "block";

begin

    process(clk)
        -- Variável auxiliar para facilitar a leitura e checagem
        variable v_addr_idx : std_logic_vector(ADDR_WIDTH-1 downto 0);
    begin
        if rising_edge(clk) then
            -- Pegamos apenas os bits relevantes para o índice
            v_addr_idx := addr_i(ADDR_WIDTH+1 downto 2);

            -- PROTEÇÃO: Verifica se há metavalues ('U', 'X', 'Z', etc.) no endereço
            if Is_X(v_addr_idx) then
                -- Se o endereço for lixo, sai 0 (evita o warning do to_integer)
                data_o <= (others => '0');
            else
                -- Conversão segura, pois sabemos que só tem '0' e '1'
                data_o <= rom_content(to_integer(unsigned(v_addr_idx)));
            end if;
        end if;
    end process;

end architecture;
