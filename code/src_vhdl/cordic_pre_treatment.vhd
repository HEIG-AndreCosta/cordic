--------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
--------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
--------------------------------------------------------------------------------
--
-- File     : cordic_pre_treatment.vhd
-- Author   : André Costa
-- Date     : 16.04.2025
--
-- Context  : SCF lab 08
--
--------------------------------------------------------------------------------
-- Description :  CORDIC Pre Treatement Entity
--------------------------------------------------------------------------------
-- Dependencies : -
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver    Date        Engineer    Comments
-- 0.1    See header  André Costa Initial version
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.cordic_pkg.all;

entity cordic_pre_treatment is
    port (
        -- input data in the cartesian form
        re_i                    : in  std_logic_vector(DATASIZE - 1 downto 0);
        im_i                    : in  std_logic_vector(DATASIZE - 1 downto 0);
        re_o                    : out  std_logic_vector(DATASIZE - 1 downto 0);
        im_o                    : out  std_logic_vector(DATASIZE - 1 downto 0);
        original_quadrant_id_o  : out std_logic_vector(1 downto 0);
        signals_exchanged_o     : out std_logic
    );
end cordic_pre_treatment;

architecture comb of cordic_pre_treatment is

begin

    process(all) 
        variable re_v : signed(re_i'range);
        variable tmp_v : signed(re_i'range);
        variable im_v : signed(im_i'range);
        variable signals_exchanged_v : std_logic;
        variable original_quadrant_id_v : std_logic_vector(1 downto 0);
    begin
        re_v := signed(re_i);
        im_v := signed(im_i);
        tmp_v := (others => '0');
        signals_exchanged_v := '0';

        -- original_quadrant_id_v(1) -> re MSb
        -- original_quadrant_id_v(0) -> im MSb
        original_quadrant_id_v := re_v(DATASIZE - 1) & im_v(DATASIZE - 1);
        
        -- Calcul de la valeur absolue de re et im.
        -- Ceci projette les coordonnées dans le premier quadrant.
        if original_quadrant_id_v(1) = '1' then
            re_v := not re_v;
            re_v := re_v + 1;
        end if;
        if original_quadrant_id_v(0) = '1' then
            im_v := not im_v;
            im_v := im_v + 1;
        end if;

        -- Comparaison entre re et im. Si im > re alors leurs valeurs sont échangées. Ceci projette
        -- les coordonnées dans le premier octant.
        if im_v > re_v then
            tmp_v := re_v;
            re_v := im_v;
            im_v := tmp_v;
            signals_exchanged_v := '1';
        end if;

        re_o <= std_logic_vector(re_v);
        im_o <= std_logic_vector(im_v);
        original_quadrant_id_o  <=  original_quadrant_id_v;
        signals_exchanged_o    <= signals_exchanged_v;

    end process;

end comb;

