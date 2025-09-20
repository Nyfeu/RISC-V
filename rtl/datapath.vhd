------------------------------------------------------------------------------------------------------------------
--
-- File: datapath.vhd
--
--   ██████╗  █████╗ ████████╗ █████╗ ██████╗  █████╗ ████████╗██╗  ██╗
--   ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██║  ██║
--   ██║  ██║███████║   ██║   ███████║██████╔╝███████║   ██║   ███████║
--   ██║  ██║██╔══██║   ██║   ██╔══██║██╔═══╝ ██╔══██║   ██║   ██╔══██║
--   ██████╔╝██║  ██║   ██║   ██║  ██║██║     ██║  ██║   ██║   ██║  ██║
--   ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝                                                             
--
-- Descrição : O Caminho de Dados (datapath) representa o 'circuito de potência' do processador RISC-V.
--             Ele contém todos os componentes estruturais responsáveis por armazenar,
--             transportar e processar os dados. Isso inclui o Contador de Programa (PC),
--             o Banco de Registradores, a Unidade Lógica e Aritmética (ALU), o Gerador
--             de Imediatos e todos os multiplexadores. Esta unidade não toma decisões;
--             ela apenas executa as operações comandadas pela Unidade de Controle.
--
-- Autor     : [André Maiolini]
-- Data      : [20/09/2025]
--
------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface do Caminho de Dados (datapath)
-------------------------------------------------------------------------------------------------------------------

entity datapath is

    port (

        ----------------------------------------------------------------------------------------------------------
        -- Sinais e Interfaces de Memória
        ----------------------------------------------------------------------------------------------------------

        -- Sinais Globais (Clock e Mater-Reset)

        CLK_i       : in  std_logic;                                  -- Clock principal
        Reset_i     : in  std_logic;                                  -- Sinal de reset assíncrono

        -- Barramento de Memória de Instruções (IMEM)

        IMem_addr_o : out std_logic_vector(31 downto 0);              -- Endereço para a IMEM (saída do PC)
        IMem_data_i : in  std_logic_vector(31 downto 0);              -- Instrução lida da IMEM

        -- Barramento de Memória de Dados (DMEM)

        DMem_addr_o        : out std_logic_vector(31 downto 0);       -- Endereço para a DMEM 
        DMem_data_o        : out std_logic_vector(31 downto 0);       -- Dado a ser escrito na DMEM (de rs2)
        DMem_data_i        : in  std_logic_vector(31 downto 0);       -- Dado lido da DMEM
        DMem_writeEnable_o : out std_logic;                           -- Habilita escrita na DMEM

        ----------------------------------------------------------------------------------------------------------
        -- Interface com a Unidade de Controle
        ----------------------------------------------------------------------------------------------------------

        -- Entradas

        RegWrite_i         : in std_logic;                            -- Habilita escrita no Banco de Registradores
        ALUSrc_i           : in std_logic;                            -- Seleciona a 2ª fonte da ALU (Reg vs Imm)
        MemtoReg_i         : in std_logic;                            -- Seleciona a fonte de escrita no registrador (ALU vs Mem)
        MemRead_i          : in std_logic;                            -- Habilita leitura da memória (DMEM)
        MemWrite_i         : in std_logic;                            -- Habilita escrita na memória (DMEM)
        Branch_i           : in std_logic;                            -- Indica que a instrução é um branch
        Jump_i             : in std_logic;                            -- Indica que a instrução é um jump
        ALUControl_i       : in std_logic_vector(3 downto 0);         -- Código de 4 bits para a operação da ALU
        WriteDataSource_i  : in std_logic                             -- Habilita PC+4 como fonte de escrita (para JAL/JALR)
    
    );

end entity;

-------------------------------------------------------------------------------------------------------------------
-- ARQUITETURA: Implementação do Caminho de Dados (datapath)
-------------------------------------------------------------------------------------------------------------------

architecture rtl of datapath is

    -- ============== DECLARAÇÃO DOS SINAIS INTERNOS DO DATAPATH ==============

    signal s_pc_current           : std_logic_vector(31 downto 0) := (others => '0');     -- Contador de Programa (PC) atual
    signal s_pc_next              : std_logic_vector(31 downto 0) := (others => '0');     -- Próximo valor do PC
    signal s_pc_plus_4            : std_logic_vector(31 downto 0) := (others => '0');     -- PC + 4 (endereço da próxima instrução)
    signal s_instruction          : std_logic_vector(31 downto 0) := (others => '0');     -- Instrução lida da memória (IMEM)
    signal s_read_data_1          : std_logic_vector(31 downto 0) := (others => '0');     -- Dados lidos do primeiro registrador (rs1)
    signal s_read_data_2          : std_logic_vector(31 downto 0) := (others => '0');     -- Dados lidos do segundo registrador (rs2)
    signal s_immediate            : std_logic_vector(31 downto 0) := (others => '0');     -- Imediato estendido (32 bits)
    signal s_alu_in_b             : std_logic_vector(31 downto 0) := (others => '0');     -- Segundo operando da ALU (registrador ou imediato)
    signal s_alu_result           : std_logic_vector(31 downto 0) := (others => '0');     -- Resultado da ALU (32 bits)
    signal s_write_back_data      : std_logic_vector(31 downto 0) := (others => '0');     -- Dados a serem escritos de volta no banco de registradores
    signal s_load_unit_out        : std_logic_vector(31 downto 0) := (others => '0');     -- Sinal de saida da load_unit
    signal s_alu_zero             : std_logic := '0';                                     -- Flag "Zero" da ALU
    signal s_branch_or_jal_addr   : std_logic_vector(31 downto 0) := (others => '0');     -- Endereço para Branch e JAL
    signal s_branch_condition_met : std_logic := '0';      

begin

    -- ============== Estágio de Busca (FETCH) ===============================================

        -- Contador de Programa (PC) 
        -- - Registrador de 32 bits com reset assíncrono

            PC_REGISTER:process(CLK_i, Reset_i)
            begin
                if Reset_i = '1' then
                    s_pc_current <= (others => '0');
                elsif rising_edge(CLK_i) then
                    s_pc_current <= s_pc_next;
                end if;
            end process;

        -- O PC atual busca a instrução na memória (IMEM)

            IMem_addr_o <= s_pc_current;
            s_instruction <= IMem_data_i;

    -- ============== Estágio de Decodificação (DECODE) ======================================

        -- - Gerador de Imediatos (Immediate Generator)
        -- -- Extrai e estende o imediato da instrução para 32 bits

            U_IMM_GEN: entity work.imm_gen port map (
                Instruction_i => s_instruction, 
                Immediate_o => s_immediate
            );

        -- Os endereços rs1 e rs2 da instrução são enviados ao Banco de Registradores,
        -- que fornece os dados dos registradores de forma combinacional.

            U_REG_FILE: entity work.reg_file
                port map (
                    clk_i        => CLK_i,                            -- Clock do processador
                    RegWrite_i   => RegWrite_i,                       -- Habilita escrita no banco de registradores
                    ReadAddr1_i  => s_instruction(19 downto 15),      -- rs1 (bits [19:15]) - 5 bits
                    ReadAddr2_i  => s_instruction(24 downto 20),      -- rs2 (bits [24:20]) - 5 bits
                    WriteAddr_i  => s_instruction(11 downto 7),       -- rd  (bits [11: 7]) - 5 bits
                    WriteData_i  => s_write_back_data,                -- Dados a serem escritos (da ALU ou da memória) - 32 bits
                    ReadData1_o  => s_read_data_1,                    -- Dados lidos do registrador rs1 (32 bits)
                    ReadData2_o  => s_read_data_2                     -- Dados lidos do registrador rs2 (32 bits)
                );

    -- ============== Estágio de Execução (EXECUTE) ==========================================

        -- O Mux ALUSrc seleciona a segunda entrada da ULA:
        -- Se s_alusrc='0' (R-Type, Branch), usa o valor do registrador s_read_data_2.
        -- Se s_alusrc='1' (I-Type, Load, Store), usa a constante s_immediate.
    
            s_alu_in_b <= s_read_data_2 when ALUSrc_i = '0' else s_immediate;

        -- A ULA executa a operação comandada pelo s_alu_control.
        -- O resultado (s_alu_result) pode ser um valor aritmético, um endereço de memória ou um resultado de comparação.

            U_ALU: entity work.alu
                port map (
                    A_i => s_read_data_1,
                    B_i => s_alu_in_b,
                    ALUControl_i => ALUControl_i,
                    Result_o => s_alu_result,
                    Zero_o => s_alu_zero
                );

    -- ============== Estágio de Acesso à Memória (MEMORY) ==================================

        -- Aqui ocorre o acesso à memória de dados (DMEM).
        -- Dependendo dos sinais de controle, a CPU pode ler ou escrever na memória.
                    
        -- - A ALU sempre calcula o endereço para a memória de dados.
    
            DMem_addr_o        <= s_alu_result;
    
        -- - O dado a ser escrito vem sempre de rs2.

            DMem_data_o        <= s_read_data_2;
    
        -- - O sinal de escrita na memória vem da unidade de controle.

            DMem_writeEnable_o <= MemWrite_i;

        -- Instanciação da Unidade de Carga

            U_LOAD_UNIT: entity work.load_unit port map (
                DMem_data_i  => DMem_data_i,                          -- Palavra completa vinda da memória de dados
                Addr_LSB_i   => s_alu_result(1 downto 0),             -- 2 bits do endereço para selecionar o byte/half
                Funct3_i     => s_instruction(14 downto 12),          -- Funct3 para decodificar o tipo de load
                Data_o       => s_load_unit_out                       -- Saída de 32 bits, já tratada
            );

    -- ============== Estágio de Escrita de Volta (WRITE-BACK) ===============================

        -- Mux MemtoReg: decide o que será escrito de volta no registrador
    
            s_write_back_data <= s_pc_plus_4 when WriteDataSource_i = '1' else
                s_load_unit_out when MemtoReg_i = '1' else
                s_alu_result;

    -- ============== Lógica de Cálculo do Próximo PC ======================================
    
        -- Candidato 1: Endereço sequencial (PC + 4)

            s_pc_plus_4 <= std_logic_vector(unsigned(s_pc_current) + 4);
    
        -- Candidato 2: Endereço de destino para Branch e JAL (PC + imediato)

            s_branch_or_jal_addr <= std_logic_vector(signed(s_pc_current) + signed(s_immediate));
    
        -- Lógica de condição do Branch

            s_branch_condition_met <= '1' when (Branch_i = '1' and (
                (s_instruction(14 downto 12) = "000" and s_alu_zero = '1') or  -- BEQ
                (s_instruction(14 downto 12) = "001" and s_alu_zero = '0') or  -- BNE
                (s_instruction(14 downto 12) = "100" and signed(s_read_data_1) < signed(s_read_data_2)) or  -- BLT (signed)
                (s_instruction(14 downto 12) = "101" and signed(s_read_data_1) >= signed(s_read_data_2)) or -- BGE (signed)
                (s_instruction(14 downto 12) = "110" and unsigned(s_read_data_1) < unsigned(s_read_data_2)) or -- BLTU (unsigned)
                (s_instruction(14 downto 12) = "111" and unsigned(s_read_data_1) >= unsigned(s_read_data_2))   -- BGEU (unsigned)
            )) else '0';

        -- Mux final que alimenta o registrador do PC no próximo ciclo de clock
        -- - A prioridade é: Jumps têm precedência sobre Branches, que têm precedência sobre PC+4.

            s_pc_next <= s_alu_result when (Jump_i = '1' and s_instruction(6 downto 0) = "1100111") else
                s_branch_or_jal_addr when (Jump_i = '1' and s_instruction(6 downto 0) = "1101111") else
                s_branch_or_jal_addr when s_branch_condition_met = '1' else
                s_pc_plus_4;

end architecture; -- rtl

-------------------------------------------------------------------------------------------------------------------