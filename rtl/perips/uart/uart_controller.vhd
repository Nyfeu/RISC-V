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
-- Data      : [01/01/2026]    
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
        CLK_FREQ    : integer := 100_000_000;                -- Configurado para 100 MHz
        BAUD_RATE   : integer := 115_200                     -- 115200 bps
    );
    port (

        -- Sinais de controle (sincronismo)

        clk         : in  std_logic;
        rst         : in  std_logic;

        -- Interface de Barramento

        sel_i       : in  std_logic; 
        we_i        : in  std_logic;                       -- 1=Write, 0=Read
        addr_i      : in  std_logic_vector( 3 downto 0);   -- Apenas o Offset (0x0, 0x4...)
        data_i      : in  std_logic_vector(31 downto 0);   -- Dado vindo da CPU
        data_o      : out std_logic_vector(31 downto 0);   -- Dado indo para CPU

        -- Pinos Físicos

        uart_tx_pin : out std_logic;
        uart_rx_pin : in  std_logic
    
    );
end entity;

architecture rtl of uart_controller is

    constant c_bit_period : integer := CLK_FREQ / BAUD_RATE;
    
    -- TX
    type t_tx_state is (TX_IDLE, TX_START, TX_DATA, TX_STOP);
    signal tx_state       : t_tx_state;
    signal tx_timer       : integer range 0 to c_bit_period;
    signal tx_bit_idx     : integer range 0 to 7;
    signal tx_shifter     : std_logic_vector(7 downto 0);
    signal tx_busy_flag   : std_logic;

    -- RX
    type t_rx_state is (RX_IDLE, RX_START, RX_DATA, RX_STOP);
    signal rx_state       : t_rx_state;
    signal rx_timer       : integer range 0 to c_bit_period;
    signal rx_bit_idx     : integer range 0 to 7;
    signal rx_shifter     : std_logic_vector(7 downto 0);
    signal rx_data_buf    : std_logic_vector(7 downto 0); 
    signal rx_valid_flag  : std_logic; 

    -- Sync RX Pin
    signal rx_pin_sync    : std_logic_vector(1 downto 0);
    signal rx_bit_val     : std_logic;

    -- Sinais de Controle Interno
    signal tx_start_pulse  : std_logic;
    signal r_tx_data_latch : std_logic_vector(7 downto 0);

begin

    rx_bit_val <= rx_pin_sync(1);
    process(clk)
    begin
        if rising_edge(clk) then
            rx_pin_sync <= rx_pin_sync(0) & uart_rx_pin;
        end if;
    end process;

    -- 1. TX STATE MACHINE
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                tx_state <= TX_IDLE;
                uart_tx_pin <= '1';
                tx_busy_flag <= '0';
                tx_timer <= 0;
                tx_bit_idx <= 0;
                tx_shifter <= (others => '0');
            else
                case tx_state is
                    when TX_IDLE =>
                        uart_tx_pin <= '1';
                        
                        -- Se o pulso chegou, começa
                        if tx_start_pulse = '1' then
                            tx_shifter   <= r_tx_data_latch; 
                            tx_state     <= TX_START;
                            tx_busy_flag <= '1'; -- Ocupado!
                        else
                            tx_busy_flag <= '0'; -- Livre
                        end if;
                        tx_timer <= 0;

                    when TX_START =>
                        uart_tx_pin <= '0';
                        tx_busy_flag <= '1'; -- Garante busy durante envio
                        if tx_timer < c_bit_period - 1 then
                            tx_timer <= tx_timer + 1;
                        else
                            tx_timer <= 0;
                            tx_state <= TX_DATA;
                            tx_bit_idx <= 0;
                        end if;

                    when TX_DATA =>
                        uart_tx_pin <= tx_shifter(tx_bit_idx);
                        if tx_timer < c_bit_period - 1 then
                            tx_timer <= tx_timer + 1;
                        else
                            tx_timer <= 0;
                            if tx_bit_idx < 7 then
                                tx_bit_idx <= tx_bit_idx + 1;
                            else
                                tx_state <= TX_STOP;
                            end if;
                        end if;

                    when TX_STOP =>
                        uart_tx_pin <= '1';
                        if tx_timer < c_bit_period - 1 then
                            tx_timer <= tx_timer + 1;
                        else
                            tx_state <= TX_IDLE;
                            -- Busy vai cair pra 0 no proximo ciclo quando entrar em IDLE
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- 2. RX STATE MACHINE
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rx_state <= RX_IDLE;
                rx_timer <= 0;
                rx_bit_idx <= 0;
                rx_data_buf <= (others => '0');
                rx_shifter <= (others => '0');
            else
                case rx_state is
                    when RX_IDLE =>
                        rx_timer <= 0;
                        rx_bit_idx <= 0;
                        if rx_bit_val = '0' then rx_state <= RX_START; end if;
                    when RX_START =>
                        if rx_timer < (c_bit_period / 2) - 1 then
                            rx_timer <= rx_timer + 1;
                        else
                            rx_timer <= 0;
                            if rx_bit_val = '0' then rx_state <= RX_DATA;
                            else rx_state <= RX_IDLE; end if;
                        end if;
                    when RX_DATA =>
                        if rx_timer < c_bit_period - 1 then
                            rx_timer <= rx_timer + 1;
                        else
                            rx_timer <= 0;
                            rx_shifter(rx_bit_idx) <= rx_bit_val;
                            if rx_bit_idx < 7 then rx_bit_idx <= rx_bit_idx + 1;
                            else rx_state <= RX_STOP; end if;
                        end if;
                    when RX_STOP =>
                        if rx_timer < c_bit_period - 1 then
                            rx_timer <= rx_timer + 1;
                        else
                            rx_data_buf <= rx_shifter;
                            rx_state <= RX_IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- 3. INTERFACE DE CONTROLE
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                tx_start_pulse  <= '0';
                rx_valid_flag   <= '0';
                r_tx_data_latch <= (others => '0');
            else
                tx_start_pulse <= '0'; -- Pulso de 1 ciclo

                -- Hardware RX update
                if rx_state = RX_STOP and rx_timer = c_bit_period - 1 then
                    rx_valid_flag <= '1';
                end if;

                -- CPU WRITE
                if sel_i = '1' and we_i = '1' then
                    if unsigned(addr_i) = 0 then
                        -- Se TX livre, aceita o dado
                        -- IMPORTANTE: usou-se o estado tx_state ou flag para checar busy.
                        -- Mas aqui a flag pode demorar 1 ciclo para subir. 
                        -- O software deve checar antes. 
                        if tx_busy_flag = '0' then
                            tx_start_pulse  <= '1';
                            r_tx_data_latch <= data_i(7 downto 0); 
                        end if;
                    elsif unsigned(addr_i) = 4 then
                        if data_i(0) = '1' then
                            rx_valid_flag <= '0';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- 4. SAÍDA (ASYNC/COMBINACIONAL)
    process(addr_i, rx_data_buf, tx_busy_flag, rx_valid_flag)
    begin
        data_o <= (others => '0');
        case to_integer(unsigned(addr_i)) is
            when 0 => 
                data_o(7 downto 0) <= rx_data_buf;
            when 4 => 
                data_o(0) <= tx_busy_flag;
                data_o(1) <= rx_valid_flag;
            when others => null;
        end case;
    end process;

end architecture; -- rtl 

------------------------------------------------------------------------------------------------------------------