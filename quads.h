#ifndef _QUADS_H
#define _QUADS_H

#include "ast.h"

enum QUAD_OPS {
    ADD_OP = 0,
    AND_OP,
    ARG_OP,
    BR_OP,
    BRLT_OP,
    BRLE_OP,
    BRGT_OP,
    BRGE_OP,
    BREQ_OP,
    CALL_OP,
    CMP_OP,
    DIV_OP,
    LEA_OP,
    LOAD_OP,
    MOV_OP,
    MOD_OP,
    MUL_OP,
    OR_OP,
    RET_OP,
    STORE_OP,
    SUB_OP,
    SHL_OP,
    SHR_OP,
    XOR_OP,
    BLOCK_OP
};

struct quad {
    int opcode;
    struct astNode *dest, *src1, *src2;
    struct quad *next;
};

struct quadList {
    int size;
    struct quad *start, *end;
};

struct quadBlock {
    int functionCount;
    struct quadList *quadList;
    struct quadBlock *next;
};

// For theoretically being able to handle nested blocks
struct quadBlockList {
    int size;
    struct quadBlock *start, *end;
};


struct quad *new_quad();

struct quadList *new_quadList();

struct quadBlock *new_quadBlock();

struct quadBlockList *new_quadBlockList();

void insert_block(struct quadBlock *block, struct quadBlockList *blockList);

void *genQuads_assignment(struct astNode *node);

void *genQuads_ifstmt(struct astNode *node);

void *genQuads_condition(struct astNode *node);

void genQuads_function(struct astNode *start);

void genQuads_statement(struct astNode *node, struct quadBlockList *blockList);

void *genQuads_fncall(struct astNode *node);

void *genQuads_forloop(struct astNode *node);

void *genQuads_returnstmt(struct astNode *node);

void printQuadList(struct quadBlockList *blockList);

void print_nodeValue(struct astNode *node);

void emit(int opcode, struct astNode *left, struct astNode *right, struct astNode *target);

struct astNode *genQuads_RHS(struct astNode *node, struct astNode *target);

struct astNode *new_tmp();

struct astNode *new_branch();

#endif