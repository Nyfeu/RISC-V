-------------------------------------------------------------------------------------------------------------------
--
-- File: store_unit.vhd
--
--   ███████╗████████╗ ██████╗ ██████╗ ███████╗        ██╗   ██╗███╗   ██╗██╗████████╗
--   ██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝        ██║   ██║████╗  ██║██║╚══██╔══╝
--   ███████╗   ██║   ██║   ██║██████╔╝█████╗          ██║   ██║██╔██╗ ██║██║   ██║   
--   ╚════██║   ██║   ██║   ██║██╔══██╗██╔══╝          ██║   ██║██║╚██╗██║██║   ██║   
--   ███████║   ██║   ╚██████╔╝██║  ██║███████╗███████╗╚██████╔╝██║ ╚████║██║   ██║   
--   ╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝   ╚═╝                                                                                 
--
-- Descrição: Prepara os dados para as instruções de armazenamento (store).
--
-- Autor:     [André Maiolini]
-- Data:      [22/09/2025]
-- 
-------------------------------------------------------------------------------------------------------------------

library ieee;                     -- Biblioteca padrão IEEE
use ieee.std_logic_1164.all;      -- Tipos lógicos (std_logic, std_logic_vector)
use ieee.numeric_std.all;         -- Biblioteca para operações aritméticas com vetores lógicos (signed, unsigned)

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface da Unidade de Armazenamento
-------------------------------------------------------------------------------------------------------------------

entity store_unit is

    port (

        -- Entradas

        Data_from_DMEM_i : in  std_logic_vector(31 downto 0); -- Dado lido da memória
        WriteData_i      : in  std_logic_vector(31 downto 0); -- Dado vindo do registrador rs2
        Addr_LSB_i       : in  std_logic_vector(1 downto 0);  -- 2 LSBs do endereço da ALU
        Funct3_i         : in  std_logic_vector(2 downto 0);  -- Funct3 para identificar SW, SH, SB

        -- Saída

        Data_o           : out std_logic_vector(31 downto 0)  -- Dado de 32 bits preparado para a DMEM

    );

end entity store_unit;

-------------------------------------------------------------------------------------------------------------------
-- ARQUITETURA: Implementação da store_unit
-------------------------------------------------------------------------------------------------------------------

architecture rtl of store_unit is

    -- Constantes para os valores de funct3
    constant c_SB : std_logic_vector(2 downto 0) := "000"; -- Store Byte
    constant c_SH : std_logic_vector(2 downto 0) := "001"; -- Store Half-word
    constant c_SW : std_logic_vector(2 downto 0) := "010"; -- Store Word

begin

    STORE_UNIT_PROC: process(all)

        variable v_data_to_write : std_logic_vector(31 downto 0);

    begin

        -- Por padrão, o dado a ser escrito é o que já está na memória.
        -- Isso preserva os bytes para escritas parciais.
        v_data_to_write := Data_from_DMEM_i;

        case Funct3_i is

            -- SW (Store Word): Sobrescreve a palavra inteira.
            when c_SW =>
                v_data_to_write := WriteData_i;

            -- SH (Store Half-word): Modifica apenas a metade correta.
            when c_SH =>
                case Addr_LSB_i(1) is
                    when '0' => -- Metade inferior
                        v_data_to_write(15 downto 0) := WriteData_i(15 downto 0);
                    when '1' => -- Metade superior
                        v_data_to_write(31 downto 16) := WriteData_i(15 downto 0);
                    when others => null;
                end case;

            -- SB (Store Byte): Modifica apenas o byte correto.
            when c_SB =>
                case Addr_LSB_i is
                    when "00"   => v_data_to_write(7 downto 0)   := WriteData_i(7 downto 0);
                    when "01"   => v_data_to_write(15 downto 8)  := WriteData_i(7 downto 0);
                    when "10"   => v_data_to_write(23 downto 16) := WriteData_i(7 downto 0);
                    when "11"   => v_data_to_write(31 downto 24) := WriteData_i(7 downto 0);
                    when others => null;
                end case;

            when others =>

                -- Para instruções que não são store, a escrita na memória
                -- estará desabilitada pelo control, mas por segurança,
                -- passamos o valor original sem modificação.
                null;

        end case;

        Data_o <= v_data_to_write;

    end process STORE_UNIT_PROC;

end architecture rtl; -- rtl

-------------------------------------------------------------------------------------------------------------------