------------------------------------------------------------------------------------------------------------------
--
-- File: control.vhd
--
--    ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  ██████╗ ██╗
--   ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗██║
--   ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║   ██║██║
--   ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║   ██║██║
--   ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║╚██████╔╝███████╗
--    ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
--
-- Descrição : A Unidade de Controle (Control) representa o 'circuito de comando' do processador.
--             Ela recebe os campos da instrução (Opcode, Funct3, Funct7) e as
--             flags de status (ex: Zero) vindos do datapath e, com base nessas informações, 
--             ela gera todos os sinais de controle (RegWrite, ALUSrc, MemtoReg, etc.) que orquestram as 
--             operações do datapath, ditando o que cada componente deve fazer em um determinado
--             momento.
--
-- Autor     : [André Maiolini]
-- Data      : [20/09/2025]
--
-------------------------------------------------------------------------------------------------------------------

library ieee;                     -- Biblioteca padrão IEEE
use ieee.std_logic_1164.all;      -- Tipos lógicos (std_logic, std_logic_vector)
use ieee.numeric_std.all;         -- Biblioteca para operações aritméticas com vetores lógicos (signed, unsigned)

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface da Unidade de Controle
-------------------------------------------------------------------------------------------------------------------

entity control is

    port (

        ----------------------------------------------------------------------------------------------------------
        -- Interface com o Datapath
        ----------------------------------------------------------------------------------------------------------

        -- Entradas

            Instruction_i : in  std_logic_vector(31 downto 0);    -- A instrução para decodificação
        
        -- Saídas (Sinais de Controle para o Datapath)

            RegWrite_o        : out std_logic;                    -- Habilita escrita no Banco de Registradores
            ALUSrc_o          : out std_logic;                    -- Seleciona a 2ª fonte da ALU (Reg vs Imm)
            MemtoReg_o        : out std_logic;                    -- Seleciona a fonte de escrita no registrador (ALU vs Mem)
            MemRead_o         : out std_logic;                    -- Habilita leitura na DMEM
            MemWrite_o        : out std_logic;                    -- Habilita escrita na DMEM
            Branch_o          : out std_logic;                    -- Indica que a instrução é um branch
            Jump_o            : out std_logic;                    -- Indica que a instrução é um jump
            WriteDataSource_o : out std_logic;                    -- Habilita PC+4 como fonte de escrita (para JAL/JALR)
            ALUControl_o      : out std_logic_vector(3 downto 0)  -- Código de 4 bits para a operação da ALU

    );

end entity;

architecture rtl of control is

    signal s_opcode : std_logic_vector(6 downto 0) := (others => '0');
    signal s_funct3 : std_logic_vector(2 downto 0) := (others => '0');
    signal s_funct7 : std_logic_vector(6 downto 0) := (others => '0');

    signal s_aluop  : std_logic_vector(1 downto 0) := (others => '0');

begin

    -- Extrai os campos da instrução

        s_opcode <= Instruction_i(6 downto 0);
        s_funct3 <= Instruction_i(14 downto 12);
        s_funct7 <= Instruction_i(31 downto 25);

    -- Unidade de Controle Principal

        -- Decodifica o Opcode para gerar os sinais de controle primários.

        -- OBS.: na arquitetura RISC-V, os campos da instrução são fixos:

        -- - opcode nos bits [6:0];
        -- - funct3 nos bits [14:12];
        -- - funct7 nos bits [31:25].     
        -- - rd nos bits [11:7];
        -- - rs1 nos bits [19:15];
        -- - rs2 nos bits [24:20].

            U_CONTROL: entity work.decoder
                port map (
                    Opcode_i           => s_opcode,
                    RegWrite_o         => RegWrite_o,
                    ALUSrc_o           => ALUSrc_o,
                    MemtoReg_o         => MemtoReg_o,
                    MemRead_o          => MemRead_o,
                    MemWrite_o         => MemWrite_o,
                    Branch_o           => Branch_o,
                    Jump_o             => Jump_o,
                    ALUOp_o            => s_aluop,
                    WriteDataSource_o  => WriteDataSource_o
                );

    -- Unidade de Controle da ALU

        -- Decodifica os campos funct3 e funct7, junto com o ALUOp,
        -- para gerar o código final da operação da ULA.
    
            U_ALU_CONTROL: entity work.alu_control
                port map (
                    ALUOp_i            => s_aluop,
                    Funct3_i           => s_funct3,
                    Funct7_i           => s_funct7,
                    ALUControl_o       => ALUControl_o
                );

end architecture; -- rtl

-------------------------------------------------------------------------------------------------------------------