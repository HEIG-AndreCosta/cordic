#!/usr/bin/tclsh

# Main proc at the end #

set PATH_VHDL   "../src_vhdl"
set PATH_TB     "../src_tb"
set PATH_UVM    "/opt/mentor/questasim/verilog_src/uvm-1.2/src"

#------------------------------------------------------------------------------
proc vhdl_compil {} {
    global PATH_VHDL
    global PATH_TB
    puts "\nVHDL compilation :"

    vcom -2008 $PATH_VHDL/cordic_pkg.vhd
    vcom -2008 $PATH_VHDL/cordic_iteration.vhd
    vcom -2008 $PATH_VHDL/cordic_post_treatment.vhd
    vcom -2008 $PATH_VHDL/cordic_pre_treatment.vhd
    vcom -2008 $PATH_VHDL/cordic.vhd
    #vlog -sv $PATH_TB/cordic_tb.sv
}

proc sv_tb_compil {} {
  global PATH_TB PATH_UVM

  vlog -work work \
       +incdir+$PATH_UVM \
       +acc \
       -sv $PATH_UVM/uvm_pkg.sv

  vlog -work work \
       +incdir+$PATH_UVM \
       +acc \
       -sv $PATH_TB/cordic_pkg/cordic_pkg_sv.sv

   vlog -work work \
       +acc \
       +incdir+$PATH_UVM \
       -sv $PATH_TB/cordic_pkg/*.sv \
       $PATH_TB/interfaces/*.sv \
       $PATH_TB/env/*.sv \
       $PATH_TB/sequence/*.sv \
       $PATH_TB/tests/*sv \
       $PATH_TB/tb_top.sv
}

#------------------------------------------------------------------------------
proc sim_start {TESTNAME} {
    global PATH_UVM
    vsim -c \
       -sv_lib $PATH_UVM/../../../uvm-1.2/linux_x86_64/uvm_dpi \
       -voptargs=+acc \
       +UVM_TESTNAME=$TESTNAME \
       work.tb_top \
       -do {
         run -all;
    }
}

#------------------------------------------------------------------------------
proc do_all {TESTNAME} {
    sim_start $TESTNAME
}

## MAIN #######################################################################

# Compile folder ----------------------------------------------------
if {[file exists work] == 0} {
    vlib work
}
#if {![file exists uvm]}  { vlib uvm }

vhdl_compil

# start of sequence -------------------------------------------------
if {$argc > 0} {
    if {[string compare $1 "all"] == 0} {
        sv_tb_compil
        puts "All simulation"
        do_all pre_test
        do_all cordic_iteration_test
        do_all post_test
    } elseif {[string compare $1 "comp_vhdl"] == 0} {
	    puts "VHDL compilation"
    } else {
        sv_tb_compil
        do_all $1
    }
} else {
    sv_tb_compil
    puts "Default values"
    do_all pre_test
}
