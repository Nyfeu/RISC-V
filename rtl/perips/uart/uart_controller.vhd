------------------------------------------------------------------------------------------------------------------
-- 
-- File: uart_controller.vhd
-- 
-- ██╗   ██╗ █████╗ ██████╗ ████████╗
-- ██║   ██║██╔══██╗██╔══██╗╚══██╔══╝
-- ██║   ██║███████║██████╔╝   ██║   
-- ██║   ██║██╔══██║██╔══██╗   ██║   
-- ╚██████╔╝██║  ██║██║  ██║   ██║   
--  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   
-- 
-- Descrição : Módulo Controlador UART (TX + RX)
-- 
-- Autor     : [André Maiolini]
-- Data      : [22/12/2025]    
--
------------------------------------------------------------------------------------------------------------------
           
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface do Controlador UART
-------------------------------------------------------------------------------------------------------------------

entity uart_controller is
    generic (
        CLK_FREQ  : integer := 100_000_000;
        BAUD_RATE : integer := 115_200
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;

        -- Interface de Barramento
        -- O processador ativa 'sel_i' quando o endereço começa com '0x1'...
        sel_i       : in  std_logic; 
        we_i        : in  std_logic;                     -- 1=Write, 0=Read
        addr_i      : in  std_logic_vector(3 downto 0);  -- Apenas o Offset (0x0, 0x4...)
        data_i      : in  std_logic_vector(31 downto 0); -- Dado vindo da CPU
        data_o      : out std_logic_vector(31 downto 0); -- Dado indo para CPU

        -- Pinos Físicos
        uart_tx_pin : out std_logic;
        uart_rx_pin : in  std_logic
    );
end entity;

-------------------------------------------------------------------------------------------------------------------
-- ARQUITETURA: Implementação do Controlador UART
-------------------------------------------------------------------------------------------------------------------

architecture rtl of uart_controller is

    -- Sinais de interconexão interna
    signal w_tx_start : std_logic;
    signal w_tx_data  : std_logic_vector(7 downto 0);
    signal w_tx_busy  : std_logic;
    
    signal w_rx_data  : std_logic_vector(7 downto 0);
    signal w_rx_dv    : std_logic;

    -- Registradores de Memória Mapeada
    signal r_rx_stored_data : std_logic_vector(7 downto 0);
    signal r_rx_ready       : std_logic; 

begin

    -- 1. Instância do Transmissor (TX)
    u_tx : entity work.uart_tx
    generic map (CLK_FREQ => CLK_FREQ, BAUD_RATE => BAUD_RATE)
    port map (
        clk       => clk,
        rst       => rst,
        tx_start  => w_tx_start,
        tx_data   => w_tx_data,
        tx_busy   => w_tx_busy,
        tx_serial => uart_tx_pin
    );

    -- 2. Instância do Receptor (RX)
    u_rx : entity work.uart_rx
    generic map (CLK_FREQ => CLK_FREQ, BAUD_RATE => BAUD_RATE)
    port map (
        clk       => clk,
        rst       => rst,
        rx_serial => uart_rx_pin,
        rx_data   => w_rx_data,
        rx_dv     => w_rx_dv
    );

    -- 3. Escrita da CPU (CPU -> TX)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                w_tx_start <= '0';
                w_tx_data  <= (others => '0');
            else
                w_tx_start <= '0'; -- Pulso dura 1 ciclo por padrão

                -- Se CPU selecionou este módulo E quer escrever
                if sel_i = '1' and we_i = '1' then
                    -- Se o endereço for 0 (Data Register)
                    if unsigned(addr_i) = 0 then
                        w_tx_data  <= data_i(7 downto 0);
                        w_tx_start <= '1'; -- Dispara transmissão
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- 4. Leitura e Flags (RX -> CPU)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r_rx_ready       <= '0';
                r_rx_stored_data <= (others => '0');
            else
                -- Prioridade 1: Chegou dado novo do hardware
                if w_rx_dv = '1' then
                    r_rx_stored_data <= w_rx_data;
                    r_rx_ready       <= '1'; -- Avisa CPU: "Tem carta pra você"
                
                -- Prioridade 2: CPU leu o dado (Limpa a flag)
                elsif sel_i = '1' and we_i = '0' and unsigned(addr_i) = 0 then
                    r_rx_ready <= '0'; 
                end if;
            end if;
        end if;
    end process;

    -- 5. Multiplexador de Saída (Leitura Combinacional)
    process(addr_i, r_rx_stored_data, w_tx_busy, r_rx_ready)
    begin
        data_o <= (others => '0'); -- Default

        case to_integer(unsigned(addr_i)) is
            -- Offset 0: Dados
            when 0 => 
                data_o(7 downto 0) <= r_rx_stored_data;
            
            -- Offset 4: Status
            when 4 => 
                data_o(0) <= w_tx_busy;  -- Bit 0
                data_o(1) <= r_rx_ready; -- Bit 1
            
            when others =>
                data_o <= (others => '0');
        end case;
    end process;

end architecture;

-------------------------------------------------------------------------------------------------------------------