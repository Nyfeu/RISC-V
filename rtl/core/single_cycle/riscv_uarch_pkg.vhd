------------------------------------------------------------------------------------------------------------------
-- 
-- File: riscv_uarch_pkg.vhd
--
-- ██╗   ██╗ █████╗ ██████╗  ██████╗██╗  ██╗
-- ██║   ██║██╔══██╗██╔══██╗██╔════╝██║  ██║
-- ██║   ██║███████║██████╔╝██║     ███████║
-- ██║   ██║██╔══██║██╔══██╗██║     ██╔══██║
-- ╚██████╔╝██║  ██║██║  ██║╚██████╗██║  ██║
--  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝                                                                                                                                                      
-- 
-- Descrição : Pacote que carrega as especificações para a micro-arquitetura específica.
--
-- Autor     : [André Maiolini]
-- Data      : [25/12/2025]
--
-------------------------------------------------------------------------------------------------------------------

library ieee;                     -- Biblioteca padrão IEEE
use ieee.std_logic_1164.all;      -- Tipos lógicos (std_logic, std_logic_vector)
use ieee.numeric_std.all;         -- Biblioteca para operações aritméticas com vetores lógicos (signed, unsigned)

-------------------------------------------------------------------------------------------------------------------
-- PACOTE: Definição do pacote para especificações micro-arquiteturais
-------------------------------------------------------------------------------------------------------------------

package riscv_uarch_pkg is

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

end package riscv_uarch_pkg;