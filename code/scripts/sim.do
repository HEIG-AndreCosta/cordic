#!/usr/bin/tclsh

# Main proc at the end #

#------------------------------------------------------------------------------
proc vhdl_compil { ARCHI } {
    global Path_VHDL
    global Path_TB
    puts "\nVHDL compilation :"

    vcom -2008 $Path_VHDL/cordic_pkg.vhd
    vcom -2008 $Path_VHDL/cordic.vhd
    vcom -2008 $Path_VHDL/cordic_pre_treatment.vhd
    vcom -2008 $Path_VHDL/cordic_post_treatment.vhd
    vcom -2008 $Path_VHDL/cordic_arch_$ARCHI.vhd
    vlog -sv $Path_TB/cordic_tb.sv
}

#------------------------------------------------------------------------------
proc sim_start {TESTCASE} {

    vsim -voptargs="+acc" -t 1ns -GTESTCASE=$TESTCASE work.cordic_tb
    if {[file exists wave.do] == 0} {
	add wave -r *
    } else {
	do wave.do
    }
    wave refresh
    run -all
}

#------------------------------------------------------------------------------
proc do_all {ARCHI TESTCASE} {
    vhdl_compil $ARCHI
    sim_start $TESTCASE
}

## MAIN #######################################################################

# Compile folder ----------------------------------------------------
if {[file exists work] == 0} {
    vlib work
}

puts -nonewline "  Path_VHDL => "
set Path_VHDL     "../src_vhdl"
set Path_TB       "../src_tb"

global Path_VHDL
global Path_TB

# start of sequence -------------------------------------------------
if {$argc > 0} {
    if {[string compare $1 "all"] == 0} {
        puts "All simulation"
        do_all comb 0
        quit -sim
        do_all pipeline 0
        quit -sim
        do_all sequential 0
        quit -sim
    } elseif {[string compare $1 "comp_vhdl"] == 0} {
	    puts "VHDL compilation"
	    vhdl_compil $2
    } elseif {[string compare $1 "sim"] == 0} {
	    puts "Sim option"
	    sim_start $2
    } else {
        do_all $1 $2
    }
} else {
    puts "Default values"
    do_all comb 0
}
