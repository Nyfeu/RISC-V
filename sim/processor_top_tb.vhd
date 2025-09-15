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
    
    signal s_memory : t_mem_array := init_mem_from_hex(PROGRAM_PATH);
    
    constant c_HALT_ADDR : std_logic_vector(31 downto 0) := x"10000008";
    constant CLK_PERIOD : time := 10 ns;

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

    -- Processo que escuta o endereço de CHAR_OUTPUT (MMIO - Memory Mapped IO)
    CONSOLE_OUTPUT: process(s_clk)

        -- Endereço do dispositivo de saída virtual
        constant c_CONSOLE_ADDR : std_logic_vector(31 downto 0) := x"10000000";
        variable L : line;

    begin

        if rising_edge(s_clk) then

            -- Verifica se o processador está tentando escrever na memória
            -- e se o endereço corresponde ao console.

            if s_dmem_write_enable = '1' and s_dmem_addr = c_CONSOLE_ADDR then

                -- Pega os 8 bits menos significativos do dado e os imprime como um caractere.
                -- A função character'val() converte o valor inteiro do byte para um caractere.

                -- Escreve um caractere no console
                write(L, string'("CONSOLE: "));
                write(L, character'val(to_integer(unsigned(s_dmem_data_write(7 downto 0)))));
                writeline(output, L);

            end if;

        end if;

    end process CONSOLE_OUTPUT;

    -- Processo que escuta o endereço de INT_OUTPUT (MMIO - Memory Mapped IO)
    INTEGER_OUTPUT: process(s_clk)

        -- Endereço para dispositivo de saída de inteiros
        constant c_INTEGER_ADDR : std_logic_vector(31 downto 0) := x"10000004";
        variable L : line;

    begin

        if rising_edge(s_clk) then

            -- Verifica se o processador está escrevendo no endereço do console de inteiros
            if s_dmem_write_enable = '1' and s_dmem_addr = c_INTEGER_ADDR then

                -- Usa a função 'to_integer' para converter o dado de 32 bits em um inteiro
                -- e 'integer'image' para formatá-lo como string para impressão.
                write(L, string'("INTEGER: "));
                write(L, to_integer(signed(s_dmem_data_write)));
                writeline(output, L);
                
            end if;

        end if;

    end process INTEGER_OUTPUT;

    -- Estímulo (define a execução do testbench)
    stimulus_proc: process is

        variable L : line;

    begin

        writeline(output, L);
        write(L, string'("INICIANDO SIMULACAO DO PROCESSADOR COMPLETO..."));
        writeline(output, L);
        writeline(output, L);
        wait for CLK_PERIOD * 2;
        s_reset <= '0';

        -- Aguarda o programa escrever no endereço de MMIO de parada.
        wait until (s_dmem_write_enable = '1' and s_dmem_addr = c_HALT_ADDR);

        writeline(output, L);
        write(L, string'("SIMULACAO CONCLUIDA. Programa finalizado por sinal de HALT."));
        writeline(output, L);
        writeline(output, L);
        std.env.stop;
        wait;
        
    end process stimulus_proc;

end architecture test;

-------------------------------------------------------------------------------------------------------------------