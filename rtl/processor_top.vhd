-- ===============================================================================================================================================
--
-- File: processor_top.vhd (Top Level do Processador RISC-V RV32I)
-- 
--   ██████╗ ██╗   ██╗██████╗ ██████╗ ██╗
--   ██╔══██╗██║   ██║╚════██╗╚════██╗██║
--   ██████╔╝██║   ██║ █████╔╝ █████╔╝██║
--   ██╔══██╗╚██╗ ██╔╝ ╚═══██╗██╔═══╝ ██║    ->> PROJETO: Processador RISC-V (RV32I) - Implementação em VHDL
--   ██║  ██║ ╚████╔╝ ██████╔╝███████╗██║    ->> AUTOR: André Solano F. R. Maiolini 
--   ╚═╝  ╚═╝  ╚═══╝  ╚═════╝ ╚══════╝╚═╝    ->> DATA: 15/09/2025
--
-- ============+=================================================================================================================================
--   Descrição |
-- ------------+
--
-- Este código VHDL descreve a arquitetura RISC-V de 32 bits (RV32I), organizada em duas principais seções: o datapath e o control path.
--
-- O datapath é responsável pelo processamento dos dados, incluindo a Unidade Lógica e Aritmética (ALU),
-- o banco de registradores, o acesso à memória de instruções e de dados, e os multiplexadores que direcionam o fluxo de dados.
--
-- O control path gera os sinais de controle a partir da instrução atual, determinando o comportamento do datapath,
-- como qual operação a ALU deve executar, quando escrever em registradores ou memória, e quando atualizar o PC.
--
-- =====================+=========================================================================================================================
--  Diagrama de Blocos  |
-- ---------------------+                     Arquitetura de Harvard Modificada                    ____________________________
--                                                                                                /                           /\
--                  +--------+             +-----+   addr   +-----+   addr   +-----+             /         RISC-V           _/ /\
--       Reset_i >--|        |             |     | <------- |     | -------> |     |            /       (Harvard Mod)      / \/
--         CLK_i >--|  CPU   |     ==>     | ROM |   inst   | CPU |   data   | RAM |           /                           /\
--                  |        |             |     | -------> |     | <------> |     |          /___________________________/ /
--                  +--------+             +-----+          +-----+          +-----+          \___________________________\/
--                                                  (IMEM)           (DMEM)                    \ \ \ \ \ \ \ \ \ \ \ \ \ \ \
--
--
--  A arquitetura de Harvard modificada permite que o processador acesse simultaneamente a memória de instruções (IMEM) e a memória de dados (DMEM),
--  melhorando o desempenho geral. A CPU busca instruções da IMEM enquanto lê ou escreve dados na DMEM.
--
-- ===============================================================================================================================================

-- ==| Libraries |================================================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ==| PROCESSOR_TOP |============================================================================================================================

entity processor_top is

  port (
    
    -- Sinais de controle

    CLK_i               : in  std_logic;                          -- Clock principal do processador
    Reset_i             : in  std_logic;                          -- Sinal de reset assíncrono (ativo em nível alto)

    -- Barramento de memória de instruções (IMEM)

    IMem_addr_o         : out std_logic_vector(31 downto 0);      -- Endereço de 32 bits para a memória de instruções
    IMem_data_i         : in  std_logic_vector(31 downto 0);      -- Instrução de 32 bits vinda da memória de instruções

    -- Barramento de memória de dados (DMEM)

    DMem_addr_o         : out std_logic_vector(31 downto 0);      -- Endereço de 32 bits para a memória de dados
    DMem_data_o         : out std_logic_vector(31 downto 0);      -- Dados de 32 bits a serem escritos na memória de dados
    DMem_data_i         : in  std_logic_vector(31 downto 0);      -- Dados de 32 bits lidos da memória de dados
    DMem_writeEnable_o  : out std_logic                           -- Sinal de habilitação de escrita na memória de dados (ativo em nível alto)

  ) ;

end processor_top ;

-- ==| ARQUITETURA |==============================================================================================================================

-- Faz conexão estrutural dos dois principais blocos do processador:
--  1) Control Path (U_CONTROLPATH)  -> circuito de comando (gera sinais de controle)
--  2) Datapath (U_DATAPATH)         -> circuito de potência (lida com os dados)

architecture rtl of processor_top is

    -- ============== DECLARAÇÃO DOS SINAIS INTERMEDIÁRIOS ============== --
    
        -- Estes sinais conectam controlpath ao datapath, 
        -- indicando o que deve ser feito a cada ciclo de clock.

            signal s_alu_zero, s_alu_negative, s_reg_write, s_alusrc, s_memtoreg, s_memread, s_memwrite, s_branch, s_jump, 
                s_wdatasrc : std_logic := '0';

            signal s_pc_src     : std_logic_vector(1 downto 0) := (others => '0');
            signal s_alucontrol : std_logic_vector(3 downto 0) := (others => '0');

        -- Sinal para transmissão da instrução entre os caminhos...

            signal s_instruction_to_ctrl : std_logic_vector(31 downto 0) := (others => '0'); 

begin

    -- ============== CONTROL PATH ======================== 

        -- Este bloco recebe a instrução atual da memória de programa
        -- e gera todos os sinais de controle necessários para o datapath executar a instrução corretamente.

            U_CONTROLPATH: entity work.control
                port map (
                    Instruction_i => s_instruction_to_ctrl,                 -- Instrução buscada na memória
                    ALU_Zero_i    => s_alu_zero,
                    ALU_Negative_i => s_alu_negative,
                    RegWrite_o    => s_reg_write,
                    ALUSrc_o      => s_alusrc,
                    MemtoReg_o    => s_memtoreg,
                    MemRead_o     => s_memread,
                    MemWrite_o    => s_memwrite,
                    PCSrc_o       => s_pc_src,
                    WriteDataSource_o => s_wdatasrc,
                    ALUControl_o  => s_alucontrol
                );

    -- ============== DATAPATH =============================

        -- O datapath realiza todas as operações aritméticas, lógicas e de movimentação de dados.
        -- Ele também atualiza o PC (program counter) e acessa a memória de dados conforme os sinais de controle.

            U_DATAPATH: entity work.datapath
                port map (
                    CLK_i       => CLK_i,
                    Reset_i     => Reset_i,
                    IMem_addr_o => IMem_addr_o,
                    IMem_data_i => IMem_data_i,
                    DMem_addr_o => DMem_addr_o,
                    DMem_data_o => DMem_data_o,
                    DMem_data_i => DMem_data_i,
                    DMem_writeEnable_o => DMem_writeEnable_o,
                    RegWrite_i  => s_reg_write,
                    ALUSrc_i    => s_alusrc,
                    MemtoReg_i  => s_memtoreg,
                    MemWrite_i  => s_memwrite,
                    PCSrc_i     => s_pc_src, 
                    ALUControl_i => s_alucontrol,
                    WriteDataSource_i  => s_wdatasrc,
                    Instruction_o => s_instruction_to_ctrl,
                    ALU_Zero_o => s_alu_zero,
                    ALU_Negative_o => s_alu_negative
                );

end architecture rtl; -- rtl

-- ===============================================================================================================================================