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
            Decoder_o : out t_decoder
        );
    end component decoder;

-------------------------------------------------------------------------------------------------------------------
    -- 2. Sinais para o Teste
-------------------------------------------------------------------------------------------------------------------

    -- Sinais para conectar ao DUT
    signal s_opcode_i : std_logic_vector(6 downto 0);
    
    -- Sinal único que agrupa todas as saídas de controle
    signal s_decoder     : t_decoder;

begin

-------------------------------------------------------------------------------------------------------------------
    -- 3. Instanciação do Componente sob Teste (DUT)
-------------------------------------------------------------------------------------------------------------------

    DUT: entity work.decoder
        port map (
            Opcode_i  => s_opcode_i,
            Decoder_o => s_decoder
        );

-------------------------------------------------------------------------------------------------------------------
    -- 4. Processo de Estímulo e Verificação Automática
-------------------------------------------------------------------------------------------------------------------

    stimulus_proc: process is
    begin

        -- Mensagem inicial indicando o início dos testes
        report "INICIANDO VERIFICACAO DA UNIDADE DECODIFICADORA PRINCIPAL..." severity note;

        -- Teste 1: R-Type (ADD, SUB, etc.)
        report "TESTE 1: Opcode R-Type (add, sub, and, or, etc.)" severity note;
        s_opcode_i <= c_OPCODE_R_TYPE;
        wait for 1 ns;
        ASSERT s_decoder.reg_write = '1' 
            REPORT "ERRO R-Type: reg_write deve ser '1'" SEVERITY error;
        ASSERT s_decoder.alu_src_a = "00" 
            REPORT "ERRO R-Type: alu_src_a deve ser '00'" SEVERITY error;
        ASSERT s_decoder.alu_src_b = '0' 
            REPORT "ERRO R-Type: alu_src_b deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_to_reg = '0' 
            REPORT "ERRO R-Type: mem_to_reg deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_write = '0' 
            REPORT "ERRO R-Type: mem_write deve ser '0'" SEVERITY error;
        ASSERT s_decoder.write_data_src = '0' 
            REPORT "ERRO R-Type: write_data_src deve ser '0'" SEVERITY error;
        ASSERT s_decoder.branch = '0' 
            REPORT "ERRO R-Type: branch deve ser '0'" SEVERITY error;
        ASSERT s_decoder.jump = '0' 
            REPORT "ERRO R-Type: jump deve ser '0'" SEVERITY error;
        ASSERT s_decoder.alu_op = "10" 
            REPORT "ERRO R-Type: alu_op deve ser '10'" SEVERITY error;

        -- Teste 2: I-Type Aritmético (ADDI, ANDI, ORI, etc.)
        report "TESTE 2: Opcode I-Type (addi, andi, ori, etc.)" severity note;
        s_opcode_i <= c_OPCODE_I_TYPE;
        wait for 1 ns;
        ASSERT s_decoder.reg_write = '1' 
            REPORT "ERRO I-Type: reg_write deve ser '1'" SEVERITY error;
        ASSERT s_decoder.alu_src_a = "00" 
            REPORT "ERRO I-Type: alu_src_a deve ser '00'" SEVERITY error;
        ASSERT s_decoder.alu_src_b = '1' 
            REPORT "ERRO I-Type: alu_src_b deve ser '1'" SEVERITY error;
        ASSERT s_decoder.mem_to_reg = '0' 
            REPORT "ERRO I-Type: mem_to_reg deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_write = '0' 
            REPORT "ERRO I-Type: mem_write deve ser '0'" SEVERITY error;
        ASSERT s_decoder.write_data_src = '0' 
            REPORT "ERRO I-Type: write_data_src deve ser '0'" SEVERITY error;
        ASSERT s_decoder.branch = '0' 
            REPORT "ERRO I-Type: branch deve ser '0'" SEVERITY error;
        ASSERT s_decoder.jump = '0' 
            REPORT "ERRO I-Type: jump deve ser '0'" SEVERITY error;
        ASSERT s_decoder.alu_op = "11" 
            REPORT "ERRO I-Type: alu_op deve ser '11'" SEVERITY error;

        -- Teste 3: LOAD (LB, LH, LW, LBU, LHU)
        report "TESTE 3: Opcode LOAD (lw, lb, lh, etc.)" severity note;
        s_opcode_i <= c_OPCODE_LOAD;
        wait for 1 ns;
        ASSERT s_decoder.reg_write = '1' 
            REPORT "ERRO LOAD: reg_write deve ser '1'" SEVERITY error;
        ASSERT s_decoder.alu_src_a = "00" 
            REPORT "ERRO LOAD: alu_src_a deve ser '00'" SEVERITY error;
        ASSERT s_decoder.alu_src_b = '1' 
            REPORT "ERRO LOAD: alu_src_b deve ser '1'" SEVERITY error;
        ASSERT s_decoder.mem_to_reg = '1' 
            REPORT "ERRO LOAD: mem_to_reg deve ser '1'" SEVERITY error;
        ASSERT s_decoder.mem_write = '0' 
            REPORT "ERRO LOAD: mem_write deve ser '0'" SEVERITY error;
        ASSERT s_decoder.write_data_src = '0' 
            REPORT "ERRO LOAD: write_data_src deve ser '0'" SEVERITY error;
        ASSERT s_decoder.branch = '0' 
            REPORT "ERRO LOAD: branch deve ser '0'" SEVERITY error;
        ASSERT s_decoder.jump = '0' 
            REPORT "ERRO LOAD: jump deve ser '0'" SEVERITY error;
        ASSERT s_decoder.alu_op = "00" 
            REPORT "ERRO LOAD: alu_op deve ser '00'" SEVERITY error;

        -- Teste 4: STORE (SB, SH, SW)
        report "TESTE 4: Opcode STORE (sw, sb, sh, etc.)" severity note;
        s_opcode_i <= c_OPCODE_STORE;
        wait for 1 ns;
        ASSERT s_decoder.reg_write = '0' 
            REPORT "ERRO STORE: reg_write deve ser '0'" SEVERITY error;
        ASSERT s_decoder.alu_src_a = "00" 
            REPORT "ERRO STORE: alu_src_a deve ser '00'" SEVERITY error;
        ASSERT s_decoder.alu_src_b = '1' 
            REPORT "ERRO STORE: alu_src_b deve ser '1'" SEVERITY error;
        ASSERT s_decoder.mem_to_reg = '0' 
            REPORT "ERRO STORE: mem_to_reg deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_write = '1' 
            REPORT "ERRO STORE: mem_write deve ser '1'" SEVERITY error;
        ASSERT s_decoder.write_data_src = '0' 
            REPORT "ERRO STORE: write_data_src deve ser '0'" SEVERITY error;
        ASSERT s_decoder.branch = '0' 
            REPORT "ERRO STORE: branch deve ser '0'" SEVERITY error;
        ASSERT s_decoder.jump = '0' 
            REPORT "ERRO STORE: jump deve ser '0'" SEVERITY error;
        ASSERT s_decoder.alu_op = "00" 
            REPORT "ERRO STORE: alu_op deve ser '00'" SEVERITY error;

        -- Teste 5: BRANCH (BEQ, BNE, BLT, BGE, BLTU, BGEU)
        report "TESTE 5: Opcode BRANCH (beq, bne, blt, bge, etc.)" severity note;
        s_opcode_i <= c_OPCODE_BRANCH;
        wait for 1 ns;
        ASSERT s_decoder.reg_write = '0' 
            REPORT "ERRO BRANCH: reg_write deve ser '0'" SEVERITY error;
        ASSERT s_decoder.alu_src_a = "00" 
            REPORT "ERRO BRANCH: alu_src_a deve ser '00'" SEVERITY error;
        ASSERT s_decoder.alu_src_b = '0' 
            REPORT "ERRO BRANCH: alu_src_b deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_to_reg = '0' 
            REPORT "ERRO BRANCH: mem_to_reg deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_write = '0' 
            REPORT "ERRO BRANCH: mem_write deve ser '0'" SEVERITY error;
        ASSERT s_decoder.write_data_src = '0' 
            REPORT "ERRO BRANCH: write_data_src deve ser '0'" SEVERITY error;
        ASSERT s_decoder.branch = '1' 
            REPORT "ERRO BRANCH: branch deve ser '1'" SEVERITY error;
        ASSERT s_decoder.jump = '0' 
            REPORT "ERRO BRANCH: jump deve ser '0'" SEVERITY error;
        ASSERT s_decoder.alu_op = "01" 
            REPORT "ERRO BRANCH: alu_op deve ser '01'" SEVERITY error;

        -- Teste 6: JAL (Jump and Link)
        report "TESTE 6: Opcode JAL (jump and link)" severity note;
        s_opcode_i <= c_OPCODE_JAL;
        wait for 1 ns;
        ASSERT s_decoder.reg_write = '1' 
            REPORT "ERRO JAL: reg_write deve ser '1'" SEVERITY error;
        ASSERT s_decoder.alu_src_a = "00" 
            REPORT "ERRO JAL: alu_src_a deve ser '00'" SEVERITY error;
        ASSERT s_decoder.alu_src_b = '0' 
            REPORT "ERRO JAL: alu_src_b deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_to_reg = '0' 
            REPORT "ERRO JAL: mem_to_reg deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_write = '0' 
            REPORT "ERRO JAL: mem_write deve ser '0'" SEVERITY error;
        ASSERT s_decoder.write_data_src = '1' 
            REPORT "ERRO JAL: write_data_src deve ser '1' (PC+4)" SEVERITY error;
        ASSERT s_decoder.branch = '0' 
            REPORT "ERRO JAL: branch deve ser '0'" SEVERITY error;
        ASSERT s_decoder.jump = '1' 
            REPORT "ERRO JAL: jump deve ser '1'" SEVERITY error;
        ASSERT s_decoder.alu_op = "00" 
            REPORT "ERRO JAL: alu_op deve ser '00'" SEVERITY error;

        -- Teste 7: JALR (Jump and Link Register)
        report "TESTE 7: Opcode JALR (jump and link register)" severity note;
        s_opcode_i <= c_OPCODE_JALR;
        wait for 1 ns;
        ASSERT s_decoder.reg_write = '1' 
            REPORT "ERRO JALR: reg_write deve ser '1'" SEVERITY error;
        ASSERT s_decoder.alu_src_a = "00" 
            REPORT "ERRO JALR: alu_src_a deve ser '00'" SEVERITY error;
        ASSERT s_decoder.alu_src_b = '1' 
            REPORT "ERRO JALR: alu_src_b deve ser '1'" SEVERITY error;
        ASSERT s_decoder.mem_to_reg = '0' 
            REPORT "ERRO JALR: mem_to_reg deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_write = '0' 
            REPORT "ERRO JALR: mem_write deve ser '0'" SEVERITY error;
        ASSERT s_decoder.write_data_src = '1' 
            REPORT "ERRO JALR: write_data_src deve ser '1' (PC+4)" SEVERITY error;
        ASSERT s_decoder.branch = '0' 
            REPORT "ERRO JALR: branch deve ser '0'" SEVERITY error;
        ASSERT s_decoder.jump = '1' 
            REPORT "ERRO JALR: jump deve ser '1'" SEVERITY error;
        ASSERT s_decoder.alu_op = "00" 
            REPORT "ERRO JALR: alu_op deve ser '00'" SEVERITY error;

        -- Teste 8: LUI (Load Upper Immediate)
        report "TESTE 8: Opcode LUI (load upper immediate)" severity note;
        s_opcode_i <= c_OPCODE_LUI;
        wait for 1 ns;
        ASSERT s_decoder.reg_write = '1' 
            REPORT "ERRO LUI: reg_write deve ser '1'" SEVERITY error;
        ASSERT s_decoder.alu_src_a = "10" 
            REPORT "ERRO LUI: alu_src_a deve ser '10' (Zero)" SEVERITY error;
        ASSERT s_decoder.alu_src_b = '1' 
            REPORT "ERRO LUI: alu_src_b deve ser '1'" SEVERITY error;
        ASSERT s_decoder.mem_to_reg = '0' 
            REPORT "ERRO LUI: mem_to_reg deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_write = '0' 
            REPORT "ERRO LUI: mem_write deve ser '0'" SEVERITY error;
        ASSERT s_decoder.write_data_src = '0' 
            REPORT "ERRO LUI: write_data_src deve ser '0'" SEVERITY error;
        ASSERT s_decoder.branch = '0' 
            REPORT "ERRO LUI: branch deve ser '0'" SEVERITY error;
        ASSERT s_decoder.jump = '0' 
            REPORT "ERRO LUI: jump deve ser '0'" SEVERITY error;
        ASSERT s_decoder.alu_op = "00" 
            REPORT "ERRO LUI: alu_op deve ser '00'" SEVERITY error;

        -- Teste 9: AUIPC (Add Upper Immediate to PC)
        report "TESTE 9: Opcode AUIPC (add upper imm to PC)" severity note;
        s_opcode_i <= c_OPCODE_AUIPC;
        wait for 1 ns;
        ASSERT s_decoder.reg_write = '1' 
            REPORT "ERRO AUIPC: reg_write deve ser '1'" SEVERITY error;
        ASSERT s_decoder.alu_src_a = "01" 
            REPORT "ERRO AUIPC: alu_src_a deve ser '01' (PC)" SEVERITY error;
        ASSERT s_decoder.alu_src_b = '1' 
            REPORT "ERRO AUIPC: alu_src_b deve ser '1'" SEVERITY error;
        ASSERT s_decoder.mem_to_reg = '0' 
            REPORT "ERRO AUIPC: mem_to_reg deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_write = '0' 
            REPORT "ERRO AUIPC: mem_write deve ser '0'" SEVERITY error;
        ASSERT s_decoder.write_data_src = '0' 
            REPORT "ERRO AUIPC: write_data_src deve ser '0'" SEVERITY error;
        ASSERT s_decoder.branch = '0' 
            REPORT "ERRO AUIPC: branch deve ser '0'" SEVERITY error;
        ASSERT s_decoder.jump = '0' 
            REPORT "ERRO AUIPC: jump deve ser '0'" SEVERITY error;
        ASSERT s_decoder.alu_op = "00" 
            REPORT "ERRO AUIPC: alu_op deve ser '00'" SEVERITY error;

        -- Teste 10: FENCE (deve se comportar como NOP)
        report "TESTE 10: Opcode FENCE (memory fence - NOP)" severity note;
        s_opcode_i <= C_OPCODE_FENCE;
        wait for 1 ns;
        ASSERT s_decoder.reg_write = '0' 
            REPORT "ERRO FENCE: reg_write deve ser '0' (NOP)" SEVERITY error;
        ASSERT s_decoder.alu_src_a = "00" 
            REPORT "ERRO FENCE: alu_src_a deve ser '00'" SEVERITY error;
        ASSERT s_decoder.alu_src_b = '0' 
            REPORT "ERRO FENCE: alu_src_b deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_to_reg = '0' 
            REPORT "ERRO FENCE: mem_to_reg deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_write = '0' 
            REPORT "ERRO FENCE: mem_write deve ser '0' (NOP)" SEVERITY error;
        ASSERT s_decoder.write_data_src = '0' 
            REPORT "ERRO FENCE: write_data_src deve ser '0'" SEVERITY error;
        ASSERT s_decoder.branch = '0' 
            REPORT "ERRO FENCE: branch deve ser '0'" SEVERITY error;
        ASSERT s_decoder.jump = '0' 
            REPORT "ERRO FENCE: jump deve ser '0'" SEVERITY error;
        ASSERT s_decoder.alu_op = "00" 
            REPORT "ERRO FENCE: alu_op deve ser '00'" SEVERITY error;

        -- Teste 11: SYSTEM (ECALL/EBREAK - deve se comportar como NOP)
        report "TESTE 11: Opcode SYSTEM (ecall/ebreak - NOP)" severity note;
        s_opcode_i <= C_OPCODE_SYSTEM;
        wait for 1 ns;
        ASSERT s_decoder.reg_write = '0' 
            REPORT "ERRO SYSTEM: reg_write deve ser '0' (NOP)" SEVERITY error;
        ASSERT s_decoder.alu_src_a = "00" 
            REPORT "ERRO SYSTEM: alu_src_a deve ser '00'" SEVERITY error;
        ASSERT s_decoder.alu_src_b = '0' 
            REPORT "ERRO SYSTEM: alu_src_b deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_to_reg = '0' 
            REPORT "ERRO SYSTEM: mem_to_reg deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_write = '0' 
            REPORT "ERRO SYSTEM: mem_write deve ser '0' (NOP)" SEVERITY error;
        ASSERT s_decoder.write_data_src = '0' 
            REPORT "ERRO SYSTEM: write_data_src deve ser '0'" SEVERITY error;
        ASSERT s_decoder.branch = '0' 
            REPORT "ERRO SYSTEM: branch deve ser '0'" SEVERITY error;
        ASSERT s_decoder.jump = '0' 
            REPORT "ERRO SYSTEM: jump deve ser '0'" SEVERITY error;
        ASSERT s_decoder.alu_op = "00" 
            REPORT "ERRO SYSTEM: alu_op deve ser '00'" SEVERITY error;

        -- Teste 12: Opcode Ilegal (teste da cláusula 'others' - deve ser NOP)
        report "TESTE 12: Opcode ILEGAL (unknown opcode - NOP)" severity note;
        s_opcode_i <= "1111111"; -- Um opcode que não existe no RV32I
        wait for 1 ns;
        ASSERT s_decoder.reg_write = '0' 
            REPORT "ERRO ILEGAL: reg_write deve ser '0' (NOP)" SEVERITY error;
        ASSERT s_decoder.alu_src_a = "00" 
            REPORT "ERRO ILEGAL: alu_src_a deve ser '00'" SEVERITY error;
        ASSERT s_decoder.alu_src_b = '0' 
            REPORT "ERRO ILEGAL: alu_src_b deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_to_reg = '0' 
            REPORT "ERRO ILEGAL: mem_to_reg deve ser '0'" SEVERITY error;
        ASSERT s_decoder.mem_write = '0' 
            REPORT "ERRO ILEGAL: mem_write deve ser '0' (NOP)" SEVERITY error;
        ASSERT s_decoder.write_data_src = '0' 
            REPORT "ERRO ILEGAL: write_data_src deve ser '0'" SEVERITY error;
        ASSERT s_decoder.branch = '0' 
            REPORT "ERRO ILEGAL: branch deve ser '0'" SEVERITY error;
        ASSERT s_decoder.jump = '0' 
            REPORT "ERRO ILEGAL: jump deve ser '0'" SEVERITY error;
        ASSERT s_decoder.alu_op = "00" 
            REPORT "ERRO ILEGAL: alu_op deve ser '00' (NOP)" SEVERITY error;

        -- Mensagem final indicando que todos os testes finalizaram
        report "VERIFICACAO DA UNIDADE DECODIFICADORA CONCLUIDA COM SUCESSO!" severity note;
        
        -- Para a simulação para não rodar para sempre.
        std.env.stop;
        
    end process stimulus_proc;

end architecture test;