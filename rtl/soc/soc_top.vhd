------------------------------------------------------------------------------------------------------------------
-- 
-- File: soc_top.vhd
-- 
--   ███████╗ ██████╗  ██████╗    ████████╗ ██████╗ ██████╗ 
--   ██╔════╝██╔═══██╗██╔════╝    ╚══██╔══╝██╔═══██╗██╔══██╗
--   ███████╗██║   ██║██║            ██║   ██║   ██║██████╔╝
--   ╚════██║██║   ██║██║            ██║   ██║   ██║██╔═══╝ 
--   ███████║╚██████╔╝╚██████╗       ██║   ╚██████╔╝██║     
--   ╚══════╝ ╚═════╝  ╚═════╝       ╚═╝    ╚═════╝ ╚═╝     
-- 
-- Descrição : Top-level do SoC RISC-V. 
--             Integra o núcleo processador com memórias e periféricos reais.
--             Utiliza arquitetura Dual-Port para ROM e RAM (Harvard Modificada).
-- 
-- Autor     : [André Maiolini]
-- Data      : [23/12/2025]    
--
------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_pkg.all;

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface do SoC Top-Level (SOC_TOP)
-------------------------------------------------------------------------------------------------------------------

entity soc_top is
    generic (
        CLK_FREQ  : integer := 100_000_000;  -- Frequência do Clock em Hz
        BAUD_RATE : integer := 115_200       -- Taxa de Baud para a UART
    );
    port (
        -- Sinais de Controle do Sistema ------------------------------------------------
        CLK_i       : in  std_logic;         -- Clock de sistema
        Reset_i     : in  std_logic;         -- Sinal de Reset assíncrono ativo alto
        
        -- Pinos Externos (Interface com a FPGA) ----------------------------------------
        UART_TX_o   : out std_logic;         -- Saída TX da UART
        UART_RX_i   : in  std_logic          -- Entrada RX da UART
    );
end entity;

-------------------------------------------------------------------------------------------------------------------
-- ARQUITETURA: Implementação do SoC Top-Level (SOC_TOP)
-------------------------------------------------------------------------------------------------------------------

architecture rtl of soc_top is

    -- === Sinais Internos do Processador ===

    -- Sinais de Instrução (IMem)
    signal s_imem_addr   : std_logic_vector(31 downto 0);
    signal s_imem_data   : std_logic_vector(31 downto 0);
    
    -- Sinais de Dados (DMem)
    signal s_dmem_addr   : std_logic_vector(31 downto 0);
    signal s_dmem_data_w : std_logic_vector(31 downto 0);
    signal s_dmem_data_r : std_logic_vector(31 downto 0);
    signal s_dmem_we     : std_logic;

    -- === Sinais de Seleção do Barramento ===

    signal s_rom_sel     : std_logic;
    signal s_ram_sel     : std_logic;
    signal s_ram_we      : std_logic;
    signal s_uart_sel    : std_logic;
    signal s_uart_we     : std_logic;

    -- === Dados de Saída dos Componentes ===

    -- Sinais de dados da Boot ROM
    signal s_rom_data_fetch : std_logic_vector(31 downto 0); -- Porta A (Instrução)
    signal s_rom_data_bus   : std_logic_vector(31 downto 0); -- Porta B (Dados)

    -- Sinais de dados da RAM
    signal s_ram_data_fetch : std_logic_vector(31 downto 0); -- Porta A (Instrução)
    signal s_ram_data_bus   : std_logic_vector(31 downto 0); -- Porta B (Dados)

    -- Sinais de dados da UART
    signal s_uart_data      : std_logic_vector(31 downto 0);

begin

    -- =========================================================================
    -- 1. NÚCLEO PROCESSADOR (CPU)
    -- =========================================================================
    U_CORE: entity work.processor_top
        port map (
            CLK_i               => CLK_i,
            Reset_i             => Reset_i,
            IMem_addr_o         => s_imem_addr,
            IMem_data_i         => s_imem_data,
            DMem_addr_o         => s_dmem_addr,
            DMem_data_o         => s_dmem_data_w,
            DMem_data_i         => s_dmem_data_r,
            DMem_writeEnable_o  => s_dmem_we
        );

    -- =========================================================================
    -- 2. BARRAMENTO (BUS INTERCONNECT) - Lado de Dados (DMem)
    -- =========================================================================
    U_BUS: entity work.bus_interconnect
        port map (
            -- Interface com o Processador -----
            addr_i         => s_dmem_addr,
            data_i         => s_dmem_data_w,
            we_i           => s_dmem_we,
            data_o         => s_dmem_data_r,
            
            -- Interface: Boot ROM (0x00000000)
            rom_data_i     => s_rom_data_bus, -- Conectado à Porta B (Dados)
            rom_sel_o      => s_rom_sel,
            
            -- Interface: RAM (0x80000000)
            ram_data_i     => s_ram_data_bus, -- Conectado à Porta B (Dados)
            ram_sel_o      => s_ram_sel,
            ram_we_o       => s_ram_we,
            
            -- Interface: UART (0x10000000)
            uart_data_i    => s_uart_data,
            uart_sel_o     => s_uart_sel,
            uart_we_o      => s_uart_we
        );

    -- =========================================================================
    -- 3. BOOT ROM (0x00000000) - Dual Port
    -- =========================================================================
    U_ROM: entity work.boot_rom
        port map (
            clk      => CLK_i,
            addr_a_i => s_imem_addr,        -- Porta A: Fetch de Instrução
            data_a_o => s_rom_data_fetch,
            addr_b_i => s_dmem_addr,        -- Porta B: Leitura de Dados (via Barramento)
            data_b_o => s_rom_data_bus
        );

    -- =========================================================================
    -- 4. RAM (0x80000000) - Dual Port
    -- =========================================================================
    U_RAM: entity work.dual_port_ram
        generic map (ADDR_WIDTH => 12)              -- 16 KB de espaço de endereçamento
        port map (

            -- Sinais de controle do componente
            clk        => CLK_i,                    -- Clock comum para ambas as portas

            -- Porta A: Instruções (Fetch)
            we_a       => '0',                      -- Read-Only para o PC
            addr_a     => s_imem_addr(13 downto 2), -- Endereço da instrução (word address)
            data_in_a  => (others => '0'),          -- Não usado (leitura apenas)
            data_out_a => s_ram_data_fetch,         -- Dados lidos para o PC

            -- Porta B: Dados (Load/Store)
            we_b       => s_ram_we,                 -- Sinal de escrita
            addr_b     => s_dmem_addr(13 downto 2), -- Endereço de dados (word address)
            data_in_b  => s_dmem_data_w,            -- Dados a serem escritos na RAM
            data_out_b => s_ram_data_bus            -- Dados lidos da RAM para o Barramento

        );

    -- =========================================================================
    -- 5. MUX DE INSTRUÇÃO (Seleção de Fetch)
    -- =========================================================================
    -- Decide se o PC busca código da ROM (0x0...) ou da RAM (0x8...)
    s_imem_data <= s_rom_data_fetch when s_imem_addr(31) = '0' else s_ram_data_fetch;

    -- =========================================================================
    -- 6. CONTROLADOR UART (0x10000000)
    -- =========================================================================
    U_UART: entity work.uart_controller
        generic map (CLK_FREQ => CLK_FREQ, BAUD_RATE => BAUD_RATE)
        port map (
            clk         => CLK_i,
            rst         => Reset_i,
            sel_i       => s_uart_sel,
            we_i        => s_uart_we,
            addr_i      => s_dmem_addr(3 downto 0),
            data_i      => s_dmem_data_w,
            data_o      => s_uart_data,
            uart_tx_pin => UART_TX_o,
            uart_rx_pin => UART_RX_i
        );

end architecture;

------------------------------------------------------------------------------------------------------------------