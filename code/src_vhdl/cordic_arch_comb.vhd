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

    component cordic_pre_treatment is
    port (
        clk_i                   : in  std_logic;
        rst_i                   : in  std_logic;
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
        clk_i                   : in  std_logic;
        rst_i                   : in  std_logic;
        re_i                    : in  std_logic_vector(DATASIZE - 1 downto 0);
        im_i                    : in  std_logic_vector(DATASIZE - 1 downto 0);
        original_quadrant_id_i  : in std_logic_vector(1 downto 0);
        signals_exchanged_i     : in std_logic;
        phi_i                   : in std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0);
        amp_o       : out std_logic_vector(AMP_OUTPUTSIZE - 1 downto 0);
        phi_o       : out std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0)
    );
    end component;

    type iter_values_array_t is array (0 to 10) 
                              of std_logic_vector(DATASIZE - 1 downto 0);

    type iter_phi_array_t is array (0 to 10) 
                              of std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0);

    signal re_s                     : iter_values_array_t; 
    signal im_s                     : iter_values_array_t; 
    signal phi_s                    : iter_phi_array_t; 
    signal original_quadrant_id_s   : std_logic_vector(1 downto 0);
    signal signals_exchanged_s      : std_logic;

begin
    phi_s(0) <= (others => '0');

    pre_treatment: entity work.cordic_pre_treatment
    port map(
       clk_i => clk_i,
       rst_i => rst_i,
       re_i => re_i,
       im_i => im_i,
       re_o => re_s(0),
       im_o => im_s(0),
       original_quadrant_id_o => original_quadrant_id_s,
       signals_exchanged_o => signals_exchanged_s
    );
    
    cordic_iterations: for i in 0 to 9 generate
        iteration: cordic_iteration port map (
            re_i  => re_s(i),   
            im_i  => im_s(i), 
            phi_i => phi_s(i),
            re_o  => re_s(i + 1),    
            im_o  => im_s(i + 1),
            phi_o => phi_s(i + 1),
            iter_i => std_logic_vector(to_unsigned(i + 1, 4))
        );
    end generate;

    post_treatment: entity work.cordic_post_treatment
    port map(
       clk_i => clk_i,
       rst_i => rst_i,
       re_i => re_s(re_s'high),
       im_i => im_s(im_s'high),
       original_quadrant_id_i => original_quadrant_id_s,
       signals_exchanged_i => signals_exchanged_s,
       phi_i => phi_s(phi_s'high),
       amp_o => amp_o,
       phi_o => phi_o
    );

    ready_o <= ready_i;
    valid_o <= ready_i and valid_i;

end comb;
