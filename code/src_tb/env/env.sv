`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

class cordic_env extends uvm_env;

    pre_agent       pre_agnt;
    cordic_agent    cordic_agnt;
    post_agent      post_agnt;

    pre_scoreboard pre_scb;
    cordic_scoreboard cordic_scb;
    post_scoreboard post_scb;
    
    `uvm_component_utils(cordic_env)

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // build_phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        pre_agnt = pre_agent::type_id::create("pre_agnt", this);
        cordic_agnt = cordic_agent::type_id::create("cordic_agnt", this);
        post_agnt = post_agent::type_id::create("post_agnt", this);

        pre_scb = pre_scoreboard::type_id::create("pre_scb", this);
        cordic_scb = cordic_scoreboard::type_id::create("cordic_scb", this);
        post_scb = post_scoreboard::type_id::create("post_scb", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);

        // The driver in pre_agent publishes RAW inputs
        pre_agnt.driver.out.connect(pre_scb.in);

        // The monitor in pre_agent publishes NORMALISED outputs
        pre_agnt.monitor.out.connect(pre_scb.out);

        // The driver in pre_agent publishes RAW inputs
        cordic_agnt.driver.out.connect(cordic_scb.in);

        // The monitor in pre_agent publishes NORMALISED outputs
        cordic_agnt.monitor.out.connect(cordic_scb.out);

        // The driver in pre_agent publishes RAW inputs
        post_agnt.driver.out.connect(post_scb.in);

        // The monitor in pre_agent publishes NORMALISED outputs
        post_agnt.monitor.out.connect(post_scb.out);
    endfunction

endclass : cordic_env