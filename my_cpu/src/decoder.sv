`ifndef DECODER_V
`define DECODER_V

`include "src/instructions.sv"

module decoder (
        input clk,
        input logic [11:0] opcode,
        output mode,
        output offset,
        output [2:0] reg_a,
        output [2:0] reg_b,
        output [5:0] value,
        output [2:0] instruction_type,
        output [2:0] sub_instruction
    );
    assign mode = opcode[11];
    assign offset = opcode[10];
    assign reg_a = opcode[5:3];
    assign reg_b = opcode[2:0];
    assign value = opcode[5:0]; 
    assign instruction_type = opcode[10:9];
    assign sub_instruction = opcode[8:6];

endmodule

`endif
