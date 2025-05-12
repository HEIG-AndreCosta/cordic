`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

`include "../src_tb/env/agent_cordic_iteration.sv"

class cordic_iteration_env extends uvm_env;

    cordic_iteration_agent cordic_iteration_agnt;
    cordic_iteration_scoreboard cordic_iteration_scb;

    `uvm_component_utils(cordic_iteration_env)

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // build_phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cordic_iteration_agnt = cordic_iteration_agent::type_id::create("cordic_iteration_agnt", this);
        cordic_iteration_scb = cordic_iteration_scoreboard::type_id::create("cordic_iteration_scb", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        // The driver in cordic_iteration_agent publishes RAW inputs
        cordic_iteration_agnt.driver.out.connect(cordic_iteration_scb.in);

        // The monitor in cordic_iteration_agent publishes NORMALISED outputs
        cordic_iteration_agnt.monitor.out.connect(cordic_iteration_scb.in);
    endfunction

endclass : cordic_iteration_env