// ECE466 - Quad Generation
// Miraj Patel

#include "quads.h"
#include "mparser.tab.h"

int tempreg, numBranches;
struct quadList *currentList;
struct quadBlockList *currentBlockList;

struct quad *new_quad() {
    struct quad *quad;
    if ( (quad = malloc(sizeof(struct quad))) == NULL) {
        fprintf(stderr, "Error allocating memory for a new quad: '%s'\n", strerror(errno));
        return NULL;
    }
    quad->opcode = -1;
    quad->dest = NULL;
    quad->src1 = NULL;
    quad->src2 = NULL;
    quad->next = NULL;
    return quad;
}

struct quadList *new_quadList() {
    struct quadList *list;
    if ( (list = malloc(sizeof(struct quadList))) == NULL) {
        fprintf(stderr, "Error allocating memory for a new quad list: '%s'\n", strerror(errno));
        return NULL;
    }
    
    list->size = 0;
    list->start = NULL;
    list->end = NULL;
    return list;
}

struct quadBlock *new_quadBlock() {
    struct quadBlock *block;
    if ( (block = malloc(sizeof(struct quadBlock))) == NULL ) {
        fprintf(stderr, "Error allocating memory for a new quad block: '%s'\n", strerror(errno));
        return NULL;
    }
    
    block->functionCount = 0;
    block->next = NULL;
    block->quadList = new_quadList();
    return block;
}

struct quadBlockList *new_quadBlockList() {
    struct quadBlockList *blockList;
    if ( (blockList = malloc(sizeof(struct quadBlockList))) == NULL ) {
        fprintf(stderr, "Error allocating memory for a new quad block list: '%s'\n", strerror(errno));
        return NULL;
    }
    
    blockList->size = 0;
    blockList->start = NULL;
    blockList->end = NULL;
    
    return blockList;
}

void insert_block(struct quadBlock *block, struct quadBlockList *blockList) {
    if (blockList->size == 0) {
        blockList->start = block;
    }
    else {
        blockList->end->next = block;
    }
    
    blockList->size++;
    blockList->end = block;
}

void insert_quad(struct quad *newQuad, struct quadList *quadList) {
    if (quadList->size == 0) {
        quadList->start = newQuad;
    }
    else {
        quadList->end->next = newQuad;
    }
    
    quadList->size++;
    quadList->end = newQuad;
}


void genQuads_function(struct astNode *start) {
    struct quadBlock *block = new_quadBlock();
    struct quadBlockList *blockList = new_quadBlockList();
    
    currentBlockList = blockList;
    
    insert_block(block, blockList);
    currentList = block->quadList;
    while (start != NULL) {
        genQuads_statement(start, blockList);
        start = start->next;
    }
    
    printf("Alloc: %d\n", 4*tempreg);
    printQuadList(blockList);
}

void genQuads_statement(struct astNode *node, struct quadBlockList *blockList) {
    struct quad *newQuad = NULL;
    switch(node->type){
        case AST_ASSIGN:
            genQuads_assignment(node);
            break;
        case AST_IF:
        case AST_IFELSE:
            genQuads_ifstmt(node);
            break;
        case AST_UNOP:
            genQuads_RHS(node, node);
            break;
        case AST_FN:
            genQuads_fncall(node);
            break;
        case AST_RETURN:
            genQuads_returnstmt(node);
            break;
        case AST_FOR:
            genQuads_forloop(node);
            break;
        case AST_WHILE:
            genQuads_whileloop(node);
            break;
        case AST_TYPE:
            break;
        default:
            printf("Unknown AST NODE type %d\n", node->type);
            break;
    }
    /*
    if (newQuad != NULL) {
        insert_quad(newQuad, blockList->end->quadList);
        blockList->size++;
    }
    */
}

struct astNode *genQuads_RHS(struct astNode *node, struct astNode *target) {
    struct astNode *left, *right;
    switch (node->type) {
        case AST_VAR:
            
            if (node->attributes.varNum == 0) {
                tempreg++;
                node->attributes.varNum = tempreg;
            }
            
        case AST_CHAR:
        case AST_NUM:
        case AST_STRING:
            return node;
        
        case AST_BINOP:
            //fprintf(stderr, "RHS sees BINOP\n");
            left = genQuads_RHS(node->left, NULL);
            right = genQuads_RHS(node->right, NULL);
            if (target == NULL) {
                target = new_tmp();
            }
            //fprintf(stderr, "Emitting quad with op = %d in RHS\n", node->attributes.op);
            emit(node->attributes.op, left, right, target);
            return target;
            
        case AST_UNOP:
            left = genQuads_RHS(node->left, NULL);
            emit(node->attributes.op, left, right, target);
            return target;
            
        default:
            fprintf(stderr, "DEFAULT BRANCH OF genquads_rhs\n");
            break;
    }
    
}

void genQuads_assignment(struct astNode *node) {
    struct quad *newQuad = new_quad();
    struct astNode *left = node->left;
    struct astNode *right = genQuads_RHS(node->right, left);
    
    //if (right->type == AST_CHAR || right->type == AST_NUM || right->type == AST_STRING) {
    if (right->type == AST_CHAR || right->type == AST_NUM || right->type == AST_STRING || right->type == AST_VAR) {
        emit(MOV_OP, right, NULL, left);
    }
}

void genQuads_fncall(struct astNode *node) {
    struct astNode *target = new_tmp();
    emit(CALL_OP, node, NULL, target);
    //emit(CALL_OP, node, NULL, NULL);
}

void genQuads_forloop(struct astNode *node) {
    if (node->initCondition)  {
        genQuads_statement(node->initCondition, currentBlockList);
    }
	
    struct astNode *conditionBranch = new_branch();
	struct astNode *trueBranch = new_branch();
	struct astNode *skipBranch = new_branch();
    
    emit(BR_OP, conditionBranch, NULL, NULL);
    if (node->condition) {
        int op = node->condition->attributes.op;
        emit(CMP_OP, node->condition->left, node->condition->right, NULL);
        switch(op) {
            case EQEQ:
                emit(BRNQ_OP, skipBranch, NULL, NULL);
                break;
            case NOTEQ:
                emit(BREQ_OP, skipBranch, NULL, NULL);
                break;
			case '>':
                emit(BRLE_OP, skipBranch, NULL, NULL);
                break;
			case GTEQ:
                emit(BRLT_OP, skipBranch, NULL, NULL);
                break;
			case '<':
				emit(BRGE_OP, skipBranch, NULL, NULL);
                break;
            case LTEQ:
                emit(BRGT_OP, skipBranch, NULL, NULL);
				break;
            default:
                fprintf(stderr, "Unknown conditional operator.\n");
        }
    }
	
	emit(BR_OP, trueBranch, NULL, NULL);
	struct astNode *loopcode = node->if_true;
	while (loopcode != NULL) {
		genQuads_statement(loopcode, currentBlockList);
		loopcode = loopcode->next;
	}
	
	if (node->loopCondition) {
        genQuads_statement(node->loopCondition, currentBlockList);
	}

    emit(JMP_OP, conditionBranch, NULL, NULL);
	emit(BR_OP, skipBranch, NULL, NULL);
}

void genQuads_whileloop(struct astNode *node) {
    struct astNode *conditionBranch = new_branch();
	struct astNode *trueBranch = new_branch();
	struct astNode *skipBranch = new_branch();
    
    emit(BR_OP, conditionBranch, NULL, NULL);
    if (node->condition) {
        int op = node->condition->attributes.op;
        emit(CMP_OP, node->condition->left, node->condition->right, NULL);
        switch(op) {
            case EQEQ:
                emit(BRNQ_OP, skipBranch, NULL, NULL);
                break;
            case NOTEQ:
                emit(BREQ_OP, skipBranch, NULL, NULL);
                break;
			case '>':
                emit(BRLE_OP, skipBranch, NULL, NULL);
                break;
			case GTEQ:
                emit(BRLT_OP, skipBranch, NULL, NULL);
                break;
			case '<':
				emit(BRGE_OP, skipBranch, NULL, NULL);
                break;
            case LTEQ:
                emit(BRGT_OP, skipBranch, NULL, NULL);
				break;
            default:
                fprintf(stderr, "Unknown conditional operator.\n");
        }
    }
	
	emit(BR_OP, trueBranch, NULL, NULL);
	struct astNode *loopcode = node->if_true;
	while (loopcode != NULL) {
		genQuads_statement(loopcode, currentBlockList);
		loopcode = loopcode->next;
	}
	
    emit(JMP_OP, conditionBranch, NULL, NULL);
	emit(BR_OP, skipBranch, NULL, NULL);
}

void genQuads_ifstmt(struct astNode *node) {
    struct astNode *trueBranch = new_branch();
	struct astNode *skipBranch = new_branch();
    
    if (node->condition) {
        int op = node->condition->attributes.op;
        emit(CMP_OP, node->condition->left, node->condition->right, NULL);
        switch(op) {
            case EQEQ:
                emit(BRNQ_OP, skipBranch, NULL, NULL);
                break;
            case NOTEQ:
                emit(BREQ_OP, skipBranch, NULL, NULL);
                break;
			case '>':
                emit(BRLE_OP, skipBranch, NULL, NULL);
                break;
			case GTEQ:
                emit(BRLT_OP, skipBranch, NULL, NULL);
                break;
			case '<':
				emit(BRGE_OP, skipBranch, NULL, NULL);
                break;
            case LTEQ:
                emit(BRGT_OP, skipBranch, NULL, NULL);
				break;
            default:
                fprintf(stderr, "Unknown conditional operator.\n");
        }
    }
	
	emit(BR_OP, trueBranch, NULL, NULL);
	struct astNode *truecode = node->if_true;
	while (truecode != NULL) {
		genQuads_statement(truecode, currentBlockList);
		truecode = truecode->next;
	}
	
    emit(BR_OP, skipBranch, NULL, NULL);
    
    struct astNode *elsecode = node->else_true;
    while (elsecode != NULL) {
        genQuads_statement(elsecode, currentBlockList);
        elsecode = elsecode ->next;
    }
}

void genQuads_returnstmt(struct astNode *node) {
    emit(RET_OP, node->left, NULL, NULL);
}

void emit(int opcode, struct astNode *left, struct astNode *right, struct astNode *target) {
    struct quad *newQuad = new_quad();
    
    switch (opcode) {
        case (int) '*':
            newQuad->opcode = MUL_OP;
            break;
        case (int) '+':
            newQuad->opcode = ADD_OP;
            break;
        case (int) '-':
            newQuad->opcode = SUB_OP;
            break;
        case (int) '/':
            newQuad->opcode = DIV_OP;
            break;
        case (int) '%':
            newQuad->opcode = MOD_OP;
            break;
        /*
        case MOV_OP:
            newQuad->opcode = MOV_OP;
            break;
        */
        default:
            newQuad->opcode = opcode;
            break;
        
    }
    newQuad->dest = target;
    newQuad->src1 = left;
    newQuad->src2 = right;
    
    if (newQuad->opcode == PLUSPLUS) {
        newQuad->dest = newQuad->src1;
        struct astNode *tmpNum = new_astNode(AST_NUM);
        tmpNum->attributes.val = 1;
        newQuad->src2 = tmpNum;
        newQuad->opcode = ADD_OP;
    }
    if (newQuad->opcode == MINUSMINUS) {
        newQuad->dest = newQuad->src1;
        struct astNode *tmpNum = new_astNode(AST_NUM);
        tmpNum->attributes.val = 1;
        newQuad->src2 = tmpNum;
        newQuad->opcode = SUB_OP;
    }
    
    insert_quad(newQuad, currentList);
}

void print_nodeValue(struct astNode *node) {
    if (node) {    
        switch (node->type) {
			case AST_LABEL:
				printf("%s", node->attributes.identname);
				break;
            case AST_VAR:
                if (node->attributes.varNum == 0) {
                    tempreg++;
                    node->attributes.varNum = tempreg;
                }
                //printf("%s", node->attributes.identname);
                printf("%%T%d", node->attributes.varNum);
                
                break;
            case AST_CHAR:
                printf("%c", (char) node->attributes.val);
                break;
            case AST_STRING:
                printf("\"%s\"", node->attributes.stringval);
                break;
            case AST_NUM:
                printf("$%d", node->attributes.val);
                break;
            default:
                if (node->type == AST_BINOP)
                    fprintf(stderr, "SOMEHOW PRINT NODE GOT BINOP\n");
                break;
        }
    }
}

struct astNode *new_tmp() {
    struct astNode *tmp = new_astNode(AST_VAR);
    tempreg++;
    char newName[16];
    sprintf(newName, "%%T%d", tempreg);
    tmp->attributes.identname = strdup(newName);
    return tmp;
}

struct astNode *new_branch() {
    struct astNode *tmp = new_astNode(AST_LABEL);
    numBranches++;
    char newName[16];
    sprintf(newName, "BB%d", numBranches);
    tmp->attributes.identname = strdup(newName);
    return tmp;
}

void genQuads_condition(struct astNode *node) {
    /*
    if (node->type == AST_BINOP) {
        int op = node->attributes.op;
        emit(CMP_OP, node->left, node->right, NULL);
        switch(op) {
            case EQEQ:
                //fprintf(stderr, "EQEQ operator in condition.\n");
                emit(BREQ_OP, 
                break;
            default:
                fprintf(stderr, "Unknown conditional operator.\n");
        }
        
    }
    */
}

void printQuadList(struct quadBlockList *blockList) {
    struct quadBlock *blockiter = blockList->start;
    
    while (blockiter != NULL) {
        struct quadList *list = blockiter->quadList;
        struct quad *quaditer = list->start;
        while (quaditer != NULL) {
            /*
            if (quaditer->dest && quaditer->opcode != CALL_OP)
                printf("\t%s\t= ", quaditer->dest->attributes.identname);
            else if (quaditer->opcode != CALL_OP)
                printf("\t\t");
            */
            
            if (quaditer->dest && quaditer->opcode != CALL_OP) {
                if (quaditer->dest->type == AST_VAR) {
                    if (quaditer->dest->attributes.varNum == 0) {
                        tempreg++;
                        quaditer->dest->attributes.varNum = tempreg;
                    }
                    printf("\t%%T%d = ", quaditer->dest->attributes.varNum);
                }
                else {
                    printf("\t%s = ", quaditer->dest->attributes.identname);
                }
            }
            switch (quaditer->opcode) {
				case BR_OP:
					print_nodeValue(quaditer->src1);
					printf(":\n");
					break;
                case JMP_OP:
                    printf("\tJMP ");
                    print_nodeValue(quaditer->src1);
                    printf("\n");
                    break;
                case MOV_OP:
                    printf("MOV ");
                    print_nodeValue(quaditer->src1);
                    printf("\n");
                    break;
                case MUL_OP:
                    printf("MUL ");
                    print_nodeValue(quaditer->src1);
                    printf(", ");
                    print_nodeValue(quaditer->src2);
                    printf("\n");
                    break;
                case DIV_OP:
                    printf("DIV ");
                    print_nodeValue(quaditer->src1);
                    printf(", ");
                    print_nodeValue(quaditer->src2);
                    printf("\n");
                    break;
                case MOD_OP:
                    printf("MOD ");
                    print_nodeValue(quaditer->src1);
                    printf(", ");
                    print_nodeValue(quaditer->src2);
                    printf("\n");
                    break;
                case ADD_OP:
                    printf("ADD ");
                    print_nodeValue(quaditer->src1);
                    printf(", ");
                    print_nodeValue(quaditer->src2);
                    printf("\n");
                    break;
                case SUB_OP:
                    printf("SUB ");
                    print_nodeValue(quaditer->src1);
                    printf(", ");
                    print_nodeValue(quaditer->src2);
                    printf("\n");
                    break;
                case CMP_OP:
                    printf("\tCMP ");
                    print_nodeValue(quaditer->src1);
                    printf(", ");
                    print_nodeValue(quaditer->src2);
                    printf("\n");
                    break;
                case CALL_OP:
                    if (quaditer->src1->attributes.size > 0) {
                        printf("\tARGBEGIN %d\n", quaditer->src1->attributes.size);
                    }
                    struct astNode *arg = quaditer->src1->right;
                    while (arg != NULL) {
                        printf("\tARG ");
                        print_nodeValue(arg);
                        printf("\n");
                        arg = arg->next;
                    }
                    //struct astNode *target = new_tmp();
                    //printf("\t%s = CALL ", target->attributes.identname);
                    printf("\t%s = CALL ", quaditer->dest->attributes.identname);
                    //print_nodeValue(quaditer->src1->left);
                    printf("%s", quaditer->src1->left->attributes.identname);
                    printf("\n");
                    break;
                case RET_OP:
                    printf("\tRETURN ");
                    print_nodeValue(quaditer->src1);
                    printf("\n");
                    break;
				case BREQ_OP:
                    printf("\tBREQ ");
                    print_nodeValue(quaditer->src1);
                    printf("\n");
                    break;
				case BRNQ_OP:
                    printf("\tBRNQ ");
                    print_nodeValue(quaditer->src1);
                    printf("\n");
					break;
				case BRLE_OP:
                    printf("\tBRLE ");
                    print_nodeValue(quaditer->src1);
                    printf("\n");
					break;
				case BRLT_OP:
					printf("\tBRLT ");
                    print_nodeValue(quaditer->src1);
                    printf("\n");
                    break;
                case BRGE_OP:
                    printf("\tBRGE ");
                    print_nodeValue(quaditer->src1);
                    printf("\n");
					break;
				case BRGT_OP:
                    printf("\tBRGT ");
                    print_nodeValue(quaditer->src1);
                    printf("\n");
					break;
				default:
                    printf("UNKNOWN OP IN PRINT QUAD LIST = %d\n", quaditer->opcode);
                    break;
            }
            quaditer = quaditer->next;
        }
        printf("\n");
        blockiter = blockiter->next;
    }
}
