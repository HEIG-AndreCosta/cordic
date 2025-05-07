class pre_test_sequence extends uvm_sequence;
	`uvm_object_utils (pre_test_sequence)

	function new (string name = "pre_test_sequence");
		super.new (name);
	endfunction

	task body ();
		pre_in_item req = pre_in_item::type_id::create("req");
        start_item(req);
        req.trans.re = 12'sd(-1000);
        req.trans.im = 12'sd(-1500);
        finish_item(req);
        `uvm_info("SEQ", $sformatf("Sent RE=%0d IM=%0d",req.trans.re, req.trans.im), UVM_LOW)
	endtask
endclass