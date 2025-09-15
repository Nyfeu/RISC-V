-- ===============================================================================================================================================
--
-- File: processor_top.vhd (Top Level do Processador RISC-V RV32I)
-- 
--   ██████╗ ██╗   ██╗██████╗ ██████╗ ██╗
--   ██╔══██╗██║   ██║╚════██╗╚════██╗██║
--   ██████╔╝██║   ██║ █████╔╝ █████╔╝██║
--   ██╔══██╗╚██╗ ██╔╝ ╚═══██╗██╔═══╝ ██║    ->> PROJETO: Processador RISC-V (RV32I) - Implementação em VHDL
--   ██║  ██║ ╚████╔╝ ██████╔╝███████╗██║    ->> AUTOR: André Solano F. R. Maiolini 
--   ╚═╝  ╚═╝  ╚═══╝  ╚═════╝ ╚══════╝╚═╝    ->> DATA: 25/06/2024
--
-- ============+=================================================================================================================================
--   Descrição |
-- ------------+
-- 
--  Este código VHDL descreve a arquitetura de uma Unidade Central de Processamento (CPU) baseada na arquitetura RISC-V de 32 bits (RV32I).
--  O processador é composto por vários módulos, incluindo a unidade de controle, a unidade lógica e aritmética (ALU), o banco de registradores,
--  a memória de instruções, a memória de dados, e os multiplexadores necessários para o fluxo de dados.
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

-- Implementação estrutural do processador, conectando todos os módulos.

architecture rtl of processor_top is

    -- ============== DECLARAÇÃO DOS COMPONENTES ==============
    
    -- Componente: Unidade Lógica e Aritmética (ALU)

    component alu is
        port (
            A_i           : in  std_logic_vector(31 downto 0);    -- Operando A (32 bits)
            B_i           : in  std_logic_vector(31 downto 0);    -- Operando B (32 bits)
            ALUControl_i  : in  std_logic_vector(3 downto 0);     -- Código de operação da ALU (4 bits)
            Result_o      : out std_logic_vector(31 downto 0);    -- Resultado da operação (32 bits)
            Zero_o        : out std_logic                         -- Flag "Zero" (ativo em '1' se Result_o for zero)
        );
    end component alu;

    -- Componente: Unidade de Controle (Control Unit)

    component control_unit is
        port (
            Opcode_i      : in  std_logic_vector(6 downto 0);     -- Opcode da instrução (bits [6:0])
            RegWrite_o    : out std_logic;                        -- Habilita escrita no banco de registradores
            ALUSrc_o      : out std_logic;                        -- Seleciona a fonte do segundo operando da ALU (0=registrador, 1=imediato)
            MemtoReg_o    : out std_logic;                        -- Seleciona a fonte dos dados a serem escritos no registrador (0=ALU, 1=Memória)
            MemRead_o     : out std_logic;                        -- Habilita leitura da memória
            MemWrite_o    : out std_logic;                        -- Habilita escrita na memória
            Branch_o      : out std_logic;                        -- Indica desvio condicional
            Jump_o        : out std_logic;                        -- Indica salto incondicional
            ALUOp_o       : out std_logic_vector(1 downto 0)      -- Código de operação da ALU (2 bits)
        ) ;
    end component control_unit ;

    -- Componente: Banco de Registradores (Register File)

    component reg_file is
        port (
            clk_i        : in  std_logic;                         -- Sinal de clock
            RegWrite_i   : in  std_logic;                         -- Habilita escrita no banco de registradores
            ReadAddr1_i  : in  std_logic_vector(4 downto 0);      -- Endereço do primeiro registrador a ser lido (0-31) rs1
            ReadAddr2_i  : in  std_logic_vector(4 downto 0);      -- Endereço do segundo registrador a ser lido (0-31) rs2
            WriteAddr_i  : in  std_logic_vector(4 downto 0);      -- Endereço do registrador a ser escrito (0-31) rd
            WriteData_i  : in  std_logic_vector(31 downto 0);     -- Dados a serem escritos no registrador
            ReadData1_o  : out std_logic_vector(31 downto 0);     -- Dados lidos do primeiro registrador
            ReadData2_o  : out std_logic_vector(31 downto 0)      -- Dados lidos do segundo registrador
        );
    end component reg_file;

    -- Componente: Gerador de Imediatos (Immediate Generator)

    component imm_gen is
        port (
            Instruction_i : in  std_logic_vector(31 downto 0);    -- Instrução de 32 bits
            Immediate_o   : out std_logic_vector(31 downto 0)     -- Imediato estendido para 32 bits
        );
    end component imm_gen;

    -- Componente: Unidade de Controle da ALU (ALU Control)

    component alu_control is
        port (
            ALUOp_i       : in  std_logic_vector(1 downto 0);     -- Código de operação da ALU vindo da control_unit
            Funct3_i      : in  std_logic_vector(2 downto 0);     -- Campo funct3 da instrução (bits [14:12])
            Funct7_i      : in  std_logic_vector(6 downto 0);     -- Campo funct7 da instrução (bits [31:25])
            ALUControl_o  : out std_logic_vector(3 downto 0)      -- Sinal de controle da ALU (4 bits)
        ) ;
    end component ;

    -- ============== DECLARAÇÃO DOS SINAIS INTERMEDIÁRIOS ==============

    -- Sinais do Caminho de Dados
    
    signal s_pc_current           : std_logic_vector(31 downto 0) := (others => '0');     -- Contador de Programa (PC) atual
    signal s_pc_next              : std_logic_vector(31 downto 0) := (others => '0');     -- Próximo valor do PC
    signal s_pc_plus_4            : std_logic_vector(31 downto 0) := (others => '0');     -- PC + 4 (endereço da próxima instrução)
    signal s_instruction          : std_logic_vector(31 downto 0) := (others => '0');     -- Instrução atual (32 bits) - IR (Instruction Register)
    signal s_read_data_1          : std_logic_vector(31 downto 0) := (others => '0');     -- Dados lidos do primeiro registrador (rs1)
    signal s_read_data_2          : std_logic_vector(31 downto 0) := (others => '0');     -- Dados lidos do segundo registrador (rs2)
    signal s_immediate            : std_logic_vector(31 downto 0) := (others => '0');     -- Imediato estendido (32 bits)
    signal s_alu_in_b             : std_logic_vector(31 downto 0) := (others => '0');     -- Segundo operando da ALU (registrador ou imediato)
    signal s_alu_result           : std_logic_vector(31 downto 0) := (others => '0');     -- Resultado da ALU (32 bits)
    signal s_branch_or_jal_addr   : std_logic_vector(31 downto 0) := (others => '0');     -- Endereço para Branch e JAL
    signal s_branch_condition_met : std_logic := '0';                                     -- '1' se a condição do branch for atendida
    signal s_write_back_data      : std_logic_vector(31 downto 0) := (others => '0');     -- Dados a serem escritos de volta no banco de registradores

    -- Sinais de Controle

    signal s_reg_write            : std_logic := '0';                                     -- Habilita escrita no banco de registradores
    signal s_alusrc               : std_logic := '0';                                     -- Seleciona a fonte do segundo operando da ALU (0=registrador, 1=imediato)
    signal s_memtoreg             : std_logic := '0';                                     -- Seleciona a fonte dos dados a serem escritos no registrador (0=ALU, 1=Memória)
    signal s_memread              : std_logic := '0';                                     -- Habilita leitura da memória
    signal s_memwrite             : std_logic := '0';                                     -- Habilita escrita na memória
    signal s_branch               : std_logic := '0';                                     -- Indica desvio condicional
    signal s_jump                 : std_logic := '0';                                     -- Indica salto incondicional
    signal s_alu_zero             : std_logic := '0';                                     -- Flag "Zero" da ALU
    signal s_pc_src               : std_logic := '0';                                     -- Seleciona a fonte do próximo PC (0=PC+4, 1=branch/jump)
    signal s_aluop                : std_logic_vector(1 downto 0) := (others => '0');      -- Código de operação da ALU (2 bits)
    signal s_alu_control          : std_logic_vector(3 downto 0) := (others => '0');      -- Sinal de controle da ALU (4 bits)

begin

-- ==| Fetch, Decode, Execute, Memory, Writeback |================================================================================================

    -- ============== Estágio de Busca (FETCH) ===============================================

        -- Contador de Programa (PC) 
        -- - Registrador de 32 bits com reset assíncrono

            PC_REGISTER: process(CLK_i, Reset_i)
            begin
                if Reset_i = '1' then
                    s_pc_current <= (others => '0');
                elsif rising_edge(CLK_i) then
                    s_pc_current <= s_pc_next;                    -- Recebe o valor calculado pela lógica do "Próximo PC"
                end if;
            end process PC_REGISTER;

        -- O PC atual busca a instrução na memória (IMEM)
        
            IMem_addr_o <= s_pc_current;

        -- Captura a instrução que vem da memória (IMEM)
        
            s_instruction <= IMem_data_i;

    -- ============== Estágio de Decodificação (DECODE) ======================================

        -- A instrução é enviada para os três decodificadores simultaneamente.

        -- OBS.: na arquitetura RISC-V, os campos da instrução são fixos:

        -- - opcode nos bits [6:0];
        -- - funct3 nos bits [14:12];
        -- - funct7 nos bits [31:25].     
        -- - rd nos bits [11:7];
        -- - rs1 nos bits [19:15];
        -- - rs2 nos bits [24:20].

        -- - Unidade de Controle (Control Unit)
        -- -- Decodifica o opcode da instrução para gerar os sinais de controle

            U_CONTROL: entity work.control_unit port map (
                Opcode_i       => s_instruction(6 downto 0),
                RegWrite_o     => s_reg_write,
                ALUSrc_o       => s_alusrc,
                MemtoReg_o     => s_memtoreg,
                MemRead_o      => s_memread,
                MemWrite_o     => s_memwrite,
                Branch_o       => s_branch,
                Jump_o         => s_jump,
                ALUOp_o        => s_aluop
            );

        -- - Unidade de Controle da ALU (ALU Control)
        -- -- Decodifica funct3 e funct7 para gerar o sinal de controle da ALU

            U_ALU_CONTROL: entity work.alu_control port map (
                ALUOp_i        => s_aluop, 
                Funct3_i       => s_instruction(14 downto 12), 
                Funct7_i       => s_instruction(31 downto 25),
                ALUControl_o   => s_alu_control
            );

        -- - Gerador de Imediatos (Immediate Generator)
        -- -- Extrai e estende o imediato da instrução para 32 bits

            U_IMM_GEN: entity work.imm_gen port map (
                Instruction_i => s_instruction, 
                Immediate_o => s_immediate
            );

        -- Os endereços rs1 e rs2 da instrução são enviados ao Banco de Registradores,
        -- que fornece os dados dos registradores de forma combinacional.

            U_REG_FILE: entity work.reg_file port map (
                clk_i        => CLK_i,                            -- Clock do processador
                RegWrite_i   => s_reg_write,                      -- Habilita escrita no banco de registradores
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
            
            s_alu_in_b <= s_read_data_2 when s_alusrc = '0' else s_immediate;

        -- A ULA executa a operação comandada pelo s_alu_control.
        -- O resultado (s_alu_result) pode ser um valor aritmético, um endereço de memória ou um resultado de comparação.

            U_ALU: entity work.alu port map (
                A_i          => s_read_data_1,
                B_i          => s_alu_in_b,
                ALUControl_i => s_alu_control,
                Result_o     => s_alu_result,
                Zero_o       => s_alu_zero
            );

    -- ============== Estágio de Acesso à Memória (MEMORY) ==================================

        -- Aqui ocorre o acesso à memória de dados (DMEM).
        -- Dependendo dos sinais de controle, a CPU pode ler ou escrever na memória.
                    
        -- - A ALU sempre calcula o endereço para a memória de dados.

            DMem_addr_o        <= s_alu_result;   

        -- - O dado a ser escrito vem sempre de rs2.

            DMem_data_o        <= s_read_data_2;  

        -- - O sinal de escrita na memória vem da unidade de controle.

            DMem_writeEnable_o <= s_memwrite;

    -- ============== 5. ESTÁGIO DE ESCRITA DE VOLTA (WRITE-BACK) ==============

        -- O Mux MemtoReg decide o que será escrito de volta no registrador.

            s_write_back_data <= DMem_data_i when s_memtoreg = '1' else s_alu_result;

        -- Cálculo do próximo PC (s_pc_next)

        -- - Calcular todos os endereços candidatos possíveis para o próximo PC.
        -- - O resultado da ULA (s_alu_zero) e os sinais de controle decidem qual será o próximo PC.

        -- -- Candidato 1: Endereço sequencial (PC + 4)

            s_pc_plus_4 <= std_logic_vector(unsigned(s_pc_current) + 4);

        -- -- Candidato 2: Endereço de destino para Branch e JAL (PC + imediato)

            s_branch_or_jal_addr <= std_logic_vector(signed(s_pc_current) + signed(s_immediate));

        -- -- Candidato 3: Endereço de destino para JALR (rs1 + imediato)
        -- -- Este valor já está calculado e disponível na saída da ULA, em s_alu_result.

        -- - Determinar as condições de seleção do próximo PC:

        -- A condição para um desvio (branch) ser tomado depende do tipo de desvio.
        -- O sinal s_branch da control unit nos diz que é um branch.
        -- A ULA nos diz se a CONDIÇÃO do branch foi atendida.
        -- (Esta lógica será expandida para outros branches como BNE, BLT, etc.)

            s_branch_condition_met <= '1' when (s_branch = '1') and (
                    (s_instruction(14 downto 12) = "000" and s_alu_zero = '1') or  -- BEQ: Z=1 (A==B)
                    (s_instruction(14 downto 12) = "001" and s_alu_zero = '0') or  -- BNE: Z=0 (A!=B)
                    (s_instruction(14 downto 12) = "100" and s_alu_result(31) = '1') or  -- BLT: N=1 (A<B, com sinal)
                    (s_instruction(14 downto 12) = "101" and s_alu_result(31) = '0') or  -- BGE: N=0 (A>=B, com sinal)
                    (s_instruction(14 downto 12) = "110" and s_alu_result(31) = '1') or  -- BLTU: C=1 (A<B, sem sinal) -> Simplificado
                    (s_instruction(14 downto 12) = "111" and s_alu_result(31) = '0')     -- BGEU: C=0 (A>=B, sem sinal) -> Simplificado
                    )
                else '0';

        -- Mux final que alimenta o registrador do PC no próximo ciclo de clock

        -- - A prioridade é: Jumps têm precedência sobre Branches, que têm precedência sobre PC+4.

            s_pc_next <= s_alu_result when s_jump = '1' and s_instruction(6 downto 0) = "1100111" else -- JALR
                        s_branch_or_jal_addr when s_jump = '1' and s_instruction(6 downto 0) = "1101111" else -- JAL
                        s_branch_or_jal_addr when s_branch_condition_met = '1'  else -- Branch (se a condição for atendida)
                        s_pc_plus_4; 

end architecture rtl; -- rtl

-- ===============================================================================================================================================