library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package riscv_pkg is

    -- === Opcodes (RV32I) ===
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
    constant c_OPCODE_SYSTEM : std_logic_vector(6 downto 0) := "1110011";
    constant c_OPCODE_FENCE  : std_logic_vector(6 downto 0) := "0001111";

    -- === Funct3 (ALU/Branch/Mem) ===
    
    constant c_FUNCT3_BEQ  : std_logic_vector(2 downto 0) := "000";
    constant c_FUNCT3_BNE  : std_logic_vector(2 downto 0) := "001";
    constant c_FUNCT3_BLT  : std_logic_vector(2 downto 0) := "100";
    constant c_FUNCT3_BGE  : std_logic_vector(2 downto 0) := "101";
    constant c_FUNCT3_BLTU : std_logic_vector(2 downto 0) := "110";
    constant c_FUNCT3_BGEU : std_logic_vector(2 downto 0) := "111";

    -- === Funct3 (Load/Store Unit) ===
    -- Constantes para os valores de funct3 para as instruções de Load

    constant c_LB  : std_logic_vector(2 downto 0) := "000";               -- Load Byte (com sinal)
    constant c_LH  : std_logic_vector(2 downto 0) := "001";               -- Load Half-word (com sinal)
    constant c_LW  : std_logic_vector(2 downto 0) := "010";               -- Load Word
    constant c_LBU : std_logic_vector(2 downto 0) := "100";               -- Load Byte Unsigned (sem sinal)
    constant c_LHU : std_logic_vector(2 downto 0) := "101";               -- Load Half-word Unsigned (sem sinal)

    -- Constantes para os valores de funct3 para as intruções de store

    constant c_SB : std_logic_vector(2 downto 0) := "000";                -- Store Byte
    constant c_SH : std_logic_vector(2 downto 0) := "001";                -- Store Half-word
    constant c_SW : std_logic_vector(2 downto 0) := "010";                -- Store Word

    -- === ALU Operations (Interno) ===
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

    -- === TIPO DE REGISTRO PARA OS SINAIS DO DECODIFICADOR (DECODER) ===

    -- Agrupa todas as saídas do decodificador (decoder.vhd)

    type t_decoder is record
        reg_write         : std_logic;                                -- Habilita escrita no banco de registradores
        alu_src_a         : std_logic_vector(1 downto 0);             -- Seleciona a fonte do primeiro operando da ALU
        alu_src_b         : std_logic;                                -- Seleciona a fonte do segundo operando da ALU (0=registrador, 1=imediato)
        mem_to_reg        : std_logic;                                -- Seleciona a fonte dos dados a serem escritos no registrador (0=ALU, 1=Memória)
        mem_write         : std_logic;                                -- Habilita escrita na memória
        write_data_src    : std_logic;                                -- Habilita PC+4 como fonte de escrita
        branch            : std_logic;                                -- Sinal de desvio condicional
        jump              : std_logic;                                -- Sinal de salto incondicional
        alu_op            : std_logic_vector(1 downto 0);             -- Código de operação da ALU
    end record;

    -- Constante para "zerar" tudo em t_decoder (NOP)

    constant c_DECODER_NOP : t_decoder := (
        reg_write      => '0', 
        alu_src_a      => "00", 
        alu_src_b      => '0',
        mem_to_reg     => '0', 
        mem_write      => '0',
        write_data_src => '0',
        branch         => '0',
        jump           => '0',
        alu_op         => "00"
    );

    -- === TIPO DE REGISTRO PARA OS SINAIS DE CONTROLE (CONTROL) ===

    -- Agrupa todas as saídas da unidade de controle (control.vhd) que vão para o datapath

    type t_control is record
        reg_write         : std_logic;                    -- Habilita escrita no banco de registradores
        alu_src_a         : std_logic_vector(1 downto 0); -- Seleciona a fonte do primeiro operando da ALU
        alu_src_b         : std_logic;                    -- Seleciona a fonte do segundo operando da ALU (0=registrador, 1=imediato)
        mem_to_reg        : std_logic;                    -- Seleciona a fonte dos dados a serem escritos no registrador (0=ALU, 1=Memória)
        mem_write         : std_logic;                    -- Habilita escrita na memória
        write_data_src    : std_logic;                    -- Habilita PC+4 como fonte de escrita
        pcsrc      : std_logic_vector(1 downto 0);        -- Seleção do PC (branch/jump)
        alucontrol : std_logic_vector(3 downto 0);        -- Código de operação da ALU
    end record;

    -- Constante para "zerar" tudo em t_control (NOP)

    constant c_CONTROL_NOP : t_control := (
        reg_write      => c_DECODER_NOP.reg_write, 
        alu_src_a      => c_DECODER_NOP.alu_src_a, 
        alu_src_b      => c_DECODER_NOP.alu_src_b,
        mem_to_reg     => c_DECODER_NOP.mem_to_reg, 
        mem_write      => c_DECODER_NOP.mem_write,
        write_data_src => c_DECODER_NOP.write_data_src,
        pcsrc          => "00",
        alucontrol     => "0000"
    );

end package riscv_pkg;