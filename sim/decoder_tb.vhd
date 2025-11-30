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
            Opcode_i  : in  std_logic_vector(6 downto 0);
            Control_o : out t_control
        );
    end component decoder;

-------------------------------------------------------------------------------------------------------------------
    -- 2. Sinais para o Teste
-------------------------------------------------------------------------------------------------------------------

    -- Sinais para conectar ao DUT
    signal s_opcode_i : std_logic_vector(6 downto 0);
    
    -- Sinal único que agrupa todas as saídas de controle
    signal s_ctrl     : t_control;

begin

-------------------------------------------------------------------------------------------------------------------
    -- 3. Instanciação do Componente sob Teste (DUT)
-------------------------------------------------------------------------------------------------------------------

    DUT: entity work.decoder
        port map (
            Opcode_i  => s_opcode_i,
            Control_o => s_ctrl
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
        ASSERT s_ctrl.reg_write = '1' and s_ctrl.alu_src_b = '0' and s_ctrl.mem_to_reg = '0' and s_ctrl.mem_read = '0' and s_ctrl.mem_write = '0' and s_ctrl.branch = '0' and s_ctrl.jump = '0' and s_ctrl.alu_op = "10"
            REPORT "ERRO: Sinais de controle incorretos para R-Type!" SEVERITY error;

        -- Teste 2: LW (Load Word)
        report "TESTE: Opcode LW (load)" severity note;
        s_opcode_i <= c_OPCODE_LOAD;
        wait for 1 ns;
        ASSERT s_ctrl.reg_write = '1' and s_ctrl.alu_src_b = '1' and s_ctrl.mem_to_reg = '1' and s_ctrl.mem_read = '1' and s_ctrl.mem_write = '0' and s_ctrl.branch = '0' and s_ctrl.jump = '0' and s_ctrl.alu_op = "00"
            REPORT "ERRO: Sinais de controle incorretos para LW!" SEVERITY error;

        -- Teste 3: SW (Store Word)
        report "TESTE: Opcode SW (store)" severity note;
        s_opcode_i <= c_OPCODE_STORE;
        wait for 1 ns;
        ASSERT s_ctrl.reg_write = '0' and s_ctrl.alu_src_b = '1' and s_ctrl.mem_read = '0' and s_ctrl.mem_write = '1' and s_ctrl.branch = '0' and s_ctrl.jump = '0' and s_ctrl.alu_op = "00"
            REPORT "ERRO: Sinais de controle incorretos para SW!" SEVERITY error;
            
        -- Teste 4: Branch (beq)
        report "TESTE: Opcode Branch (beq, bne, etc.)" severity note;
        s_opcode_i <= c_OPCODE_BRANCH;
        wait for 1 ns;
        ASSERT s_ctrl.reg_write = '0' and s_ctrl.alu_src_b = '0' and s_ctrl.mem_read = '0' and s_ctrl.mem_write = '0' and s_ctrl.branch = '1' and s_ctrl.jump = '0' and s_ctrl.alu_op = "01"
            REPORT "ERRO: Sinais de controle incorretos para Branch!" SEVERITY error;
            
        -- Teste 5: I-Type (addi)
        report "TESTE: Opcode I-Type (addi, etc.)" severity note;
        s_opcode_i <= c_OPCODE_I_TYPE;
        wait for 1 ns;
        ASSERT s_ctrl.reg_write = '1' and s_ctrl.alu_src_b = '1' and s_ctrl.mem_to_reg = '0' and s_ctrl.mem_read = '0' and s_ctrl.mem_write = '0' and s_ctrl.branch = '0' and s_ctrl.jump = '0' and s_ctrl.alu_op = "11"
            REPORT "ERRO: Sinais de controle incorretos para I-Type!" SEVERITY error;
            
        -- Teste 6: JAL (Jump and Link)
        report "TESTE: Opcode JAL" severity note;
        s_opcode_i <= c_OPCODE_JAL;
        wait for 1 ns;
        ASSERT s_ctrl.reg_write = '1' and s_ctrl.jump = '1' and s_ctrl.branch = '0' and s_ctrl.write_data_src = '1'
            REPORT "ERRO: Sinais de controle incorretos para JAL!" SEVERITY error;

        -- Teste 7: JALR (Jump and Link Register) 
        report "TESTE: Opcode JALR" severity note;
        s_opcode_i <= c_OPCODE_JALR;
        wait for 1 ns;
        ASSERT s_ctrl.reg_write = '1' and s_ctrl.jump = '1' and s_ctrl.alu_src_b = '1' and s_ctrl.alu_op = "00"
            REPORT "ERRO: Sinais de controle incorretos para JALR!" SEVERITY error;

        -- Teste 8: LUI (Load Upper Immediate)
        report "TESTE: Opcode LUI" severity note;
        s_opcode_i <= c_OPCODE_LUI;
        wait for 1 ns;
        ASSERT s_ctrl.reg_write = '1' and s_ctrl.alu_src_b = '1' and s_ctrl.mem_to_reg = '0' and s_ctrl.mem_read = '0' and s_ctrl.mem_write = '0' and s_ctrl.branch = '0' and s_ctrl.jump = '0' and s_ctrl.alu_op = "00"
            REPORT "ERRO: Sinais de controle incorretos para LUI!" SEVERITY error;

        -- Teste 9: FENCE (deve se comportar como NOP)
        report "TESTE: Opcode FENCE" severity note;
        s_opcode_i <= C_OPCODE_FENCE;
        wait for 1 ns;
        ASSERT s_ctrl.reg_write = '0' and s_ctrl.mem_read = '0' and s_ctrl.mem_write = '0' and s_ctrl.branch = '0' and s_ctrl.jump = '0'
            REPORT "ERRO: Sinais de controle incorretos para FENCE! (deveria ser NOP)" SEVERITY error;

        -- Teste 10: SYSTEM (deve se comportar como NOP) 
        report "TESTE: Opcode SYSTEM (ECALL/EBREAK)" severity note;
        s_opcode_i <= C_OPCODE_SYSTEM;
        wait for 1 ns;
        ASSERT s_ctrl.reg_write = '0' and s_ctrl.mem_read = '0' and s_ctrl.mem_write = '0' and s_ctrl.branch = '0' and s_ctrl.jump = '0'
            REPORT "ERRO: Sinais de controle incorretos para SYSTEM! (deveria ser NOP)" SEVERITY error;

        -- Teste 11: Opcode Ilegal (teste da cláusula 'others')
        report "TESTE: Opcode ILEGAL" severity note;
        s_opcode_i <= "1111111"; -- Um opcode que não existe no RV32I
        wait for 1 ns;
        ASSERT s_ctrl.reg_write = '0' and s_ctrl.mem_write = '0' and s_ctrl.branch = '0' and s_ctrl.jump = '0'
            REPORT "ERRO: A clausula 'others' nao gerou um estado seguro!" SEVERITY error;

        -- Mensagem final indicando que todos os testes finalizaram
        report "VERIFICACAO DA UNIDADE DECODIFICADORA CONCLUIDA" severity note;
        
        -- Para a simulação para não rodar para sempre.
        std.env.stop;
        
    end process stimulus_proc;

end architecture test;