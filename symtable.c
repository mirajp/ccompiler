// ECE466 - Symbol Table, relying on underlying hash table, for a parser for a C compiler
// Miraj Patel

#include "symtable.h"

#define FALSE   0
#define TRUE    1


// Upon entering new scope (i.e. block scope) append new symbol table onto stack (returns this table)
struct symTable *new_symTable(int scope, char *srcfilename, int linenum, struct symTable *parent) {
    struct symTable *table;
    
    if ( (table = malloc(sizeof(struct symTable))) == NULL ) {
        fprintf(stderr, "Error allocating memory for new symbol table: '%s'\n", strerror(errno));
        return NULL;
    }
    
    table->scope = scope;
    strcpy(table->filename, srcfilename);
    table->linedeclared = linenum;
    table->symbols = new_hashTable(0);
    table->prevTable = parent;
    
    return table;
}

// Takes current symbol and returns parent symbol table
struct symTable *destroy_symTable(struct symTable *current) {
    struct symTable *newCurr;
    newCurr = current->prevTable;
    current = NULL;
    free(current);
    return newCurr;
}

/*
// Create a new symbol (when spotting an identifier)
struct symbol *newSymbol(int linenum, char *srcfilename, int scope) {
    struct symbol *newSym;
    if ( (newSym = malloc(sizeof(struct symbol))) == NULL ) {
        fprintf(stderr, "Error allocating memory for new symbol table: '%s'\n", strerror(errno));
        return NULL;
    }
    
    newSym->linedeclared = linenum;
    newSym->scope = scope;
    strcpy(newSym->filename, srcfilename);
    
    return newSym;
}
*/

// Return 0 if insert successful, else 1 if symbol (IDENT) already exists in current scope, else 2 if table is full
int insertSymbol(struct symTable *destTable, char *identKey, void *ptr) {
    if ( contains(destTable->symbols, identKey) == TRUE ) {
        return 1;
    }
    
    int ret = insert(destTable->symbols, identKey, ptr); 
    if ( ret == 1) {
        fprintf(stderr, "Strange - 'insertSymbol'/hashentry found identifier already in table, though contains missed it.\n");
        return 1;
    }
    
    else if (ret == 2) {
        fprintf(stderr, "Error: Hash table of symbol entries is full - could not insert identifier: '%s'\n", identKey);
        return 2;
    }
    
    return 0;
}


// Returns value of the symbol
void *getSymbol(struct symTable *current, char *identKey) {
    void *ret = NULL;
    while (current != NULL) {
        ret = getPointer(current->symbols, identKey, NULL);
        if ( ret != NULL ) {
            return ret;
        }
        else  {
            current = current->prevTable;
        }
    }
    
    return ret;
}
