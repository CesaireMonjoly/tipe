//Fibo

xor H H;
push_l _l_entry;
push_h _h_entry;
pop H;
jump H;
//Jump to entry
xor H H; //unreachable code

_entry:
    //Working registers
    xor A A;
    xor B B;
    xor D D;
    xor F F;
    push_l $1;
    push_h $0;
    pop B;
    mov_r_r F B; 

    //Amount of iteration (10)
    xor E E;
    push_l $10;
    push_h $0;
    pop E;

    //Counter
    xor C C; 

    // End jump
    push_l _l_end;
    push_h _h_end;
    pop H;

    // Loop jump
    push_l _l_incr;
    push_h _h_incr;
    pop G;
    jump G;

_incr:
    sub E C; 
    jump_if_e H  
    
    // fibo stuff
    mov_r_r D B;
    add B A;
    mov_r_r A D;

    //incr counter
    add C F;

    jump G;

_end:
    mov_r_r A D;
