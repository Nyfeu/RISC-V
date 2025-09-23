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
        variable word_val   : std_logic_vector(31 downto 0);
        variable byte_count : integer := 0;
        variable C          : character;

    begin

        -- Mensagem inicial do processo de leitura do arquivo de programa (.hex)
        report "Lendo arquivo de programa: " & file_path severity note;

        -- Enquanto não for o fim do arquivo de programa
        while not endfile(hex_file) loop

            -- Lê uma linha completa do arquivo
            readline(hex_file, file_line);

            -- Testa o primeiro caractere real da linha
            if file_line'length > 0 and file_line(file_line'low) /= '@' then

                -- Processa a linha inteira
                while file_line'length > 0 and mem_idx < mem'length loop

                    -- Verifica se próximo caractere é espaço/tab
                    if file_line(file_line'low) = ' ' or file_line(file_line'low) = HT then
                        read(file_line, C);

                    -- Caso contrário, lê um byte em hexadecimal
                    else
                        hread(file_line, byte_val);

                        case byte_count is
                            when 0 => word_val(7 downto 0)   := byte_val;
                            when 1 => word_val(15 downto 8)  := byte_val;
                            when 2 => word_val(23 downto 16) := byte_val;
                            when 3 => word_val(31 downto 24) := byte_val;
                            when others => null;
                        end case;

                        byte_count := byte_count + 1;

                        -- A cada 4 bytes formamos uma palavra
                        if byte_count = 4 then
                            mem(mem_idx) := word_val;
                            mem_idx := mem_idx + 1;
                            byte_count := 0;
                        end if;

                    end if;

                end loop;

            end if;

        end loop;

        -- Mensagem sinalizando a finalização do carregamento do programa na memória
        report "Carregamento do programa na memoria de simulacao concluida. "
            & integer'image(mem_idx) & " palavras lidas."
            severity note;

        return mem;
        
    end function;

end package body memory_loader_pkg;

-------------------------------------------------------------------------------------------------------------------