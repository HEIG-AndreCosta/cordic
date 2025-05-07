--------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
--------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
--------------------------------------------------------------------------------
--
-- File     : cordic_pkg.vhd
-- Author   : Peter Podolec
-- Date     : 27.04.2023
--
-- Context  : CORDIC implementation
--
--------------------------------------------------------------------------------
-- Description : Package containing constants and datatypes used by the CORDIC
--               architectures
--               
--------------------------------------------------------------------------------
-- Dependencies : - 
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver    Date        Engineer    Comments
-- 0.1    See header  PPC         Initial version
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package cordic_pkg is
    -----------------------------
    --- Constant declarations ---
    -----------------------------

    -- Size of input data (re_i, im_i)
    constant DATASIZE           : integer := 12;

    -- Size of output angle (phi_o)
    constant PHI_OUTPUTSIZE     : integer := 11;

    -- Size of output amplitude (amp_o)
    constant AMP_OUTPUTSIZE     : integer := 12;

    -- Number of CORDIC iterations
    constant N_ITER             : integer := 10;

    -- Size of cumulated angle propagation through CORDIC stages
    constant INTERNAL_ANGLESIZE : integer := 11;

    -- Size of cumulated angle propagation through CORDIC stages
    constant INTERNAL_DATASIZE  : integer := DATASIZE + 1;

    

    constant pidiv2_c           : unsigned(INTERNAL_ANGLESIZE-1 downto 0) :=        -- PI/2
                                    (INTERNAL_ANGLESIZE-2 => '1', others => '0');
    constant pidiv1_c           : unsigned(INTERNAL_ANGLESIZE-1 downto 0) :=        -- PI
                                    (INTERNAL_ANGLESIZE-1 => '1', others => '0');

    -------------------------
    --- Type declarations ---
    -------------------------

    type alpha_values_array_t is array (integer range <>) 
                              of std_logic_vector(INTERNAL_ANGLESIZE - 1 downto 0);

    -- Rotation angle values
    constant alpha_values_c : alpha_values_array_t(1 to 10):= (
        "00100101110",
        "00010100000",
        "00001010001",
        "00000101001",
        "00000010100",
        "00000001010",
        "00000000101",
        "00000000011",
        "00000000001",
        "00000000001"
    );
end cordic_pkg;
