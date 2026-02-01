`timescale 1ns/1ps


module core_tb;
    // Parametres
    localparam CLK_PERIOD = 10;

    // Signaux
    logic reset;
    
    logic rxd;
    wire txd;
    
    logic led_0;
    logic led_1;
    logic led_2;
    logic led_3;
    logic led_4;

    
    // Horloge
    logic clk;
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end


    core core_dut (
        .clk(clk),
        .reset(reset),
        .rxd(rxd),
        .txd(txd),
        .led_0(led_0),
        .led_1(led_1),
        .led_2(led_2),
        .led_3(led_3),
        .led_4(led_4)
    );


    // Dump var
	initial begin
			$dumpfile("wave.vcd");
			$dumpvars(0, core_dut);
	end

    // Tasks
    task reset_cpu;
        begin
            $display("--- Reset du CPU ---");
            reset = 1; 
            #(CLK_PERIOD * 5);
            reset = 0;
            @(posedge clk);
        end
    endtask

    task wait_cycles;
        input int count;
        begin
            repeat (count) @(posedge clk);
        end
    endtask

    // Main
    initial begin
        // Initialisation
        rxd = 1;
        reset = 0;

        // Sequence de test
        reset_cpu();

        $display("--- Debut de l'execution ---");
        
        // On laisse le processeur executer les instructions chargees
        // dans le fichier "program" via la memoire 
        
        // Chaque instruction prend 3 cycles de cpu_ce (FETCH, DECODE, EXEC) 
        // Avec MAX=2, cpu_ce arrive tous les 2 cycles de clk 
        for (int i = 0; i < 20; i++) begin
            wait_cycles(6); // Attend le temps d'une instruction complete
            $display("Temps: %t | Etat: %0d | PC: %h | Inst: %h | R0: %h", 
                     $time, core_dut.state, core_dut.core_program_counter, 
                     core_dut.core_current_instruction, core_dut.core_registers[0]);
        end

        $display("--- Simulation terminee ---");
        $finish;
    end

endmodule

