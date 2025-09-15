------------------------------------------------------------------------------------------------------------------
-- 
-- File: control_unit.vhd
--
--    ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  ██████╗ ██╗             ██╗   ██╗███╗   ██╗██╗████████╗
--   ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗██║             ██║   ██║████╗  ██║██║╚══██╔══╝
--   ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║   ██║██║             ██║   ██║██╔██╗ ██║██║   ██║   
--   ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║   ██║██║             ██║   ██║██║╚██╗██║██║   ██║   
--   ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║╚██████╔╝███████╗███████╗╚██████╔╝██║ ╚████║██║   ██║   
--    ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝   ╚═╝                                                                                                                                                            
-- 
-- Descrição : Unidade de Controle para um processador RISC-V de 32 bits (RV32I).
--             Decodifica o opcode da instrução e gera os sinais de controle
--             necessários para a operação correta do datapath.
--
-- Autor     : [André Maiolini]
-- Data      : [14/09/2025]
--
-------------------------------------------------------------------------------------------------------------------

library ieee;                     -- Biblioteca padrão IEEE
use ieee.std_logic_1164.all;      -- Tipos lógicos (std_logic, std_logic_vector)
use ieee.numeric_std.all;         -- Biblioteca para operações aritméticas com vetores lógicos (signed, unsigned)

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface da unidade de controle
-------------------------------------------------------------------------------------------------------------------

entity control_unit is

  port (
    
    -- Entradas
    Opcode_i      : in  std_logic_vector(6 downto 0);    -- Opcode da instrução (bits [6:0])

    -- Saídas
    RegWrite_o    : out std_logic;                       -- Habilita escrita no banco de registradores
    ALUSrc_o      : out std_logic;                       -- Seleciona a fonte do segundo operando da ALU (0=registrador, 1=imediato)
    MemtoReg_o    : out std_logic;                       -- Seleciona a fonte dos dados a serem escritos no registrador (0=ALU, 1=Memória)
    MemRead_o     : out std_logic;                       -- Habilita leitura da memória
    MemWrite_o    : out std_logic;                       -- Habilita escrita na memória
    Branch_o      : out std_logic;                       -- Indica desvio condicional
    Jump_o        : out std_logic;                       -- Indica salto incondicional
    ALUOp_o       : out std_logic_vector(1 downto 0)     -- Código de operação da ALU (2 bits)

  ) ;

end control_unit ;

-------------------------------------------------------------------------------------------------------------------
-- ARQUITETURA: Implementação da unidade de controle
-------------------------------------------------------------------------------------------------------------------

architecture rtl of control_unit is

    -- Constantes para os opcodes das instruções RISC-V
    constant c_OPCODE_R_TYPE : std_logic_vector(6 downto 0) := "0110011";
    constant c_OPCODE_LOAD   : std_logic_vector(6 downto 0) := "0000011";
    constant c_OPCODE_STORE  : std_logic_vector(6 downto 0) := "0100011";
    constant c_OPCODE_BRANCH : std_logic_vector(6 downto 0) := "1100011";
    constant c_OPCODE_IMM    : std_logic_vector(6 downto 0) := "0010011";
    constant c_OPCODE_JAL    : std_logic_vector(6 downto 0) := "1101111";
    constant c_OPCODE_JALR   : std_logic_vector(6 downto 0) := "1100111";
    constant c_OPCODE_LUI    : std_logic_vector(6 downto 0) := "0110111";
    constant c_OPCODE_AUIPC  : std_logic_vector(6 downto 0) := "0010111";

begin

    -- Processo de decodificação do opcode para gerar os sinais de controle
    DECODER: process(Opcode_i)
    begin

        case Opcode_i is
        
            when c_OPCODE_R_TYPE =>

                -- Valores para instruções R-Type (add, sub, and, or, etc.)
                RegWrite_o <= '1';
                ALUSrc_o   <= '0';
                MemtoReg_o <= '0';
                MemRead_o  <= '0';
                MemWrite_o <= '0';
                Branch_o   <= '0';
                Jump_o     <= '0';
                ALUOp_o    <= "10";  -- Operação da ALU definida pelo funct3/funct7

            when c_OPCODE_LOAD =>

                -- Valores para instruções de carga (lw, lb, lh)
                RegWrite_o <= '1';
                ALUSrc_o   <= '1';
                MemtoReg_o <= '1';
                MemRead_o  <= '1';
                MemWrite_o <= '0';
                Branch_o   <= '0';
                Jump_o     <= '0';
                ALUOp_o    <= "00";  -- Operação de soma para cálculo de endereço

            when c_OPCODE_STORE =>

                -- Valores para instruções de armazenamento (sw, sb, sh)
                RegWrite_o <= '0';
                ALUSrc_o   <= '1';
                MemtoReg_o <= '0';   -- Don't care (não tem efeito sem MemWrite_o)    
                MemRead_o  <= '0';
                MemWrite_o <= '1';
                Branch_o   <= '0';
                Jump_o     <= '0';
                ALUOp_o    <= "00";  -- Operação de soma para cálculo de endereço

            when c_OPCODE_BRANCH =>

                -- Valores para instruções de desvio (BEQ, BNE, etc.)
                RegWrite_o <= '0';
                AluSrc_o   <= '0';
                MemtoReg_o <= '0';   -- Don't care (não tem efeito sem RegWrite_o)
                MemRead_o  <= '0';
                MemWrite_o <= '0';
                Branch_o   <= '1';
                Jump_o     <= '0';
                ALUOp_o    <= "01";  -- Operação de subtração para comparação

            when c_OPCODE_IMM =>

                -- Valores para instruções I-Type (ADDI, ANDI, ORI, etc.)
                RegWrite_o <= '1';
                AluSrc_o   <= '1';
                MemtoReg_o <= '0';
                MemRead_o  <= '0';
                MemWrite_o <= '0';
                Branch_o   <= '0';
                Jump_o     <= '0';
                ALUOp_o    <= "00";  -- Operação de soma para cálculo de endereço

            when c_OPCODE_JAL =>

                -- Valores para instruções JAL (Jump and Link)
                RegWrite_o <= '1';
                AluSrc_o   <= '0';   -- Don't care (não é usado pela ALU)
                MemtoReg_o <= '0';   
                MemRead_o  <= '0';
                MemWrite_o <= '0';
                Branch_o   <= '0';
                Jump_o     <= '1';
                ALUOp_o    <= "00";  -- Não é usado pela ALU

            when c_OPCODE_JALR =>

                -- Valores para instruções JALR (Jump and Link Register)
                RegWrite_o <= '1';
                AluSrc_o   <= '1';   -- Usa imediato para calcular o endereço
                MemtoReg_o <= '0';   
                MemRead_o  <= '0';
                MemWrite_o <= '0';
                Branch_o   <= '0';
                Jump_o     <= '1';
                ALUOp_o    <= "00";  -- Operação de soma para cálculo de endereço

            when c_OPCODE_LUI | c_OPCODE_AUIPC =>

                -- Valores para instruções U-Type (LUI, AUIPC)
                RegWrite_o <= '1';
                AluSrc_o   <= '1';   
                MemtoReg_o <= '0';
                MemRead_o  <= '0';
                MemWrite_o <= '0';
                Branch_o   <= '0';
                Jump_o     <= '0';
                ALUOp_o    <= "00";  -- Não é usado pela ALU

            when others => 

                -- Valores padrão para opcodes desconhecidos
                RegWrite_o <= '0';
                ALUSrc_o   <= '0';
                MemtoReg_o <= '0';
                MemRead_o  <= '0';
                MemWrite_o <= '0';
                Branch_o   <= '0';
                Jump_o     <= '0';
                ALUOp_o    <= "00";
        
        end case ;

    end process DECODER;

end architecture rtl;

-------------------------------------------------------------------------------------------------------------------