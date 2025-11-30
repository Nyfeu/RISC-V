-------------------------------------------------------------------------------------------------------------------
--
-- File: decoder_tb.vhd (Testbench para a Unidade Decodificadora)
--
-- Descrição: Este testbench verifica a funcionalidade da unidade decodificadora
--            para um processador RISC-V de 32 bits (RV32I). Ele aplica uma
--            série de opcodes de instrução e verifica se os sinais de controle
--            gerados correspondem aos valores esperados.
--
-------------------------------------------------------------------------------------------------------------------

-- Inclusão dos módulos necessários
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_pkg.all;

-- A entidade de um testbench é sempre vazia.
entity decoder_tb is
end entity decoder_tb;

-- A arquitetura do testbench contém a instância do DUT e o processo de estímulo.
architecture test of decoder_tb is

-------------------------------------------------------------------------------------------------------------------
    -- 1. Declaração do Componente sob Teste (DUT - Device Under Test)
-------------------------------------------------------------------------------------------------------------------

    component decoder is
        port (
            Opcode_i      : in  std_logic_vector(6 downto 0);
            RegWrite_o    : out std_logic;
            ALUSrcB_o      : out std_logic;
            MemtoReg_o    : out std_logic;
            MemRead_o     : out std_logic;
            MemWrite_o    : out std_logic;
            Branch_o      : out std_logic;
            Jump_o        : out std_logic;
            ALUOp_o       : out std_logic_vector(1 downto 0)
        );
    end component decoder;

-------------------------------------------------------------------------------------------------------------------
    -- 2. Sinais para o Teste
-------------------------------------------------------------------------------------------------------------------

    -- Sinais para conectar ao DUT
    signal s_opcode_i            : std_logic_vector(6 downto 0);
    signal s_reg_write_o         : std_logic;
    signal s_ALUSrcA_o           : std_logic_vector(1 downto 0) := "00";
    signal s_ALUSrcB_o           : std_logic;
    signal s_memtoreg_o          : std_logic;
    signal s_memread_o           : std_logic;
    signal s_memwrite_o          : std_logic;
    signal s_branch_o            : std_logic;
    signal s_jump_o              : std_logic;
    signal s_aluop_o             : std_logic_vector(1 downto 0);
    signal s_write_data_source_o : std_logic;

begin

-------------------------------------------------------------------------------------------------------------------
    -- 3. Instanciação do Componente sob Teste (DUT)
-------------------------------------------------------------------------------------------------------------------

    DUT: entity work.decoder
        port map (
            Opcode_i      => s_opcode_i,
            RegWrite_o    => s_reg_write_o,
            ALUSrcA_o     => s_ALUSrcA_o,
            ALUSrcB_o     => s_ALUSrcB_o,
            MemtoReg_o    => s_memtoreg_o,
            MemRead_o     => s_memread_o,
            MemWrite_o    => s_memwrite_o,
            Branch_o      => s_branch_o,
            Jump_o        => s_jump_o,
            ALUOp_o       => s_aluop_o,
            WriteDataSource_o => s_write_data_source_o
        );

-------------------------------------------------------------------------------------------------------------------
    -- 4. Processo de Estímulo e Verificação Automática
-------------------------------------------------------------------------------------------------------------------

    stimulus_proc: process is
    begin

        -- Mensagem inicial indicando o início dos testes
        report "INICIANDO VERIFICACAO DA UNIDADE DECODIFICADORA PRINCIPAL..." severity note;

        -- Teste 1: R-Type
        report "TESTE: Opcode R-Type (add, sub, etc.)" severity note;
        s_opcode_i <= c_OPCODE_R_TYPE;
        wait for 1 ns;
        ASSERT s_reg_write_o = '1' and s_ALUSrcB_o = '0' and s_memtoreg_o = '0' and s_memread_o = '0' and s_memwrite_o = '0' and s_branch_o = '0' and s_jump_o = '0' and s_aluop_o = "10"
            REPORT "ERRO: Sinais de controle incorretos para R-Type!" SEVERITY error;

        -- Teste 2: LW (Load Word)
        report "TESTE: Opcode LW (load)" severity note;
        s_opcode_i <= c_OPCODE_LOAD;
        wait for 1 ns;
        ASSERT s_reg_write_o = '1' and s_ALUSrcB_o = '1' and s_memtoreg_o = '1' and s_memread_o = '1' and s_memwrite_o = '0' and s_branch_o = '0' and s_jump_o = '0' and s_aluop_o = "00"
            REPORT "ERRO: Sinais de controle incorretos para LW!" SEVERITY error;

        -- Teste 3: SW (Store Word)
        report "TESTE: Opcode SW (store)" severity note;
        s_opcode_i <= c_OPCODE_STORE;
        wait for 1 ns;
        ASSERT s_reg_write_o = '0' and s_ALUSrcB_o = '1' and s_memread_o = '0' and s_memwrite_o = '1' and s_branch_o = '0' and s_jump_o = '0' and s_aluop_o = "00"
            REPORT "ERRO: Sinais de controle incorretos para SW!" SEVERITY error;
            
        -- Teste 4: Branch (beq)
        report "TESTE: Opcode Branch (beq, bne, etc.)" severity note;
        s_opcode_i <= c_OPCODE_BRANCH;
        wait for 1 ns;
        ASSERT s_reg_write_o = '0' and s_ALUSrcB_o = '0' and s_memread_o = '0' and s_memwrite_o = '0' and s_branch_o = '1' and s_jump_o = '0' and s_aluop_o = "01"
            REPORT "ERRO: Sinais de controle incorretos para Branch!" SEVERITY error;
            
        -- Teste 5: I-Type (addi)
        report "TESTE: Opcode I-Type (addi, etc.)" severity note;
        s_opcode_i <= c_OPCODE_I_TYPE;
        wait for 1 ns;
        ASSERT s_reg_write_o = '1' and s_ALUSrcB_o = '1' and s_memtoreg_o = '0' and s_memread_o = '0' and s_memwrite_o = '0' and s_branch_o = '0' and s_jump_o = '0' and s_aluop_o = "11"
            REPORT "ERRO: Sinais de controle incorretos para I-Type!" SEVERITY error;
            
        -- Teste 6: JAL (Jump and Link)
        report "TESTE: Opcode JAL" severity note;
        s_opcode_i <= c_OPCODE_JAL;
        wait for 1 ns;
        ASSERT s_reg_write_o = '1' and s_jump_o = '1' and s_branch_o = '0' and s_write_data_source_o = '1'
            REPORT "ERRO: Sinais de controle incorretos para JAL!" SEVERITY error;

        -- Teste 7: JALR (Jump and Link Register) 
        report "TESTE: Opcode JALR" severity note;
        s_opcode_i <= c_OPCODE_JALR;
        wait for 1 ns;
        ASSERT s_reg_write_o = '1' and s_jump_o = '1' and s_ALUSrcB_o = '1' and s_aluop_o = "00"
            REPORT "ERRO: Sinais de controle incorretos para JALR!" SEVERITY error;

        -- Teste 8: LUI (Load Upper Immediate)
        report "TESTE: Opcode LUI" severity note;
        s_opcode_i <= c_OPCODE_LUI;
        wait for 1 ns;
        ASSERT s_reg_write_o = '1' and s_ALUSrcB_o = '1' and s_memtoreg_o = '0' and s_memread_o = '0' and s_memwrite_o = '0' and s_branch_o = '0' and s_jump_o = '0' and s_aluop_o = "00"
            REPORT "ERRO: Sinais de controle incorretos para LUI!" SEVERITY error;

        -- Teste 9: FENCE (deve se comportar como NOP)
        report "TESTE: Opcode FENCE" severity note;
        s_opcode_i <= C_OPCODE_FENCE;
        wait for 1 ns;
        ASSERT s_reg_write_o = '0' and s_memread_o = '0' and s_memwrite_o = '0' and s_branch_o = '0' and s_jump_o = '0'
            REPORT "ERRO: Sinais de controle incorretos para FENCE! (deveria ser NOP)" SEVERITY error;

        -- Teste 10: SYSTEM (deve se comportar como NOP) 
        report "TESTE: Opcode SYSTEM (ECALL/EBREAK)" severity note;
        s_opcode_i <= C_OPCODE_SYSTEM;
        wait for 1 ns;
        ASSERT s_reg_write_o = '0' and s_memread_o = '0' and s_memwrite_o = '0' and s_branch_o = '0' and s_jump_o = '0'
            REPORT "ERRO: Sinais de controle incorretos para SYSTEM! (deveria ser NOP)" SEVERITY error;

        -- Teste 11: Opcode Ilegal (teste da cláusula 'others')
        report "TESTE: Opcode ILEGAL" severity note;
        s_opcode_i <= "1111111"; -- Um opcode que não existe no RV32I
        wait for 1 ns;
        ASSERT s_reg_write_o = '0' and s_memwrite_o = '0' and s_branch_o = '0' and s_jump_o = '0'
            REPORT "ERRO: A clausula 'others' nao gerou um estado seguro!" SEVERITY error;

        -- Mensagem final indicando que todos os testes finalizaram
        report "VERIFICACAO DA UNIDADE DECODIFICADORA CONCLUIDA" severity note;
        
        -- Para a simulação para não rodar para sempre.
        std.env.stop;
        
    end process stimulus_proc;

end architecture test;