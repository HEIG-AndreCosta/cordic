`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import cordic_pkg_sv::*;

class cordic_iteration_sequencer extends uvm_sequencer#(cordic_iteration_in_item);
    // tie our component to the UVM 'factory'
   `uvm_component_utils(cordic_iteration_sequencer)
     
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

endclass : cordic_iteration_sequencer

class cordic_iteration_driver extends uvm_driver#(cordic_iteration_in_item);

    // Virtual Interface
    virtual cordic_iteration_in_if.drv vif;

    // tie our component to the UVM 'factory'
    `uvm_component_utils(cordic_iteration_driver)

    uvm_analysis_port #(cordic_iteration_io_item) out;

    // Constructor
    function new (string name, uvm_component parent);
      super.new(name, parent);
      out = new("out", this);
    endfunction : new

    //get the interface handle from the uvm config
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
       if(!uvm_config_db#(virtual cordic_iteration_in_if.drv)::get(this, "", "vif", vif))
         `uvm_fatal("NO_VIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
    endfunction: build_phase

    // run phase
    virtual task run_phase(uvm_phase phase);
        cordic_iteration_in_item req;
        cordic_iteration_in_transaction trans;
        cordic_iteration_io_item io;
        forever begin
            seq_item_port.get_next_item(req);
            trans = req.trans;
            @(posedge vif.clk);
            vif.re <= trans.re;
            vif.im <= trans.im;
            vif.phi <= trans.phi;
            vif.iter <= trans.iter;
            seq_item_port.item_done();
            io = cordic_iteration_io_item::type_id::create("io", this);
            io.in = trans;
            out.write(io);
        end
    endtask : run_phase

endclass : cordic_iteration_driver

class cordic_iteration_monitor extends uvm_monitor;

    // Virtual Interface
    virtual cordic_iteration_out_if.mon vif;

    // this line is used to connect to our scoreboard
    uvm_analysis_port #(cordic_iteration_io_item) out;
    
    // tie our component to the UVM 'factory'
    `uvm_component_utils(cordic_iteration_monitor)

    // new - constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
        out = new("out", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual cordic_iteration_out_if.mon)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
    endfunction: build_phase

    // run phase
    virtual task run_phase(uvm_phase phase);
      forever begin
        cordic_iteration_out_transaction trans;
        cordic_iteration_io_item io;
        @(posedge vif.clk);
        trans.re = vif.re;
        trans.im = vif.im;
        trans.phi = vif.phi;
        //finally send it to the scoreboard or whoever is listening
        io = cordic_iteration_io_item::type_id::create("io", this);
        io.out = trans;
        out.write(io);
      end;
    endtask : run_phase

endclass : cordic_iteration_monitor

class cordic_iteration_agent extends uvm_agent;
  //declaring agent components
  cordic_iteration_driver    driver;
  cordic_iteration_sequencer sequencer;
  cordic_iteration_monitor   monitor;

  // UVM automation macros for general components
  `uvm_component_utils(cordic_iteration_agent)

  // constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  // build_phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(get_is_active() == UVM_ACTIVE) begin
      driver = cordic_iteration_driver::type_id::create("driver", this);
      sequencer = cordic_iteration_sequencer::type_id::create("sequencer", this);
    end

    monitor = cordic_iteration_monitor::type_id::create("monitor", this);
  endfunction : build_phase

  // connect_phase
  function void connect_phase(uvm_phase phase);
    if(get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction : connect_phase

endclass : cordic_iteration_agent

class cordic_iteration_scoreboard extends uvm_scoreboard;

  // tie our component to the UVM 'factory'
  `uvm_component_utils(cordic_iteration_scoreboard)

  // listen to the port connected to driver/monitor
  uvm_analysis_imp#(cordic_iteration_io_item, cordic_iteration_scoreboard) in;

  uvm_tlm_analysis_fifo #(cordic_iteration_in_transaction) in_fifo ;
  uvm_tlm_analysis_fifo #(cordic_iteration_out_transaction) out_fifo;

  // report data
  int unsigned total_pass = 0;
  int unsigned total_failed = 0;
	cordic_iteration_cg all_iter;

  // new - constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    in  = new("in",  this);

    in_fifo  = new("in_fifo" , this);
    out_fifo = new("out_fifo", this);
  endfunction: build_phase
  
  // write
  virtual function void write(cordic_iteration_io_item pkt);
    if(pkt.in.re !== 'X) begin
      in_fifo.write(pkt.in);
    end
    if(pkt.out.re !== 'X) begin
      out_fifo.write(pkt.out);
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    cordic_iteration_in_transaction  in;
    cordic_iteration_out_transaction reference = '{default:0};
    cordic_iteration_out_transaction result;
    bit [3:0] iter;
    //coverage
    all_iter = new(iter);
    
    // Comparaison des valeurs reçue (Attendu - Résultat)
    forever begin 
      in_fifo.get(in);
      out_fifo.get(result);

      reference.re = in.re;
      reference.im = in.im;
      reference.phi = in.phi;

      reference = cordic_iter_calculus(in, reference);
      iter = in.iter;
      all_iter.sample();
      if(reference === result) begin
        total_pass++;
        //`uvm_info(get_type_name(), $sformatf("PASS! re=%0d im=%0d, phi=%0d", result.re, result.im, result.phi), UVM_LOW)
      end
      else begin
        total_failed++;
        `uvm_error (get_type_name(), $sformatf("ERROR! \nreference = %p\nresult = %p", reference, result))
      end
    end
  endtask

  // Beau report affiché
  function void report_phase(uvm_phase phase);
    real cov = (all_iter == null) ? 0.0 : all_iter.get_inst_coverage();
    string line;
    line = "\n************  ITERATION  SUMMARY  ************\n";
    line = {line, $sformatf(" Number of Transactions : %0d\n", total_pass + total_failed)};
    line = {line, $sformatf(" Total Coverage         : %0.2f %%\n", cov)};
    line = {line, $sformatf(" Test Passed            : %0d\n", total_pass)};
    line = {line, $sformatf(" Test Failed            : %0d\n", total_failed)};
    line = {line,   "*********************************************"};
    `uvm_info("ITERATION_SUMMARY", line, UVM_NONE)
  endfunction

endclass : cordic_iteration_scoreboard