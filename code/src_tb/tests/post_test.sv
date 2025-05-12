`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import cordic_pkg_sv::*;

`include "../src_tb/env/post_env.sv"
`include "../src_tb/sequence/post_sequence.sv"

class post_test extends uvm_test;

    // tie our component to the UVM 'factory'
  `uvm_component_utils(post_test)

  post_env env;

  function new(string name = "post_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = post_env::type_id::create("env", this);
  endfunction : build_phase

  // Start our sequence
  task run_phase(uvm_phase phase);
    post_sequence seq;
    phase.raise_objection(this);
    seq = post_sequence::type_id::create("seq");
    seq.start(env.post_agnt.sequencer);
    #200
    phase.drop_objection(this);
  endtask : run_phase

endclass : post_test