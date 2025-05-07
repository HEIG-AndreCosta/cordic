interface cordic_in_if(input bit clk);
    logic[11:0] re;
    logic[11:0] im;
    logic[10:0] phi;
    logic[3:0] iter;

    // to add in the vhdl code
    //logic valid;
    //logic ready;

    /*modport drv (output re, im, phi, iter, valid,
               input  ready,
               input clk);*/
    modport drv (output re, im, phi, iter,
               input clk);
endinterface

interface cordic_out_if(input bit clk);
    logic[11:0] re;
    logic[11:0] im;
    logic[10:0] phi;

    // to add in the vhdl code
    //logic valid;
    //logic ready;

    /*modport mon (input  re, im, phi, valid, ready,
                 input  clk);*/
    modport mon (input  re, im, phi,
                 input  clk);
endinterface