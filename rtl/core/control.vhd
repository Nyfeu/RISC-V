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
use work.riscv_pkg.all;           -- Contém todas as definições de constantes e tipos

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface da Unidade de Controle
-------------------------------------------------------------------------------------------------------------------

entity control is

    port (

        ----------------------------------------------------------------------------------------------------------
        -- Interface com o Datapath
        ----------------------------------------------------------------------------------------------------------

        -- Entradas

            Instruction_i  : in  std_logic_vector(31 downto 0);   -- A instrução para decodificação
            ALU_Zero_i     : in  std_logic;                       -- Flag 'Zero' vinda do Datapath
            ALU_Negative_i : in  std_logic;                       -- Flag 'Negative' vinda do Datapath
        
        -- Saídas (Sinais de Controle para o Datapath)

            Control_o      : out t_control;                       -- Record com todos os sinais do decoder
            PCSrc_o        : out std_logic_vector(1 downto 0);    -- Seleciona o PC (program counter)
            ALUControl_o   : out std_logic_vector(3 downto 0)     -- Código de 4 bits para a operação da ALU

    );

end entity;

architecture rtl of control is

    -- Sinais internos
    signal s_opcode : std_logic_vector(6 downto 0) := (others => '0');
    signal s_funct3 : std_logic_vector(2 downto 0) := (others => '0');
    signal s_funct7 : std_logic_vector(6 downto 0) := (others => '0');

    -- Sinal para armazenar o pacote de controle vindo do Decoder
    signal s_ctrl : t_control;

    -- Sinal interno para lógica de branch
    signal s_branch_condition_met : std_logic := '0'; 

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
                    Opcode_i       => s_opcode,
                    Control_o      => s_ctrl
                );

        -- Repassa os sinais estáticos diretamente para a saída da entidade control
        Control_o <= s_ctrl;

    -- Unidade de Controle da ALU

        -- Decodifica os campos funct3 e funct7, junto com o ALUOp,
        -- para gerar o código final da operação da ULA.
    
            U_ALU_CONTROL: entity work.alu_control
                port map (
                    ALUOp_i        => s_ctrl.alu_op,
                    Funct3_i       => s_funct3,
                    Funct7_i       => s_funct7,
                    ALUControl_o   => ALUControl_o
                );

    -- Lógica para o sinal PCSrc_o
    
        -- Usa funct3 para decidir qual condição verificar
            U_BRANCH_UNIT: entity work.branch_unit
                port map (
                    Branch_i       => s_ctrl.branch,         -- Sinal vindo do decoder principal
                    Funct3_i       => s_funct3,              -- Campo funct3 da instrução
                    ALU_Zero_i     => ALU_Zero_i,            -- Flag Zero vinda do datapath
                    ALU_Negative_i => ALU_Negative_i,        -- Flag Negative vinda do datapath
                    BranchTaken_o  => s_branch_condition_met -- Saída que indica se o desvio deve ser tomado
                );

        -- O desvio é tomado se a instrução for um Branch E a condição Zero for atendida.

            PCSrc_o <= "10" when (s_ctrl.jump = '1' and s_opcode = "1100111") else -- JALR
               "01" when (s_ctrl.jump = '1' and s_opcode = "1101111") else -- JAL
               "01" when (s_ctrl.branch = '1' and s_branch_condition_met = '1') else -- Branch Tomado
               "00"; -- Padrão (PC + 4)

end architecture; -- rtl

-------------------------------------------------------------------------------------------------------------------