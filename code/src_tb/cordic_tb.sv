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

    // Tâche pour envoyer des données d'entrée
    task automatic input_data(logic signed [11:0] re, logic signed [11:0] im);
        // Attendre que le système soit prêt
        wait(in_if.ready == 1);
        @(posedge clk);
        in_if.re = re;
        in_if.im = im;
        in_if.valid = 1;
        @(posedge clk);
        in_if.valid = 0;
    endtask

    // Tâche pour capturer les données de sortie
    task automatic output_capture(output logic signed [11:0] amp, output logic signed [10:0] phi);
        wait(out_if.valid == 1);
        @(posedge clk);
        amp = out_if.amp;
        phi = out_if.phi;
    endtask

    // Fonction pour convertir l'angle de CORDIC en radians
    function real cordic_to_rad(logic signed [10:0] phi);
        // Conversion selon la spécification : plage binaire complète = [-π, π]
        return real'(phi) * PI / (2.0**10);
    endfunction

    // Fonction pour calculer l'amplitude attendue
    function real expected_amp(real re, real im);
        return $sqrt(re*re + im*im);
    endfunction

    // Fonction pour calculer la phase attendue
    function real expected_phase(real re, real im);
        return $atan2(im, re);
    endfunction

    // Fonction pour calculer la valeur absolue (remplacement de $abs)
    function real abs_real(real value);
        if (value < 0)
            return -value;
        else
            return value;
    endfunction

    // Tâche de test avec vérification
    task automatic test_cordic(logic signed [11:0] re, logic signed [11:0] im);
        real expected_amplitude, expected_angle;
        real actual_amplitude, actual_angle;
        real amp_error, phase_error;
        logic signed [11:0] result_amp;
        logic signed [10:0] result_phi;
        
        // Calculer les valeurs attendues
        expected_amplitude = expected_amp(real'(re), real'(im));
        expected_angle = expected_phase(real'(re), real'(im));
        
        // Envoyer les données d'entrée
        input_data(re, im);
        
        // Capturer les résultats
        output_capture(result_amp, result_phi);
        
        // Convertir les résultats
        actual_amplitude = real'(result_amp);
        actual_angle = cordic_to_rad(result_phi);
        
        // Calculer les erreurs
        amp_error = abs_real(actual_amplitude - expected_amplitude);
        phase_error = abs_real(actual_angle - expected_angle);
        
        // Afficher les résultats
        $display("Test: re=%0d, im=%0d", re, im);
        $display("  Amplitude - Attendue: %0.3f, Obtenue: %0.3f, Erreur: %0.3f", 
                 expected_amplitude, actual_amplitude, amp_error);
        $display("  Phase - Attendue: %0.3f rad, Obtenue: %0.3f rad, Erreur: %0.3f", 
                 expected_angle, actual_angle, phase_error);
        
        // Vérifier si l'erreur est acceptable (tolérance)
        if (amp_error > 10.0) 
            $error("Erreur d'amplitude trop grande!");
        if (phase_error > 0.01) 
            $error("Erreur de phase trop grande!");
    endtask

    // Bloc initial principal
    initial begin
        logic signed [11:0] test_re, test_im;
        
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
        
        // Tests selon les quadrants
        $display("=== Test du système CORDIC ===");
        
        // Premier quadrant (re > 0, im > 0)
        $display("\n--- Premier quadrant ---");
        test_cordic(12'd1000, 12'd500);
        ##5;
        test_cordic(12'd800, 12'd800);
        ##5;
        
        // Deuxième quadrant (re < 0, im > 0)
        $display("\n--- Deuxième quadrant ---");
        test_cordic(-12'd1000, 12'd500);
        ##5;
        test_cordic(-12'd600, 12'd900);
        ##5;
        
        // Troisième quadrant (re < 0, im < 0)
        $display("\n--- Troisième quadrant ---");
        test_cordic(-12'd1000, -12'd500);
        ##5;
        test_cordic(-12'd700, -12'd700);
        ##5;
        
        // Quatrième quadrant (re > 0, im < 0)
        $display("\n--- Quatrième quadrant ---");
        test_cordic(12'd1000, -12'd500);
        ##5;
        test_cordic(12'd600, -12'd900);
        ##5;
        
        // Cas spéciaux
        $display("\n--- Cas spéciaux ---");
        test_cordic(12'd0, 12'd1000);    // Axe imaginaire positif
        ##5;
        test_cordic(12'd0, -12'd1000);   // Axe imaginaire négatif
        ##5;
        test_cordic(12'd1000, 12'd0);    // Axe réel positif
        ##5;
        test_cordic(-12'd1000, 12'd0);   // Axe réel négatif
        ##5;
        
        // Test avec valeurs maximales
        $display("\n--- Valeurs maximales ---");
        test_cordic(12'd2047, 12'd0);
        ##5;
        test_cordic(12'd0, 12'd2047);
        ##5;
        test_cordic(12'd2047, 12'd2047);
        ##5;
        
        // Test avec valeurs minimales
        $display("\n--- Valeurs minimales ---");
        test_cordic(-12'd2048, 12'd0);
        ##5;
        test_cordic(12'd0, -12'd2048);
        ##5;
        test_cordic(-12'd2048, -12'd2048);
        ##5;
        
        $display("\n=== Fin des tests ===");
        #100;
        $finish;
    end

endmodule
