-------------------------------------------------------------------------------------------------------------------
--
-- File: reg_file_tb.vhd (Testbench para o Register File)
--
-- Descrição: Este testbench autoverificável aplica um conjunto de testes
--            usando a instrução ASSERT para validar automaticamente se 
--            os resultados estão corretos.
--
-------------------------------------------------------------------------------------------------------------------

-- Inclusão dos módulos necessários
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- A entidade de um testbench é sempre vazia.
entity reg_file_tb is
end entity reg_file_tb;

-- A arquitetura do testbench contém a instância do DUT e o processo de estímulo.
architecture test of reg_file_tb is

-------------------------------------------------------------------------------------------------------------------
    -- 1. Declaração do Componente sob Teste (DUT - Device Under Test)
-------------------------------------------------------------------------------------------------------------------

    component reg_file is

        port (

            clk_i        : in  std_logic;                             
            RegWrite_i   : in  std_logic;                             
            ReadAddr1_i  : in  std_logic_vector(4 downto 0);          
            ReadAddr2_i  : in  std_logic_vector(4 downto 0);           
            WriteAddr_i  : in  std_logic_vector(4 downto 0);           
            WriteData_i  : in  std_logic_vector(31 downto 0);         
            ReadData1_o  : out std_logic_vector(31 downto 0);         
            ReadData2_o  : out std_logic_vector(31 downto 0)   

        );

    end component reg_file;

-------------------------------------------------------------------------------------------------------------------
    -- 2. Constantes e Sinais para o Teste
-------------------------------------------------------------------------------------------------------------------

    signal s_clk        : std_logic := '0';
    signal s_reg_write  : std_logic := '0';
    signal s_read_addr1 : std_logic_vector(4 downto 0) := (others => '0');
    signal s_read_addr2 : std_logic_vector(4 downto 0) := (others => '0');
    signal s_write_addr : std_logic_vector(4 downto 0) := (others => '0');
    signal s_write_data : std_logic_vector(31 downto 0) := (others => '0');
    signal s_read_data1 : std_logic_vector(31 downto 0);
    signal s_read_data2 : std_logic_vector(31 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

-------------------------------------------------------------------------------------------------------------------
    -- 3. Instanciação do Componente sob Teste (DUT)
-------------------------------------------------------------------------------------------------------------------

    dut: entity work.reg_file
        port map (
            clk_i        => s_clk,
            RegWrite_i   => s_reg_write,
            ReadAddr1_i  => s_read_addr1,
            ReadAddr2_i  => s_read_addr2,
            WriteAddr_i  => s_write_addr,
            WriteData_i  => s_write_data,
            ReadData1_o  => s_read_data1,
            ReadData2_o  => s_read_data2
        );

-------------------------------------------------------------------------------------------------------------------
    -- 4. Geração de Clock
-------------------------------------------------------------------------------------------------------------------

    s_clk <= not s_clk after CLK_PERIOD / 2;

-------------------------------------------------------------------------------------------------------------------
    -- 5. Processo de Estímulo e Verificação Automática
-------------------------------------------------------------------------------------------------------------------

    STIMULUS: process
    begin

        report "INICIANDO VERIFICACAO DO BANCO DE REGISTRADORES..." severity note;

        -- Teste 1: Escrever no registrador x5 e ler de volta
        report "TESTE 1: Escrever 42 em x5..." severity note;
        s_reg_write  <= '1';
        s_write_addr <= "00101"; -- x5
        s_write_data <= std_logic_vector(to_unsigned(42, 32));
        wait until rising_edge(s_clk); -- Espera a escrita acontecer
        
        s_reg_write <= '0'; -- Desabilita a escrita
        s_read_addr1 <= "00101"; -- Lê x5
        wait for 1 ns; -- Espera a leitura combinacional propagar
        ASSERT s_read_data1 = std_logic_vector(to_unsigned(42, 32)) REPORT "ERRO [Teste 1]: Leitura de x5 falhou!" SEVERITY error;

        -- Teste 2: Tentar escrever no x0 e verificar
        report "TESTE 2: Tentar escrever 99 em x0..." severity note;
        s_reg_write  <= '1';
        s_write_addr <= "00000"; -- x0
        s_write_data <= std_logic_vector(to_unsigned(99, 32));
        wait until rising_edge(s_clk);
        
        s_reg_write <= '0';
        s_read_addr1 <= "00000"; -- Lê x0
        wait for 1 ns;
        ASSERT s_read_data1 = x"00000000" REPORT "ERRO [Teste 2]: Leitura de x0 retornou valor nao-zero!" SEVERITY error;

        -- Teste 3: Leitura de duas portas simultaneamente
        report "TESTE 3: Escrever -1 em x10 e ler x5 e x10..." severity note;
        s_reg_write  <= '1';
        s_write_addr <= "01010"; -- x10
        s_write_data <= std_logic_vector(to_signed(-1, 32));
        wait until rising_edge(s_clk);

        s_reg_write <= '0';
        s_read_addr1 <= "00101"; -- Lê x5 (ainda deve ter 42)
        s_read_addr2 <= "01010"; -- Lê x10 (deve ter -1)
        wait for 1 ns;
        ASSERT s_read_data1 = std_logic_vector(to_unsigned(42, 32)) REPORT "ERRO [Teste 3a]: Leitura de x5 mudou de valor!" SEVERITY error;
        ASSERT s_read_data2 = std_logic_vector(to_signed(-1, 32))   REPORT "ERRO [Teste 3b]: Leitura de x10 falhou!" SEVERITY error;


        -- Teste 4: Leitura e Escrita Simultânea (Read-Before-Write) ---
        report "TESTE 4: Escrever 99 em x7 e ler x7 no mesmo ciclo..." severity note;
        s_reg_write  <= '1';
        s_write_addr <= "00111"; -- x7
        s_write_data <= std_logic_vector(to_unsigned(99, 32));
        s_read_addr1 <= "00111"; -- Lendo x7
        -- O valor inicial de x7 é 0. A leitura é combinacional, então deve ler 0 durante este ciclo.
        wait for 1 ns;
        ASSERT s_read_data1 = x"00000000" REPORT "ERRO [Teste 4a]: Leitura durante a escrita retornou o valor novo!" SEVERITY error;
        
        wait until rising_edge(s_clk); -- A escrita de 99 acontece aqui.
        
        -- Agora, no ciclo SEGUINTE, a leitura de x7 deve retornar 99.
        s_reg_write <= '0';
        wait for 1 ns;
        ASSERT s_read_data1 = std_logic_vector(to_unsigned(99, 32)) REPORT "ERRO [Teste 4b]: Leitura apos a escrita falhou!" SEVERITY error;
        
        -- Teste 5: Teste da Habilitação de Escrita (RegWrite = '0') ---
        report "TESTE 5: Tentar escrever 123 em x8 com RegWrite='0'..." severity note;
        s_write_addr <= "01000"; -- x8
        s_write_data <= std_logic_vector(to_unsigned(123, 32));
        s_reg_write  <= '0'; -- <<<< ESCRITA DESABILITADA
        wait until rising_edge(s_clk); -- Tenta escrever

        -- A leitura de x8 deve retornar o valor antigo (0), não 123.
        s_read_addr1 <= "01000";
        wait for 1 ns;
        ASSERT s_read_data1 = x"00000000" REPORT "ERRO [Teste 5]: Escrita ocorreu com RegWrite desabilitado!" SEVERITY error;

        -- Teste 6: Verificação da Leitura Assíncrona ---
        report "TESTE 6: Mudar endereço de leitura no meio do ciclo..." severity note;
        -- Sabemos que x5=42 e x10=-1. Vamos alternar a leitura entre eles sem esperar o clock.
        s_read_addr1 <= "00101"; -- Lendo x5
        wait for 2 ns;
        ASSERT s_read_data1 = std_logic_vector(to_unsigned(42, 32)) REPORT "ERRO [Teste 6a]: Leitura assincrona de x5 falhou!" SEVERITY error;
        
        s_read_addr1 <= "01010"; -- Lendo x10
        wait for 2 ns;
        ASSERT s_read_data1 = std_logic_vector(to_signed(-1, 32))   REPORT "ERRO [Teste 6b]: Leitura assincrona de x10 falhou!" SEVERITY error;
        
        -- Mensagem final indicando que todos os testes finalizaram
        report "VERIFICACAO DO BANCO DE REGISTRADORES CONCLUIDA!" severity note;

        -- Para a simulação para não rodar para sempre.
        std.env.stop;

    end process STIMULUS;

end architecture test;

-------------------------------------------------------------------------------------------------------------------