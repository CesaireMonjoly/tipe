#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "instructions.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

// Fonction de hachage (djb2)
static unsigned long hash_function(const char *str) {
    unsigned long hash = 5381;
    int c;
    
    while ((c = *str++)) {
        hash = ((hash << 5) + hash) + c;
    }
    
    return hash;
}

// Création d'une nouvelle table
static struct HashTable* hash_table_create(int size) {
    struct HashTable *table = malloc(sizeof(struct HashTable));
    if (!table) return NULL;
    
    table->size = size;
    table->count = 0;
    table->buckets = calloc(size, sizeof(struct HashEntry*));
    
    if (!table->buckets) {
        free(table);
        return NULL;
    }
    
    return table;
}

// Création d'une nouvelle entrée
static struct HashEntry* create_entry(const char *key, int opcode) {
    struct HashEntry *entry = malloc(sizeof(struct HashEntry));
    if (!entry) return NULL;
    
    entry->key = strdup(key);
    if (!entry->key) {
        free(entry);
        return NULL;
    }
    entry->opcode = opcode;
    entry->next = NULL;
    return entry;
}

// Insertion d'un élément
static bool hash_table_insert(struct HashTable *table, const char *key, int instruction) {
    if (!table || !key) return false;
    
    unsigned long index = hash_function(key) % table->size;
    struct HashEntry *entry = table->buckets[index];
    
    // Vérifier si la clé existe déjà
    while (entry) {
        if (strcmp(entry->key, key) == 0) {
            entry->opcode = instruction;
            return true;
        }
        entry = entry->next;
    }
    
    // Créer une nouvelle entrée
    struct HashEntry *new_entry = create_entry(key, instruction);
    if (!new_entry) return false;
    
    // Insérer en tête de liste
    new_entry->next = table->buckets[index];
    table->buckets[index] = new_entry;
    table->count++;
    
    return true;
}

// Recherche d'un élément
static unsigned int hash_table_get(struct HashTable *table, const char *key) {
    if (!table || !key) return -1;
    
    unsigned long index = hash_function(key) % table->size;
    struct HashEntry *entry = table->buckets[index];
    
    while (entry) {
        if (strcmp(entry->key, key) == 0) {
            return entry->opcode;
        }
        entry = entry->next;
    }
    
    return -1;
}

// Suppression d'un élément
static bool hash_table_remove(struct HashTable *table, const char *key) {
    if (!table || !key) return false;
    
    unsigned long index = hash_function(key) % table->size;
    struct HashEntry *entry = table->buckets[index];
    struct HashEntry *prev = NULL;
    
    while (entry) {
        if (strcmp(entry->key, key) == 0) {
            if (prev) {
                prev->next = entry->next;
            } else {
                table->buckets[index] = entry->next;
            }
            
            free(entry->key);
            free(entry);
            table->count--;
            return true;
        }
        
        prev = entry;
        entry = entry->next;
    }
    
    return false;
}

// Destruction de la table
static void hash_table_destroy(struct HashTable *table) {
    if (!table) return;
    
    for (int i = 0; i < table->size; i++) {
        struct HashEntry *entry = table->buckets[i];
        while (entry) {
            struct HashEntry *next = entry->next;
            free(entry->key);
            free(entry);
            entry = next;
        }
    }
    
    free(table->buckets);
    free(table);
}

// Affichage de la table
static void hash_table_print(struct HashTable *table) {
    if (!table) return;
    
    printf("Table de hachage (taille: %d, éléments: %d):\n", table->size, table->count);
    for (int i = 0; i < table->size; i++) {
        if (table->buckets[i]) {
            printf("  [%d]: ", i);
            struct HashEntry *entry = table->buckets[i];
            while (entry) {
                printf("(%s -> %p) ", entry->key, entry->opcode);
                entry = entry->next;
            }
            printf("\n");
        }
    }
}


struct HashTable* init_hash_table() {
    struct HashTable* dict = hash_table_create(50);
    for (int i = 0; i < str_count_register; i++) {
        hash_table_insert(dict, str_registers[i], i);
    }
    for (int i = 0; i < str_count_alu; i++) {
        hash_table_insert(dict, str_alu[i], i);
    }
    for (int i = 0; i < str_count_mov; i++) {
        hash_table_insert(dict, str_mov[i], 8+i);
    }
    for (int i = 0; i < str_count_push; i++) {
        hash_table_insert(dict, str_push[i], 12+i); 
    }
    for (int i = 0; i < str_count_jump; i++) {
        hash_table_insert(dict, str_jump[i], 16+i);
    }
    return dict;
}

unsigned int read_instruction(struct instruction inst, struct HashTable* dict) {
    unsigned int opcode = 0;
    unsigned int inst_opcode, src_opcode, dest_opcode, value_opcode = 0;
    unsigned int mode = 0;
    inst_opcode = hash_table_get(dict, inst.inst);
    if (inst_opcode != OPCODE_PUSH_LOW && inst_opcode != OPCODE_PUSH_HIGH){
        mode = 0;
        src_opcode = hash_table_get(dict, inst.src);
        dest_opcode = hash_table_get(dict, inst.dest);
    } else {
        mode = 1;
        value_opcode = atoi(&inst.dest[1]);
    }
    opcode = src_opcode + (dest_opcode << 3) + (inst_opcode << 6) + (mode << 11);
    return opcode;
}



