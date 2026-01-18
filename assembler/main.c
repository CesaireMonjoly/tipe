#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "instructions.h"
#define FST 1 << 11

void print_bin(int n) {
    for (int j = 0; j < 4; j++){
        printf("(%d)", j);
        for (int i = 0; i < 3; i++){
            printf("%d", (n & FST) >> 11);
            n = n << 1;
        }
        printf(" ");
    }
    printf("\n");
    return;
}

int main(int argc, char* argv[]){
    printf("%d\n\n", FST);
    if (argc != 2) {
        fprintf(stderr, "usage : ./comp source.s\n");
        return -1;
    }
    FILE* source = fopen(argv[1], "r");
    if (source == NULL) {
        fprintf(stderr, "source not found\n");
    }
    struct instruction instructions[MAX_INSTRUCTIONS];
    int instruction_count = 0;
    char line[MAX_LINE_LENGTH];

    while (fgets(line, sizeof(line), source) && instruction_count < MAX_INSTRUCTIONS) {
        // Initialiser la structure courante
        struct instruction* current = &instructions[instruction_count];
        current->inst = current->dest = current->src = NULL;

        // Supprimer le point-virgule et le retour à la ligne
        char* semicolon = strchr(line, ';');
        if (semicolon) *semicolon = '\0';
        line[strcspn(line, "\n")] = '\0';

        // Diviser la ligne en tokens
        char* token = strtok(line, " ");
        int token_count = 0;
        
        while (token && token_count < 3) {
            switch(token_count) {
                case 0:
                    current->inst = strdup(token);
                    break;
                case 1:
                    current->dest = strdup(token);
                    break;
                case 2:
                    current->src = strdup(token);
                    break;
            }
            token = strtok(NULL, " ");
            token_count++;
        }
        
        instruction_count++;
    }
    fclose(source);

    // Affichage des résultats pour vérification
    /*
    for (int i = 0; i < instruction_count; i++) {
        printf("Instruction %d:\n", i);
        printf("  inst: %s\n", instructions[i].inst ? instructions[i].inst : "NULL");
        printf("  dest: %s\n", instructions[i].dest ? instructions[i].dest : "NULL");
        printf("  src:  %s\n\n", instructions[i].src ? instructions[i].src : "NULL");
    }
    */

    FILE* dest = fopen("a.out", "r");
    if (dest == NULL) {
        system("touch a.out");
        dest = fopen("a.out", "r");
    }
    struct HashTable* dict = init_hash_table();

    for(int i = 0; i < instruction_count; i++){
        int opcode = read_instruction(instructions[i], dict);
        printf("[%d] : ", i+1);
        print_bin(opcode);

    }


    return 0;
}
