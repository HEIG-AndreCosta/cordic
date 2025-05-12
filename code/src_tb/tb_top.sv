`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

`include "../src_tb/tests/pre_test.sv"
`include "../src_tb/tests/post_test.sv"
`include "../src_tb/tests/cordic_iteration_test.sv"

module tb_top;

    //clock and reset signal declaration
    bit clk = 0;
    bit rst = 1;   

    //clock generation
    always #5 clk = ~clk;

    //reset Generation
    initial begin
        rst = 1;
        #5 rst = 0;
    end

    //creating instance of interface, inorder to connect DUT and testcase
    pre_in_if                   pre_in_if_inst   (.*);
    pre_out_if                  pre_out_if_inst   (.*);
    cordic_iteration_in_if      cordic_iteration_in_if_inst(.*);
    cordic_iteration_out_if     cordic_iteration_out_if_inst(.*);
    post_in_if                  post_in_if_inst  (.*);
    post_out_if                 post_out_if_inst  (.*);
    cordic_in_if                cordic_in_if_inst(.*);
    cordic_out_if               cordic_out_if_inst(.*);

    //DUT instance, interface signals are connected to the DUT ports
    cordic_pre_treatment pre_DUT (
        .re_i                       (pre_in_if_inst.re),
        .im_i                       (pre_in_if_inst.im),
        .re_o                       (pre_out_if_inst.re),
        .im_o                       (pre_out_if_inst.im),
        .original_quadrant_id_o     (pre_out_if_inst.original_quadrant_id),
        .signals_exchanged_o        (pre_out_if_inst.signals_exchanged)
    );

    cordic_iteration cordic_iteration_DUT (
        .re_i     (cordic_iteration_in_if_inst.re),
        .im_i     (cordic_iteration_in_if_inst.im),
        .phi_i    (cordic_iteration_in_if_inst.phi),
        .re_o     (cordic_iteration_out_if_inst.re),
        .im_o     (cordic_iteration_out_if_inst.im),
        .phi_o    (cordic_iteration_out_if_inst.phi),
        .iter_i   (cordic_iteration_in_if_inst.iter)
    );

    cordic cordic_DUT (
        .clk_i                      (clk),
        .rst_i                      (rst),
        .re_i       (cordic_in_if_inst.re),
        .im_i       (cordic_in_if_inst.im),
        .amp_o      (cordic_out_if_inst.amp),
        .phi_o      (cordic_out_if_inst.phi),
        .ready_o    (cordic_out_if_inst.ready),
        .valid_i    (cordic_out_if_inst.valid),
        .ready_i    (cordic_in_if_inst.ready),
        .valid_o    (cordic_in_if_inst.valid)
    );

    cordic_post_treatment post_DUT (
        .re_i                       (post_in_if_inst.re),
        .im_i                       (post_in_if_inst.im),
        .original_quadrant_id_i     (post_in_if_inst.original_quadrant_id),
        .signals_exchanged_i        (post_in_if_inst.signals_exchanged),
        .phi_i                      (post_in_if_inst.phi),

        .amp_o                      (post_out_if_inst.amp),
        .phi_o                      (post_out_if_inst.phi)
    );

    initial begin
        // example for later so the argument of set are these one:
        // first is an object from uvm_component so whenever we call this object component elsewhere it knows it has to get this setting
        // second is the instance name who can see this
        // third is the name of the componant we want to have to retrieve our signal (must match the get)
        // fourth is the value we store (our interface instance)
        // finally this uvm_config_db#(virtual x)::set is a command to tell UVM which interface instance goes with the name "vif" or another name, so that we can get the signal with uvm_config_db::get
        uvm_config_db#(virtual pre_in_if.drv)::set(null,"*","vif",pre_in_if_inst);
        uvm_config_db#(virtual pre_out_if.mon)::set(null,"*","vif",pre_out_if_inst);
        uvm_config_db#(virtual cordic_iteration_in_if.drv)::set(null,"*","vif",cordic_iteration_in_if_inst);
        uvm_config_db#(virtual cordic_iteration_out_if.mon)::set(null,"*","vif",cordic_iteration_out_if_inst);
        uvm_config_db#(virtual post_in_if.drv)::set(null,"*","vif",post_in_if_inst);
        uvm_config_db#(virtual post_out_if.mon)::set(null,"*","vif",post_out_if_inst);
        uvm_config_db#(virtual cordic_in_if.drv)::set(null,"*","vif",cordic_in_if_inst);
        uvm_config_db#(virtual cordic_out_if.mon)::set(null,"*","vif",cordic_out_if_inst);
        
        // these command are used to get a file so we can view waveform after our run 
        // dumpfile is for the name of the output file
        // dumpvars is used to store the value in the output file
        // $dumpfile("dump.vcd"); $dumpvars;
    end

    initial begin 
        run_test();
    end

endmodule
