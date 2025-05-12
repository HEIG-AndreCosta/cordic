`timescale 1ns/1ps
`include "uvm_macros.svh"
package cordic_pkg_sv;
    import uvm_pkg::*;
    
    // Déclaration des signaux d'entrée et de sortie pour chaque bloc
    typedef struct packed {
        logic signed [11:0] re;
        logic signed [11:0] im;
        logic signed [10:0] phi;
        logic[3:0] iter;
    } cordic_iteration_in_transaction;

    typedef struct packed {
        logic signed [11:0] re;
        logic signed [11:0] im;
        logic signed [10:0] phi;
    } cordic_iteration_out_transaction;

    typedef struct packed {
        logic[11:0] re;
        logic[11:0] im;
        logic[1:0] original_quadrant_id;
        logic signals_exchanged;
        logic[10:0] phi;
    } post_in_transaction;

    typedef struct packed {
        logic[11:0] amp;
        logic[10:0] phi;
    } post_out_transaction;

    typedef struct packed {
        logic signed [11:0] re;
        logic signed [11:0] im;
        logic [2:0] octant;
    } pre_in_transaction;

    typedef struct packed {
        logic signed [11:0] re;
        logic signed [11:0] im;
        logic [1:0]  original_quadrant_id;
        logic        signals_exchanged;
    } pre_out_transaction;

    typedef logic [10:0] alpha_value_t;   
    typedef alpha_value_t alpha_values_array_t [1:10];
    localparam alpha_values_array_t alpha_values_c = '{
        11'b00100101110,
        11'b00010100000,
        11'b00001010001,
        11'b00000101001,
        11'b00000010100,
        11'b00000001010,
        11'b00000000101,
        11'b00000000011,
        11'b00000000001,
        11'b00000000001
    };

    // Coverage vérifiant que chaque octant est testé
    covergroup all_octant (ref bit [2:0] oct_ref);
  		coverpoint oct_ref {
  		  bins all[] = {[0:7]};
  		}
	endgroup

    // Coverage vérifiant que toutes les projections fonctionne
    covergroup post_cg (ref bit [1:0] original_quadrant_id, ref bit signals_exchanged);
  		coverpoint original_quadrant_id {
  		  bins all[] = {[0:3]};
  		}
        coverpoint signals_exchanged {
  		  bins all[] = {[0:1]};
  		}
        cross original_quadrant_id, signals_exchanged;
	endgroup

    // Coverage vérifiant que chaque itération est testée
    covergroup cordic_iteration_cg (ref bit [3:0] iter);
  		coverpoint iter {
  		  bins all[] = {[1:10]};
        }
	endgroup

    // PI
    localparam int PI_C       = 11'd1024;
    localparam int PI_HALF_C  = 11'd512; 

    // Item pour faire de la randomisation dans les séquence du pre_traitement
    class octant_item extends uvm_sequence_item;
        rand bit signed [11:0] re, im;
        rand bit [2:0] octant;
        bit signed [12:0] abs_re, abs_im;

        localparam int MAX = 2047;
        localparam int MIN = -2048;
        
        constraint range {
            re inside {[MIN:MAX]};
            im inside {[MIN:MAX]};
        };

        // Défini les octant en fonction des valeurs réels et imaginaires
        constraint my_octant {
            // Premier quadrant
            (re >= 0 && im >= 0 && (abs_re >= abs_im)) == (octant == 0);
            (re >= 0 && im >= 0 && (abs_re  < abs_im)) == (octant == 1);
            
            // Deuxième quadrant
            (re < 0 && im >= 0 && (abs_re  < abs_im)) == (octant == 2);
            (re < 0 && im >= 0 && (abs_re >= abs_im)) == (octant == 3);
            
            // Troisième quadrant
            (re < 0 && im <  0 && (abs_re >= abs_im)) == (octant == 4);
            (re < 0 && im <  0 && (abs_re  < abs_im)) == (octant == 5);
            
            // Quatrième quadrant
            (re >= 0 && im <  0 && (abs_re  < abs_im)) == (octant == 6);
            (re >= 0 && im <  0 && (abs_re >= abs_im)) == (octant == 7);
        };

        // Valeur absolue de re et im (Fonction exécutée dès le call d'une randomisation)
        function void post_randomize();
            abs_re = (re < 0) ? -re : re;
            abs_im = (im < 0) ? -im : im;
        endfunction

        // Déclare l'objet dans la factory UVM
        `uvm_object_utils(octant_item)
        function new(string name="octant_item"); super.new(name); endfunction
    endclass

    // Item pour faire de la randomisation dans les séquences du post_traitement
    class post_item extends uvm_sequence_item;
        rand bit signed [11:0] re, im;
        rand bit [1:0] original_quadrant;
        rand bit signals_exchanged;
        rand bit signed [10:0] phi;
        
        localparam int MAX = 2047;
        localparam int MIN = -2048;
        
        constraint range {
            re inside {[MIN:MAX]};
            im inside {[MIN:MAX]};
            phi inside {[MIN/2:MAX/2]};
        };

        // Déclare l'objet dans la factory UVM
        `uvm_object_utils(post_item)
        function new(string name="post_item"); super.new(name); endfunction
    endclass

    // Item pour faire de la randomisation dans les séquences du cordic_itération_traitement
    class cordic_iteration_item extends uvm_sequence_item;
        rand bit signed [11:0] re, im;
        rand bit signed [10:0] phi;
        rand bit [3:0] iter;
        
        localparam int MAX = 2047;
        localparam int MIN = -2048;
        
        constraint range {
            re inside {[MIN:MAX]};
            im inside {[MIN:MAX]};
            phi inside {[MIN/2:MAX/2]};
            iter inside {[1:10]};
        };

        // Contrainte affiramnt que le
        constraint re_bigger_im {
            (iter == 1) -> abs(re) >= abs(im);
        };

        static function int abs (bit signed [11:0] v);
            return v < 0 ? -v : v;
        endfunction

        // Déclare l'objet dans la factory UVM
        `uvm_object_utils(cordic_iteration_item)
        function new(string name="cordic_iteration_item"); super.new(name); endfunction
    endclass

    // Item pour faire les transaction du sequencer au driver
    class pre_in_item extends uvm_sequence_item;
        rand pre_in_transaction trans;

        // Déclare l'objet dans la factory UVM
        `uvm_object_utils(pre_in_item)
        function new(string name="pre_in_item"); super.new(name); endfunction
    endclass

    // Item pour faire les transaction du sequencer au driver
    class post_in_item extends uvm_sequence_item;
        rand post_in_transaction trans;

        // Déclare l'objet dans la factory UVM
        `uvm_object_utils(post_in_item)
        function new(string name="post_in_item"); super.new(name); endfunction
    endclass

    // Item pour faire les transaction du sequencer au driver
    class cordic_iteration_in_item extends uvm_sequence_item;
        rand cordic_iteration_in_transaction trans;

        // Déclare l'objet dans la factory UVM
        `uvm_object_utils(cordic_iteration_in_item)
        function new(string name="cordic_iteration_in_item"); super.new(name); endfunction
    endclass

    // Item pour faire les transaction du driver/monitor au scoreboard
    class cordic_iteration_io_item extends uvm_sequence_item;
        `uvm_object_utils(cordic_iteration_io_item)

        cordic_iteration_in_transaction  in;
        cordic_iteration_out_transaction out;

        // constructor
        function new(string name = "cordic_iteration_io_item");
          super.new(name);
          in  = '{default:'x};
          out = '{default:'x};
        endfunction
    endclass : cordic_iteration_io_item

    // Item pour faire les transaction du driver/monitor au scoreboard
    class post_io_item extends uvm_sequence_item;
        `uvm_object_utils(post_io_item)

        post_in_transaction  in;
        post_out_transaction out;

        // constructor
        function new(string name = "post_io_item");
          super.new(name);
          in  = '{default:'x};
          out = '{default:'x};
        endfunction
    endclass : post_io_item

    // Item pour faire les transaction du driver/monitor au scoreboard
    class pre_io_item extends uvm_sequence_item;
        `uvm_object_utils(pre_io_item)

        pre_in_transaction  in;
        pre_out_transaction out;

        // constructor
        function new(string name = "pre_io_item");
          super.new(name);
          in  = '{default:'x};
          out = '{default:'x};
        endfunction
    endclass : pre_io_item

    // Calcul du bloc d'itération
    function cordic_iteration_out_transaction cordic_iter_calculus (input cordic_iteration_in_transaction in, cordic_iteration_out_transaction reference);
        automatic bit signed [11:0] tmp = reference.re;
        // négatif
        if(in.im[11]) begin
          // shift right : >> for unsigned, >>> for signed
          reference.re = reference.re - (reference.im >>> in.iter);
          reference.im = reference.im + (tmp >>> in.iter);
          reference.phi = reference.phi - alpha_values_c[in.iter];
        end
        //positif
        else begin
          reference.re = reference.re + (reference.im >>> in.iter);
          reference.im = reference.im - (tmp >>> in.iter);
          reference.phi = reference.phi + alpha_values_c[in.iter];
        end
        return reference;
    endfunction

    // Calcul du bloc de psot-traitement
    function post_out_transaction post_calculus(input post_in_transaction in, post_out_transaction reference);
        reference.phi = in.phi;
        if(in.signals_exchanged) begin
            reference.phi = PI_HALF_C - in.phi;
        end

        case (in.original_quadrant_id)
            //Premier
            2'b00 : reference.phi = reference.phi;
            //Deuxième
            2'b10 : reference.phi = PI_C - reference.phi;
            //Troisième
            2'b11 : reference.phi = reference.phi + PI_C;
            //Quatrième
            2'b01 : reference.phi = -reference.phi;
        endcase;

        reference.amp = in.re;
        return reference;
    endfunction

    // Calcul du bloc de pré-traitement
    function automatic pre_out_transaction pre_calculus (input pre_in_transaction in, pre_out_transaction reference);
        automatic bit signed [11:0] s_re;
        automatic bit signed [11:0] s_im;
        automatic bit signed [11:0] abs_re;
        automatic bit signed [11:0] abs_im; 

        s_re = in.re;
        s_im = in.im;

        reference.original_quadrant_id = {s_re[11], s_im[11]};

        abs_re = s_re[11] ? -s_re : s_re;
        abs_im = s_im[11] ? -s_im : s_im;

        if (abs_im > abs_re) begin
            reference.re  = abs_im;
            reference.im  = abs_re;
            reference.signals_exchanged = 1'b1;
        end
        else begin
            reference.re  = abs_re;
            reference.im  = abs_im;
            reference.signals_exchanged = 1'b0;
        end
        return reference;
    endfunction

endpackage : cordic_pkg_sv