library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Wrapper do Sistema de Memória para Simulação
-- Descrição: Integra memórias e periféricos usando o novo Bus Interconnect (Hub Central).
-------------------------------------------------------------------------------------------------------------------

entity memory_wrapper is
    port (
        clk_i          : in  std_logic;
        reset_i        : in  std_logic;
        
        -- Interface de Instruções (Simulando o Fetch do Core)
        imem_addr_i    : in  std_logic_vector(31 downto 0);
        imem_data_o    : out std_logic_vector(31 downto 0);
        
        -- Interface de Dados (Simulando Load/Store do Core)
        dmem_addr_i    : in  std_logic_vector(31 downto 0);
        dmem_data_i    : in  std_logic_vector(31 downto 0); -- Dados para escrita (DMem_data_o do core)
        dmem_we_i      : in  std_logic;                     -- Sinal de escrita (DMem_writeEnable_o)
        dmem_data_o    : out std_logic_vector(31 downto 0)  -- Dados lidos (DMem_data_i do core)
    );
end entity;

architecture sim of memory_wrapper is

    -- Sinais de interconexão: ROM (Dual Port)
    signal s_rom_addr_a, s_rom_addr_b : std_logic_vector(31 downto 0);
    signal s_rom_data_a, s_rom_data_b : std_logic_vector(31 downto 0);
    signal s_rom_sel_b                : std_logic;

    -- Sinais de interconexão: RAM (Dual Port)
    signal s_ram_addr_a, s_ram_addr_b : std_logic_vector(31 downto 0);
    signal s_ram_data_a_out           : std_logic_vector(31 downto 0);
    signal s_ram_data_b_in            : std_logic_vector(31 downto 0);
    signal s_ram_data_b_out           : std_logic_vector(31 downto 0);
    signal s_ram_we_b                 : std_logic_vector(3 downto 0);
    signal s_ram_sel_b                : std_logic;

    -- Sinais de interconexão: UART
    signal s_uart_addr                : std_logic_vector(3 downto 0);
    signal s_uart_data_in             : std_logic_vector(31 downto 0);
    signal s_uart_data_out            : std_logic_vector(31 downto 0);
    signal s_uart_we                  : std_logic;
    signal s_uart_sel                 : std_logic;

    -- Sinal auxiliar para converter WE de 1 bit para 4 bits
    signal s_dmem_we_vec              : std_logic_vector(3 downto 0);

begin

    -- Expande bit único de entrada para controlar os 4 bytes da palavra
    s_dmem_we_vec <= (others => dmem_we_i);

    -- =========================================================================
    -- 1. HUB DE INTERCONEXÃO (BUS INTERCONNECT)
    -- =========================================================================
    U_BUS: entity work.bus_interconnect
        port map (
            -- Interface Core (Instruction & Data)
            imem_addr_i     => imem_addr_i,
            imem_data_o     => imem_data_o,
            dmem_addr_i     => dmem_addr_i,
            dmem_data_i     => dmem_data_i,
            dmem_we_i       => s_dmem_we_vec,
            dmem_data_o     => dmem_data_o,

            -- Interface ROM
            rom_addr_a_o    => s_rom_addr_a,
            rom_data_a_i    => s_rom_data_a,
            rom_addr_b_o    => s_rom_addr_b,
            rom_data_b_i    => s_rom_data_b,
            rom_sel_b_o     => s_rom_sel_b,

            -- Interface RAM
            ram_addr_a_o    => s_ram_addr_a,
            ram_data_a_i    => s_ram_data_a_out,
            ram_addr_b_o    => s_ram_addr_b,
            ram_data_b_i    => s_ram_data_b_out,
            ram_data_b_o    => s_ram_data_b_in,
            ram_we_b_o      => s_ram_we_b,
            ram_sel_b_o     => s_ram_sel_b,

            -- Interface UART
            uart_addr_o     => s_uart_addr,
            uart_data_i     => s_uart_data_out,
            uart_data_o     => s_uart_data_in,
            uart_we_o       => s_uart_we,
            uart_sel_o      => s_uart_sel
        );

    -- =========================================================================
    -- 2. COMPONENTES REAIS
    -- =========================================================================

    -- Boot ROM (0x00000000)
    U_ROM: entity work.boot_rom
        port map (
            clk      => clk_i,
            addr_a_i => s_rom_addr_a,        -- Porta A: Fetch
            data_a_o => s_rom_data_a,
            addr_b_i => s_rom_addr_b,        -- Porta B: Dados
            data_b_o => s_rom_data_b
        );

    -- RAM (0x80000000)
    U_RAM: entity work.dual_port_ram
        generic map (ADDR_WIDTH => 12)
        port map (
            clk        => clk_i,
            we_a       => (others => '0'),   -- Porta A apenas para leitura
            addr_a     => s_ram_addr_a(13 downto 2),
            data_in_a  => (others => '0'),
            data_out_a => s_ram_data_a_out,
            we_b       => s_ram_we_b,        -- Escrita qualificada pelo Barramento
            addr_b     => s_ram_addr_b(13 downto 2),
            data_in_b  => s_ram_data_b_in,   -- Dados vindos do Barramento
            data_out_b => s_ram_data_b_out   -- Dados lidos para o Barramento
        );

    -- UART Controller (0x10000000)
    U_UART: entity work.uart_controller
        port map (
            clk         => clk_i,
            rst         => reset_i,
            sel_i       => s_uart_sel,       -- Seleção via Barramento
            we_i        => s_uart_we,        -- Escrita via Barramento
            addr_i      => s_uart_addr,      -- Endereço simplificado (4 bits)
            data_i      => s_uart_data_in,
            data_o      => s_uart_data_out, 
            uart_tx_pin => open,
            uart_rx_pin => '1'               -- Pull-up na entrada RX
        );

end architecture;