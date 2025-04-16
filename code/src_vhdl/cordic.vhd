--------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
--------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
--------------------------------------------------------------------------------
--
-- File     : cordic.vhd
-- Author   : Peter Podolec
-- Date     : 21.04.2023
--
-- Context  : CORDIC implementation
--
--------------------------------------------------------------------------------
-- Description :  Entity that computes the cartesian-to-polar coordinate
--                transform using CORDIC vectoring mode.
--                A complex vector (re, im) is given to the calculator and 
--                the result is output as an (amp, phi) pair corresponding
--                respectively to the amplitude and phase of the input vector.
--                The following equations apply :
--                  re = Re(amp * e^(j*phi)) + Er
--                  im = Im(amp * e^(j*phi)) + Ei
--                with Er and Ei being the compulational errors.
--                The entity provides dataflow control signals to enable the 
--                implementation of different architectures.
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

use work.cordic_pkg.all;

entity cordic is
    port (
        clk_i       : in  std_logic;
        rst_i       : in  std_logic;
        -- input data in the cartesian form
        re_i       : in  std_logic_vector(DATASIZE - 1 downto 0);     -- real
        im_i       : in  std_logic_vector(DATASIZE - 1 downto 0);     -- imaginary
        -- output data in the polar form
        amp_o       : out std_logic_vector(AMP_OUTPUTSIZE - 1 downto 0);    -- amplitude
        phi_o       : out std_logic_vector(PHI_OUTPUTSIZE - 1 downto 0);    -- phase
        -- dataflow control signals
        ready_o     : out std_logic;
        valid_i     : in  std_logic;
        ready_i     : in  std_logic;
        valid_o     : out std_logic
    );
end cordic;