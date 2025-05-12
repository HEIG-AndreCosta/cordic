`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import cordic_pkg_sv::*;

class post_sequencer extends uvm_sequencer#(post_in_item);
    // tie our component to the UVM 'factory'
    `uvm_component_utils(post_sequencer)
     
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

endclass : post_sequencer

class post_driver extends uvm_driver#(post_in_item);

    // Virtual Interface
    virtual post_in_if.drv vif;

    // tie our component to the UVM 'factory'
    `uvm_component_utils(post_driver)

    uvm_analysis_port #(post_io_item) out;

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
        post_in_transaction trans;
        post_io_item io;
        forever begin
            seq_item_port.get_next_item(req);
            trans = req.trans;
            @(posedge vif.clk);
            vif.re <= trans.re;
            vif.im <= trans.im;
            vif.phi <= trans.phi;
            vif.original_quadrant_id <= trans.original_quadrant_id;
            vif.signals_exchanged <= trans.signals_exchanged;
            seq_item_port.item_done();
            io = post_io_item::type_id::create("io", this);
            io.in = trans;
            out.write(io);
        end
    endtask : run_phase

endclass : post_driver

class post_monitor extends uvm_monitor;

    // Virtual Interface
    virtual post_out_if.mon vif;

    // this line is used to connect to our scoreboard
    uvm_analysis_port #(post_io_item) out;
    
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
          `uvm_fatal("NOVIF", $sformatf("virtual interface must be set for: %s.vif", get_full_name()))    
    endfunction: build_phase

    // run phase
    virtual task run_phase(uvm_phase phase);
      forever begin
        post_out_transaction trans;
        post_io_item io;
        @(posedge vif.clk);
        trans.amp = vif.amp;
        trans.phi = vif.phi;
        //finally send it to the scoreboard or whoever is listening
        io = post_io_item::type_id::create("io", this);
        io.out = trans;
        out.write(io);
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

  // tie our component to the UVM 'factory'
  `uvm_component_utils(post_scoreboard)

  // listen to the port connected to driver/monitor
  uvm_analysis_imp#(post_io_item, post_scoreboard) in;

  uvm_tlm_analysis_fifo #(post_in_transaction ) in_fifo ;
  uvm_tlm_analysis_fifo #(post_out_transaction) out_fifo;

  // report data
  int unsigned total_pass = 0;
  int unsigned total_failed = 0;
  post_cg all_combination;

  // new - constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    in = new("in", this);

    in_fifo  = new("in_fifo" , this);
    out_fifo = new("out_fifo", this);
  endfunction: build_phase
  
  // write
  virtual function void write(post_io_item pkt);
    if(pkt.in.re !== 'x) begin
      in_fifo.write(pkt.in);
    end
    if(pkt.out.amp !== 'x) begin
      out_fifo.write(pkt.out);
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    post_in_transaction  in;
    post_out_transaction reference = '{default:0};
    post_out_transaction result;
    bit [1:0] original_quadrant_id;
    bit signals_exchanged;
    //coverage
    all_combination = new(original_quadrant_id, signals_exchanged);

    // Comparaison des valeurs reçue (Attendu - Résultat)
    forever begin 
      in_fifo.get(in);
      out_fifo.get(result);
      
      reference = post_calculus(in, reference);
      original_quadrant_id = in.original_quadrant_id;
      signals_exchanged = in.signals_exchanged;
      all_combination.sample();
      if(reference == result) begin
        total_pass++;
        //`uvm_info("PRE_SCB", $sformatf("PASS! amp=%0d phi=%0d", result.amp, result.phi), UVM_LOW)
      end
      else begin
        total_failed++;
        `uvm_error("PRE_SCB", $sformatf("ERROR! reference=%p result=%p", reference, result))      
      end
    end
  endtask

  // Beau report affiché
  function void report_phase(uvm_phase phase);
    real cov = (all_combination == null) ? 0.0 : all_combination.get_inst_coverage();
    string line;
    line = "\n************  POST  SUMMARY  ************\n";
    line = {line, $sformatf(" Number of Transactions : %0d\n", total_pass + total_failed)};
    line = {line, $sformatf(" Total Coverage         : %0.2f %%\n", cov)};
    line = {line, $sformatf(" Test Passed            : %0d\n", total_pass)};
    line = {line, $sformatf(" Test Failed            : %0d\n", total_failed)};
    line = {line,   "*********************************************"};
    `uvm_info("POST_SUMMARY", line, UVM_NONE)
  endfunction

endclass : post_scoreboard