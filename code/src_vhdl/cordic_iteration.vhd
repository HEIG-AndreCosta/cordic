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
        variable re_v  : signed(re_i'range);   
        variable im_v  : signed(im_i'range);    
        variable re_shift_v  : signed(re_i'range);   
        variable im_shift_v  : signed(im_i'range); 
        variable phi_v : signed(phi_i'range);
        variable iter_v : unsigned(iter_i'range);
        variable negative_v : std_logic;
    begin
        re_v :=  signed(re_i);
        im_v :=  signed(im_i);
        re_shift_v := to_signed(0, re_i'length);
        im_shift_v := to_signed(0, im_i'length);
        phi_v := signed(phi_i);
        iter_v := unsigned(iter_i);
        negative_v :=  im_v(im_i'high);

        -- Handle the case in simulation where iter_v is undefined and thus 0 when converted to integer
        if to_integer(iter_v) = 0 then
            iter_v := to_unsigned(1, iter_v'length);
        end if;
        
        -- shift
        re_shift_v := shift_right(re_v, to_integer(iter_v));
        im_shift_v := shift_right(im_v, to_integer(iter_v));

        if negative_v = '1' then
            re_v := re_v - im_shift_v;
            im_v := im_v + re_shift_v;
            phi_v := phi_v - signed(alpha_values_c(to_integer(iter_v)));
        else
            re_v := re_v + im_shift_v;
            im_v := im_v - re_shift_v;
            phi_v := phi_v + signed(alpha_values_c(to_integer(iter_v)));
        end if;

        re_o  <= std_logic_vector(re_v);
        im_o  <= std_logic_vector(im_v);
        phi_o  <= std_logic_vector(phi_v);
    end process;
end cordic_iteration;
