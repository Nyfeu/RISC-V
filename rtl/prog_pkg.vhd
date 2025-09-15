-- rtl/prog_pkg.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package prog_pkg is

    -- define o tipo do array de memória
    type t_mem_array is array (0 to 1023) of std_logic_vector(31 downto 0);

    -- programa de teste
    constant prog_mem : t_mem_array := (
        0 => x"02A00513",  -- addi a0, zero, 42
        1 => x"0000006F",  -- jal zero, 0 (loop infinito)
        others => (others => '0')
    );

end package prog_pkg;
