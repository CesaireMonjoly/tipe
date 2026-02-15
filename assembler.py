import sys
import struct

class Assembler:
    def __init__(self):
        self.registers = {
            'A': 0, 'B': 1, 'C': 2, 'D': 3, 
            'E': 4, 'F': 5, 'G': 6, 'H': 7
        }
        
        self.opcodes = {
            # ALU
            'add': 0, 'sub': 1, 'rot_l': 2, 'rot_r': 3,
            'xor': 4, 'and': 5, 'or': 6, 'not': 7,
            # MEM
            'mov_r_r': 8, 'mov_a_r': 9, 'mov_r_a': 10,
            # DIRECT PUSH
            'push_l': 12, 'push_h': 13,
            # PUSH/POP
            'push': 14, 'pop': 15,
            # JUMP
            'jump_if_e': 16, 'jump_if_ne': 17, 
            'jump_if_pos': 18, 'jump_if_neg': 19,
            'jump': 20, 'nop': 21,
            # UART
            'uart_send': 22, 'uart_read': 23
        }

        self.labels = {}
        self.binary_output = []

    def is_register(self, arg):
        return arg in self.registers

    def is_immediate(self, arg):
        return arg.startswith('$')

    def is_label_ref(self, arg):
        return arg.startswith('_l_') or arg.startswith('_h_')

    def parse_immediate(self, arg):
        try:
            val = int(arg[1:])
            if val < 0 or val > 63:
                raise ValueError
            return val
        except:
            print(f"Error parsing immediate: {arg}")
            sys.exit(1)

    def resolve_label_part(self, arg):
        mode = arg[:3] 
        target = "_" + arg[3:] 
        
        # Gestion de nommage flexible
        if target not in self.labels:
             if arg[3:] in self.labels: target = arg[3:]
             else:
                 print(f"Error: Unknown label '{arg}'")
                 sys.exit(1)

        addr = self.labels[target]
        
        # L'adresse est l'index de l'instruction (0, 1, 2...)
        # Le CPU gère le saut, peu importe comment c'est stocké sur le disque
        if mode == '_l_': return addr & 0x3F
        elif mode == '_h_': return (addr >> 6) & 0x3F
        return 0

    def first_pass(self, lines):
        """Repérage des labels"""
        pc = 0
        clean_lines = []
        for line in lines:
            line = line.split('//')[0].strip()
            if not line: continue
            if line.endswith(':'):
                self.labels[line[:-1]] = pc
                continue 
            clean_lines.append(line)
            pc += 1 
        return clean_lines

    def second_pass(self, lines):
        """Génération des instructions 12 bits"""
        for line in lines:
            parts = line.replace(',', ' ').split()
            mnemo = parts[0].replace(';', '')
            args = [a.replace(';', '') for a in parts[1:]]

            if mnemo not in self.opcodes:
                print(f"Error: Unknown instruction '{mnemo}'")
                sys.exit(1)

            opcode = self.opcodes[mnemo]
            operand = 0

            # Encodage standard
            if len(args) == 2: # add A B
                operand = (self.registers[args[0]] << 3) | self.registers[args[1]]
            elif mnemo in ['push_l', 'push_h']: # push_l $10
                if self.is_immediate(args[0]): operand = self.parse_immediate(args[0])
                elif self.is_label_ref(args[0]): operand = self.resolve_label_part(args[0])
            elif len(args) == 1: # push A
                operand = (self.registers[args[0]] << 3)
            
            # Instruction finale (12 bits)
            self.binary_output.append((opcode << 6) | (operand & 0x3F))

    def save_packed_binary(self, filename="out.bin"):
        """
        Compacte 2 instructions (24 bits) en 3 octets.
        """
        packed_bytes = bytearray()
        instructions = self.binary_output
        
        # On itère par paire (i, i+1)
        for i in range(0, len(instructions), 2):
            inst1 = instructions[i]
            
            if i + 1 < len(instructions):
                # Cas standard : On a une paire
                inst2 = instructions[i+1]
                
                # Inst1: AAAA AAAA AAAA
                # Inst2: BBBB BBBB BBBB
                
                # Byte 1: AAAA AAAA (Top 8 bits of Inst1)
                b1 = (inst1 >> 4) & 0xFF
                
                # Byte 2: AAAA BBBB (Bottom 4 bits Inst1 + Top 4 bits Inst2)
                b2 = ((inst1 & 0x0F) << 4) | ((inst2 >> 8) & 0x0F)
                
                # Byte 3: BBBB BBBB (Bottom 8 bits Inst2)
                b3 = inst2 & 0xFF
                
                packed_bytes.append(b1)
                packed_bytes.append(b2)
                packed_bytes.append(b3)
            else:
                # Cas impair : Il reste une seule instruction à la fin
                # On écrit 2 octets, avec 4 bits de bourrage (padding) à la fin
                # Byte 1: AAAA AAAA
                # Byte 2: AAAA 0000
                b1 = (inst1 >> 4) & 0xFF
                b2 = (inst1 & 0x0F) << 4
                packed_bytes.append(b1)
                packed_bytes.append(b2)

        with open(filename, 'wb') as f:
            f.write(packed_bytes)
        print(f"\n[+] Packed Binary saved to {filename}")
        print(f"    Original: {len(instructions)} instructions (12-bit)")
        print(f"    Packed:   {len(packed_bytes)} bytes")

    def assemble(self, source_code, filename="out.bin"):
        lines = self.first_pass(source_code.splitlines())
        self.second_pass(lines)
        self.save_packed_binary(filename)

def format_bin_to_text(opcode): #visual purpose only
    s = f"{opcode:0{12}b}"
    return " ".join(s[i:i+3] for i in range(0, len(s), 3))

if __name__ == "__main__":
    code = """
    // Initialisation
    push_l $10;
    push_h $0;
    pop A;
    
    _loop:
        // Corps de la boucle
        sub A B;
        
        // Saut conditionnel vers _end
        push_l _l_end;
        push_h _h_end;
        pop H;
        jump_if_neg H;
        
        // Saut inconditionnel vers _loop
        push_l _l_loop;
        push_h _h_loop;
        pop H;
        jump H;

    _end:
        nop;
    """

    simple_code = """
        push_l $10;
        push_h $0;
        pop A;
    """
    
    asm = Assembler()
    asm.assemble(code, "prog.bin")
    
    print("\nDisplay bin result :")
    for i in asm.binary_output:
        print(format_bin_to_text(i))
    print("\n")
