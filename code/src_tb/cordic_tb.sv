

interface cordic_in_if;
    logic[11:0] re;
    logic[11:0] im;
    logic valid;
    logic ready;
endinterface

interface cordic_out_if;
    logic[11:0] amp;
    logic[10:0] phi;
    logic valid;
    logic ready;
endinterface
    
module cordic_tb#(int TESTCASE = 0);

    const real PI = $asin(1) * 2;

    logic clk = 0;
    logic rst = 0;

    default clocking cb @(posedge clk);
    endclocking

    // clock generation
    always #10 clk = ~clk;

    cordic_in_if in_if();
    cordic_out_if out_if();

    cordic duv(
        .clk_i(clk),
        .rst_i(rst),
        .re_i(in_if.re),
        .im_i(in_if.im),
        .amp_o(out_if.amp),
        .phi_o(out_if.phi),
        .ready_o(in_if.ready),
        .valid_i(in_if.valid),
        .ready_i(out_if.ready),
        .valid_o(out_if.valid)
    );


    initial begin
        in_if.re = 0;
        in_if.im = 0;
        in_if.valid = 0;
        out_if.ready = 1;
        rst = 1;
        ##2;
        rst = 0;
        // Do something
        ##10;
    end


endmodule
