------------------------------------------------------------------------------------------------------------------
-- 
-- File: branch_unit.vhd
--   
--   ██████╗ ██████╗  █████╗ ███╗   ██╗ ██████╗██╗  ██╗        ██╗   ██╗███╗   ██╗██╗████████╗
--   ██╔══██╗██╔══██╗██╔══██╗████╗  ██║██╔════╝██║  ██║        ██║   ██║████╗  ██║██║╚══██╔══╝
--   ██████╔╝██████╔╝███████║██╔██╗ ██║██║     ███████║        ██║   ██║██╔██╗ ██║██║   ██║   
--   ██╔══██╗██╔══██╗██╔══██║██║╚██╗██║██║     ██╔══██║        ██║   ██║██║╚██╗██║██║   ██║   
--   ██████╔╝██║  ██║██║  ██║██║ ╚████║╚██████╗██║  ██║███████╗╚██████╔╝██║ ╚████║██║   ██║   
--   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝   ╚═╝                                                                                           
--                                                               
-- Descrição : Avalia as condições para desvios condicionais (branches).
--
-- Autor     : [André Maiolini]
-- Data      : [21/09/2025]
--
-------------------------------------------------------------------------------------------------------------------

library ieee;                     -- Biblioteca padrão IEEE
use ieee.std_logic_1164.all;      -- Tipos lógicos (std_logic, std_logic_vector)
use ieee.numeric_std.all;         -- Biblioteca para operações aritméticas com vetores lógicos (signed, unsigned)

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface da Branch Unit
-------------------------------------------------------------------------------------------------------------------

entity branch_unit  is

    port (

        -- Entradas
        Branch_i       : in  std_logic;                     -- Sinal do decoder principal que indica uma instrução de branch
        Funct3_i       : in  std_logic_vector(2 downto 0);  -- Campo Funct3 para identificar o tipo de branch
        ALU_Zero_i     : in  std_logic;                     -- Flag 'Zero' vinda da ALU
        ALU_Negative_i : in  std_logic;                     -- Flag 'Negative' vinda da ALU

        -- Saída
        BranchTaken_o  : out std_logic                      -- '1' se a condição do branch for atendida 

    );

end entity branch_unit ;

-------------------------------------------------------------------------------------------------------------------
-- ARQUITETURA: Implementação da Branch Unit
-------------------------------------------------------------------------------------------------------------------

architecture rtl of branch_unit  is
begin

    BRANCH_CONDITION_LOGIC: process(all)
    begin
        if Branch_i = '1' then
            case Funct3_i is
                when "000" => -- BEQ
                    if ALU_Zero_i = '1' then BranchTaken_o <= '1'; else BranchTaken_o <= '0'; end if;
                when "001" => -- BNE
                    if ALU_Zero_i = '0' then BranchTaken_o <= '1'; else BranchTaken_o <= '0'; end if;
                when "100" | "110" => -- BLT, BLTU
                    if ALU_Negative_i = '1' then BranchTaken_o <= '1'; else BranchTaken_o <= '0'; end if;
                when "101" | "111" => -- BGE, BGEU
                    if ALU_Negative_i = '0' then BranchTaken_o <= '1'; else BranchTaken_o <= '0'; end if;
                when others =>
                    BranchTaken_o <= '0';
            end case;
        else
            BranchTaken_o <= '0';
        end if;
    end process BRANCH_CONDITION_LOGIC;

end architecture rtl;

-------------------------------------------------------------------------------------------------------------------