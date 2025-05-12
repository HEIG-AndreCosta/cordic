`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import cordic_pkg_sv::*;

// Sequence to send to the sequencer
class pre_sequence extends uvm_sequence;
	// register to the 'factory'
	`uvm_object_utils (pre_sequence)

	function new (string name = "pre_sequence");
		super.new (name);
	endfunction

	int unsigned N_test = 100;

	task body ();
		// ressource to send
		pre_in_item req;
		// ressource generated
		octant_item oct = octant_item::type_id::create("oct");
		repeat (N_test) begin
			req = pre_in_item::type_id::create("req");
        	start_item(req);
			assert(oct.randomize())
        		else `uvm_fatal("PRE_SEQ", "Randomization failed");
        	req.trans.re = oct.re;
        	req.trans.im = oct.im;
			req.trans.octant = oct.octant;
        	finish_item(req);

        	//`uvm_info("PRE_SEQ", $sformatf("Sent octant=%0d, RE=%0d IM=%0d",oct.octant, req.trans.re, req.trans.im), UVM_LOW)
		end
	endtask
endclass