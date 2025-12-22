library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dual_port_ram is
    generic (
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

    -- ALTERAÇÃO 1: Usar 'shared variable' ao invés de 'signal'
    -- Isso permite que múltiplos processos acessem a memória sem conflito de drivers.
    shared variable ram : t_ram := (others => (others => '0'));

    -- Atributo para forçar inferência de Block RAM (importante para FPGA)
    attribute ram_style : string;
    attribute ram_style of ram : variable is "block";

begin

    -- =========================
    -- PORTA A
    -- =========================
    process(clk)
    begin
        if rising_edge(clk) then
            -- MODO READ-FIRST:
            -- 1. Lemos a variável para a saída (pega o valor atual/antigo)
            data_out_a <= ram(to_integer(unsigned(addr_a)));

            -- 2. Se houver escrita, atualizamos a variável
            -- Como a leitura acima já agendou o valor antigo para o sinal de saída,
            -- esta atualização só afetará a leitura do PRÓXIMO ciclo.
            if we_a = '1' then
                ram(to_integer(unsigned(addr_a))) := data_in_a; -- Note o uso de :=
            end if;
        end if;
    end process;

    -- =========================
    -- PORTA B
    -- =========================
    process(clk)
    begin
        if rising_edge(clk) then
            -- 1. Leitura (Read-First)
            data_out_b <= ram(to_integer(unsigned(addr_b)));

            -- 2. Escrita
            if we_b = '1' then
                ram(to_integer(unsigned(addr_b))) := data_in_b;
            end if;
        end if;
    end process;

end architecture;