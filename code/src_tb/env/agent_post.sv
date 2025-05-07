`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

typedef struct packed {
    logic[11:0] re;
    logic[11:0] im;
    logic[1:0] original_quadrant_id;
    logic signals_exchanged;
    logic[10:0] phi;
} post_in_transaction;

typedef struct packed {
    logic[11:0] amp;
    logic[10:0] phi;
} post_out_transaction;

class post_in_item extends uvm_sequence_item;
  rand post_in_transaction trans;

  `uvm_object_utils(post_in_item)
  function new(string name="post_in_item"); super.new(name); endfunction
endclass

class post_sequencer extends uvm_sequencer#(post_in_item);

   `uvm_component_utils(post_sequencer)
     
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //add your sequence here

endclass : post_sequencer

class post_driver extends uvm_driver#(post_in_item);

    // Virtual Interface
    virtual post_in_if.drv vif;

    // tie our component to the UVM 'factory'
    `uvm_component_utils(post_driver)

    uvm_analysis_port #(post_in_transaction) out;

    

    // Constructor
    function new (string name, uvm_component parent);
      super.new(name, parent);
      out = new("out", this);
    endfunction : new

    //get the interface handle from the uvm config
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
       if(!uvm_config_db#(virtual post_in_if.drv)::get(this, "", "vif", vif))
         `uvm_fatal("NO_VIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
    endfunction: build_phase

    // run phase
    virtual task run_phase(uvm_phase phase);
        post_in_item req;
        forever begin
            seq_item_port.get_next_item(req);
            post_in_transaction trans = req.trans;
            //respond_to_transfer(req);
            driver(trans);
            seq_item_port.item_done();
            out.write(trans);
        end
    endtask : run_phase

    // driver 
    virtual task driver(post_in_transaction trans);
        @(posedge vif.clk);
        vif.re <= trans.re;
        vif.im <= trans.im;
        vif.phi <= trans.phi;
        vif.original_quadrant_id <= trans.original_quadrant_id;
        vif.signals_exchanged <= trans.signals_exchanged;
    endtask : driver

endclass : post_driver

class post_monitor extends uvm_monitor;

    // Virtual Interface
    virtual post_out_if.mon vif;

    // this line is used to connect to our scoreboard
    uvm_analysis_port #(post_out_transaction) out;

    // Placeholder to capture transaction information.
    // post_out_transaction trans;
    
    // tie our component to the UVM 'factory'
    `uvm_component_utils(post_monitor)

    // new - constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
        out = new("out", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual post_out_if.mon)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
    endfunction: build_phase

    // run phase
    virtual task run_phase(uvm_phase phase);
      forever begin
        post_out_transaction trans;
        @(posedge vif.clk);
        trans.amp = vif.amp;
        trans.phi = vif.phi;
        //finally send it to the scoreboard or whoever is listening
        out.write(trans);
      end
    endtask : run_phase

endclass : post_monitor

class post_agent extends uvm_agent;
  //declaring agent components
  post_driver    driver;
  post_sequencer sequencer;
  post_monitor   monitor;

  // UVM automation macros for general components
  `uvm_component_utils(post_agent)

  // constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  // build_phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(get_is_active() == UVM_ACTIVE) begin
      driver = post_driver::type_id::create("driver", this);
      sequencer = post_sequencer::type_id::create("sequencer", this);
    end

    monitor = post_monitor::type_id::create("monitor", this);
  endfunction : build_phase

  // connect_phase
  function void connect_phase(uvm_phase phase);
    if(get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction : connect_phase

endclass : post_agent

class post_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(post_scoreboard)
  uvm_analysis_imp#(post_in_transaction, post_scoreboard) in;
  uvm_analysis_imp#(post_out_transaction, post_scoreboard) out;

  // new - constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    in = new("in", this);
    out = new("out", this);
  endfunction: build_phase
  
  // write
  virtual function void write(post_in_transaction pkt);
    $display("SCB:: Pkt recived");
    //pkt.print();
  endfunction : write

  virtual function void write(post_out_transaction pkt);
    $display("SCB:: Pkt recived");
    //pkt.print();
  endfunction : write

endclass : post_scoreboard