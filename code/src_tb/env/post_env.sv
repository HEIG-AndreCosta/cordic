`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

`include "../src_tb/env/agent_post.sv"

class post_env extends uvm_env;

    post_agent post_agnt;
    post_scoreboard post_scb;

    `uvm_component_utils(post_env)

    // new - constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // build_phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        post_agnt = post_agent::type_id::create("post_agnt", this);
        post_scb = post_scoreboard::type_id::create("post_scb", this);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        // The driver in post_agent publishes RAW inputs
        post_agnt.driver.out.connect(post_scb.in);

        // The monitor in post_agent publishes NORMALISED outputs
        post_agnt.monitor.out.connect(post_scb.in);
    endfunction

endclass : post_env