--------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
--------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
--------------------------------------------------------------------------------
--
-- File     : cordic_post_treatment.vhd
-- Author   : André Costa
-- Date     : 16.04.2025
--
-- Context  : SCF lab 08
--
--------------------------------------------------------------------------------
-- Description :  CORDIC Post Treatement Entity
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

entity cordic_post_treatment is
    port (
        -- input data in the cartesian form
        re_i                    : in  std_logic_vector(DATASIZE - 1 downto 0);
        im_i                    : in  std_logic_vector(DATASIZE - 1 downto 0);
        original_quadrant_id_i  : in std_logic_vector(1 downto 0);
        signals_exchanged_i     : in std_logic;
        phi_i                   : in std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0);

        amp_o       : out std_logic_vector(AMP_OUTPUTSIZE - 1 downto 0);
        phi_o       : out std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0)
    );
end cordic_post_treatment;

architecture comb of cordic_post_treatment is

begin

    process(all) 
        variable phi_v        : signed(phi_i'range);
        variable pidiv2_v     : signed(phi_i'range);
        variable pidiv1_v     : signed(phi_i'range);
    begin
        phi_v := signed(phi_i);
        
        -- Convertir les constantes en signed de la bonne taille
        pidiv2_v := signed(std_logic_vector(pidiv2_c));
        pidiv1_v := signed(std_logic_vector(pidiv1_c));

        -- Si les coordonnées re et im ont été échangées à l'étape 1,
        -- appliquer la correction phi = PI/2 − phi. Sinon laisser l'angle tel quel
        if signals_exchanged_i = '1' then
            phi_v := pidiv2_v - phi_v;
        end if;

        -- Projection sur les quatre quadrants
        --  — Premier quadrant : phi = phi
        --  — Deuxième quadrant : phi = PI − phi
        --  — Troisième quadrant : phi = phi + PI
        --  — Quatrième quadrant : phi = −phi
        -- original_quadrant_id_i(1) -> re MSb  (signe de re)
        -- original_quadrant_id_i(0) -> im MSb  (signe de im)
        case original_quadrant_id_i is
            -- Premier quadrant : re positif, im positif
            when "00" => null; -- phi = phi
            -- Deuxième quadrant : re négatif, im positif  
            when "10" => phi_v := pidiv1_v - phi_v;
            -- Troisième quadrant : re négatif, im négatif
            when "11" => phi_v := pidiv1_v + phi_v;
            -- Quatrième quadrant : re positif, im négatif
            when "01" => phi_v := -phi_v;
            -- Couvrir tous les cas possibles même si théoriquement on ne devrait pas y arriver
            when others => null;
        end case;
        
        phi_o <= std_logic_vector(phi_v);
    end process;
    
    -- L'amplitude est simplement la valeur réelle à la sortie de la dernière itération
    amp_o <= re_i;

end comb;