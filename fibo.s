//Fibo

xor H H;
push_l _l_entry;
push_h _h_entry;
pop_h H;
pop_l H;
jump H;
//Jump to entry

_entry:
    //Working registers
    xor A A; 
    xor B B;
    xor D D;
    xor F F;
    push_l $1;
    push_h $0;
    pop_h B;
    pop_l B;
    mov_r_r C B; 

    //B = 1
    //C = 1

    //Amount of iteration (10)
    xor E E;
    push_l $13;
    push_h $0;
    pop_h E;
    pop_l E;

    //E = 10 (= 0x0A)

    // End jump
    push_l _l_end;
    push_h _h_end;
    pop_h H;
    pop_l H;

    // Loop jump
    push_l _l_incr;
    push_h _h_incr;
    pop_h G;
    pop_l G;
    jump G;

_incr:
    sub E C; 
    jump_if_pos H  
    
    // fibo stuff
    mov_r_r D B;
    add B A;
    mov_r_r A D;
    push A;

    //incr counter
    //add C F;

    jump G;

_end:
    jump H;
