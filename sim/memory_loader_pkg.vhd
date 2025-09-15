-- sim/memory_loader_pkg.vhd
-- Pacote VHDL dedicado para carregar arquivos .hex na memória da simulação.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use std.env.all;

-- ================================================================= --
-- >> PARTE 1: DECLARAÇÃO DO PACOTE (O que estava faltando) <<
-- ================================================================= --
-- Isto define a "interface pública" do pacote.
package memory_loader_pkg is
    type t_mem_array is array (0 to 1023) of std_logic_vector(31 downto 0);
    impure function init_mem_from_hex(file_path : string) return t_mem_array;
end package memory_loader_pkg;


-- ================================================================= --
-- >> PARTE 2: CORPO DO PACOTE (A implementação da função) <<
-- ================================================================= --
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
        report "Lendo arquivo de programa: " & file_path severity note;

        while not endfile(hex_file) loop
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

        report "Carga do programa na memoria de simulacao concluida. "
            & integer'image(mem_idx) & " palavras lidas."
            severity note;

        return mem;
    end function;

end package body memory_loader_pkg;