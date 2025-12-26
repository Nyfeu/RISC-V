-- ===============================================================================================================================================
--
-- File: lsu.vhd
--
-- ██╗     ███████╗██╗   ██╗
-- ██║     ██╔════╝██║   ██║
-- ██║     ███████╗██║   ██║
-- ██║     ╚════██║██║   ██║
-- ███████╗███████║╚██████╔╝
-- ╚══════╝╚══════╝ ╚═════╝ 
--
-- Descrição: Load Store Unit (Unidade de Carga e Armazenamento).
--      Centraliza o acesso à memória de dados, encapsulando as lógicas
--      de Load (leitura formatada) e Store (escrita formatada/parcial).
--
-- Autor     : [André Maiolini]
-- Data      : [26/12/2025]
--
-- ============+=================================================================================================================================

library ieee;                     -- Biblioteca padrão IEEE
use ieee.std_logic_1164.all;      -- Tipos lógicos (std_logic, std_logic_vector)
use ieee.numeric_std.all;         -- Biblioteca para operações aritméticas com vetores lógicos (signed, unsigned)

-------------------------------------------------------------------------------------------------------------------
-- ENTIDADE: Definição da interface da LOAD-STORE UNIT
-------------------------------------------------------------------------------------------------------------------

entity lsu is
    port (

        -----------------------------------------------------------------------
        -- Interface com o Core (Datapath/Control)
        -----------------------------------------------------------------------
        Addr_i        : in  std_logic_vector(31 downto 0); -- Endereço calculado pela ALU
        WriteData_i   : in  std_logic_vector(31 downto 0); -- Dado para escrita (vem de rs2)
        MemWrite_i    : in  std_logic;                     -- Sinal de controle de escrita (WE)
        Funct3_i      : in  std_logic_vector(2 downto 0);  -- Define o tamanho (Byte, Half, Word) e extensão (Signed/Unsigned)

        -----------------------------------------------------------------------
        -- Interface com a Memória RAM (DMem)
        -----------------------------------------------------------------------
        -- A RAM recebe o endereço diretamente
        DMem_addr_o   : out std_logic_vector(31 downto 0);
        
        -- A RAM fornece o dado lido (necessário tanto para Loads quanto para RMW - Read-Modify-Write - dos Stores)
        DMem_data_i   : in  std_logic_vector(31 downto 0);
        
        -- A LSU entrega o dado formatado para ser escrito na RAM
        DMem_data_o   : out std_logic_vector(31 downto 0);
        
        -- Sinal de habilitação de escrita repassado
        DMem_we_o     : out std_logic;

        -----------------------------------------------------------------------
        -- Saída para o Datapath (Write Back)
        -----------------------------------------------------------------------
        LoadData_o    : out std_logic_vector(31 downto 0)  -- Dado lido da memória e formatado (Sign/Zero extended)

    );
end entity lsu;

-------------------------------------------------------------------------------------------------------------------
-- ARQUITETURA:Implementação da arquitetura da LOAD-STORE UNIT
-------------------------------------------------------------------------------------------------------------------

architecture rtl of lsu is
    
    -- Sinal auxiliar para os bits menos significativos do endereço
    signal s_addr_lsb : std_logic_vector(1 downto 0);

begin

    -- 1. Conexões Diretas
    -- O endereço vai direto para a memória
    DMem_addr_o <= Addr_i;
    
    -- O sinal de escrita vai direto para a memória
    DMem_we_o   <= MemWrite_i;

    -- Extrai os 2 LSBs do endereço para definir alinhamento de Byte/Half
    s_addr_lsb  <= Addr_i(1 downto 0);

    -- 2. Instanciação da Unidade de Load
    -- Responsável por ler DMem_data_i e formatar (estender sinal/zero) para o registrador
    U_LOAD_UNIT: entity work.load_unit 
        port map (
            DMem_data_i => DMem_data_i,
            Addr_LSB_i  => s_addr_lsb,
            Funct3_i    => Funct3_i,
            Data_o      => LoadData_o        -- Vai para o Mux de Write-Back
        );

    -- 3. Instanciação da Unidade de Store
    -- Responsável por pegar o WriteData_i e fundir com DMem_data_i (Read-Modify-Write)
    -- para preservar bytes vizinhos em escritas de Byte/Half

    U_STORE_UNIT: entity work.store_unit 
        port map (
            Data_from_DMEM_i => DMem_data_i, -- Lê o valor atual para preservar bytes não escritos
            WriteData_i      => WriteData_i, -- Dado novo (rs2)
            Addr_LSB_i       => s_addr_lsb,
            Funct3_i         => Funct3_i,
            Data_o           => DMem_data_o  -- Dado final combinado para a RAM
        );

end architecture rtl;

-------------------------------------------------------------------------------------------------------------------