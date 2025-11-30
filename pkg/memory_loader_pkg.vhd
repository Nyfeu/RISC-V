------------------------------------------------------------------------------------------------------------------
-- 
-- File: memory_loader_pkg.vhd
--   
--   ███╗   ███╗███████╗███╗   ███╗        ██╗      ██████╗  █████╗ ██████╗ ███████╗██████╗ 
--   ████╗ ████║██╔════╝████╗ ████║        ██║     ██╔═══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗
--   ██╔████╔██║█████╗  ██╔████╔██║        ██║     ██║   ██║███████║██║  ██║█████╗  ██████╔╝
--   ██║╚██╔╝██║██╔══╝  ██║╚██╔╝██║        ██║     ██║   ██║██╔══██║██║  ██║██╔══╝  ██╔══██╗
--   ██║ ╚═╝ ██║███████╗██║ ╚═╝ ██║███████╗███████╗╚██████╔╝██║  ██║██████╔╝███████╗██║  ██║
--   ╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝                                                                                     
--                                                                                                                                                                                                                                                          
-- 
-- Descrição : Pacote VHDL dedicado ao carregamento de arquivos .hex na memória
--             de instruções (IMEM) da simulação executada pelo processor_top_tb
--             (testbench) de maneira dinâmica.
--
-- Autor     : [André Maiolini]
-- Data      : [15/09/2025]
--
-------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use std.env.all;

------------------------------------------------------------------------------------------------------------------
-- PACOTE: Definição do pacote (interface pública)
-------------------------------------------------------------------------------------------------------------------

package memory_loader_pkg is
    -- Aumentado para 4096 palavras = 16KB de memória total
    type t_mem_array is array (0 to 4095) of std_logic_vector(31 downto 0); 
    impure function init_mem_from_hex(file_path : string) return t_mem_array;
end package memory_loader_pkg;

------------------------------------------------------------------------------------------------------------------
-- CORPO: Definição do corpo do pacote (implementação da função)
-------------------------------------------------------------------------------------------------------------------

package body memory_loader_pkg is

    impure function init_mem_from_hex(file_path : string) return t_mem_array is
        file hex_file       : text open read_mode is file_path;
        variable file_line  : line;
        variable mem        : t_mem_array := (others => (others => '0'));
        variable mem_idx    : integer := 0;
        variable byte_val   : std_logic_vector(7 downto 0);
        variable word_val   : std_logic_vector(31 downto 0) := (others => '0'); -- Importante iniciar com 0
        variable byte_count : integer := 0;
        variable C          : character;
        variable addr_hex   : std_logic_vector(31 downto 0);
    begin

        report "Lendo arquivo de programa: " & file_path severity note;

        while not endfile(hex_file) loop
            readline(hex_file, file_line);

            -- Verifica se a linha não está vazia
            if file_line'length > 0 then
                
                -- Checa se é uma linha de endereço (inicia com @)
                if file_line(file_line'low) = '@' then
                    -- 1. Se havia bytes pendentes da seção anterior, escreve na memória antes de pular
                    if byte_count > 0 then
                        mem(mem_idx) := word_val;
                        -- Não incrementamos mem_idx aqui pois vamos mudá-lo agora
                        byte_count := 0;
                        word_val := (others => '0'); -- Limpa para a próxima
                    end if;

                    -- 2. Lê o novo endereço
                    read(file_line, C); -- Descarta o '@'
                    hread(file_line, addr_hex);
                    
                    -- Converte endereço de bytes para índice de palavra (div 4)
                    mem_idx := to_integer(unsigned(addr_hex)) / 4;

                else
                    -- É uma linha de dados
                    while file_line'length > 0 and mem_idx < mem'length loop
                        -- Pula espaços e tabs
                        if file_line(file_line'low) = ' ' or file_line(file_line'low) = HT then
                            read(file_line, C);
                        else
                            -- Lê o byte
                            hread(file_line, byte_val);

                            -- Monta a palavra Little Endian
                            case byte_count is
                                when 0 => word_val(7 downto 0)   := byte_val;
                                when 1 => word_val(15 downto 8)  := byte_val;
                                when 2 => word_val(23 downto 16) := byte_val;
                                when 3 => word_val(31 downto 24) := byte_val;
                                when others => null;
                            end case;

                            byte_count := byte_count + 1;

                            -- Se completou 4 bytes, salva na memória
                            if byte_count = 4 then
                                mem(mem_idx) := word_val;
                                mem_idx := mem_idx + 1;
                                byte_count := 0;
                                word_val := (others => '0'); -- Limpa
                            end if;
                        end if;
                    end loop;
                end if;
            end if;
        end loop;

        -- CORREÇÃO PRINCIPAL:
        -- Se o arquivo acabou e sobraram bytes (ex: string de 15 bytes), salva a última palavra parcial.
        if byte_count > 0 then
            mem(mem_idx) := word_val;
        end if;

        report "Carregamento do programa concluido." severity note;
        return mem;
        
    end function;

end package body memory_loader_pkg;

-------------------------------------------------------------------------------------------------------------------