`include "src/instructions.sv"
`include "src/decoder.sv"
`include "src/alu.sv"
`include "src/memory.sv"
`include "src/clock.sv"
`include "src/uart.sv"

module core #(parameter CPU_CE = 9000, parameter UART_CE = 2000) (
        input clk,
        input reset,

        input rxd,
        output txd,

        output logic led_0,
        output logic led_1,
        output logic led_2,
        output logic led_3,
        output logic led_4,

        output logic r0,  
        output logic r1, 
        output logic r2, 
        output logic r3, 
        output logic r4, 
        output logic r5, 
        output logic r6, 
        output logic r7, 

        output logic clk_out
    );

    //State
    typedef enum logic [1:0] {
        FETCH  = 2'd0,
        DECODE = 2'd1, 
        EXEC   = 2'd2,
        STORE  = 2'd3
    } state_t;
    state_t state;

    assign clk_out = clk;


    logic [11:0] core_program_counter;
    logic [11:0] core_current_instruction;

    logic [11:0] core_reg_w;
    logic [11:0] core_reg_r;


    logic [5:0] core_low_reg_w = core_reg_w[5:0];
    logic [11:6] core_high_reg_w = core_reg_w[11:6];

    logic [11:0] core_jump_addr;
    
    logic [11:0] core_registers [0:7]; //A B C D E F G H

    logic [11:0] core_A;
    logic [11:0] core_B;
    logic [11:0] core_C;
    logic [11:0] core_D;
    logic [11:0] core_E;
    logic [11:0] core_F;
    logic [11:0] core_G;
    logic [11:0] core_H;

    assign core_A = core_registers[0];
    assign core_B = core_registers[1];
    assign core_C = core_registers[2];
    assign core_D = core_registers[3];
    assign core_E = core_registers[4];
    assign core_F = core_registers[5];
    assign core_G = core_registers[6];
    assign core_H = core_registers[7];


    logic core_equ_flag;
    logic core_sign_flag;

    logic [11:0] core_instruction_counter; //Count how many instructions that have been executed (for debug purpose)


    //assign led_0 = core_reg_w[0];
    //assign led_1 = core_reg_w[1];
    //assign led_2 = core_reg_w[2];
    //assign led_3 = core_reg_w[3];
    //assign led_4 = core_reg_w[4];
    //
    
    //Uart transmiter====



    logic uart_tx_ce;
    logic uart_tx_data_available;
    logic [7:0] uart_tx_data_byte;

    logic uart_tx_active;
    logic uart_tx_done;
    logic uart_tx_output;


    clock_enable #(
        .MAX(UART_CE)
    ) uart_clock_enable (
        .clk(clk),
        .reset(reset),
        .ce(uart_tx_ce)
    );


    uart_tx #(
        .CLKS_PER_BIT(8), .SIZE(7)
    ) send (
            .clk(clk),
            .ce(uart_tx_ce),
            .i_data_available(uart_tx_data_available),
            .i_data_byte(uart_tx_data_byte),
            .o_active(uart_tx_active),
            .o_done(uart_tx_done),
            .o_tx(uart_tx_output)
    );


    //Clock==============
    logic cpu_ce;

    clock_enable #(
        .MAX(CPU_CE)
    ) cpu_clock_enable (
        .clk(clk),
        .reset(reset),
        .ce(cpu_ce)
    );

    //User Stacks==========
    logic [11:0] stack_pointer = -1;

    logic stack_we;
    logic [5:0] stack_in;
    logic [5:0] stack_out;

    memory #(
        .COUNT(64),
        .DATA_WIDTH(6),
        .WRITE_PRG(0)
    ) stack ( //Bits de poids faibles
        .clk(clk),
        .addr(stack_pointer),
        .write_enable(stack_we),
        .data_in(stack_in),
        .data_out(stack_out)
    );

    //====================


    //ALU=================
    logic [11:0] alu_output;
    logic [2:0] alu_func_code;
    logic alu_carry_in;
    logic alu_carry_out;
    logic alu_equ_out;
    logic alu_sign_out;
    logic alu_overflow;

 
    alu core_alu (
        .a_in(core_reg_w),
        .b_in(core_reg_r),
        .carry_in(alu_carry_in),
        .func_code(alu_func_code),
        .a_out(alu_output),
        .carry_out(alu_carry_out),
        .equ_out(alu_equ_out),
        .sign_out(alu_sign_out),
        .overflow_out(alu_overflow)
    );
    //=====================

    //Decoder==============
    logic [11:0] dec_opcode;
    logic [4:0] dec_instruction;
    logic [3:0] dec_operation_type;
    logic [5:0] dec_value;
    logic [2:0] dec_reg_r;
    logic [2:0] dec_reg_w;
    logic [11:0] dec_addr;
    logic [1:0] dec_instruction_type;
    logic [2:0] dec_sub_instruction;
    logic dec_mode;
    logic dec_offset;


    decoder core_decoder (
        .clk(clk),
        .opcode(dec_opcode),
        .instruction(dec_instruction),
        .mode(dec_mode),
        .offset(dec_offset),
        .value(dec_value),
        .reg_a(dec_reg_w),
        .reg_b(dec_reg_r),
        .instruction_type(dec_instruction_type),
        .sub_instruction(dec_sub_instruction)
    );
    //=====================
    
    //Main Memory=========
    logic mem_write_enable;
    logic [11:0] mem_data_in;
    wire [11:0] mem_data_out;

    memory #(
        .COUNT(255),
        .DATA_WIDTH(12),
        .WRITE_PRG(1)
    ) main_memory (
        .clk(clk),
        .addr(core_program_counter),
        .write_enable(mem_write_enable),
        .data_in(mem_data_in),
        .data_out(mem_data_out)
    );
    //====================
    
    assign dec_opcode = core_current_instruction;
    assign alu_func_code = dec_sub_instruction;

    always_ff @ (posedge clk) begin
        //Reset
        if (reset) begin
            state <= FETCH;
            mem_data_in <= 0;
            core_program_counter <= 0;
            mem_write_enable <= 0;

            stack_we <= 0;
            stack_in <= 0;
            stack_pointer <= -1;

            alu_carry_in <= 0;

            core_program_counter <= 0;
            core_current_instruction <= 0;
            core_reg_r <= 0;
            core_reg_w <= 0;
            core_jump_addr <= 0;
            for(int i = 0; i < 8; i++) begin
                core_registers[i] <= 0;
            end
            core_equ_flag <= 0;
            core_sign_flag <= 0;
            core_instruction_counter <= 0;
        end
        //Datapath
        if (cpu_ce) begin
            //led_4 <= state[0];
            case (state)
                FETCH : begin
                    state <= DECODE;
                    core_current_instruction <= mem_data_out;
                end
                DECODE : begin
                    if (dec_mode == 0) begin //REG/ADDR MODE
                        core_reg_w <= core_registers[dec_reg_w];
                        core_reg_r <= core_registers[dec_reg_r];
                        core_jump_addr <= core_registers[dec_reg_w];
                        stack_in <= core_registers[dec_reg_w]; 
                        //core_program_counter <= core_registers[dec_reg_w];
                    end else if (dec_mode == 1) begin //VALUE MODE
                        core_jump_addr <= stack_out;
                        core_reg_w <= stack_out;
                        stack_in[5:0] <= dec_value;
                    end
                    state <= EXEC;
                end
                EXEC : begin
                    //led_2 <= ~led_2;
                    case (dec_instruction_type) 
                        `ALU_INSTRUCTION : begin
                            core_registers[dec_reg_w] <= alu_output;
                            core_equ_flag <= alu_equ_out;
                            core_sign_flag <= alu_sign_out;
                        end
                        `JUMP_INSTRUCTION : begin
                            core_equ_flag <= 0;
                            core_sign_flag <= 0;
                            if (dec_instruction == `JUMP_IF_E && core_equ_flag == 1) begin
                                core_program_counter <= core_jump_addr - 1;
                            end else if (dec_instruction == `JUMP_IF_NE && core_equ_flag == 0) begin
                                core_program_counter <= core_jump_addr - 1;
                            end else if (dec_instruction == `JUMP_IF_POS && core_sign_flag == 1) begin
                                core_program_counter <= core_jump_addr - 1 ;
                            end else if (dec_instruction == `JUMP_IF_NEG && core_sign_flag == 0) begin
                                core_program_counter <= core_jump_addr - 1;
                            end else if (dec_instruction == `JUMP) begin
                                core_program_counter <= core_jump_addr - 1;
                            end
                        end
                        `MEM_MAN_INSTRUCTION : begin
                            core_equ_flag <= 0;
                            core_sign_flag <= 0;
                            if (dec_instruction == `MOV_R_R) begin
                                core_registers[dec_reg_w] <= core_reg_r;
                            end else if (dec_instruction == `MOV_A_R) begin
                                mem_write_enable <= 1;            
                            end else if (dec_instruction == `MOV_R_A) begin
                                core_registers[dec_reg_w] <= mem_data_out;
                            end else if (dec_instruction == `PUSH_LOW) begin
                                stack_we <= 1;
                                stack_pointer <= stack_pointer + 11'b1;
                            end else if (dec_instruction == `PUSH_HIGH) begin
                                stack_we <= 1;
                                stack_pointer <= stack_pointer + 11'b1;
                            end else if (dec_instruction == `POP_LOW) begin
                                //stack_we <= 1;
                                //stack_in <= 6'b111111;
                                core_registers[dec_reg_w][5:0] <= stack_out;
                                stack_pointer <= stack_pointer - 11'b1;
                            end else if (dec_instruction == `POP_HIGH) begin
                                //stack_we <= 1;
                                //stack_in <= 6'b111111;
                                core_registers[dec_reg_w][11:6] <= stack_out;
                                stack_pointer <= stack_pointer - 11'b1;
                            end
                        end
                    endcase
                    state <= STORE;
                end
                STORE : begin
                    //led_3 <= ~led_3;
                    //
                    
                    r0 <= core_A[0];
                    r1 <= core_A[1];
                    r2 <= core_A[2];
                    r3 <= core_A[3];
                    r4 <= core_A[4];
                    r5 <= core_A[5];
                    r6 <= core_A[6];
                    r7 <= core_A[7];

                    stack_we <= 0;
                    stack_in <= 0;
                    core_reg_w <= 0;
                    mem_write_enable <= 0;
                    state <= FETCH;
                    core_program_counter <= core_program_counter + 1;
                end
                default : begin
                    state <= FETCH;
                end
            endcase
        end
    end
endmodule

