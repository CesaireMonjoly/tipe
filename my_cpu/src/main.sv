`include "src/instructions.sv"
`include "src/decoder.sv"
`include "src/alu.sv"
`include "src/memory.sv"
`include "src/clock.sv"
`include "src/uart.sv"

module core (
        input clk,
        input reset_n,

        input rxd,
        output txd,

        output led_0,
        output led_1,
        output led_2,
        output led_3,
        output led_4
    );

    //State
    typedef enum logic [1:0] {
        FETCH  = 2'd0,
        DECODE = 2'd1, 
        EXEC   = 2'd2
    } state_t;
    state_t state;

    //assign led_0 = state[0];
    //assign led_1 = state[1];
    //assign led_2 = state[2];

    logic [11:0] core_program_counter;
    logic [11:0] core_current_instruction;

    logic [11:0] core_reg_w;
    logic [11:0] core_reg_r;

    logic [11:0] core_jump_addr;
    
    logic [11:0] core_registers [0:3]; //A B C D E F G H

    logic core_equ_flag;
    logic core_sign_flag;

    //Uart transmiter====

    logic uart_tx_ce;
    logic uart_tx_data_available;
    logic [7:0] uart_tx_data_byte;

    logic uart_tx_active;
    logic uart_tx_done;
    logic uart_tx_output;


    clock_enable #(
        .MAX(200000)
    ) uart_clock_enable (
        .clk(clk),
        .reset(reset_n),
        .ce(uart_ce)
    );


    uart_tx #(
        .CLKS_PER_BIT(8), .SIZE(7)
    ) send (
            .clk(clk),
            .ce(uart_ce),
            .i_data_available(uart_tx_data_available),
            .i_data_byte(uart_tx_data_byte),
            .o_active(uart_tx_active),
            .o_done(uart_tx_done),
            .o_tx(uart_tx_output)
    );


    //Clock==============
    logic cpu_ce;

    clock_enable #(
        .MAX(200000)
    ) cpu_clock_enable (
        .clk(clk),
        .reset(reset_n),
        .ce(cpu_ce)
    );

    //User Stacks==========
    logic [11:0] stack_pointer;

    logic stack_we;
    logic [11:0] stack_in;
    logic [11:0] stack_out;

    memory #(
        .COUNT(64),
        .DATA_WIDTH(12),
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
    wire alu_carry_out;
    wire alu_equ_out;
    wire alu_sign_out;
    wire alu_overflow;

    assign alu_func_code = dec_sub_instruction;
 
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
    wire [3:0] dec_operation_type;
    wire [5:0] dec_value;
    wire [2:0] dec_reg_r;
    wire [2:0] dec_reg_w;
    wire [11:0] dec_addr;
    wire [2:0] dec_instruction_type;
    wire [2:0] dec_sub_instruction;
    wire dec_mode;
    wire dec_offset;

    assign dec_opcode = core_current_instruction;

    decoder core_decoder (
        .clk(clk),
        .opcode(dec_opcode),
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
    logic [11:0] mem_addr;
    logic mem_write_enable;
    logic [11:0] mem_data_in;
    wire [11:0] mem_data_out;

    memory #(
        .COUNT(255),
        .DATA_WIDTH(12),
        .WRITE_PRG(1)
    ) main_memory (
        .clk(clk),
        .addr(mem_addr),
        .write_enable(mem_write_enable),
        .data_in(mem_data_in),
        .data_out(mem_data_out)
    );
    //====================
    
    //Reset
    always_ff @ (posedge clk) begin
        if (reset_n) begin
            //state <= FETCH;
            core_program_counter <= 0;
            core_current_instruction <= 0;
            core_reg_r <= 0;
            core_reg_w <= 0;
            core_jump_addr <= 0;
            for(int i = 0; i < 4; i++) begin
                core_registers[i] <= 0;
            end
            core_equ_flag <= 0;
            core_sign_flag <= 0;
            stack_pointer <= 0;
        end
    end
        
    //Datapath
    always_ff @ (posedge clk) begin
        if (cpu_ce) begin
            case (state)
                FETCH : begin
                    led_0 <= ~led_0;
                    mem_addr <= core_program_counter;
                    state <= DECODE;
                end
                DECODE : begin
                    core_current_instruction <= mem_data_out;
                    led_1 <= ~led_1;
                    if (dec_mode == 0) begin //REG/ADDR MODE
                        core_reg_w <= core_registers[dec_reg_w];
                        core_reg_r <= core_registers[dec_reg_r];
                        core_jump_addr <= core_registers[dec_reg_w];
                        stack_in <= core_registers[dec_reg_w];
                        mem_addr <= core_registers[dec_reg_w];
                    end else if (dec_mode == 1) begin //VALUE MODE
                        core_jump_addr <= stack_out;
                        core_reg_w <= stack_out;
                        stack_in[11:6] <= dec_reg_w;
                        stack_in[5:0] <= dec_reg_r;
                    end
                    state <= EXEC;
                end
                EXEC : begin
                    led_2 <= ~led_2;
                    core_program_counter <= core_program_counter + 1;
                    case (dec_instruction_type) 
                        `ALU_INSTRUCTION : begin
                            core_registers[dec_reg_w] <= alu_output;
                            core_equ_flag <= alu_equ_out;
                            core_sign_flag <= alu_sign_out;
                        end
                        `JUMP_INSTRUCTION : begin
                            if (dec_opcode == `JUMP_IF_E && core_equ_flag == 1) begin
                                core_program_counter <= core_jump_addr;
                            end else if (dec_opcode == `JUMP_IF_NE && core_equ_flag == 0) begin
                                core_program_counter <= core_jump_addr;
                            end else if (dec_opcode == `JUMP_IF_POS && core_sign_flag == 1) begin
                                core_program_counter <= core_jump_addr;
                            end else if (dec_opcode == `JUMP_IF_NEG && core_sign_flag == 0) begin
                                core_program_counter <= core_jump_addr;
                            end
                        end
                        `MEM_MAN_INSTRUCTION : begin
                            if (dec_opcode == `MOV_R_R) begin
                                core_reg_w <= core_reg_r;
                            end else if (dec_opcode == `MOV_A_R) begin
                                mem_write_enable <= 1;            
                            end else if (dec_opcode == `MOV_R_A) begin
                                core_reg_w <= mem_data_out;
                            end else if (dec_opcode == `PUSH_LOW) begin
                                stack_we <= 1;
                            end else if (dec_opcode == `PUSH_HIGH) begin
                                stack_we <= 1;
                                stack_pointer <= stack_pointer + 1;
                            end else if (dec_opcode == `PUSH_LOW) begin
                                stack_we <= 1;
                            end else if (dec_opcode == `POP) begin
                                core_reg_w <= stack_out;
                            end
                        end
                    endcase
                    state <= FETCH;
                end
                default : begin
                    state <= FETCH;
                end
            endcase
        end
    end
endmodule

