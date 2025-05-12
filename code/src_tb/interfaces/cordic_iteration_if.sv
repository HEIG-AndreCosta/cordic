interface cordic_iteration_in_if(input bit clk);
    logic[11:0] re;
    logic[11:0] im;
    logic[10:0] phi;
    logic[3:0] iter;

    modport drv (output re, im, phi, iter,
               input clk);
endinterface

interface cordic_iteration_out_if(input bit clk);
    logic[11:0] re;
    logic[11:0] im;
    logic[10:0] phi;

    modport mon (input  re, im, phi,
                 input  clk);
endinterface