//https://verificationguide.com/

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
    
    // Variables pour le scoreboard
    int tests_total = 0;
    int tests_passed = 0;
    string architecture_type = "";

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

    // Tache pour envoyer des donnees
    task automatic input_data(logic[11:0] re, logic[11:0] im);
        wait(in_if.ready == 1);
        @(posedge clk);
        in_if.re = re;
        in_if.im = im;
        in_if.valid = 1;
        @(posedge clk);
        in_if.valid = 0;
    endtask

    // Tache pour capturer les donnees de sortie
    task automatic output_capture(output logic[11:0] amp, output logic[10:0] phi);
        wait(out_if.valid == 1);
        @(posedge clk);
        amp = out_if.amp;
        phi = out_if.phi;
    endtask

    // Fonction pour calculer les valeurs attendues
    function automatic void calculate_expected(
        input logic signed [11:0] re_in,
        input logic signed [11:0] im_in,
        output logic [11:0] amp_expected,
        output logic signed [10:0] phi_expected
    );
        // Toutes les declarations doivent etre au debut de la fonction
        logic signed [11:0] re, im;
        logic signed [10:0] phi;
        logic [1:0] original_quadrant_id;
        logic signals_exchanged;
        logic signed [10:0] alpha_values[10];
        logic signed [11:0] temp;
        logic signed [10:0] PI_DIV_2;
        logic signed [10:0] PI_VALUE;
        int i;
        logic signed [11:0] re_old, im_old;
        logic signed [10:0] phi_old;
        logic im_negative;
        logic signed [11:0] re_shift, im_shift;
        
        // Constantes alpha (comme dans le package VHDL)
        alpha_values[0] = 11'b00100101110; // 302
        alpha_values[1] = 11'b00010100000; // 160
        alpha_values[2] = 11'b00001010001; // 81
        alpha_values[3] = 11'b00000101001; // 41
        alpha_values[4] = 11'b00000010100; // 20
        alpha_values[5] = 11'b00000001010; // 10
        alpha_values[6] = 11'b00000000101; // 5
        alpha_values[7] = 11'b00000000011; // 3
        alpha_values[8] = 11'b00000000001; // 1
        alpha_values[9] = 11'b00000000001; // 1
        
        // Etape 1 : Pretraitement
        // Determiner le quadrant d'origine
        original_quadrant_id = {re_in[11], im_in[11]};
        
        // Calcul des valeurs absolues
        re = (re_in[11]) ? -re_in : re_in;
        im = (im_in[11]) ? -im_in : im_in;
        
        // Echange si re > im
        signals_exchanged = 0;
        if (re > im) begin
            temp = re;
            re = im;
            im = temp;
            signals_exchanged = 1;
        end
        
        // Etape 2 : Iterations CORDIC
        phi = 0;
        
        for (i = 1; i <= 10; i++) begin
            re_old = re;
            im_old = im;
            phi_old = phi;
            im_negative = (im[11] == 1);
            
            // Division par 2^i (shift)
            re_shift = re_old >>> i;
            im_shift = im_old >>> i;
            
            if (im_negative) begin
                re = re_old - im_shift;
                im = im_old + re_shift;
                phi = phi_old - alpha_values[i-1];
            end else begin
                re = re_old + im_shift;
                im = im_old - re_shift;
                phi = phi_old + alpha_values[i-1];
            end
        end
        
        // Etape 3 : Projection de l'angle sur les 4 quadrants
        PI_DIV_2 = 11'd512; // 2^9
        PI_VALUE = 11'd1024; // 2^10
        
        // 1. Projection sur le premier quadrant
        if (signals_exchanged) begin
            phi = PI_DIV_2 - phi;
        end
        
        // 2. Projection sur les quatre quadrants
        case (original_quadrant_id)
            2'b00: ; // Premier quadrant : phi = phi (pas de changement)
            2'b10: phi = PI_VALUE - phi; // Deuxieme quadrant
            2'b11: phi = phi + PI_VALUE; // Troisieme quadrant
            2'b01: phi = -phi; // Quatrieme quadrant
        endcase
        
        // Etape 4 : Extraction de l'amplitude
        amp_expected = re[11:0];
        phi_expected = phi;
    endfunction

    // Tache pour effectuer un test complet
    task automatic test_cordic(
        input string test_name,
        input logic signed [11:0] test_re,
        input logic signed [11:0] test_im
    );
        automatic logic [11:0] result_amp;
        automatic logic signed [10:0] result_phi;
        automatic logic [11:0] expected_amp;
        automatic logic signed [10:0] expected_phi;
        automatic real theoretical_amp;
        automatic real theoretical_phi_rad;
        automatic logic signed [10:0] theoretical_phi;
        
        $display("\n--- Test: %s ---", test_name);
        $display("Entrees: re=%0d, im=%0d", test_re, test_im);
        
        // Calculer les valeurs attendues
        calculate_expected(test_re, test_im, expected_amp, expected_phi);
        
        // Calculer les valeurs theoriques
        theoretical_amp = $sqrt($pow($itor(test_re), 2) + $pow($itor(test_im), 2));
        theoretical_phi_rad = $atan2($itor(test_im), $itor(test_re));
        theoretical_phi = theoretical_phi_rad * (1024.0 / PI);
        
        // Envoyer les donnees d'entree
        input_data(test_re, test_im);
        
        // Attendre et capturer les resultats
        output_capture(result_amp, result_phi);
        
        // Afficher la comparaison
        $display("Amplitude - Attendue: %0d, Obtenue: %0d, Theorique: %0.0f", expected_amp, result_amp, theoretical_amp);
        $display("Phase - Attendue: %0d, Obtenue: %0d, Theorique: %0d", expected_phi, result_phi, theoretical_phi);
        
        // Mise à jour du compteur de tests
        tests_total++;
        
        // Verification
        if (result_amp == expected_amp && result_phi == expected_phi) begin
            $display("*** TEST REUSSI ***");
            tests_passed++;
        end else begin
            $display("*** TEST ECHOUE ***");
            $display("Erreur amplitude: %0d", $signed(result_amp - expected_amp));
            $display("Erreur phase: %0d", $signed(result_phi - expected_phi));
        end
    endtask

    // Tâche pour afficher le scoreboard final
    task automatic display_scoreboard();
        $display("\n=== SCOREBOARD FINAL ===");
        $display("Architecture: %s", architecture_type);
        $display("Tests réussis: %0d / %0d", tests_passed, tests_total);
        $display("Pourcentage de réussite: %0.2f%%", (tests_passed * 100.0) / tests_total);
        $display("===================");
    endtask

    initial begin
        // Déterminer l'architecture utilisée
        // Ceci pourrait être fait automatiquement en analysant la configuration
        // Ou pourrait être passé en paramètre par le script de simulation
        case (TESTCASE)
            0: architecture_type = "Combinatoire";
            1: architecture_type = "Pipeline";
            2: architecture_type = "Séquentielle";
            default: architecture_type = "Inconnue";
        endcase
        
        // Initialisation
        in_if.re = 0;
        in_if.im = 0;
        in_if.valid = 0;
        out_if.ready = 1;
        
        // Reset
        rst = 1;
        ##2;
        rst = 0;
        ##10;
        
        $display("=== Test du systeme CORDIC - 8 tests pour tous les quadrants ===");
        $display("Architecture: %s", architecture_type);
        
        // Quadrant 1 (re > 0, im > 0)
        test_cordic("Q1: re > im", 12'd1000, 12'd500);  // re > im
        ##10;
        test_cordic("Q1: im > re", 12'd400, 12'd800);   // im > re
        ##10;
        
        // Quadrant 2 (re < 0, im > 0)
        test_cordic("Q2: |re| > |im|", -12'd900, 12'd600);  // |re| > |im|
        ##10;
        test_cordic("Q2: |im| > |re|", -12'd300, 12'd700);  // |im| > |re|
        ##10;
        
        // Quadrant 3 (re < 0, im < 0)
        test_cordic("Q3: |re| > |im|", -12'd1100, -12'd800);  // |re| > |im|
        ##10;
        test_cordic("Q3: |im| > |re|", -12'd500, -12'd1000);  // |im| > |re|
        ##10;
        
        // Quadrant 4 (re > 0, im < 0)
        test_cordic("Q4: re > |im|", 12'd850, -12'd450);  // re > |im|
        ##10;
        test_cordic("Q4: |im| > re", 12'd600, -12'd950);  // |im| > re
        ##10;
        
        // Afficher le scoreboard final
        display_scoreboard();
        
        $display("\n=== Fin des tests ===");
        #100;
        $finish;
    end

endmodule