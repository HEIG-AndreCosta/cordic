`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import cordic_pkg_sv::*;

class pre_sequencer extends uvm_sequencer#(pre_in_item);
    // tie our component to the UVM 'factory'
   `uvm_component_utils(pre_sequencer)
     
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

endclass : pre_sequencer

class pre_driver extends uvm_driver#(pre_in_item);

    // Virtual Interface
    virtual pre_in_if.drv vif;

    // tie our component to the UVM 'factory'
    `uvm_component_utils(pre_driver)

    uvm_analysis_port #(pre_io_item) out;

    // Constructor
    function new (string name, uvm_component parent);
      super.new(name, parent);
      out = new("out", this);
    endfunction : new

    //get the interface handle from the uvm config
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
       if(!uvm_config_db#(virtual pre_in_if.drv)::get(this, "", "vif", vif))
         `uvm_fatal("NO_VIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
    endfunction: build_phase

    // run phase
    virtual task run_phase(uvm_phase phase);
        pre_in_item req;
        pre_in_transaction trans;
        pre_io_item io;
        forever begin
            seq_item_port.get_next_item(req);
            trans = req.trans;
            @(posedge vif.clk);
            vif.re <= trans.re;
            vif.im <= trans.im;
            seq_item_port.item_done();
            io = pre_io_item::type_id::create("io", this);
            io.in = trans;
            out.write(io);
        end
    endtask : run_phase

    // driver 
    virtual task driver(pre_in_transaction trans);

    endtask : driver

endclass : pre_driver

class pre_monitor extends uvm_monitor;

    // Virtual Interface
    virtual pre_out_if.mon vif;

    // this line is used to connect to our scoreboard
    uvm_analysis_port #(pre_io_item) out;

    // tie our component to the UVM 'factory'
    `uvm_component_utils(pre_monitor)

    // new - constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
        out = new("out", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual pre_out_if.mon)::get(this, "", "vif", vif))
          `uvm_fatal("NOVIF", $sformatf("virtual interface must be set for: %s.vif", get_full_name()))    
    endfunction: build_phase

    // run phase
    virtual task run_phase(uvm_phase phase);
        forever begin
            pre_out_transaction trans;
            pre_io_item io;
            @(posedge vif.clk);
            trans.re = vif.re;
            trans.im = vif.im;
            trans.original_quadrant_id = vif.original_quadrant_id;
            trans.signals_exchanged = vif.signals_exchanged;
            //finally send it to the scoreboard or whoever is listening
            io = pre_io_item::type_id::create("io", this);
            io.out = trans;
            out.write(io);
        end
    endtask : run_phase

endclass : pre_monitor

class pre_agent extends uvm_agent;
  //declaring agent components
  pre_driver    driver;
  pre_sequencer sequencer;
  pre_monitor   monitor;

  // UVM automation macros for general components
  `uvm_component_utils(pre_agent)

  // constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  // build_phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(get_is_active() == UVM_ACTIVE) begin
      driver = pre_driver::type_id::create("driver", this);
      sequencer = pre_sequencer::type_id::create("sequencer", this);
    end

    monitor = pre_monitor::type_id::create("monitor", this);
  endfunction : build_phase

  // connect_phase
  function void connect_phase(uvm_phase phase);
    if(get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction : connect_phase

endclass : pre_agent

class pre_scoreboard extends uvm_scoreboard;

  // tie our component to the UVM 'factory'
  `uvm_component_utils(pre_scoreboard)

  // listen to the port connected to driver/monitor
  uvm_analysis_imp#(pre_io_item, pre_scoreboard) in;

  uvm_tlm_analysis_fifo #(pre_in_transaction) in_fifo ;
  uvm_tlm_analysis_fifo #(pre_out_transaction) out_fifo;

  // report data
  int unsigned total_pass = 0;
  int unsigned total_failed = 0;
  all_octant all_oct; 

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
  virtual function void write(pre_io_item pkt);
    if(pkt.in.re !== 'x) begin
      in_fifo.write(pkt.in);
    end
    if(pkt.out.re !== 'x) begin
      out_fifo.write(pkt.out);
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    pre_in_transaction  in;
    pre_out_transaction reference = '{default:0};
    pre_out_transaction result;
    bit [2:0] octant;    
    //coverage
    all_oct = new(octant);

    // Comparaison des valeurs reçue (Attendu - Résultat)
    forever begin 
      in_fifo.get(in);
      out_fifo.get(result);

      reference = pre_calculus(in, reference);
      octant = in.octant;
      all_oct.sample();
      if(reference === result) begin
        total_pass++;
        //`uvm_info(get_type_name(), $sformatf("PASS! re=%0d im=%0d", result.re, result.im), UVM_LOW)
      end
      else begin
        total_failed++;
        `uvm_error (get_type_name(), $sformatf("ERROR! \nreference = %p\nresult = %p", reference, result))
      end
    end
  endtask

  // Beau report affiché
  function void report_phase(uvm_phase phase);
    real cov = (all_oct == null) ? 0.0 : all_oct.get_inst_coverage();
    string line;
    line = "\n************  PRE  SUMMARY  ************\n";
    line = {line, $sformatf(" Number of Transactions : %0d\n", total_pass + total_failed)};
    line = {line, $sformatf(" Total Coverage         : %0.2f %%\n", cov)};
    line = {line, $sformatf(" Test Passed            : %0d\n", total_pass)};
    line = {line, $sformatf(" Test Failed            : %0d\n", total_failed)};
    line = {line,   "*********************************************"};
    `uvm_info("PRE_SUMMARY", line, UVM_NONE)
  endfunction

endclass : pre_scoreboard