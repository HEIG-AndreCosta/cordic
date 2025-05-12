`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
import cordic_pkg_sv::*;

// Sequence to send to the sequencer
class post_sequence extends uvm_sequence;
	// register to the 'factory'
	`uvm_object_utils (post_sequence)

	function new (string name = "post_sequence");
		super.new (name);
	endfunction

	int unsigned N_test = 100;

	task body ();
		// ressource to send
		post_in_item req;
		// ressource generated
		post_item post = post_item::type_id::create("post");
		repeat (N_test) begin
			req = post_in_item::type_id::create("req");
        	start_item(req);
			assert(post.randomize())
        		else `uvm_fatal("POST_SEQ", "Randomization failed");
        	req.trans.re = post.re;
        	req.trans.im = post.im;
            req.trans.original_quadrant_id = post.original_quadrant;
            req.trans.signals_exchanged = post.signals_exchanged;
            req.trans.phi = post.phi;
        	finish_item(req);
        	//`uvm_info("POST_SEQ", $sformatf("Sent RE=%0d, IM=%0d, QUADRANT=%0d, SIGNALS_EXCHANGED=%0d, PHI=%0d,", req.trans.re, req.trans.im, req.trans.original_quadrant_id, req.trans.signals_exchanged, req.trans.phi), UVM_LOW)
		end
	endtask
endclass