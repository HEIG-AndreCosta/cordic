--------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
--------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
--------------------------------------------------------------------------------
--
-- File     : cordic_arch_pipeline.vhd
-- Author   : Yann Thoma
-- Date     : 10.04.2025
--
-- Context  : SCF lab 08
--
--------------------------------------------------------------------------------
-- Description :  Pipelined CORDIC architecture
--------------------------------------------------------------------------------
-- Dependencies : - 
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver    Date        Engineer    Comments
-- 0.1    See header  PPC         Initial version
--------------------------------------------------------------------------------

architecture pipeline of cordic is
    --------------------------
    --- Signal declaration ---
    --------------------------
    -- Signaux pour l'étape 1: réduction au premier octant
    signal abs_re, abs_im : unsigned(DATASIZE-1 downto 0);
    signal quadrant       : unsigned(1 downto 0);
    signal echanges       : std_logic;
    
    -- Signaux pour les registres du pipeline
    type re_im_array_t is array (0 to N_ITER) of signed(INTERNAL_DATASIZE-1 downto 0);
    type phi_array_t is array (0 to N_ITER) of unsigned(INTERNAL_ANGLESIZE-1 downto 0);
    type quadrant_array_t is array (0 to N_ITER) of unsigned(1 downto 0);
    type echanges_array_t is array (0 to N_ITER) of std_logic;
    
    signal re_stages     : re_im_array_t;
    signal im_stages     : re_im_array_t;
    signal phi_stages    : phi_array_t;
    signal quadrant_pipe : quadrant_array_t;
    signal echanges_pipe : echanges_array_t;
    
    -- Signaux de contrôle du pipeline
    signal valid_pipe : std_logic_vector(0 to N_ITER);
    signal ready_pipe : std_logic_vector(0 to N_ITER);
    
    -- Signaux pour l'étape 3: projection de l'angle sur les 4 quadrants
    signal phi_final  : unsigned(INTERNAL_ANGLESIZE-1 downto 0);
    signal amp_final  : unsigned(INTERNAL_DATASIZE-1 downto 0);

begin
    -- Propagation des signaux de contrôle à travers le pipeline
    valid_pipe(0) <= valid_i;
    ready_pipe(N_ITER) <= ready_i;
    valid_o <= valid_pipe(N_ITER);
    
    -- Propagation du ready signal à travers le pipeline (en sens inverse)
    ready_backwards_gen: for i in 0 to N_ITER-1 generate
        ready_pipe(i) <= ready_pipe(i+1) or not valid_pipe(i+1);
    end generate;
    
    ready_o <= ready_pipe(0);
    
    -- Étape 1: Réduction des coordonnées au premier octant (combinatoire)
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
    
    -- Premier étage du pipeline: chargement des données initiales
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                valid_pipe(1) <= '0';
                re_stages(0) <= (others => '0');
                im_stages(0) <= (others => '0');
                phi_stages(0) <= (others => '0');
                quadrant_pipe(0) <= (others => '0');
                echanges_pipe(0) <= '0';
            elsif ready_pipe(0) = '1' then
                valid_pipe(1) <= valid_pipe(0);
                
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
                
                -- Propagation des informations du quadrant et échanges
                quadrant_pipe(0) <= quadrant;
                echanges_pipe(0) <= echanges;
            end if;
        end if;
    end process;
    
    -- Étape 2: Itérations CORDIC avec pipeline
    cordic_iterations: for i in 0 to N_ITER-1 generate
        process(clk_i)
        begin
            if rising_edge(clk_i) then
                if rst_i = '1' then
                    valid_pipe(i+2) <= '0';
                    re_stages(i+1) <= (others => '0');
                    im_stages(i+1) <= (others => '0');
                    phi_stages(i+1) <= (others => '0');
                    quadrant_pipe(i+1) <= (others => '0');
                    echanges_pipe(i+1) <= '0';
                elsif ready_pipe(i+1) = '1' then
                    valid_pipe(i+2) <= valid_pipe(i+1);
                    quadrant_pipe(i+1) <= quadrant_pipe(i);
                    echanges_pipe(i+1) <= echanges_pipe(i);
                    
                    -- Logique CORDIC
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
                end if;
            end if;
        end process;
    end generate;
    
    -- Étape 3: Projection de l'angle sur les 4 quadrants (dernier registre du pipeline)
    final_stage: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                amp_o <= (others => '0');
                phi_o <= (others => '0');
                valid_pipe(N_ITER+1) <= '0';
            elsif ready_pipe(N_ITER) = '1' then
                valid_pipe(N_ITER+1) <= valid_pipe(N_ITER);
                
                -- Amplitude est toujours la partie réelle de la dernière itération
                amp_o <= std_logic_vector(re_stages(N_ITER)(AMP_OUTPUTSIZE-1 downto 0));
                
                -- 1. Projection sur le premier quadrant
                if echanges_pipe(N_ITER-1) = '1' then
                    -- Si échange a été effectué: phi = PI/2 - phi
                    phi_final <= pidiv2_c - phi_stages(N_ITER);
                else
                    phi_final <= phi_stages(N_ITER);
                end if;
                
                -- 2. Projection sur les quatre quadrants en fonction du quadrant d'origine
                case quadrant_pipe(N_ITER-1) is
                    when "00" =>  -- Premier quadrant: phi = phi
                        phi_o <= std_logic_vector(phi_final(PHI_OUTPUTSIZE-1 downto 0));
                    when "01" =>  -- Deuxième quadrant: phi = PI - phi
                        phi_o <= std_logic_vector((pidiv1_c - phi_final)(PHI_OUTPUTSIZE-1 downto 0));
                    when "10" =>  -- Troisième quadrant: phi = phi + PI
                        phi_o <= std_logic_vector((phi_final + pidiv1_c)(PHI_OUTPUTSIZE-1 downto 0));
                    when others =>  -- Quatrième quadrant: phi = -phi
                        -- Complément à 2 pour la négation
                        phi_o <= std_logic_vector((not phi_final + 1)(PHI_OUTPUTSIZE-1 downto 0));
                end case;
            end if;
        end if;
    end process;

end pipeline;