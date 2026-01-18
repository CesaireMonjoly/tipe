#ifndef INSTRUCTIONS_H
#define INSTRUCTIONS_H

#define MAX_LINE_LENGTH 30
#define MAX_INSTRUCTIONS 100

#define TABLE_SIZE 100

struct instruction {
    char* inst;
    char* dest;
    char* src;
};

enum registers {
    REG_A,
    REG_B,
    REG_C,
    REG_D,
    REG_E,
    REG_F,
    REG_G,
    REG_H
};

enum instruction_type {
    ALU,
    JUMP,
    MEM_R_R,
    MEM_A_R,
    MEM_A_A
};

enum opcode {
    OPCODE_ADD = 0,
    OPCODE_SUB = 1,
    OPCODE_ROT_L = 2,
    OPCODE_ROT_R = 3,
    OPCODE_XOR = 4,
    OPCODE_AND = 5,
    OPCODE_OR = 6,
    OPCODE_NOT = 7,
    
    OPCODE_MOV_R_R = 8,
    OPCODE_MOV_A_R = 9,
    OPCODE_MOV_R_A = 10,
    
    OPCODE_PUSH_LOW = 12,
    OPCODE_PUSH_HIGH = 13,
    
    OPCODE_PUSH = 14,
    OPCODE_POP = 15,
    
    OPCODE_JUMP_IF_E = 16,
    OPCODE_JUMP_IF_NE = 17,
    OPCODE_JUMP_IF_POS = 18,
    OPCODE_JUMP_IF_NEG = 19,
    
    OPCODE_JUMP = 20,
    OPCODE_NOP = 21
}; 

// Structure pour un élément de la table
struct HashEntry {
    char *key;
    int opcode;
    struct HashEntry *next;
};

// Structure pour la table de hachage
struct HashTable {
    struct HashEntry **buckets;
    int size;
    int count;
};

#define STR_REG_A "A"
#define STR_REG_B "B"
#define STR_REG_C "C"
#define STR_REG_D "D"
#define STR_REG_E "E"
#define STR_REG_F "F"
#define STR_REG_G "G"
#define STR_REG_H "H"

#define STR_ADD "add"
#define STR_SUB "sub"
#define STR_ROT_L "rot_l"
#define STR_ROT_R "rot_r"
#define STR_XOR "xor"
#define STR_AND "and"
#define STR_OR "or"
#define STR_NOT "not"

#define STR_MOV "mov"
#define STR_MOVAR "movar"
#define STR_MOVRA "movra"

#define STR_PUSH_LOW "push_l"
#define STR_PUSH_HIGH "push_h"

#define STR_PUSH "push"
#define STR_POP "pop"

#define STR_JUMP_IF_E "jmp_e"
#define STR_JUMP_IF_NE "jmp_ne"
#define STR_JUMP_IF_POS "jmp_p"
#define STR_JUMP_IF_NEG "jmp_n"

#define STR_JUMP "jmp"
#define STR_NOP "nop"

static const char* str_registers[] = {
    STR_REG_A, STR_REG_B, STR_REG_C, STR_REG_D,
    STR_REG_E, STR_REG_F, STR_REG_G, STR_REG_H
}; 
static const int str_count_register = sizeof(str_registers)/sizeof(str_registers[0]);

static const char* str_alu[] = {
    STR_ADD, STR_SUB, STR_ROT_L, STR_ROT_R,
    STR_XOR, STR_AND, STR_OR, STR_NOT
};
static const int str_count_alu = sizeof(str_alu)/sizeof(str_alu[0]);

static const char* str_mov[] = {
    STR_MOV, STR_MOVAR, STR_MOVRA
};
static const int str_count_mov = sizeof(str_mov)/sizeof(str_mov[0]);

static const char* str_push[] = {
    STR_PUSH_LOW, STR_PUSH_HIGH,
    STR_PUSH, STR_POP
};
static const int str_count_push = sizeof(str_push)/sizeof(str_push[0]);

static const char* str_jump[] = {
    STR_JUMP_IF_E, STR_JUMP_IF_NE,
    STR_JUMP_IF_POS, STR_JUMP_IF_NEG,
    STR_JUMP, STR_NOP
};
static const int str_count_jump = sizeof(str_jump)/sizeof(str_jump[0]);

static struct HashTable* hash_table_create(int size);
static struct HashEntry* create_entry(const char *key, int opcode);
static bool hash_table_insert(struct HashTable *table, const char *key, int opcode);
static unsigned int hash_table_get(struct HashTable *table, const char *key);
static bool hash_table_remove(struct HashTable *table, const char *key);
static void hash_table_destroy(struct HashTable *table);
static void hash_table_print(struct HashTable *table);

struct HashTable* init_hash_table();
unsigned int read_instruction(struct instruction inst, struct HashTable* dict);

#endif
