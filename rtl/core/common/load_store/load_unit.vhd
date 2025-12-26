-- ===============================================================================================================================================
--
-- File: load_unit.vhd
--
--    ██╗      ██████╗   █████╗ ██████╗ ██╗   ██╗███╗   ██╗██╗████████╗
--    ██║     ██╔═══██╗ ██╔══██╗██╔══██╗██║   ██║████╗  ██║██║╚══██╔══╝
--    ██║     ██║   ██║ ███████║██║  ██║██║   ██║██╔██╗ ██║██║   ██║
--    ██║     ██║   ██║ ██╔══██║██║  ██║██║   ██║██║╚██╗██║██║   ██║
--    ███████╗╚██████╔╝ ██║  ██║██████╔╝╚██████╔╝██║ ╚████║██║   ██║
--    ╚══════╝ ╚═════╝  ╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═╝   ╚═╝
--
-- Autor     : [André Maiolini]
-- Data      : [15/09/2025]
--
-- ============+=================================================================================================================================
--   Descrição |
-- ------------+
--
--  Esta é a Unidade de Carga (Load Unit) para o processador RISC-V.
--
--  PROPÓSITO:
--  A memória principal do processador é otimizada para acessar dados em "palavras" de 32 bits. No entanto, linguagens
--  de programação como C precisam manipular dados de tamanhos menores, como caracteres (char, 1 byte) e inteiros
--  curtos (short, 2 bytes). Esta unidade atua como uma "ponte" inteligente entre a memória e o banco de registradores.
--
--  Ela recebe a palavra inteira de 32 bits que a memória sempre entrega e, com base na instrução de 'load'
--  (lw, lh, lhu, lb, lbu), ela extrai o pedaço correto de dado (byte ou meia-palavra), o estende para 32 bits e o
--  envia para o estágio de write-back. Sem esta unidade, o processador só conseguiria ler palavras inteiras,
--  tornando impossível, por exemplo, ler uma string caractere por caractere.
--
-- =====================+=========================================================================================================================
--  Endianness          |
-- ---------------------+
--
--  Este módulo foi projetado para uma arquitetura Little-Endian, que é o padrão do RISC-V.
--
--  O QUE ISSO SIGNIFICA?
--  Imagine uma palavra de 32 bits na memória no endereço 0x100. Ela contém 4 bytes.
--  Em um sistema Little-Endian, o byte MENOS significativo (o "menor" ou "little end") é armazenado no
--  endereço de memória mais baixo.
--
--  Exemplo: A palavra 0x11223344 é armazenada assim:
--
--  Endereço de Memória | Conteúdo do Byte
--  --------------------+------------------
--         0x103        |       0x11  (Byte 3) - Mais significativo
--         0x102        |       0x22  (Byte 2)
--         0x101        |       0x33  (Byte 1)
--         0x100        |       0x44  (Byte 0) - Menos significativo
--
--  Quando a memória entrega a palavra inteira, ela chega como `DMem_data_i = "00010001 00100010 00110011 01000100"`.
--  Este módulo usa os 2 bits menos significativos do endereço (Addr_LSB_i) para saber qual byte/meia-palavra extrair.
--
--  - Addr_LSB_i = "00" -> Pega o Byte 0 (bits 7 downto 0).
--  - Addr_LSB_i = "01" -> Pega o Byte 1 (bits 15 downto 8).
--  - Addr_LSB_i = "10" -> Pega o Byte 2 (bits 23 downto 16).
--  - Addr_LSB_i = "11" -> Pega o Byte 3 (bits 31 downto 24).
--
-- ===============================================================================================================================================

library ieee;                     -- Biblioteca padrão IEEE
use ieee.std_logic_1164.all;      -- Tipos lógicos (std_logic, std_logic_vector)
use ieee.numeric_std.all;         -- Biblioteca para operações aritméticas com vetores lógicos (signed, unsigned)
use work.riscv_isa_pkg.all;       -- Contém todas as definições da ISA RISC-V especificadas

--------------------------------------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface da unidade de carregamento (load_unit)
--------------------------------------------------------------------------------------------------------------------------------------------------

entity load_unit is

    port (

        -- Entradas
        DMem_data_i  : in  std_logic_vector(31 downto 0); -- A palavra de 32 bits vinda da memória de dados
        Addr_LSB_i   : in  std_logic_vector(1 downto 0);  -- Os 2 bits menos significativos do endereço da ALU (seleciona o byte/half)
        Funct3_i     : in  std_logic_vector(2 downto 0);  -- Campo funct3 da instrução (define o tipo de load)

        -- Saída
        Data_o       : out std_logic_vector(31 downto 0)  -- O dado final de 32 bits, corretamente extraído e estendido

    );

end entity load_unit;

--------------------------------------------------------------------------------------------------------------------------------------------------
-- ARQUITETURA: Implementação da load_unit
--------------------------------------------------------------------------------------------------------------------------------------------------

architecture rtl of load_unit is
begin

    -- Processo combinacional que seleciona e estende o dado correto
    LOAD_UNIT_PROC: process(DMem_data_i, Addr_LSB_i, Funct3_i)

        variable v_byte : std_logic_vector(7 downto 0);
        variable v_half : std_logic_vector(15 downto 0);

    begin

        -- O default é indefinido para ajudar na detecção de bugs (evita latches)
        Data_o <= (others => 'X');

        -- Decodifica o tipo de Load usando o campo funct3
        case Funct3_i is

            -- LW (Load Word): a palavra inteira é passada diretamente.
            when c_LW =>
                Data_o <= DMem_data_i;

            -- LH (Load Half-word, com extensão de sinal)
            when c_LH =>
                -- Usa o bit 1 do endereço para escolher a metade correta da palavra
                case Addr_LSB_i(1) is
                    when '0' => v_half := DMem_data_i(15 downto 0);  -- Metade inferior
                    when '1' => v_half := DMem_data_i(31 downto 16); -- Metade superior
                    when others => v_half := (others => 'X');
                end case;
                -- Redimensiona para 32 bits, preenchendo com o bit de sinal (o mais à esquerda)
                Data_o <= std_logic_vector(resize(signed(v_half), 32));

            -- LHU (Load Half-word, com extensão de zero)
            when c_LHU =>
                case Addr_LSB_i(1) is
                    when '0' => v_half := DMem_data_i(15 downto 0);
                    when '1' => v_half := DMem_data_i(31 downto 16);
                    when others => v_half := (others => 'X');
                end case;
                -- Redimensiona para 32 bits, preenchendo com zeros
                Data_o <= std_logic_vector(resize(unsigned(v_half), 32));

            -- LB (Load Byte, com extensão de sinal)
            when c_LB =>
                -- Usa os 2 bits do endereço para escolher o byte correto
                case Addr_LSB_i is
                    when "00"   => v_byte := DMem_data_i(7 downto 0);
                    when "01"   => v_byte := DMem_data_i(15 downto 8);
                    when "10"   => v_byte := DMem_data_i(23 downto 16);
                    when "11"   => v_byte := DMem_data_i(31 downto 24);
                    when others => v_byte := (others => 'X');
                end case;
                Data_o <= std_logic_vector(resize(signed(v_byte), 32));

            -- LBU (Load Byte, com extensão de zero)
            when c_LBU =>
                case Addr_LSB_i is
                    when "00"   => v_byte := DMem_data_i(7 downto 0);
                    when "01"   => v_byte := DMem_data_i(15 downto 8);
                    when "10"   => v_byte := DMem_data_i(23 downto 16);
                    when "11"   => v_byte := DMem_data_i(31 downto 24);
                    when others => v_byte := (others => 'X');
                end case;
                Data_o <= std_logic_vector(resize(unsigned(v_byte), 32));

            -- Caso padrão para outros valores de funct3
            when others => Data_o <= (others => 'X');

        end case;

    end process LOAD_UNIT_PROC;

end architecture rtl;

--------------------------------------------------------------------------------------------------------------------------------------------------