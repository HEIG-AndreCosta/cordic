`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import cordic_pkg_sv::*;

// Sequence to send to the sequencer
class cordic_iteration_sequence extends uvm_sequence;
	// register to the 'factory'
	`uvm_object_utils (cordic_iteration_sequence)

	function new (string name = "cordic_iteration_sequence");
		super.new (name);
	endfunction

	int unsigned N_test = 100;

	task body ();
		// ressource to send
		cordic_iteration_in_item req;
		// ressource generated
		cordic_iteration_item cordic_iteration = cordic_iteration_item::type_id::create("cordic_iteration");
		repeat (N_test) begin
			req = cordic_iteration_in_item::type_id::create("req");
        	start_item(req);
			assert(cordic_iteration.randomize())
        		else `uvm_fatal("ITER_SEQ", "Randomization failed");
        	req.trans.re = cordic_iteration.re;
        	req.trans.im = cordic_iteration.im;
            req.trans.phi = cordic_iteration.phi;
            req.trans.iter = cordic_iteration.iter;
        	finish_item(req);

        	//`uvm_info("ITER_SEQ", $sformatf("Sent RE=%0d, IM=%0d, ITER=%0d, PHI=%0d,", req.trans.re, req.trans.im, req.trans.iter, req.trans.phi), UVM_LOW)
		end
	endtask
endclass