`ifndef INSTURCTIONS_SV
`define INSTURCTIONS_SV

`define INSTRUCTION_SIZE 12

//ALU //incr/decr ? 
`define ADD 6'd0       
`define SUB 6'd1       
`define ROT_L 6'd2     
`define ROT_R 6'd3     
`define XOR 6'd4       
`define AND 6'd5       
`define OR 6'd6        
`define NOT 6'd7       

//Mem instructions
`define MOV_R_R 6'd8 //mov register to register
`define MOV_A_R 6'd9 //mov register content to addr stored in the register
`define MOV_R_A 6'd10 //mov addr content to the register

//immediate value push
`define PUSH_LOW 6'd12 //DO NOT INCREMENT THE STACK POINTER (It needs to be follow by a PUSH_HIGH instruction)
`define PUSH_HIGH 6'd13 //DO INCREMENTE THE STACK POINTER (MAKE SURE YOU PUSH_LOW FIRST!!)

//register value push & pop
`define PUSH 6'd14 //Push register content on the stack
`define POP 6'd15 

//Jump instruction
`define JUMP_IF_E 6'd16//take the jump if equ_flag is 1
`define JUMP_IF_NE 6'd17//take the jump if equ_flag is 0
`define JUMP_IF_POS 6'd18//take the jump if sign_flag is 1
`define JUMP_IF_NEG 6'd19//take the jump if sign_flag is 0

`define JUMP 6'd20
`define NOP 6'd21

//INSTRUCTION TYPE
`define ALU_INSTRUCTION 2'd0
`define JUMP_INSTRUCTION 2'd1
`define MEM_MAN_INSTRUCTION 2'd2

`endif
