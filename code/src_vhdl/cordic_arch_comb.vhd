--------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
--------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
--------------------------------------------------------------------------------
--
-- File     : cordic_arch_comb.vhd
-- Author   : Yann Thoma
-- Date     : 10.04.2025
--
-- Context  : SCF lab 08
--
--------------------------------------------------------------------------------
-- Description :  Fully combinatorial CORDIC architecture
--------------------------------------------------------------------------------
-- Dependencies : - 
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver    Date        Engineer    Comments
-- 0.1    See header  YTA         Initial version
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cordic_pkg.all;

architecture comb of cordic is
    --------------------------
    --- Signal declaration ---
    --------------------------
    -- Signaux pour l'étape 1: réduction au premier octant
    signal abs_re, abs_im : unsigned(DATASIZE-1 downto 0);
    signal quadrant       : unsigned(1 downto 0);
    signal echanges       : std_logic;
    
    -- Signaux pour les itérations CORDIC (entrées/sorties de chaque étage)
    type re_im_array_t is array (0 to N_ITER) of signed(INTERNAL_DATASIZE-1 downto 0);
    type phi_array_t is array (0 to N_ITER) of unsigned(INTERNAL_ANGLESIZE-1 downto 0);
    
    signal re_stages  : re_im_array_t;
    signal im_stages  : re_im_array_t;
    signal phi_stages : phi_array_t;
    
    -- Signaux pour l'étape 3: projection de l'angle sur les 4 quadrants
    signal phi_final  : unsigned(INTERNAL_ANGLESIZE-1 downto 0);
    signal amp_final  : unsigned(INTERNAL_DATASIZE-1 downto 0);
    
    -- Signaux de contrôle
    signal do_calculation : std_logic;

begin
    -- Logique de contrôle du flux de données
    do_calculation <= valid_i and ready_i;
    ready_o <= ready_i;
    valid_o <= valid_i;
    
    -- Étape 1: Réduction des coordonnées au premier octant
    process(re_i, im_i)
    begin
        -- Détermination du quadrant en fonction des signes de re_i et im_i
        if re_i(DATASIZE-1) = '0' and im_i(DATASIZE-1) = '0' then
            -- Premier quadrant
            quadrant <= "00";
        elsif re_i(DATASIZE-1) = '1' and im_i(DATASIZE-1) = '0' then
            -- Deuxième quadrant
            quadrant <= "01";
        elsif re_i(DATASIZE-1) = '1' and im_i(DATASIZE-1) = '1' then
            -- Troisième quadrant
            quadrant <= "10";
        else
            -- Quatrième quadrant
            quadrant <= "11";
        end if;
        
        -- Calcul des valeurs absolues
        if re_i(DATASIZE-1) = '1' then
            abs_re <= unsigned(not(signed(re_i)) + 1);
        else
            abs_re <= unsigned(re_i);
        end if;
        
        if im_i(DATASIZE-1) = '1' then
            abs_im <= unsigned(not(signed(im_i)) + 1);
        else
            abs_im <= unsigned(im_i);
        end if;
    end process;
    
    -- Comparaison re et im pour projection dans le premier octant
    echanges <= '1' when abs_re < abs_im else '0';
    
    -- Initialisation des valeurs pour la première itération CORDIC
    process(abs_re, abs_im, echanges)
    begin
        -- Échange des valeurs si nécessaire pour projection dans le premier octant
        if echanges = '1' then
            re_stages(0) <= signed('0' & abs_im);
            im_stages(0) <= signed('0' & abs_re);
        else
            re_stages(0) <= signed('0' & abs_re);
            im_stages(0) <= signed('0' & abs_im);
        end if;
        
        -- Initialisation de l'angle phi
        phi_stages(0) <= (others => '0');
    end process;
    
    -- Étape 2: Itérations CORDIC
    cordic_iterations: for i in 0 to N_ITER-1 generate
        process(re_stages(i), im_stages(i), phi_stages(i))
        begin
            if im_stages(i)(INTERNAL_DATASIZE-1) = '1' then
                -- Partie imaginaire négative
                re_stages(i+1) <= re_stages(i) - shift_right(im_stages(i), i+1);
                im_stages(i+1) <= im_stages(i) + shift_right(re_stages(i), i+1);
                phi_stages(i+1) <= phi_stages(i) - unsigned(alpha_values_c(i+1));
            else
                -- Partie imaginaire positive
                re_stages(i+1) <= re_stages(i) + shift_right(im_stages(i), i+1);
                im_stages(i+1) <= im_stages(i) - shift_right(re_stages(i), i+1);
                phi_stages(i+1) <= phi_stages(i) + unsigned(alpha_values_c(i+1));
            end if;
        end process;
    end generate;
    
    -- Étape 3: Projection de l'angle sur les 4 quadrants
    process(phi_stages(N_ITER), quadrant, echanges)
    begin
        -- 1. Projection sur le premier quadrant
        if echanges = '1' then
            -- Si échange a été effectué: phi = PI/2 - phi
            phi_final <= pidiv2_c - phi_stages(N_ITER);
        else
            phi_final <= phi_stages(N_ITER);
        end if;
    end process;
    
    -- 2. Projection sur les quatre quadrants en fonction du quadrant d'origine
    process(phi_final, quadrant)
    begin
        case quadrant is
            when "00" =>  -- Premier quadrant: phi = phi
                amp_o <= std_logic_vector(re_stages(N_ITER)(AMP_OUTPUTSIZE-1 downto 0));
                phi_o <= std_logic_vector(phi_final(PHI_OUTPUTSIZE-1 downto 0));
            when "01" =>  -- Deuxième quadrant: phi = PI - phi
                amp_o <= std_logic_vector(re_stages(N_ITER)(AMP_OUTPUTSIZE-1 downto 0));
                phi_o <= std_logic_vector((pidiv1_c - phi_final)(PHI_OUTPUTSIZE-1 downto 0));
            when "10" =>  -- Troisième quadrant: phi = phi + PI
                amp_o <= std_logic_vector(re_stages(N_ITER)(AMP_OUTPUTSIZE-1 downto 0));
                phi_o <= std_logic_vector((phi_final + pidiv1_c)(PHI_OUTPUTSIZE-1 downto 0));
            when others =>  -- Quatrième quadrant: phi = -phi
                amp_o <= std_logic_vector(re_stages(N_ITER)(AMP_OUTPUTSIZE-1 downto 0));
                -- Complément à 2 pour la négation
                phi_o <= std_logic_vector((not phi_final + 1)(PHI_OUTPUTSIZE-1 downto 0));
        end case;
    end process;

end comb;
