#ifndef _SYMTABLE_H
#define _SYMTABLE_H

// Header file for the symbol table for variables acquired from the parser

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "hash.h"

enum SCOPE_TYPE {
    SCOPE_FILE = 0,
    SCOPE_FUNCTION,
    SCOPE_BLOCK,
    SCOPE_PROTOTYPE        
};

// The symbol table - one hash table for each scope
struct symTable {
    enum SCOPE_TYPE scope;
    char filename[128];
    int linedeclared;
    
    // For now, only one namespace, else would use an array of hashTables?
    struct hashTable *symbols;
    
    struct symTable *prevTable;
};

struct symbol {
    int linedeclared;
    int value;
    char filename[128];
    int scope;
    
    // Could also store identifier's name, but hash table will take care of that when referencing the symbol
};


// Upon entering new scope (i.e. block scope) append new symbol table onto stack (returns this table)
struct symTable *new_symTable(int scope, char *srcfilename, int linenum, struct symTable *parent);

// Takes current symbol and returns parent symbol table
struct symTable *destroy_symTable(struct symTable *current);

// Create a new symbol (when spotting an identifier)
//struct symbol *newSymbol(int linenum, char *srcfilename, int scope);

// Return 0 if insert successful, else 1 if symbol (IDENT) already exists in current scope, else 2 if table is full
int insertSymbol(struct symTable *destTable, char *identKey, void *ptr);

// Returns value of the symbol
void *getSymbol(struct symTable *current, char *identKey);


#endif
