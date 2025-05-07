`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

typedef struct packed {
    logic [11:0] re;
    logic [11:0] im;
    logic [10:0] phi;
    logic[3:0] iter;

    // to add in the vhdl code
    //logic valid;
    //logic ready;
} cordic_in_transaction;

typedef struct packed {
    logic[11:0] re;
    logic[11:0] im;
    logic[10:0] phi;

    // to add in the vhdl code
    //logic valid;
    //logic ready;
} cordic_out_transaction;

class cordic_in_item extends uvm_sequence_item;
  rand cordic_in_transaction trans;

  `uvm_object_utils(cordic_in_item)
  function new(string name="cordic_in_item"); super.new(name); endfunction
endclass


class cordic_sequencer extends uvm_sequencer#(cordic_in_item);

   `uvm_component_utils(cordic_sequencer)
     
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //add your sequence here

endclass : cordic_sequencer

class cordic_driver extends uvm_driver#(cordic_in_item);

    // Virtual Interface
    virtual cordic_in_if.drv vif;

    // tie our component to the UVM 'factory'
    `uvm_component_utils(cordic_driver)

    uvm_analysis_port #(cordic_in_transaction) out;

    // Constructor
    function new (string name, uvm_component parent);
      super.new(name, parent);
      out = new("out", this);
    endfunction : new

    //get the interface handle from the uvm config
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
       if(!uvm_config_db#(virtual cordic_in_if.drv)::get(this, "", "vif", vif))
         `uvm_fatal("NO_VIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
    endfunction: build_phase

    // run phase
    virtual task run_phase(uvm_phase phase);
        cordic_in_item req;
        forever begin
            seq_item_port.get_next_item(req);
            cordic_in_transaction trans = req.trans;
            //respond_to_transfer(req);
            driver(trans);
            seq_item_port.item_done();
            out.write(trans);
        end
    endtask : run_phase

    // driver 
    virtual task driver(cordic_in_transaction trans);
        //@(posedge vif.clk);
        /*while(vif.ready == 0) begin
            (@posedge clk_i);
        end*/
        // si le wait ne fonctionne pas, utilisé la while ci-dessus
        //wait(vif.ready == 1);
        @(posedge vif.clk);
        vif.re <= trans.re;
        vif.im <= trans.im;
        vif.phi <= trans.phi;
        vif.iter <= trans.iter;
        /*vif.valid <= 1;
        @(posedge vif.clk);
        vif.valid <= 0;*/
    endtask : driver

endclass : cordic_driver

class cordic_monitor extends uvm_monitor;

    // Virtual Interface
    virtual cordic_out_if.mon vif;

    // this line is used to connect to our scoreboard
    uvm_analysis_port #(cordic_out_transaction) out;

    // Placeholder to capture transaction information.
    //cordic_out_transaction trans;
    
    // tie our component to the UVM 'factory'
    `uvm_component_utils(cordic_monitor)

    // new - constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
        out = new("out", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual cordic_out_if.mon)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
    endfunction: build_phase

    // run phase
    virtual task run_phase(uvm_phase phase);
      forever begin
        cordic_out_transaction trans;
        @(posedge vif.clk);
        trans.re = vif.re;
        trans.im = vif.im;
        trans.phi = vif.phi;
        //trans.ready = vif.ready;
        //trans.valid = vif.valid;
        //finally send it to the scoreboard or whoever is listening
        out.write(trans);
      end;
    endtask : run_phase

endclass : cordic_monitor

class cordic_agent extends uvm_agent;
  //declaring agent components
  cordic_driver    driver;
  cordic_sequencer sequencer;
  cordic_monitor   monitor;

  // UVM automation macros for general components
  `uvm_component_utils(cordic_agent)

  // constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  // build_phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(get_is_active() == UVM_ACTIVE) begin
      driver = cordic_driver::type_id::create("driver", this);
      sequencer = cordic_sequencer::type_id::create("sequencer", this);
    end

    monitor = cordic_monitor::type_id::create("monitor", this);
  endfunction : build_phase

  // connect_phase
  function void connect_phase(uvm_phase phase);
    if(get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction : connect_phase

endclass : cordic_agent

class cordic_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(cordic_scoreboard)

  uvm_analysis_imp#(cordic_in_transaction, cordic_scoreboard) in;
  uvm_analysis_imp#(cordic_out_transaction, cordic_scoreboard) out;

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
  virtual function void write(cordic_in_transaction pkt);
    $display("SCB:: Pkt recived");
    //pkt.print();
  endfunction : write

  virtual function void write(cordic_out_transaction pkt);
    $display("SCB:: Pkt recived");
    //pkt.print();
  endfunction : write

endclass : cordic_scoreboard