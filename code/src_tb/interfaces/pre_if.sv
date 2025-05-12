interface pre_in_if(input bit clk);
    logic signed[11:0] re;
    logic signed[11:0] im;

    modport drv (output re, im,
               input clk);
endinterface

interface pre_out_if(input bit clk);
    logic signed[11:0] re;
    logic signed[11:0] im;
    logic[1:0] original_quadrant_id;
    logic signals_exchanged;

    modport mon (input  re, im,
                      original_quadrant_id,
                      signals_exchanged,
                 input  clk);

endinterface