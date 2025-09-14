-------------------------------------------------------------------------------------------------------------------
-- 
-- File: ALU.vhd
--
--    █████╗ ██╗     ██╗   ██╗
--   ██╔══██╗██║     ██║   ██║
--   ███████║██║     ██║   ██║
--   ██╔══██║██║     ██║   ██║
--   ██║  ██║███████╗╚██████╔╝
--   ╚═╝  ╚═╝╚══════╝ ╚═════╝ 
-- 
-- Descrição : Unidade Lógica e Aritmética (ALU) de 32 bits.
--             Realiza operações aritméticas e lógicas básicas
--             a partir de sinais de controle (ALUControl_i).
--
-- Autor     : [André Maiolini]
-- Data      : [14/09/2025]
--
-------------------------------------------------------------------------------------------------------------------
--
--                    A_i          B_i
--                     |            |
--                     v            v
--                 _________    _________
--                 \        \  /        /
--                  \        \/        /                               ->> Zero_o: flag de zero;
--                   \                /                                ->> A_i, B_i: operandos de entrada;
--   ALUControl_i --> \     ALU      / --> FLAGS (Zero_o)              ->> ALUControl_i: seleção da operação;
--                     \            /                                  ->> Result_o: resultado da operação.
--                      \__________/
--                           |
--                           v
--                        data_out
--
-------------------------------------------------------------------------------------------------------------------

library ieee;                        -- Biblioteca padrão IEEE
use ieee.std_logic_1164.all;         -- Tipos lógicos (std_logic, std_logic_vector)

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface da ALU
-------------------------------------------------------------------------------------------------------------------

entity alu is

    port (

        -- Operandos de entrada (32 bits cada)
        A_i           : in  std_logic_vector(31 downto 0);    
        B_i           : in  std_logic_vector(31 downto 0);

        -- Código de operação da ALU (ex.: 0111 = AND, 0110 = OR, 0000 = ADD, etc.)
        ALUControl_i  : in  std_logic_vector(3 downto 0);     

        -- Saída com resultado da operação
        Result_o      : out std_logic_vector(31 downto 0);    

        -- Flag "Zero": ativo em '1' quando o resultado for igual a zero
        Zero_o        : out std_logic         

    );

end entity alu;

-------------------------------------------------------------------------------------------------------------------
-- ARQUITETURA: Implementação da ALU
-------------------------------------------------------------------------------------------------------------------

architecture rtl of alu is
begin

    

end architecture rtl;

-------------------------------------------------------------------------------------------------------------------