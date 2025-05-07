interface pre_in_if(input bit clk);
    logic[11:0] re;
    logic[11:0] im;

    // to add in the vhdl code
    //logic valid;
    //logic ready;

    /*modport drv (output re, im, valid,
               input  ready,
               input clk);*/
    modport drv (output re, im,
               input clk);
endinterface

interface pre_out_if(input bit clk);
    logic[11:0] re;
    logic[11:0] im;
    logic[1:0] original_quadrant_id;
    logic signals_exchanged;

    // to add in the vhdl code
    //logic valid;
    //logic ready;

    /*modport mon (input  re, im,
                      original_quadrant_id,
                      signals_exchanged,
                      valid, ready,
                 input  clk);*/
    modport mon (input  re, im,
                      original_quadrant_id,
                      signals_exchanged,
                 input  clk);

endinterface