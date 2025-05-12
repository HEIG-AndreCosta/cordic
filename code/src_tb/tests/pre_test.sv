`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import cordic_pkg_sv::*;

`include "../src_tb/env/pre_env.sv"
`include "../src_tb/sequence/pre_sequence.sv"

class pre_test extends uvm_test;

  // tie our component to the UVM 'factory'
  `uvm_component_utils(pre_test)

  pre_env env;

  function new(string name = "pre_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = pre_env::type_id::create("env", this);
  endfunction : build_phase

  // Start our sequence
  task run_phase(uvm_phase phase);
    pre_sequence seq;
    phase.raise_objection(this);
    seq = pre_sequence::type_id::create("seq");
    seq.start(env.pre_agnt.sequencer);
    #200
    phase.drop_objection(this);
  endtask : run_phase

endclass : pre_test