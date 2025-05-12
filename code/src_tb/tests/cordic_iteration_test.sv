`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import cordic_pkg_sv::*;

`include "../src_tb/env/cordic_iteration_env.sv"
`include "../src_tb/sequence/cordic_iteration_sequence.sv"

class cordic_iteration_test extends uvm_test;

  // tie our component to the UVM 'factory'
  `uvm_component_utils(cordic_iteration_test)

  cordic_iteration_env env;

  function new(string name = "cordic_iteration_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = cordic_iteration_env::type_id::create("env", this);
  endfunction : build_phase

  // Start our sequence
  task run_phase(uvm_phase phase);
    cordic_iteration_sequence seq;
    phase.raise_objection(this);
    seq = cordic_iteration_sequence::type_id::create("seq");
    seq.start(env.cordic_iteration_agnt.sequencer);
    #200
    phase.drop_objection(this);
  endtask : run_phase

endclass : cordic_iteration_test