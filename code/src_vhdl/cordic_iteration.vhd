library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cordic_pkg.all;

entity cordic_iteration is
    port (
        re_i  : in  std_logic_vector(DATASIZE - 1 downto 0);   
        im_i  : in  std_logic_vector(DATASIZE - 1 downto 0);    
        phi_i : in  std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0);
        re_o  : out std_logic_vector(DATASIZE - 1 downto 0);    
        im_o  : out std_logic_vector(DATASIZE - 1 downto 0);     
        phi_o : out std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0);
        iter_i : in std_logic_vector(3 downto 0)
    );
end cordic_iteration;

architecture cordic_iteration of cordic_iteration is
begin

    process(all)
        variable re_v  : unsigned(re_i'range);   
        variable im_v  : unsigned(im_i'range);    
        variable phi_v : unsigned(phi_i'range);
        variable iter_v : unsigned(iter_i'range);
        variable negative_v : std_logic;
    begin
        re_v :=  unsigned(re_i);
        im_v :=  unsigned(im_i);
        phi_v := unsigned(phi_i);
        iter_v := unsigned(iter_i);
        negative_v :=  phi_v(phi_i'high);
        

        if negative_v = '1' then
            re_v := re_v - im_v;
            -- take the previous value so re_i instead of re_v
            im_v := im_v + unsigned(re_i) ;
            phi_v := phi_v - unsigned(alpha_values_c(to_integer(iter_v)));
        else
            re_v := re_v + im_v;
            -- take the previous value so re_i instead of re_v
            im_v := im_v - unsigned(re_i);
            phi_v := phi_v + unsigned(alpha_values_c(to_integer(iter_v)));
        end if;

        -- shift
        re_v := shift_left(re_v, to_integer(iter_v));
        im_v   := shift_left(im_v, to_integer(iter_v));

        re_o  <= std_logic_vector(re_v);
        im_o  <= std_logic_vector(im_v);
        phi_o  <= std_logic_vector(phi_v);
    end process;
end cordic_iteration;
