`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

typedef struct packed {
    logic [11:0] re;
    logic [11:0] im;
} pre_in_transaction;

typedef struct packed {
    logic [11:0] re;
    logic [11:0] im;
    logic [1:0]  original_quadrant_id;
    logic        signals_exchanged;
} pre_out_transaction;

class pre_in_item extends uvm_sequence_item;
  rand pre_in_transaction trans;

  `uvm_object_utils(pre_in_item)
  function new(string name="pre_in_item"); super.new(name); endfunction
endclass

class pre_sequencer extends uvm_sequencer#(pre_in_item);

   `uvm_component_utils(pre_sequencer)
     
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //add your sequence here

endclass : pre_sequencer

class pre_driver extends uvm_driver#(pre_in_item);

    // Virtual Interface
    virtual pre_in_if.drv vif;

    // tie our component to the UVM 'factory'
    `uvm_component_utils(pre_driver)

    uvm_analysis_port #(pre_in_transaction) out;

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
        forever begin
            seq_item_port.get_next_item(req);
            pre_in_transaction trans = req.trans;
            //respond_to_transfer(req);
            driver(trans);
            seq_item_port.item_done();
            out.write(trans);
        end
    endtask : run_phase

    // driver 
    virtual task driver(pre_in_transaction trans);
        @(posedge vif.clk);
        vif.re <= trans.re;
        vif.im <= trans.im;
    endtask : driver

endclass : pre_driver

class pre_monitor extends uvm_monitor;

    // Virtual Interface
    virtual pre_out_if.mon vif;

    // this line is used to connect to our scoreboard
    uvm_analysis_port #(pre_out_transaction) out;

    // Placeholder to capture transaction information.
    //pre_out_transaction trans;
    
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
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
    endfunction: build_phase

    // run phase
    virtual task run_phase(uvm_phase phase);
        forever begin
            pre_out_transaction trans;
            @(posedge vif.clk);
            trans.re = vif.re;
            trans.im = vif.im;
            trans.original_quadrant_id = vif.original_quadrant_id;
            trans.signals_exchanged = vif.signals_exchanged;
            //finally send it to the scoreboard or whoever is listening
            out.write(trans);
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

  `uvm_component_utils(pre_scoreboard)

  uvm_analysis_imp#(pre_in_transaction, pre_scoreboard) in;
  uvm_analysis_imp#(pre_out_transaction, pre_scoreboard) out;

  uvm_tlm_analysis_fifo #(pre_in_transaction ) in_fifo ;
  uvm_tlm_analysis_fifo #(pre_out_transaction) out_fifo;

  // new - constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    in = new("in", this);
    out = new("out", this);

    in_fifo  = new("in_fifo" , this);
    out_fifo = new("out_fifo", this);
  endfunction: build_phase
  
  // write
  virtual function void write(pre_in_transaction pkt);
    in_fifo.write(pkt);
  endfunction : write

  virtual function void write(pre_out_transaction pkt);
    out_fifo.write(pkt);
  endfunction : write

  virtual task run_phase(uvm_phase phase);
    forever begin 
      pre_in_transaction  input;
      pre_out_transaction reference = '{default:0};
      pre_out_transaction result;

      in_fifo.get(input);
      out_fifo.get(result);
      
      bit signed [11:0] s_re = $signed(input.re);
      bit signed [11:0] s_im = $signed(input.im);

      case ({s_re[11], s_im[11]})
        2'b00 : reference.original_quadrant_id = 2'd0;
        2'b10 : reference.original_quadrant_id = 2'd1;
        2'b11 : reference.original_quadrant_id = 2'd2;
        2'b01 : reference.original_quadrant_id = 2'd3;
      endcase

      bit [11:0] abs_re = s_re[11] ? -s_re : s_re;
      bit [11:0] abs_im = s_im[11] ? -s_im : s_im;

      if (abs_im > abs_re) begin
        reference.re  = abs_im;
        reference.im  = abs_re;
        reference.signals_exchanged = 1'b1;
      end
      else begin
        reference.re  = abs_re;
        reference.im  = abs_im;
        reference.signals_exchanged = 1'b0;
      end

      if(reference == result) begin
        `uvm_info(get_type_name(), $sformatf("PASS! re=%0d im=%0d", result.re, result.im), UVM_LOW)
      end
      else begin
        `uvm_error (get_type_name(), $sformatf("ERROR! \nreference = %p\nresult = %p", reference, result))
      end
    end
  endtask

endclass : pre_scoreboard