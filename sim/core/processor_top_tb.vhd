-------------------------------------------------------------------------------------------------------------------
--
-- File: processor_top_tb.vhd (Testbench para o Processador RISC-V)
--
-- Descrição: Este testbench verifica a funcionalidade de execução de códigos
--            compilados a partir da toolchain riscv64-unknown-elf-gcc do 
--            processador com suas partes integradas.
--
-------------------------------------------------------------------------------------------------------------------

-- Inclusão dos módulos necessários
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use std.textio.all;

-- Carrega o pacote memory_loader
library work;
use work.memory_loader_pkg.all;

-- A entidade de um testbench é sempre vazia.
entity processor_top_tb is
    generic (
        PROGRAM_PATH : string := "program.hex"
    );
end entity processor_top_tb;

-- A arquitetura do testbench contém a instância do DUT e o processo de estímulo.
architecture test of processor_top_tb is

-------------------------------------------------------------------------------------------------------------------
    -- 1. Declaração do Componente sob Teste (DUT - Device Under Test)
-------------------------------------------------------------------------------------------------------------------

    component processor_top is
        port (
            CLK_i              : in  std_logic;
            Reset_i            : in  std_logic;
            IMem_addr_o        : out std_logic_vector(31 downto 0);
            IMem_data_i        : in  std_logic_vector(31 downto 0);
            DMem_addr_o        : out std_logic_vector(31 downto 0);
            DMem_data_i        : in  std_logic_vector(31 downto 0);
            DMem_data_o        : out std_logic_vector(31 downto 0);
            DMem_writeEnable_o : out std_logic
        );
    end component;

-------------------------------------------------------------------------------------------------------------------
    -- 2. Constantes e Sinais para o Teste
-------------------------------------------------------------------------------------------------------------------

    signal s_clk               : std_logic := '0';
    signal s_reset             : std_logic := '1';
    signal s_imem_addr         : std_logic_vector(31 downto 0) := (others => '0');
    signal s_imem_data         : std_logic_vector(31 downto 0) := (others => '0');
    signal s_dmem_addr         : std_logic_vector(31 downto 0) := (others => '0');
    signal s_dmem_data_read    : std_logic_vector(31 downto 0) := (others => '0');
    signal s_dmem_data_write   : std_logic_vector(31 downto 0) := (others => '0');
    signal s_dmem_write_enable : std_logic := '0';
    
    signal s_memory : t_mem_array := init_mem_from_hex(PROGRAM_PATH);       -- Memória de programa
    
    constant c_HALT_ADDR : std_logic_vector(31 downto 0) := x"10000008";    -- Endereço para HALT
    
    constant CLK_PERIOD : time := 10 ns;                                    -- Período clock em [ns]

begin
    
-------------------------------------------------------------------------------------------------------------------
    -- 3. Instanciação do Componente sob Teste (DUT)
-------------------------------------------------------------------------------------------------------------------

    DUT: entity work.processor_top port map (
        CLK_i              => s_clk,
        Reset_i            => s_reset,
        IMem_addr_o        => s_imem_addr,
        IMem_data_i        => s_imem_data,
        DMem_addr_o        => s_dmem_addr,
        DMem_data_i        => s_dmem_data_read,
        DMem_data_o        => s_dmem_data_write,
        DMem_writeEnable_o => s_dmem_write_enable
    );

-------------------------------------------------------------------------------------------------------------------
    -- 4. Processo de Estímulo e Verificação
-------------------------------------------------------------------------------------------------------------------

    -- Geração do sinal de clock principal para o processador
    s_clk <= not s_clk after CLK_PERIOD / 2;

    -- Processo para leitura de memória (barramentos IMEM e DMEM)
    MEMORY_READ_PROC: process(s_reset, s_imem_addr, s_dmem_addr)
    begin

        -- Se o processador está em reset, a memória retorna '0'
        if s_reset = '1' then
            s_imem_data      <= (others => '0');
            s_dmem_data_read <= (others => '0');

        -- Somente se o reset estiver inativo, fazemos a leitura real
        else

            s_imem_data      <= s_memory(to_integer(unsigned(s_imem_addr(11 downto 2))));
            s_dmem_data_read <= s_memory(to_integer(unsigned(s_dmem_addr(11 downto 2))));
        
        end if;

    end process MEMORY_READ_PROC;

    -- Processo para a escrita na memória (barramento DMEM)
    MEM_WRITE_PROC: process(s_clk)
    begin

        if rising_edge(s_clk) then

            if s_dmem_write_enable = '1' then

                s_memory(to_integer(unsigned(s_dmem_addr(11 downto 2)))) <= s_dmem_data_write;
           
                end if;
        end if;

    end process MEM_WRITE_PROC;

    -- Processo que escuta os endereços e gera um TERMINAL (MMIO - Memory Mapped IO)
    TERMINAL_OUTPUT: process(s_clk)
        -- Endereços dos dispositivos de saída virtuais
        constant c_CONSOLE_ADDR : std_logic_vector(31 downto 0) := x"10000000";
        constant c_INTEGER_ADDR : std_logic_vector(31 downto 0) := x"10000004";

        -- Todas as variáveis devem ser declaradas aqui, antes do 'begin'.
        variable line_buffer : line := new string'(""); -- Buffer de saída
        variable L_temp      : line;                   -- Linha temporária para impressão
        variable current_char: character;

    begin
        if rising_edge(s_clk) then
            -- Verifica se o processador está tentando escrever na memória...
            if s_dmem_write_enable = '1' then
                
                -- Caso 1: Escrita no console de CARACTERES
                if s_dmem_addr = c_CONSOLE_ADDR then
                    -- Converte o byte recebido para um tipo 'character'
                    current_char := character'val(to_integer(unsigned(s_dmem_data_write(7 downto 0))));
                    
                    -- DEBUG CHARS
                    -- report "CHAR code: " & integer'image(to_integer(unsigned(s_dmem_data_write(7 downto 0))));
                    
                    -- Se o caractere for uma quebra de linha (LF - Line Feed, ou '\n')...
                    if current_char = LF then
                        -- Adiciona o LF ao buffer antes de imprimir
                        write(line_buffer, current_char);
                        -- Imprime a linha completa no console
                        write(L_temp, string'("CONSOLE: "));
                        write(L_temp, line_buffer.all);
                        writeline(output, L_temp);
                        -- Libera e recria o buffer
                        deallocate(line_buffer);
                        line_buffer := new string'("");
                    else
                        -- Caso contrário, apenas adicionamos o caractere ao final do buffer.
                        write(line_buffer, current_char);
                    end if;

                -- Caso 2: Escrita no console de INTEIROS
                elsif s_dmem_addr = c_INTEGER_ADDR then
                    write(L_temp, string'("INTEGER: "));
                    write(L_temp, to_integer(signed(s_dmem_data_write)));
                    writeline(output, L_temp);
                end if;
            end if;
        end if;
    end process TERMINAL_OUTPUT;

    -- Estímulo (define a execução do testbench)
    stimulus_proc: process is

        variable L : line;

    begin

        -- Mensagem inicial da simulação
        writeline(output, L);
        write(L, string'("INICIANDO SIMULACAO DO PROCESSADOR COMPLETO..."));
        writeline(output, L);
        writeline(output, L);
        wait for CLK_PERIOD * 2;
        s_reset <= '0';

        -- Aguarda o programa escrever no endereço de MMIO de parada.
        wait until (s_dmem_write_enable = '1' and s_dmem_addr = c_HALT_ADDR);

        -- Para a sincronização entre os processos
        wait for 5*CLK_PERIOD;

        -- Mensagem de conclusão da simulação
        writeline(output, L);
        write(L, string'("SIMULACAO CONCLUIDA. Programa finalizado por sinal de HALT."));
        writeline(output, L);
        writeline(output, L);

        std.env.stop;
        wait;
        
    end process stimulus_proc;

end architecture test;

-------------------------------------------------------------------------------------------------------------------