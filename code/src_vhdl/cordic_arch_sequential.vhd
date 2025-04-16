--------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
--------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
--------------------------------------------------------------------------------
--
-- File     : cordic_arch_sequential.vhd
-- Author   : Yann Thoma
-- Date     : 10.04.2025
--
-- Context  : SCF lab 08
--
--------------------------------------------------------------------------------
-- Description :  Sequential CORDIC architecture
--------------------------------------------------------------------------------
-- Dependencies : -
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver    Date        Engineer    Comments
-- 0.1    See header  YTA         Initial version
--------------------------------------------------------------------------------

architecture sequential of cordic is
    --------------------------
    --- Signal declaration ---
    --------------------------
    
    -- Types et constantes pour la machine à états
    type state_t is (IDLE, PRETRAITEMENT, ITERATION, POSTTRAITEMENT);
    
    -- Signaux pour la machine à états
    signal current_state, next_state : state_t;
    signal iter_count : integer range 0 to N_ITER;
    
    -- Signaux pour l'étape 1: réduction au premier octant
    signal abs_re, abs_im : unsigned(DATASIZE-1 downto 0);
    signal quadrant       : unsigned(1 downto 0);
    signal echanges       : std_logic;
    
    -- Signaux pour les itérations CORDIC
    signal re_reg, re_next   : signed(INTERNAL_DATASIZE-1 downto 0);
    signal im_reg, im_next   : signed(INTERNAL_DATASIZE-1 downto 0);
    signal phi_reg, phi_next : unsigned(INTERNAL_ANGLESIZE-1 downto 0);
    
    -- Signaux pour la sortie
    signal amp_reg, amp_next : unsigned(AMP_OUTPUTSIZE-1 downto 0);
    signal phi_out_reg, phi_out_next : signed(PHI_OUTPUTSIZE-1 downto 0);
    signal valid_out_reg, valid_out_next : std_logic;
    signal ready_out_reg, ready_out_next : std_logic;

begin
    -- Signaux de sortie
    amp_o <= std_logic_vector(amp_reg);
    phi_o <= std_logic_vector(phi_out_reg);
    valid_o <= valid_out_reg;
    ready_o <= ready_out_reg;
    
    -- Machine à états finis
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                current_state <= IDLE;
                iter_count <= 0;
                re_reg <= (others => '0');
                im_reg <= (others => '0');
                phi_reg <= (others => '0');
                amp_reg <= (others => '0');
                phi_out_reg <= (others => '0');
                valid_out_reg <= '0';
                ready_out_reg <= '1';
            else
                current_state <= next_state;
                re_reg <= re_next;
                im_reg <= im_next;
                phi_reg <= phi_next;
                amp_reg <= amp_next;
                phi_out_reg <= phi_out_next;
                valid_out_reg <= valid_out_next;
                ready_out_reg <= ready_out_next;
                
                -- Compteur d'itérations
                if current_state = ITERATION then
                    if next_state = ITERATION then
                        iter_count <= iter_count + 1;
                    else
                        iter_count <= 0;
                    end if;
                elsif current_state = IDLE and next_state = PRETRAITEMENT then
                    iter_count <= 0;
                end if;
            end if;
        end if;
    end process;
    
    -- Machine à états - partie combinatoire
    process(current_state, valid_i, ready_i, iter_count, re_i, im_i, re_reg, im_reg, phi_reg, amp_reg, phi_out_reg, valid_out_reg, ready_out_reg)
    begin
        -- Valeurs par défaut pour éviter les latches
        next_state <= current_state;
        re_next <= re_reg;
        im_next <= im_reg;
        phi_next <= phi_reg;
        amp_next <= amp_reg;
        phi_out_next <= phi_out_reg;
        valid_out_next <= valid_out_reg;
        ready_out_next <= ready_out_reg;
        
        case current_state is
            -- État initial - attente d'une donnée valide
            when IDLE =>
                ready_out_next <= '1';
                valid_out_next <= '0';
                
                if valid_i = '1' and ready_out_reg = '1' then
                    next_state <= PRETRAITEMENT;
                    ready_out_next <= '0';
                end if;
            
            -- Étape 1: Prétraitement (réduction au premier octant)
            when PRETRAITEMENT =>
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
                
                -- Comparaison re et im pour projection dans le premier octant
                if abs_re < abs_im then
                    echanges <= '1';
                    re_next <= signed('0' & abs_im);
                    im_next <= signed('0' & abs_re);
                else
                    echanges <= '0';
                    re_next <= signed('0' & abs_re);
                    im_next <= signed('0' & abs_im);
                end if;
                
                -- Initialisation de l'angle phi
                phi_next <= (others => '0');
                
                -- Passage à l'état d'itération
                next_state <= ITERATION;
            
            -- Étape 2: Itérations CORDIC
            when ITERATION =>
                -- Logique CORDIC pour une itération
                if im_reg(INTERNAL_DATASIZE-1) = '1' then
                    -- Partie imaginaire négative
                    re_next <= re_reg - shift_right(im_reg, iter_count+1);
                    im_next <= im_reg + shift_right(re_reg, iter_count+1);
                    phi_next <= phi_reg - unsigned(alpha_values_c(iter_count+1));
                else
                    -- Partie imaginaire positive
                    re_next <= re_reg + shift_right(im_reg, iter_count+1);
                    im_next <= im_reg - shift_right(re_reg, iter_count+1);
                    phi_next <= phi_reg + unsigned(alpha_values_c(iter_count+1));
                end if;
                
                -- Vérification si toutes les itérations sont terminées
                if iter_count = N_ITER-1 then
                    next_state <= POSTTRAITEMENT;
                end if;
            
            -- Étape 3: Post-traitement (projection de l'angle sur les 4 quadrants)
            when POSTTRAITEMENT =>
                -- Stockage de l'amplitude (valeur absolue de la partie réelle finale)
                amp_next <= unsigned(re_reg(AMP_OUTPUTSIZE-1 downto 0));
                
                -- 1. Projection sur le premier quadrant
                if echanges = '1' then
                    -- Si échange a été effectué: phi = PI/2 - phi
                    phi_next <= pidiv2_c - phi_reg;
                end if;
                
                -- 2. Projection sur les quatre quadrants en fonction du quadrant d'origine
                case quadrant is
                    when "00" =>  -- Premier quadrant: phi = phi
                        phi_out_next <= signed(phi_next(PHI_OUTPUTSIZE-1 downto 0));
                    when "01" =>  -- Deuxième quadrant: phi = PI - phi
                        phi_out_next <= signed((pidiv1_c - phi_next)(PHI_OUTPUTSIZE-1 downto 0));
                    when "10" =>  -- Troisième quadrant: phi = phi + PI
                        phi_out_next <= signed((phi_next + pidiv1_c)(PHI_OUTPUTSIZE-1 downto 0));
                    when others =>  -- Quatrième quadrant: phi = -phi
                        -- Complément à 2 pour la négation
                        phi_out_next <= signed((not phi_next + 1)(PHI_OUTPUTSIZE-1 downto 0));
                end case;
                
                -- Indique que le résultat est valide
                valid_out_next <= '1';
                
                -- Si ready_i est actif, on passe directement à l'état IDLE
                if ready_i = '1' then
                    next_state <= IDLE;
                    ready_out_next <= '1';
                    valid_out_next <= '0';
                end if;
        end case;
    end process;

end sequential;
