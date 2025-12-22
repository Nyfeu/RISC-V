------------------------------------------------------------------------------------------------------------------
-- 
-- File: uart_tx.vhd
-- 
-- ██╗   ██╗ █████╗ ██████╗ ████████╗████████╗██╗  ██╗
-- ██║   ██║██╔══██╗██╔══██╗╚══██╔══╝╚══██╔══╝╚██╗██╔╝
-- ██║   ██║███████║██████╔╝   ██║█████╗██║    ╚███╔╝ 
-- ██║   ██║██╔══██║██╔══██╗   ██║╚════╝██║    ██╔██╗ 
-- ╚██████╔╝██║  ██║██║  ██║   ██║      ██║   ██╔╝ ██╗
--  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝
-- 
-- Descrição : Módulo de Transmissor UART
-- 
-- Autor     : [André Maiolini]
-- Data      : [22/12/2025]    
--
------------------------------------------------------------------------------------------------------------------
                                                
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface do Transmissor UART
-------------------------------------------------------------------------------------------------------------------

entity uart_tx is
    generic (
        -- Frequência do Clock / Baud Rate
        -- Ex: 100 MHz / 115200 = 868
        CLK_FREQ  : integer := 100_000_000;
        BAUD_RATE : integer := 115_200
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        
        -- Interface com o Processador
        tx_start  : in  std_logic;                    -- Pulso para iniciar envio
        tx_data   : in  std_logic_vector(7 downto 0); -- Byte a enviar
        tx_busy   : out std_logic;                    -- 1 = enviando, 0 = livre
        
        -- Saída Física (Pino do FPGA)
        tx_serial : out std_logic
    );
end entity;

-------------------------------------------------------------------------------------------------------------------
-- ARQUITETURA: Implementação do Transmissor UART
-------------------------------------------------------------------------------------------------------------------

architecture rtl of uart_tx is

    -- Constante de divisão de clock
    constant C_CYCLES_PER_BIT : integer := CLK_FREQ / BAUD_RATE;

    -- Máquina de Estados (FSM) para controle da transmissão
    type t_state is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : t_state := IDLE;

    -- Registradores internos
    signal r_cycle_count : integer range 0 to C_CYCLES_PER_BIT := 0;
    signal r_bit_index   : integer range 0 to 7 := 0;
    signal r_data        : std_logic_vector(7 downto 0) := (others => '0');
    
begin

    -- Processo Principal da FSM do Transmissor UART
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state         <= IDLE;
                tx_busy       <= '0';
                tx_serial     <= '1'; -- Linha em repouso é HIGH (Idle High)
                r_cycle_count <= 0;
                r_bit_index   <= 0;
            else
                case state is
                    
                    -- Estado 1: Aguardando comando
                    when IDLE =>
                        tx_serial     <= '1';
                        tx_busy       <= '0';
                        r_cycle_count <= 0;
                        r_bit_index   <= 0;
                        
                        if tx_start = '1' then
                            r_data  <= tx_data; -- Captura o dado
                            tx_busy <= '1';
                            state   <= START_BIT;
                        end if;

                    -- Estado 2: Envia Start Bit (Low)
                    when START_BIT =>
                        tx_serial <= '0';
                        
                        -- Espera o tempo de 1 bit
                        if r_cycle_count < C_CYCLES_PER_BIT - 1 then
                            r_cycle_count <= r_cycle_count + 1;
                        else
                            r_cycle_count <= 0;
                            state         <= DATA_BITS;
                        end if;

                    -- Estado 3: Envia os 8 bits (LSB primeiro)
                    when DATA_BITS =>
                        tx_serial <= r_data(r_bit_index);
                        
                        if r_cycle_count < C_CYCLES_PER_BIT - 1 then
                            r_cycle_count <= r_cycle_count + 1;
                        else
                            r_cycle_count <= 0;
                            
                            -- Verifica se já enviou os 8 bits
                            if r_bit_index < 7 then
                                r_bit_index <= r_bit_index + 1;
                            else
                                r_bit_index <= 0;
                                state       <= STOP_BIT;
                            end if;
                        end if;

                    -- Estado 4: Envia Stop Bit (High)
                    when STOP_BIT =>
                        tx_serial <= '1';
                        
                        if r_cycle_count < C_CYCLES_PER_BIT - 1 then
                            r_cycle_count <= r_cycle_count + 1;
                        else
                            r_cycle_count <= 0;
                            state         <= IDLE; -- Fim da transmissão
                        end if;
                        
                end case;
            end if;
        end if;
    end process;

end architecture;

-------------------------------------------------------------------------------------------------------------------