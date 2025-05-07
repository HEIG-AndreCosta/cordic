interface post_in_if(input bit clk);
    logic[11:0] re;
    logic[11:0] im;
    logic[1:0] original_quadrant_id;
    logic signals_exchanged;
    logic[10:0] phi;

    modport drv (output re, im, original_quadrant_id, signals_exchanged, phi,
               input clk);
endinterface

interface post_out_if(input bit clk);
    logic[11:0] amp;
    logic[10:0] phi;

    modport mon (input  amp, phi,
                 input  clk);
endinterface