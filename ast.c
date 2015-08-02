// ECE466 - Abstract Symbol Table nodes
// Miraj Patel

#include "ast.h"
#include "mparser.tab.h"


struct astNode *new_astNode(int type) {
    struct astNode *node;

    if ( (node = malloc(sizeof(struct astNode))) == NULL ) {
        fprintf(stderr, "Error allocating memory for a new AST node: '%s'\n", strerror(errno));
        return NULL;
    }
    
    node->type = type;
    node->scope = -1;
    strcpy(node->filename, "NO FILENAME");
    node->left = NULL;
    node->right = NULL;
    node->initCondition = NULL;
    node->condition = NULL;
    node->loopCondition = NULL;
    node->next = NULL;
    node->prev = NULL;
    node->if_true = NULL;
    node->else_true = NULL;
    node->attributes.size = -1;
    node->attributes.val = -1;
    node->attributes.op = -1;
    node->attributes.storage = -1;
    node->attributes.type = -1;
    node->attributes.linenum = -1;
    node->attributes.returnType = -1;
    return node;
}

// This function inserts the ast node to the end of a linked list or as a left-hand ast node
struct astNode *insert_astNode(struct astNode *parent, struct astNode *node, int insertType) {
    // If node has no parent, it is its parent
    if (parent == NULL)
        return node;
    
    struct astNode *oldParent = parent;
    
    // If node being inserted is a left-side node (specifiers, declarator, etc.)
    if (insertType == AST_INSERT_LEFT) {
        struct astNode *next = parent->left;

        // Keep traversing down the tree to left most node
        while (parent->left != NULL) {
            parent = parent->left;
        }
        parent->left = node;
    }
    
    // else if node being inserted goes to end of a list
    else if (insertType == AST_INSERT_NEXT) {
        struct astNode *next = parent->next;

        // Keep traversing down the node's linked list to last node
        while (parent->next != NULL) {
            parent = parent->next;
        }
        parent->next = node;
    }
    
    // else unknown/unhandled insertion type
    else {
        return NULL;
    }
    return oldParent;
}

// After building AST backwards, make 2nd pass to reverse it
struct astNode *reverse_AST(struct astNode *parent, int insertType) {
    if (parent == NULL)
        return NULL;
    
    struct astNode *newParent = NULL;
    struct astNode *tmp = NULL;
    
    if (insertType == AST_INSERT_LEFT) {
        while (parent != NULL) {
            tmp = parent->left;
            parent->left = newParent;
            newParent = parent;
            parent = tmp;
        }
    }
    
    else if (insertType == AST_INSERT_NEXT) {
        while (parent != NULL) {
            tmp = parent->next;
            parent->next = newParent;
            newParent = parent;
            parent = tmp;
        }
    }
    
    return newParent;
}

// Print the ASTs formed at end of function definition
void print_AST(struct astNode *start) {
    while (start != NULL){
        print_astNode(start);
        fprintf(stderr, "\n");
        start = start->next;
    }
}

void print_astNode(struct astNode *node) {
    switch (node->type) {
        case AST_VAR:
            fprintf(stderr, "VARIABLE = %s ", node->attributes.identname);
            break;
            
        case AST_ASSIGN:
            fprintf(stderr, "ASSIGNMENT:\tleft: ");
            print_astNode(node->left);
            fprintf(stderr, "\tright: ");
            print_astNode(node->right);
            fprintf(stderr, "\tend of assignment statement.\n");
            break;
            
        case AST_NUM:
            fprintf(stderr, "NUMBER = %d ", node->attributes.val);
            break;
        case AST_CHAR:
            fprintf(stderr, "CHAR = %c ", (char) node->attributes.val);
            break;
        case AST_STRING:
            fprintf(stderr, "STRING = %s ", node->attributes.stringval);
            break;
            
        case AST_BINOP:
            fprintf(stderr, "BINOP = ");
            switch (node->attributes.op) {
                case SHL:
                    fprintf(stderr, "<< ");
                    break;
                case SHR:
                    fprintf(stderr, ">> ");
                    break;
                case LTEQ:
                    fprintf(stderr, "<= ");
                    break;
                case GTEQ:
                    fprintf(stderr, ">= ");
                    break;
                case EQEQ:
                    fprintf(stderr, "== ");
                    break;
                case NOTEQ:
                    fprintf(stderr, "!= ");
                    break;
                case LOGAND:
                    fprintf(stderr, "&& ");
                    break;
                case LOGOR:
                    fprintf(stderr, "|| ");
                    break;
                default:
                    fprintf(stderr, "%c ", (char) node->attributes.op);
                    break;
            }
            
            fprintf(stderr, "\tleft: ");
            print_astNode(node->left);
            fprintf(stderr, "\tright: ");
            print_astNode(node->right);
            fprintf(stderr, "\t\tend of binary op.\n");
            break;
            
        case AST_UNOP:
            fprintf(stderr, "UNOP = ");
            switch (node->attributes.op) {
                case PLUSPLUS:
                    fprintf(stderr, "++ ");
                    break;
                case MINUSMINUS:
                    fprintf(stderr, "-- ");
                    break;
                case '&':
                    fprintf(stderr, "& ");
                    break;
                case '*':
                    fprintf(stderr, "* ");
                    break;
                case '+':
                    fprintf(stderr, "+(positive) ");
                    break;
                case '-':
                    fprintf(stderr, "-(negative) ");
                    break;
                case '~':
                    fprintf(stderr, "~(bitwise negation) ");
                    break;
                case '!':
                    fprintf(stderr, "!(logical negation) ");
                    break;
                case SIZEOF:
                    fprintf(stderr, "SIZEOF ");
                    break;
                case INT:
                    fprintf(stderr, "(cast: int) ");
                    break;
                case CHAR:
                    fprintf(stderr, "(cast: char) ");
                    break;
                default:
                    fprintf(stderr, "(default)%c ", (char) node->attributes.op);
                    break;
            }
            
            if (node->left) {
                fprintf(stderr, "\tunary-left: ");
                print_astNode(node->left);
            }
            if (node->right) {
                fprintf(stderr, "\tunary-right: ");
                print_astNode(node->right);
            }
            fprintf(stderr, "\t\tend of unary op.\n");
            break;
            
        case AST_TERNOP:
            fprintf(stderr, "TERNOP:\t");
            fprintf(stderr, "CONDITION: ");
            print_astNode(node->condition);
            fprintf(stderr, "\tif true, go left: ");
            print_astNode(node->left);
            fprintf(stderr, "\telse false then go right: ");
            print_astNode(node->right);
            fprintf(stderr, "\t\tend of ternary op.\n");
            break;
            
        case AST_IF:
            fprintf(stderr, "IF-STMT:\t");
            fprintf(stderr, "CONDITION: ");
            print_astNode(node->condition);
            fprintf(stderr, "\n\tif true, then: ");
            print_astNode(node->if_true);
            fprintf(stderr, "\t\tend of if statement.\n");
            break;
            
        case AST_IFELSE:
            fprintf(stderr, "IF-ELSE-STMT:\t");
            fprintf(stderr, "CONDITION: ");
            print_astNode(node->condition);
            fprintf(stderr, "\n\tif true, then: ");
            print_astNode(node->if_true);
            fprintf(stderr, "\n\telse: ");
            print_astNode(node->else_true);
            fprintf(stderr, "\t\tend of if/else statement.\n");
            break;
            
        case AST_DO:
            fprintf(stderr, "DO-WHILE LOOP:\t");
            fprintf(stderr, "CONDITION: ");
            print_astNode(node->condition);
            fprintf(stderr, "\n\tif true, then: ");
            print_astNode(node->if_true);
            fprintf(stderr, "\t\tend of do while loop.\n");
            break;
            
        case AST_WHILE:
            fprintf(stderr, "WHILE LOOP:\t");
            fprintf(stderr, "CONDITION: ");
            print_astNode(node->condition);
            fprintf(stderr, "\n\tif true, then: ");
            print_astNode(node->if_true);
            fprintf(stderr, "\t\tend of while loop.\n");
            break;
            
        case AST_FOR:
            fprintf(stderr, "FOR LOOP:\t");
            fprintf(stderr, "CONDITION: ");
            print_astNode(node->condition);
            fprintf(stderr, "\n\tinit condition: ");
            print_astNode(node->initCondition);
            fprintf(stderr, "\n\tloop condition: ");
            print_astNode(node->loopCondition);
            fprintf(stderr, "\t\tend of for loop.\n");
            break;
            
        case AST_FN:
            fprintf(stderr, "FUNCTION (line %d): ", node->attributes.linenum);
            fprintf(stderr, "printing left node...\n\t");
            print_astNode(node->left);
            fprintf(stderr, "\nprinting right node...\n");
            fprintf(stderr, "\t - %d arguments -\n", node->attributes.size);
            struct astNode *arg = node->right;
            int count = 1;
            for (count = 1; count <= (node->attributes.size); count++) {
                fprintf(stderr, "\tArg #%d: \t", count);
                print_astNode(arg);
                arg = arg->next;
                fprintf(stderr, "\n");
            }
            fprintf(stderr, "End of function.\n");
            break;
        
        case AST_STORAGE:
            fprintf(stderr, "STORAGE CLASS = ");
            int storeType = -1;
            storeType = (node->attributes).storage;
            switch (storeType) {
                case KW_INT:
                    fprintf(stderr, "INT\n\t");
                    break;
                case KW_CHAR:
                    fprintf(stderr, "CHAR\n\t");
                    break;
                case KW_LONG:
                    fprintf(stderr, "LONG\n\t");
                    break;
                case KW_DOUBLE:
                    fprintf(stderr, "DOUBLE\n\t");
                    break;
                case KW_VOID:
                    fprintf(stderr, "VOID\n\t");
                    break;
                default:
                    fprintf(stderr, "UNKNOWN = %d\n\t", storeType);
                    break;
                fprintf(stderr, ".\n");
            }
            break;
        
        case AST_TYPE:
            fprintf(stderr, "TYPE SPECIFIER = ");
            int type = -1;
            type = (node->attributes).type;
            switch (type) {
                case KW_INT:
                    fprintf(stderr, "INT\n\t");
                    break;
                case KW_CHAR:
                    fprintf(stderr, "CHAR\n\t");
                    break;
                case KW_LONG:
                    fprintf(stderr, "LONG\n\t");
                    break;
                case KW_DOUBLE:
                    fprintf(stderr, "DOUBLE\n\t");
                    break;
                case KW_VOID:
                    fprintf(stderr, "VOID\n\t");
                    break;
                default:
                    fprintf(stderr, "UNKNOWN = %d\n\t", type);
                    break;
            }
            break;
        
        default:
            fprintf(stderr, "AST TYPE # %d not found in giant switch case!\n", node->type);
            fprintf(stderr, "\tPrinting left node: ");
            print_astNode(node->left);
            fprintf(stderr, "\t\tend of default.\n");
    }
}
