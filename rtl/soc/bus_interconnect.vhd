------------------------------------------------------------------------------------------------------------------
-- 
-- File: bus_interconnect.vhd
-- 
--  ██████╗ ██╗   ██╗███████╗ 
--  ██╔══██╗██║   ██║██╔════╝ 
--  ██████╔╝██║   ██║███████╗ 
--  ██╔══██╗██║   ██║╚════██║ 
--  ██████╔╝╚██████╔╝███████║ 
--  ╚═════╝  ╚═════╝ ╚══════╝ 
-- 
-- Descrição : Interconectador de Barramento (Bus Interconnect) para o SoC RISC-V.
--             Realiza a decodificação de endereços e roteamento de dados entre 
--             o Processador (Mestre) e os componentes endereçáveis (ROM, RAM, UART).
-- 
-- Autor     : [André Maiolini]
-- Data      : [23/12/2025]    
--
------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface do Interconectador de Barramento (BUS INTERCONNECT)
-------------------------------------------------------------------------------------------------------------------

entity bus_interconnect is
    port (
        -- Interface com o Processador
        addr_i         : in  std_logic_vector(31 downto 0);
        data_i         : in  std_logic_vector(31 downto 0);
        we_i           : in  std_logic;
        data_o         : out std_logic_vector(31 downto 0);

        -- Interface: Boot ROM (0x00000000)
        rom_data_i     : in  std_logic_vector(31 downto 0);
        rom_sel_o      : out std_logic;

        -- Interface: RAM (0x80000000)
        ram_data_i     : in  std_logic_vector(31 downto 0);
        ram_sel_o      : out std_logic;
        ram_we_o       : out std_logic;

        -- Interface: UART (0x10000000)
        uart_data_i    : in  std_logic_vector(31 downto 0);
        uart_sel_o     : out std_logic;
        uart_we_o      : out std_logic
    );
end entity;

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface do Interconectador de Barramento (BUS INTERCONNECT)
-------------------------------------------------------------------------------------------------------------------

architecture rtl of bus_interconnect is

    -- Sinais internos de seleção (Chip Select)
    signal s_sel_rom  : std_logic;
    signal s_sel_uart : std_logic;
    signal s_sel_ram  : std_logic;

begin

    -- =========================================================================
    -- 1. DECODIFICAÇÃO DE ENDEREÇO
    -- =========================================================================
    -- ROM:  0x00000000 até 0x0FFFFFFF
    -- UART: 0x10000000 até 0x1FFFFFFF
    -- RAM:  0x80000000 até 0x8FFFFFFF
    
    s_sel_rom  <= '1' when addr_i(31 downto 28) = x"0" else '0';
    s_sel_uart <= '1' when addr_i(31 downto 28) = x"1" else '0';
    s_sel_ram  <= '1' when addr_i(31 downto 28) = x"8" else '0';

    -- Saídas de seleção para dos componentes

    rom_sel_o  <= s_sel_rom;
    uart_sel_o <= s_sel_uart;
    ram_sel_o  <= s_sel_ram;

    -- Lógica de escrita (Write Enable qualificado pelo endereço)

    uart_we_o  <= we_i and s_sel_uart;
    ram_we_o   <= we_i and s_sel_ram;

    -- =========================================================================
    -- 2. MULTIPLEXAÇÃO DE LEITURA (Mux de Entrada do Processador)
    -- =========================================================================
    
    process(s_sel_rom, s_sel_uart, s_sel_ram, rom_data_i, uart_data_i, ram_data_i)
    begin
        if s_sel_rom = '1' then
            data_o <= rom_data_i;
        elsif s_sel_uart = '1' then
            data_o <= uart_data_i;
        elsif s_sel_ram = '1' then
            data_o <= ram_data_i;
        else
            data_o <= (others => '0'); -- Endereço inválido retorna 0
        end if;
    end process;

end architecture;

------------------------------------------------------------------------------------------------------------------