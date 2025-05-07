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

    type iter_values_array_t is array (0 to 10) of std_logic_vector(DATASIZE - 1 downto 0);
    type iter_phi_array_t is array (0 to 10) of std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0);
    type original_quadrant_array_t is array (0 to 10) of std_logic_vector(1 downto 0);

    signal original_quadrant_id_s   : original_quadrant_array_t;
    signal re_i_s                   : iter_values_array_t; 
    signal im_i_s                   : iter_values_array_t; 
    signal re_o_s                   : iter_values_array_t; 
    signal im_o_s                   : iter_values_array_t; 
    signal phi_i_s                  : iter_phi_array_t; 
    signal phi_o_s                  : iter_phi_array_t; 

    signal amp_s                    : std_logic_vector(amp_o'range);
    signal phi_s                    : std_logic_vector(phi_o'range);
    signal data_valid_s             : std_logic_vector(10 downto 0);
    signal signals_exchanged_s      : std_logic_vector(10 downto 0);

    signal stop_s                   : std_logic;
    signal ready_s                  : std_logic;

begin
    pre_treatment: entity work.cordic_pre_treatment
    port map(
       re_i => re_i,
       im_i => im_i,
       re_o => re_o_s(0),
       im_o => im_o_s(0),
       original_quadrant_id_o => original_quadrant_id_s(0),
       signals_exchanged_o => signals_exchanged_s(0)
    );

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if stop_s = '0' then
                re_i_s(0) <= re_o_s(0);
                im_i_s(0) <= im_o_s(0);
                phi_i_s(0) <= (others => '0');
                data_valid_s(0) <= ready_s and valid_i;
            end if;
        end if;
    end process;
    
    cordic_iterations: for i in 1 to 10 generate
        iteration: cordic_iteration port map (
            re_i  => re_i_s(i - 1),   
            im_i  => im_i_s(i - 1), 
            phi_i => phi_i_s(i - 1),
            re_o  => re_o_s(i),    
            im_o  => im_o_s(i),
            phi_o => phi_o_s(i - 1),
            iter_i => std_logic_vector(to_unsigned(i, 4))
        );
        process(clk_i)
        begin
            if rising_edge(clk_i) then
                if stop_s = '0' then
                    re_i_s(i) <= re_o_s(i);
                    im_i_s(i) <= im_o_s(i);
                    phi_i_s(i) <= phi_o_s(i - 1);
                    data_valid_s(i) <= data_valid_s(i - 1);
                    original_quadrant_id_s(i) <= original_quadrant_id_s(i - 1);
                    signals_exchanged_s(i) <= signals_exchanged_s(i - 1);
                end if;
            end if;
        end process;
    end generate;

    post_treatment: entity work.cordic_post_treatment
    port map(
       re_i => re_i_s(10),
       im_i => im_i_s(10),
       original_quadrant_id_i => original_quadrant_id_s(10),
       signals_exchanged_i => signals_exchanged_s(10),
       phi_i => phi_i_s(10),
       amp_o => amp_s,
       phi_o => phi_s
    );

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if ready_i = '1' then
                amp_o <= amp_s;
                phi_o <= phi_s;
            end if;
            valid_o <= data_valid_s(10);
        end if;
    end process;

    -- TODO: Generate stop signal for each pipeline stage
    stop_s <= '1' when ready_i = '0' and data_valid_s(10) = '1' else '0';
    ready_s <= not stop_s;
    ready_o <= ready_s;

end pipeline;
