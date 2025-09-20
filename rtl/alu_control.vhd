------------------------------------------------------------------------------------------------------------------
-- 
-- File: alu_control.vhd
--
--    █████╗ ██╗     ██╗   ██╗         ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  ██████╗ ██╗     
--   ██╔══██╗██║     ██║   ██║        ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗██║     
--   ███████║██║     ██║   ██║        ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║   ██║██║     
--   ██╔══██║██║     ██║   ██║        ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║   ██║██║     
--   ██║  ██║███████╗╚██████╔╝███████╗╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║╚██████╔╝███████╗
--   ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
--                                                                                                                                                                                                                                                           
-- 
-- Descrição : Unidade de Controle da ALU para um processador RISC-V de 32 bits (RV32I).
--             Decodifica o opcode e funct3/funct7 da instrução para gerar o sinal de controle
--             que determina a operação a ser realizada pela ALU.
--
-- Autor     : [André Maiolini]
-- Data      : [14/09/2025]
--
-------------------------------------------------------------------------------------------------------------------

library ieee;                     -- Biblioteca padrão IEEE
use ieee.std_logic_1164.all;      -- Tipos lógicos (std_logic, std_logic_vector)
use ieee.numeric_std.all;         -- Biblioteca para operações aritméticas com vetores lógicos (signed, unsigned)

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface da unidade de controle da unidade lógica e aritmética (ALU)
-------------------------------------------------------------------------------------------------------------------

entity alu_control is

  port (
    
    -- Entradas
    ALUOp_i       : in  std_logic_vector(1 downto 0);     -- Código de operação da ALU vindo da control_unit
    Funct3_i      : in  std_logic_vector(2 downto 0);     -- Campo funct3 da instrução (bits [14:12])
    Funct7_i      : in  std_logic_vector(6 downto 0);     -- Campo funct7 da instrução (bits [31:25])

    -- Saídas
    ALUControl_o  : out std_logic_vector(3 downto 0)      -- Sinal de controle da ALU (4 bits)

  ) ;

end alu_control ;

-------------------------------------------------------------------------------------------------------------------
-- ARQUITETURA: Implementação da unidade de controle da unidade lógica e aritmética (ALU)
-------------------------------------------------------------------------------------------------------------------

architecture rtl of alu_control is

    -- Constantes para os códigos de operação da ALU (4 bits)
    constant c_ALU_ADD  : std_logic_vector(3 downto 0) := "0000";
    constant c_ALU_SUB  : std_logic_vector(3 downto 0) := "1000";
    constant c_ALU_SLT  : std_logic_vector(3 downto 0) := "0010";
    constant c_ALU_SLTU : std_logic_vector(3 downto 0) := "0011";
    constant c_ALU_XOR  : std_logic_vector(3 downto 0) := "0100";
    constant c_ALU_OR   : std_logic_vector(3 downto 0) := "0110";
    constant c_ALU_AND  : std_logic_vector(3 downto 0) := "0111";
    constant c_ALU_SLL  : std_logic_vector(3 downto 0) := "0001";
    constant c_ALU_SRL  : std_logic_vector(3 downto 0) := "0101";
    constant c_ALU_SRA  : std_logic_vector(3 downto 0) := "1101";

begin

    DECODER: process(all)
    begin

        ----------------------------------------------------------------------------------------------------------
        -- NÍVEL 1: Decodificação com base em ALUOp_i
        ----------------------------------------------------------------------------------------------------------
        case ALUOp_i is
        
            -- Operação de soma 
            when "00" => ALUControl_o <= c_ALU_ADD ;

            -- Operação de subtração 
            when "01" => ALUControl_o <= c_ALU_SUB ;

            -- Avaliar funct3 e funct7
            when "10" => 

                --------------------------------------------------------------------------------------------------
                -- NÍVEL 2: Decodificação com base em funct3
                --------------------------------------------------------------------------------------------------
                case Funct3_i is 

                    when "000" =>

                        ------------------------------------------------------------------------------------------
                        -- NÍVEL 3: Decodificação com base em funct7(5) - diferenciar ADD e SUB 
                        ------------------------------------------------------------------------------------------
                        if Funct7_i(5) = '1' then
                            ALUControl_o <= C_ALU_SUB; -- SUB
                        else
                            ALUControl_o <= C_ALU_ADD; -- ADD
                        end if;

                    when "001" => ALUControl_o <= c_ALU_SLL;  -- SLL
                    when "010" => ALUControl_o <= c_ALU_SLT;  -- SLT
                    when "011" => ALUControl_o <= c_ALU_SLTU; -- SLTU
                    when "100" => ALUControl_o <= c_ALU_XOR;  -- XOR

                    when "101" =>

                        ------------------------------------------------------------------------------------------
                        -- NÍVEL 3: Decodificação com base em funct7(5) - diferenciar SRL e SRA
                        ------------------------------------------------------------------------------------------
                        if Funct7_i(5) = '1' then
                            ALUControl_o <= c_ALU_SRA; -- SRA
                        else
                            ALUControl_o <= c_ALU_SRL; -- SRL
                        end if;

                    when "110" => ALUControl_o <= c_ALU_OR;   -- OR
                    when "111" => ALUControl_o <= c_ALU_AND;  -- AND

                    -- Código não utilizado (caso padrão)
                    when others => ALUControl_o <= (others => 'X');

                end case ;

            -- I-Type Aritmético/Lógico
            when "11" => 

                --------------------------------------------------------------------------------------------------
                -- NÍVEL 2: Decodificação com base em funct3
                --------------------------------------------------------------------------------------------------
                case Funct3_i is

                    when "000" => ALUControl_o <= c_ALU_ADD;  -- ADDI
                    when "010" => ALUControl_o <= c_ALU_SLT;  -- SLTI
                    when "011" => ALUControl_o <= c_ALU_SLTU; -- SLTIU
                    when "100" => ALUControl_o <= c_ALU_XOR;  -- XORI
                    when "110" => ALUControl_o <= c_ALU_OR;   -- ORI
                    when "111" => ALUControl_o <= c_ALU_AND;  -- ANDI
                    when "001" => ALUControl_o <= c_ALU_SLL;  -- SLLI
                    when "101" => 

                        ------------------------------------------------------------------------------------------
                        -- NÍVEL 3: Decodificação com base em funct7(5) - diferenciar SRLI e SRAI
                        ------------------------------------------------------------------------------------------
                        if Funct7_i(5) = '1' then
                            ALUControl_o <= c_ALU_SRA; -- SRAI
                        else
                            ALUControl_o <= c_ALU_SRL; -- SRLI
                        end if;

                    when others => ALUControl_o <= (others => 'X');

                end case;

            -- Código não utilizado (caso padrão)
            when others => ALUControl_o <= (others => 'X');
        
        end case ;

    end process DECODER;

end rtl ; -- rtl

------------------------------------------------------------------------------------------------------------------