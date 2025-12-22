library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dual_port_ram is
    generic (
        -- 4096 palavras * 4 bytes = 16 KB
        ADDR_WIDTH : integer := 12; 
        DATA_WIDTH : integer := 32
    );
    port (
        clk        : in  std_logic;
        
        -- Porta A
        we_a       : in  std_logic;
        addr_a     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        data_in_a  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_a : out std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Porta B
        we_b       : in  std_logic;
        addr_b     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        data_in_b  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_out_b : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of dual_port_ram is

    type t_ram is array (0 to (2**ADDR_WIDTH)-1)
        of std_logic_vector(DATA_WIDTH-1 downto 0);

    signal ram : t_ram := (others => (others => '0'));

    attribute ram_style : string;
    attribute ram_style of ram : signal is "block";

begin

    process(clk)
    begin
        if rising_edge(clk) then

            -- =========================
            -- PORTA A
            -- =========================
            if we_a = '1' then
                ram(to_integer(unsigned(addr_a))) <= data_in_a;
            end if;
            data_out_a <= ram(to_integer(unsigned(addr_a)));

            -- =========================
            -- PORTA B
            -- =========================
            if we_b = '1' then
                ram(to_integer(unsigned(addr_b))) <= data_in_b;
            end if;
            data_out_b <= ram(to_integer(unsigned(addr_b)));

        end if;
    end process;

end architecture;