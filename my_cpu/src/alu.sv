`ifndef ALU_V
`define ALU_V

`include "src/instructions.sv"

module alu (
        input logic [11:0] a_in,
        input logic [11:0] b_in,
        input logic carry_in,
        input logic [2:0] func_code,
        output logic [11:0] a_out,
        output logic carry_out,
        output logic equ_out,
        output logic sign_out,
        output logic overflow_out
    );

    wire [12:0] add_res, sub_res;
    wire add_overflow, sub_overflow;
    wire [11:0] rot_l, rot_r;

    assign equ_out = (a_in == b_in);
    assign sign_out = a_out < 0; //0 = pos and 1 = neg


    assign add_res = {1'b0, a_in} + {1'b0, b_in} + carry_in;
    assign sub_res = {1'b0, a_in} - {1'b0, b_in} - carry_in;
    
    assign add_overflow = (a_in[11] & b_in[11] & ~add_res[11]) | 
                         (~a_in[11] & ~b_in[11] & add_res[11]);
    
    assign sub_overflow = (a_in[11] & ~b_in[11] & ~sub_res[11]) | 
                         (~a_in[11] & b_in[11] & sub_res[11]);
    
    assign rot_l = (a_in << b_in[3:0]) | (a_in >> (12 - b_in[3:0]));
    assign rot_r = (a_in >> b_in[3:0]) | (a_in << (12 - b_in[3:0]));

    always @(*) begin
        a_out = 12'd0;
        carry_out = 1'b0;
        overflow_out = 1'b0;

        case (func_code) 
            `ADD : begin
                a_out = add_res[11:0];
                carry_out = add_res[12];
                overflow_out = add_overflow;
            end
            `SUB : begin 
                a_out = sub_res[11:0];
                carry_out = sub_res[12];
                overflow_out = sub_overflow;
            end
            `ROT_L : begin
                a_out = rot_l;
            end
            `ROT_R : begin
                a_out = rot_r;
            end
            `XOR : begin
                a_out = a_in ^ b_in;
            end
            `AND : begin 
                a_out = a_in & b_in;
            end
            `OR : begin 
                a_out = a_in | b_in;
            end
            `NOT : begin 
                a_out = ~a_in;
            end
        endcase
    end
endmodule

`endif
