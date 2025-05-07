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
    component cordic_pre_treatment is
        port (
                 re_i                    : in  std_logic_vector(DATASIZE - 1 downto 0);
                 im_i                    : in  std_logic_vector(DATASIZE - 1 downto 0);
                 re_o                    : out  std_logic_vector(DATASIZE - 1 downto 0);
                 im_o                    : out  std_logic_vector(DATASIZE - 1 downto 0);
                 original_quadrant_id_o  : out std_logic_vector(1 downto 0);
                 signals_exchanged_o     : out std_logic
             );
    end component;

    component cordic_iteration is
        port (
                 re_i  : in  std_logic_vector(DATASIZE - 1 downto 0);   
                 im_i  : in  std_logic_vector(DATASIZE - 1 downto 0);    
                 phi_i : in  std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0);
                 re_o  : out std_logic_vector(DATASIZE - 1 downto 0);    
                 im_o  : out std_logic_vector(DATASIZE - 1 downto 0);     
                 phi_o : out std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0);
                 iter_i : in std_logic_vector(3 downto 0)
             );
    end component;

    component cordic_post_treatment is
        port (
                 re_i                    : in  std_logic_vector(DATASIZE - 1 downto 0);
                 im_i                    : in  std_logic_vector(DATASIZE - 1 downto 0);
                 original_quadrant_id_i  : in std_logic_vector(1 downto 0);
                 signals_exchanged_i     : in std_logic;
                 phi_i                   : in std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0);
                 amp_o       : out std_logic_vector(AMP_OUTPUTSIZE - 1 downto 0);
                 phi_o       : out std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0)
             );
    end component;

    type cordic_state_t is (
        IDLE,
        ITERATION,
        INCREMENT,
        POST_TREATMENT,
        VALID
    );

    signal curr_cordic_state_s : cordic_state_t;
    signal next_cordic_state_s : cordic_state_t;

    signal curr_original_quadrant_id_s : std_logic_vector(1 downto 0);
    signal next_original_quadrant_id_s : std_logic_vector(1 downto 0);
    signal pre_treatment_original_quadrant_id_s : std_logic_vector(1 downto 0);

    signal curr_signals_exchanged_s : std_logic;
    signal next_signals_exchanged_s : std_logic;
    signal pre_treatment_signals_exchanged_s : std_logic;

    signal pre_treatment_re_s : std_logic_vector(DATASIZE - 1 downto 0);
    signal iter_re_s : std_logic_vector(DATASIZE - 1 downto 0);

    signal next_re_s: std_logic_vector(DATASIZE - 1 downto 0);
    signal curr_re_s: std_logic_vector(DATASIZE - 1 downto 0);

    signal next_im_s: std_logic_vector(DATASIZE - 1 downto 0);
    signal curr_im_s: std_logic_vector(DATASIZE - 1 downto 0);

    signal pre_treatment_im_s : std_logic_vector(DATASIZE - 1 downto 0);
    signal iter_im_s : std_logic_vector(DATASIZE - 1 downto 0);

    signal next_phi_s : std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0);
    signal curr_phi_s : std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0);

    signal iter_phi_s : std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0);
    signal post_treatment_phi_s : std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0);

    signal post_treatment_amp_s : std_logic_vector(AMP_OUTPUTSIZE - 1 downto 0);
    signal next_amp_s : std_logic_vector(AMP_OUTPUTSIZE - 1 downto 0);
    signal curr_amp_s : std_logic_vector(AMP_OUTPUTSIZE - 1 downto 0);

    signal curr_iter_s : unsigned(3 downto 0);
    signal next_iter_s : unsigned(3 downto 0);

begin

    cordic_pre: entity work.cordic_pre_treatment
    port map(
       re_i => re_i,
       im_i => im_i,
       re_o => pre_treatment_re_s,
       im_o => pre_treatment_im_s,
       original_quadrant_id_o => pre_treatment_original_quadrant_id_s,
       signals_exchanged_o => pre_treatment_signals_exchanged_s
    );
    
    cordic_iter: entity work.cordic_iteration 
    port map (
            re_i  => curr_re_s,   
            im_i  => curr_im_s, 
            phi_i => curr_phi_s,
            re_o  => iter_re_s,    
            im_o  => iter_im_s,
            phi_o => iter_phi_s,
            iter_i => std_logic_vector(curr_iter_s)
    );

    cordic_post: entity work.cordic_post_treatment
    port map(
       re_i => curr_re_s,
       im_i => curr_im_s,
       original_quadrant_id_i => curr_original_quadrant_id_s,
       signals_exchanged_i => curr_signals_exchanged_s,
       phi_i => curr_phi_s,
       amp_o => post_treatment_amp_s,
       phi_o => post_treatment_phi_s
    );

    -- State Machines
    fsm_reg : process (clk_i, rst_i) is
    begin
        if rst_i = '1' then
            curr_cordic_state_s <= IDLE;
        elsif rising_edge(clk_i) then
            curr_cordic_state_s <= next_cordic_state_s;
        end if;
    end process fsm_reg;

    process (clk_i) is
    begin
        if rising_edge(clk_i) then
            curr_re_s <= next_re_s;
            curr_im_s <= next_im_s;
            curr_phi_s <= next_phi_s;
            curr_amp_s <= next_amp_s;
            curr_iter_s <= next_iter_s;
            curr_signals_exchanged_s <= next_signals_exchanged_s;
            curr_original_quadrant_id_s <= next_original_quadrant_id_s;
        end if;
    end process;

    future_state_decoder : process (all) is
        variable iter_v : unsigned(curr_iter_s'range);
        variable state_v : cordic_state_t;
    begin
        next_re_s <= curr_re_s;
        next_im_s <= curr_im_s;
        next_phi_s <= curr_phi_s;
        next_amp_s <= curr_amp_s;
        next_signals_exchanged_s <= curr_signals_exchanged_s;
        next_original_quadrant_id_s <= curr_original_quadrant_id_s;
        state_v := curr_cordic_state_s;
        iter_v := curr_iter_s;
        valid_o <= '0';
        ready_o <= '0';

        case state_v is
            when IDLE =>
                next_re_s <= pre_treatment_re_s;
                next_im_s <= pre_treatment_im_s;
                next_signals_exchanged_s <= pre_treatment_signals_exchanged_s;
                next_original_quadrant_id_s <= pre_treatment_original_quadrant_id_s;
                next_phi_s <= (others => '0');
                iter_v := to_unsigned(1, iter_v'length);
                ready_o <= '1';
                if valid_i = '1' then
                    state_v := ITERATION;
                end if;
            when ITERATION =>
                next_re_s <= iter_re_s;
                next_im_s <= iter_im_s;
                next_phi_s <= iter_phi_s;

                if iter_v = 10 then
                    state_v := POST_TREATMENT;
                end if;
                iter_v := iter_v + 1;
            when POST_TREATMENT =>
                next_phi_s <= post_treatment_phi_s;
                next_amp_s <= post_treatment_amp_s;
                state_v := VALID;
            when VALID =>
                valid_o <= '1';
                if ready_i = '1' then
                    state_v := IDLE;
                end if;
        end case;

        next_cordic_state_s <= state_v;
        next_iter_s <= iter_v;
    end process;
    amp_o <= curr_amp_s;
    phi_o <= curr_phi_s;
end sequential;
