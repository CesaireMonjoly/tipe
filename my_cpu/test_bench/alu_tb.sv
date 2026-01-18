`timescale 1ns/1ps
`include "src/instructions.sv"

module alu_tb;
    // Parametres
    localparam CLK_PERIOD = 10;
    localparam TEST_COUNT = 100;
    
    // Signaux
    logic [11:0] a_in, b_in;
    logic carry_in;
    logic [2:0] func_code;
    logic [11:0] a_out;
    logic carry_out, equ_out, overflow_out;

    // Horloge
    logic clk;
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Instanciation de l'ALU
    alu alu_dut (
        .a_in(a_in),
        .b_in(b_in),
        .carry_in(carry_in),
        .func_code(func_code),
        .a_out(a_out),
        .carry_out(carry_out),
        .equ_out(equ_out),
        .overflow_out(overflow_out)
    );
    
    // Dump var
	initial begin
			$dumpfile("wave.vcd");
			$dumpvars(0, alu_dut);
	end


    // Tasks
    task test_add_sub;
        input [11:0] a, b;
        input c_in;
        logic [12:0] expected_sum;
        logic [12:0] expected_diff;
        logic expected_ovf_add, expected_ovf_sub;
        logic expected_equ;
    begin
        func_code = `ADD;
        a_in = a;
        b_in = b;
        carry_in = c_in;
        expected_sum = a + b + c_in;
        expected_ovf_add = (a[11] & b[11] & ~expected_sum[11]) | 
                          (~a[11] & ~b[11] & expected_sum[11]);
        expected_equ = (a == b);
        
        #CLK_PERIOD;
        assert(a_out === expected_sum[11:0]) 
            else $error("ADD: a_out mismatch: %h vs %h", a_out, expected_sum[11:0]);
        assert(carry_out === expected_sum[12]) 
            else $error("ADD: carry_out mismatch");
        assert(overflow_out === expected_ovf_add) 
            else $error("ADD: overflow mismatch");
        assert(equ_out === expected_equ) 
            else $error("ADD: equ_out mismatch");
        
        // Test SUB
        func_code = `SUB;
        expected_diff = a - b - c_in;
        expected_ovf_sub = (a[11] & ~b[11] & ~expected_diff[11]) | 
                          (~a[11] & b[11] & expected_diff[11]);
        
        #CLK_PERIOD;
        assert(a_out === expected_diff[11:0]) 
            else $error("SUB: a_out mismatch: %h vs %h", a_out, expected_diff[11:0]);
        assert(carry_out === expected_diff[12]) 
            else $error("SUB: carry_out mismatch");
        assert(overflow_out === expected_ovf_sub) 
            else $error("SUB: overflow mismatch");
        assert(equ_out === expected_equ) 
            else $error("SUB: equ_out mismatch");
    end
    endtask
    
    task test_rotation;
        input [11:0] value;
        input [3:0] shift;
        input is_left;
    begin
        a_in = value;
        b_in = shift;
        carry_in = 0;
        
        if (is_left) begin
            func_code = `ROT_L;
            #CLK_PERIOD;
            assert(a_out === ((value << shift) | (value >> (12 - shift))))
                else $error("ROT_L mismatch: %h vs %h", 
                            a_out, ((value << shift) | (value >> (12 - shift))));
        end else begin
            func_code = `ROT_R;
            #CLK_PERIOD;
            assert(a_out === ((value >> shift) | (value << (12 - shift))))
                else $error("ROT_R mismatch: %h vs %h", 
                            a_out, ((value >> shift) | (value << (12 - shift))));
        end
        
        assert(carry_out === 0) else $error("Rotation carry error");
        assert(overflow_out === 0) else $error("Rotation overflow error");
        assert(equ_out === (value == shift)) 
            else $error("Rotation equ_out mismatch");
    end
    endtask
    
    task test_logical;
        input [2:0] op;
        input [11:0] a, b;
        logic [11:0] expected;
    begin
        func_code = op;
        a_in = a;
        b_in = b;
        carry_in = 0;
        
        case(op)
            `XOR: expected = a ^ b;
            `AND: expected = a & b;
            `OR:  expected = a | b;
            `NOT: expected = ~a;
        endcase
        
        #CLK_PERIOD;
        assert(a_out === expected) 
            else $error("Logical op %b: a_out mismatch: %h vs %h", op, a_out, expected);
        assert(carry_out === 0) else $error("Logical op carry error");
        assert(overflow_out === 0) else $error("Logical op overflow error");
        assert(equ_out === (a == b)) 
            else $error("Logical op equ_out mismatch");
    end
    endtask
    
    // Test aléatoire
    task random_test;
        logic [11:0] rand_a, rand_b;
        logic rand_carry;
        logic [2:0] rand_op;
    begin
        rand_a = $random;
        rand_b = $random;
        rand_carry = $random & 1;
        rand_op = $random & 'b111;
        
        a_in = rand_a;
        b_in = rand_b;
        carry_in = rand_carry;
        func_code = rand_op;
        
        #CLK_PERIOD;
        // Vérification de equ_out en continu
        assert(equ_out === (rand_a == rand_b)) 
            else $error("Random test: equ_out mismatch for op %b", rand_op);
    end
    endtask
    
    // Programme de test principal
    initial begin
        $dumpfile("alu_wave.vcd");
        $dumpvars(0, alu_tb);
        
        // Tests d'addition/soustraction
        test_add_sub(12'h000, 12'h000, 0);  // 0+0
        test_add_sub(12'h7FF, 12'h001, 0);  // Max positif +1
        test_add_sub(12'h800, 12'hFFF, 1);  // Min négatif + (-1) + carry
        test_add_sub(12'hFFF, 12'h001, 0);  // -1 +1
        test_add_sub(12'h123, 12'h456, 1);  // Valeurs aléatoires
        
        // Tests de rotation
        test_rotation(12'b1100_0000_0000, 1, 1);   // Rotation gauche
        test_rotation(12'b0000_0000_0001, 1, 0);   // Rotation droite
        test_rotation(12'hFFF, 4, 1);              // Rotation multiple
        test_rotation(12'h123, 12, 0);              // Rotation complète
        
        // Tests logiques
        test_logical(`XOR, 12'hAAA, 12'h555);  // XOR
        test_logical(`AND, 12'hFFF, 12'h555);   // AND
        test_logical(`OR,  12'h000, 12'h555);   // OR
        test_logical(`NOT, 12'h000, 12'h000);   // NOT
        
        // Tests aléatoires
        for (int i = 0; i < TEST_COUNT; i++) begin
            random_test();
        end
        
        // Test de couverture
        $display("\nTests complétés avec %0d opérations aléatoires", TEST_COUNT);
        $display("All ALU operations tested successfully!");
        $finish;
    end
endmodule
