class pre_test extends uvm_test;

  `uvm_component_utils(pre_test)

  cordic_env env;

  function new(string name = "pre_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = cordic_env::type_id::create("env", this);
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    pre_test_sequence seq = pre_test_sequence::type_id::create("seq");
    seq.start(env.pre_agnt.sequencer);
    #200
    phase.drop_objection(this);
  endtask : run_phase

endclass : pre_test