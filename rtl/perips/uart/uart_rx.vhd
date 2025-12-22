------------------------------------------------------------------------------------------------------------------
-- 
-- File: uart_tx.vhd
-- 
-- ██╗   ██╗ █████╗ ██████╗ ████████╗   ██████╗ ██╗  ██╗
-- ██║   ██║██╔══██╗██╔══██╗╚══██╔══╝   ██╔══██╗╚██╗██╔╝
-- ██║   ██║███████║██████╔╝   ██║█████╗██████╔╝ ╚███╔╝ 
-- ██║   ██║██╔══██║██╔══██╗   ██║╚════╝██╔══██╗ ██╔██╗ 
-- ╚██████╔╝██║  ██║██║  ██║   ██║      ██║  ██║██╔╝ ██╗
--  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝      ╚═╝  ╚═╝╚═╝  ╚═╝
-- 
-- Descrição : Módulo de Receptor UART
-- 
-- Autor     : [André Maiolini]
-- Data      : [22/12/2025]    
--
------------------------------------------------------------------------------------------------------------------
            
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface do Receptor UART
-------------------------------------------------------------------------------------------------------------------

entity uart_rx is
    generic (
        -- Frequência do Clock / Baud Rate
        -- Ex: 100 MHz / 115200 = 868
        CLK_FREQ  : integer := 100_000_000;
        BAUD_RATE : integer := 115_200
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        
        -- Entrada Física (Pino do FPGA)
        rx_serial : in  std_logic;
        
        -- Interface com o Processador
        rx_data   : out std_logic_vector(7 downto 0); -- Byte recebido
        rx_dv     : out std_logic                     -- Data Valid (Pulso de 1 ciclo)
    );
end entity;

-------------------------------------------------------------------------------------------------------------------
-- ARQUITETURA: Implementação do Receptor UART
-------------------------------------------------------------------------------------------------------------------

architecture rtl of uart_rx is

    -- Constantes de Tempo
    constant C_CYCLES_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
    constant C_HALF_BIT_CYCLES : integer := C_CYCLES_PER_BIT / 2;

    -- Máquina de Estados (FSM) para controle da recepção
    type t_state is (IDLE, START_BIT, DATA_BITS, STOP_BIT, CLEANUP);
    signal state : t_state := IDLE;

    -- Contadores
    signal r_cycle_count : integer range 0 to C_CYCLES_PER_BIT := 0;
    signal r_bit_index   : integer range 0 to 7 := 0;
    signal r_rx_byte     : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Sincronização de Metaestabilidade (Double Flop)
    -- O sinal rx_serial vem de fora e é assíncrono. Se entrar direto na FSM,
    -- pode causar falhas aleatórias. Passamos por 2 Flip-Flops para "limpar".
    signal r_rx_sync1 : std_logic := '1';
    signal r_rx_sync2 : std_logic := '1';

begin

    -- Processo de Sincronização (Metaestabilidade)
    process(clk)
    begin
        if rising_edge(clk) then
            r_rx_sync1 <= rx_serial;
            r_rx_sync2 <= r_rx_sync1; -- Usaremos r_rx_sync2 na lógica
        end if;
    end process;

    -- Máquina de Estados de Recepção
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state         <= IDLE;
                rx_dv         <= '0';
                rx_data       <= (others => '0');
                r_cycle_count <= 0;
                r_bit_index   <= 0;
            else
                case state is
                    
                    -- 1. Aguarda borda de descida (Falling Edge) do Start Bit
                    when IDLE =>
                        rx_dv         <= '0';
                        r_cycle_count <= 0;
                        r_bit_index   <= 0;

                        if r_rx_sync2 = '0' then -- Detectou Start Bit
                            state <= START_BIT;
                        end if;

                    -- 2. Verifica se o Start Bit é válido (Glitch Check)
                    -- Esperamos metade do tempo do bit e verificamos se ainda é 0.
                    when START_BIT =>
                        if r_cycle_count = C_HALF_BIT_CYCLES - 1 then
                            if r_rx_sync2 = '0' then
                                r_cycle_count <= 0; -- Reseta para contar bits inteiros agora
                                state         <= DATA_BITS;
                            else
                                state <= IDLE; -- Era só um ruído (glitch), volta pro inicio
                            end if;
                        else
                            r_cycle_count <= r_cycle_count + 1;
                        end if;

                    -- 3. Amostra os 8 bits de dados
                    when DATA_BITS =>
                        if r_cycle_count < C_CYCLES_PER_BIT - 1 then
                            r_cycle_count <= r_cycle_count + 1;
                        else
                            r_cycle_count <= 0;
                            
                            -- Amostra o bit atual
                            r_rx_byte(r_bit_index) <= r_rx_sync2;

                            -- Verifica se acabou
                            if r_bit_index < 7 then
                                r_bit_index <= r_bit_index + 1;
                            else
                                r_bit_index <= 0;
                                state       <= STOP_BIT;
                            end if;
                        end if;

                    -- 4. Aguarda o Stop Bit
                    when STOP_BIT =>
                        if r_cycle_count < C_CYCLES_PER_BIT - 1 then
                            r_cycle_count <= r_cycle_count + 1;
                        else
                            -- Poderíamos verificar se rx_sync2 é '1' aqui para erro de framing,
                            -- mas para simplificar, apenas assumimos sucesso.
                            rx_dv   <= '1';         -- Pulso de Data Valid
                            rx_data <= r_rx_byte;   -- Entrega o byte
                            state   <= CLEANUP;
                        end if;

                    -- 5. Estado extra para garantir que o pulso rx_dv dure apenas 1 clock
                    when CLEANUP =>
                        state <= IDLE;
                        rx_dv <= '0';

                end case;
            end if;
        end if;
    end process;

end architecture;

-------------------------------------------------------------------------------------------------------------------