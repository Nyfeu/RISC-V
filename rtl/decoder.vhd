------------------------------------------------------------------------------------------------------------------
-- 
-- File: decoder.vhd
--
--   ██████╗ ███████╗ ██████╗ ██████╗ ██████╗ ███████╗██████╗ 
--   ██╔══██╗██╔════╝██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗
--   ██║  ██║█████╗  ██║     ██║   ██║██║  ██║█████╗  ██████╔╝
--   ██║  ██║██╔══╝  ██║     ██║   ██║██║  ██║██╔══╝  ██╔══██╗
--   ██████╔╝███████╗╚██████╗╚██████╔╝██████╔╝███████╗██║  ██║
--   ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝                                                                                                                                                           
-- 
-- Descrição : Unidade de Decodificação para um processador RISC-V de 32 bits (RV32I).
--             Decodifica o opcode da instrução e gera os sinais de controle
--             necessários para a operação correta do datapath.
--
-- Autor     : [André Maiolini]
-- Data      : [14/09/2025]
--
-------------------------------------------------------------------------------------------------------------------
--
-- IMPORTANTE: 
--  - O "opcode" indica apeenas a CATEGORIA (formato) da instrução.
--  - A operação exata (ex: ADD vs SUB, AND vs OR) é definida em outro nível,
--    usando os campos funct3 e funct7.
--
-------------------------------------------------------------------------------------------------------------------

library ieee;                     -- Biblioteca padrão IEEE
use ieee.std_logic_1164.all;      -- Tipos lógicos (std_logic, std_logic_vector)
use ieee.numeric_std.all;         -- Biblioteca para operações aritméticas com vetores lógicos (signed, unsigned)

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface da unidade decodificadora
-------------------------------------------------------------------------------------------------------------------

entity decoder is

  port (
    
    -- Entradas
    Opcode_i      : in  std_logic_vector(6 downto 0);    -- Opcode da instrução (bits [6:0])

    -- Saídas
    RegWrite_o    : out std_logic;                       -- Habilita escrita no banco de registradores
    ALUSrcA_o     : out std_logic_vector(1 downto 0);    -- Seleciona a fonte do primeiro operando da ALU
    ALUSrcB_o     : out std_logic;                       -- Seleciona a fonte do segundo operando da ALU (0=registrador, 1=imediato)
    MemtoReg_o    : out std_logic;                       -- Seleciona a fonte dos dados a serem escritos no registrador (0=ALU, 1=Memória)
    MemRead_o     : out std_logic;                       -- Habilita leitura da memória
    MemWrite_o    : out std_logic;                       -- Habilita escrita na memória
    Branch_o      : out std_logic;                       -- Indica desvio condicional
    Jump_o        : out std_logic;                       -- Indica salto incondicional
    ALUOp_o       : out std_logic_vector(1 downto 0);    -- Código de operação da ALU (2 bits)
    WriteDataSource_o : out std_logic                    -- Habilita PC+4 como fonte de escrita

  ) ;

end decoder ;

-------------------------------------------------------------------------------------------------------------------
-- ARQUITETURA: Implementação da unidade decodificadora
-------------------------------------------------------------------------------------------------------------------

architecture rtl of decoder is

    ---------------------------------------------------------------------------------------------------------------
    --
    -- MAPA DE FORMATOS DO RV32I
    --
    -- - Cada instrução pertence a um "formato" definido pelo campo OPCODE (7 bits).
    -- 
    -- - Formato R (registrador-registrador): operações aritméticas/lógicas
    --     opcode = 0110011
    --
    -- - Formato I (imediato): operações com imediato, loads, JALR
    --     opcode = 0010011 (I-type aritmético: ADDI, ANDI, ORI, ...)
    --     opcode = 0000011 (LOAD: LB, LH, LW, LBU, LHU)
    --     opcode = 1100111 (JALR)
    --
    -- - Formato S (store): operações de armazenamento na memória
    --     opcode = 0100011 (SB, SH, SW)
    --
    -- - Formato B (branch): desvios condicionais
    --     opcode = 1100011 (BEQ, BNE, BLT, ...)
    --
    -- - Formato U (upper immediate): imediato de 20 bits
    --     opcode = 0110111 (LUI)
    --     opcode = 0010111 (AUIPC)
    --
    -- - Formato J (jump): salto incondicional
    --     opcode = 1101111 (JAL)
    ---------------------------------------------------------------------------------------------------------------

    -- Constantes para os opcodes das instruções RISC-V
    constant c_OPCODE_R_TYPE : std_logic_vector(6 downto 0) := "0110011"; -- Operações entre registradores
    constant c_OPCODE_I_TYPE : std_logic_vector(6 downto 0) := "0010011"; -- Operações imediato
    constant c_OPCODE_LOAD   : std_logic_vector(6 downto 0) := "0000011";
    constant c_OPCODE_STORE  : std_logic_vector(6 downto 0) := "0100011";
    constant c_OPCODE_BRANCH : std_logic_vector(6 downto 0) := "1100011";
    constant c_OPCODE_JAL    : std_logic_vector(6 downto 0) := "1101111";
    constant c_OPCODE_JALR   : std_logic_vector(6 downto 0) := "1100111";
    constant c_OPCODE_LUI    : std_logic_vector(6 downto 0) := "0110111";
    constant c_OPCODE_AUIPC  : std_logic_vector(6 downto 0) := "0010111";

begin

    -- Processo de decodificação do opcode para gerar os sinais de controle

    --------------------------------------------------------------------------------------------------------------
    -- Processo de decodificação do OPCODE
    -- 
    -- Observação: ALUOp_o é um código "resumido":
    --
    --   "00" → operações de soma (load/store, endereçamento, jalr, auipc)
    --   "01" → operações de comparação (branch)
    --   "10" → operações R-type (ADD, SUB, AND, OR, etc.)
    --   "11" → operações I-type aritméticas (ADDI, ANDI, ORI, etc.)
    --
    -- A distinção final é feita no módulo ALUControl, usando funct3/funct7.
    --
    --------------------------------------------------------------------------------------------------------------

    DECODING : process(Opcode_i)
    begin

        -- Valores padrão (NOP)

        RegWrite_o        <= '0'  ;
        ALUSrcA_o         <= "00" ;
        AluSrcB_o         <= '0'  ;
        MemtoReg_o        <= '0'  ;
        MemRead_o         <= '0'  ;
        MemWrite_o        <= '0'  ;
        Branch_o          <= '0'  ;
        Jump_o            <= '0'  ;
        ALUOp_o           <= "00" ;
        WriteDataSource_o <= '0'  ;

        case Opcode_i is

            -- ===================================================================================================
            -- Formato R (ex: ADD, SUB...)
            -- ===================================================================================================
            when c_OPCODE_R_TYPE =>
                RegWrite_o <= '1';
                AluSrcB_o   <= '0';
                ALUOp_o    <= "10";

            -- ===================================================================================================
            -- Formato I (imediato ALU)
            -- ===================================================================================================
            when c_OPCODE_I_TYPE =>
                RegWrite_o <= '1';
                AluSrcB_o   <= '1';
                ALUOp_o    <= "11";

            -- ===================================================================================================
            -- LOAD (ex: LW)
            -- ===================================================================================================
            when c_OPCODE_LOAD =>
                RegWrite_o <= '1';
                AluSrcB_o   <= '1';
                MemtoReg_o <= '1';
                MemRead_o  <= '1';
                ALUOp_o    <= "00"; -- soma para endereçamento

            -- ===================================================================================================
            -- STORE (ex: SW)
            -- ===================================================================================================
            when c_OPCODE_STORE =>
                AluSrcB_o   <= '1';
                MemWrite_o <= '1';
                ALUOp_o    <= "00"; -- soma para endereçamento

            -- ===================================================================================================
            -- BRANCH (ex: BEQ)
            -- ===================================================================================================
            when c_OPCODE_BRANCH =>
                Branch_o   <= '1';
                ALUOp_o    <= "01"; -- subtração para comparação

            -- ===================================================================================================
            -- JUMP (JAL)
            -- ===================================================================================================
            when c_OPCODE_JAL =>
                RegWrite_o        <= '1';
                Jump_o            <= '1';
                WriteDataSource_o <= '1'; -- grava PC+4 no rd

            -- ===================================================================================================
            -- JUMP (JALR)
            -- ===================================================================================================
            when c_OPCODE_JALR =>
                RegWrite_o        <= '1';
                AluSrcB_o          <= '1';
                Jump_o            <= '1';
                WriteDataSource_o <= '1';

            -- ===================================================================================================
            -- U-Type (LUI, AUIPC)
            -- ===================================================================================================
            when c_OPCODE_LUI =>
                RegWrite_o <= '1' ;
                ALUSrcA_o  <= "10"; 
                AluSrcB_o  <= '1' ;
                ALUOp_o    <= "00";

            when c_OPCODE_AUIPC =>
                RegWrite_o <= '1' ;
                ALUSrcA_o  <= "01"; 
                AluSrcB_o  <= '1' ;
                ALUOp_o    <= "00";

            -- ===================================================================================================
            -- OPCODE desconhecido → NOP
            -- ===================================================================================================
            when others => null; -- mantém os valores padrão

        end case;
        
    end process;

end architecture rtl;

-------------------------------------------------------------------------------------------------------------------