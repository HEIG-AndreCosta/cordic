`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

`include "../src_tb/env/agent_pre.sv"

class pre_env extends uvm_env;

    pre_agent pre_agnt;
    pre_scoreboard pre_scb;

    `uvm_component_utils(pre_env)

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // build_phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        pre_agnt = pre_agent::type_id::create("pre_agnt", this);
        pre_scb = pre_scoreboard::type_id::create("pre_scb", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);

        // The driver in pre_agent publishes RAW inputs
        pre_agnt.driver.out.connect(pre_scb.in);

        // The monitor in pre_agent publishes NORMALISED outputs
        pre_agnt.monitor.out.connect(pre_scb.in);

    endfunction

endclass : pre_env
