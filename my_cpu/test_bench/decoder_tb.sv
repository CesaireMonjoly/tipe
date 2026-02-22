`timescale 1ns/1ps
`include "src/instructions.sv"

module decoder_tb;
    // Parametres
    localparam CLK_PERIOD = 10;
    localparam PROG = "prog.txt";

    localparam COUNT = 32;
    localparam DATA_WIDTH = 12;
    
    // Signaux
    logic [11:0] opcode;
    logic mode;
    logic offset;
    logic [2:0] reg_a;
    logic [2:0] reg_b;
    logic [5:0] value;
    logic [2:0] instruction_type;
    logic [2:0] sub_instruction;

    // Internals
    logic [DATA_WIDTH-1:0] ram [0:COUNT-1];
    string inst_type [3];
    string inst_name [22];
    string reg_name[8];


    initial begin 
        $readmemb(PROG, ram);

        inst_type[0] = "alu instruction";
        inst_type[1] = "mem manipulation instruction";
        inst_type[2] = "jump instruction";

        inst_name[0] = "add";
        inst_name[1] = "sub";
        inst_name[2] = "rot_l";
        inst_name[3] = "rot_r";
        inst_name[4] = "xor";
        inst_name[5] = "and";
        inst_name[6] = "or";
        inst_name[7] = "not";
        inst_name[8] = "mov_r_r";
        inst_name[9] = "mov_a_r";
        inst_name[10] = "mov_r_a";
        inst_name[11] = "not an instruction";
        inst_name[12] = "push_low";
        inst_name[13] = "push_high";
        inst_name[14] = "push";
        inst_name[15] = "pop";
        inst_name[16] = "jump_if_e";
        inst_name[17] = "jump_if_ne";
        inst_name[18] = "jump_if_pos";
        inst_name[19] = "jump_if_neg";
        inst_name[20] = "jump";
        inst_name[21] = "nop";

        reg_name[0] = "A";
        reg_name[1] = "B";
        reg_name[2] = "C";
        reg_name[3] = "D";
        reg_name[4] = "E";
        reg_name[5] = "F";
        reg_name[6] = "A";
        reg_name[7] = "H";
    end
    
    // Horloge
    logic clk;
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Instanciation de l'ALU
    decoder decoder_dut (
        .clk(clk),
        .opcode(opcode),
        .mode(mode),
        .offset(offset),
        .reg_a(reg_a),
        .reg_b(reg_b),
        .value(value),
        .instruction_type(instruction_type),
        .sub_instruction(sub_instruction)
    );
    
    // Dump var
	initial begin
			$dumpfile("wave.vcd");
			$dumpvars(0, decoder_dut);
	end


    // Tasks
    task decode_single_instruction;
        input [31:0] program_counter;
        input [11:0] op;
    begin
        opcode = op;
        #CLK_PERIOD;
        $display("program counter = %d", program_counter);
        $display("instruction type : %s", inst_type[instruction_type]);
        $display("inst : %s", inst_name[sub_instruction+(instruction_type*8)]);
        if (mode == 0) begin
            $display("reg A = %s", reg_name[reg_a]);
            $display("reg B = %s", reg_name[reg_b]);
        end else begin
            $display("Value = %d", value);
        end
        $display("");
    end
    endtask

    initial begin
        int i = 0;
        forever begin
            //for (int k = DATA_WIDTH-2; k >= 0; k--) begin
            //    $write("%b", ram[i][k]);
            //end
            //$write("\n");

            decode_single_instruction(i, ram[i]);
            i++;
            #CLK_PERIOD;
            if (i > 13 ) begin
                $finish;
            end
        end
    end
endmodule
