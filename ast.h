#ifndef _AST_H
#define _AST_H

// Header file for the abstract syntax tree nodes used by the parser


#include <stdio.h>
#include <errno.h>
#include "symtable.h"

enum AST_TYPE {
    AST_VAR = 0,
    AST_FN,
    AST_PARAMETERS,
    AST_STORAGE,
    AST_TYPE = 4,
    AST_QUALIFIER,
    AST_STRUCT,
    AST_UNION,
    AST_ASSIGN,
    AST_RETURN,
    AST_NUM = 10,
    AST_CHAR,
    AST_STRING,
    AST_BINOP,
    AST_UNOP,
    AST_TERNOP = 15,
    AST_IF,
    AST_IFELSE,
    AST_FOR,
    AST_WHILE,
    AST_DO = 20,
    AST_SWITCH,
	AST_LABEL
};

enum KW_TYPE {
    KW_INT = 0,
    KW_CHAR,
    KW_DOUBLE,
    KW_LONG,
    KW_SHORT,
    KW_VOID,
    KW_FLOAT,
    KW_SIGNED,
    KW_UNSIGNED    
};

enum AST_INSERT_TYPE {
    AST_INSERT_LEFT = 0,
    AST_INSERT_NEXT = 1
};

struct astNode {
    enum AST_TYPE type;
    int scope;
    char filename[128];
    struct astNode *left, *right, *initCondition, *condition, *loopCondition, *next, *prev, *if_true, *else_true;
    struct attr {
        int size, val, op, storage, type, linenum, returnType, varNum;
        char *identname, stringval[4096];
    } attributes;
    
};


struct astNode *new_astNode(int type);

struct astNode *insert_astNode(struct astNode *parent, struct astNode *node, int insertType);

struct astNode *reverse_AST(struct astNode *parent, int insertType);

void print_astNode(struct astNode *node);

void print_AST(struct astNode *start);

#endif
