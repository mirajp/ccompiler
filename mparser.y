%error-verbose
%debug
%{
// Miraj Patel, ECE 466 Compilers: Bison Parser in Conjunction with the Flexer
// Expression construction 'inspired' by "C: A Reference Manual" by: Harbison and Steele

// Nonzero YYDEBUG macro enables tracing
#define YYDEBUG 1

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include "symtable.h"
#include "ast.h"
#include "mparser.tab.h"
//
#define FALSE   0
#define TRUE    1

extern int linenum;
extern char filename[128];
//extern int yylex();
extern int yyparse();
extern FILE* yyin;

// Catch errors and print out their verbose error statement
void yyerror(const char *);

struct symTable *currTable;

int stringCount;
%}

%union{
    int val_signed;
    int intval;
    long longval;
    float floatval;
    long double doubleval;
    char charval;
    char *stringval;
    void *voidptr;
    struct astNode *astNode;
}
%token<charval> CHARLIT
%token<stringval> STRING IDENT 
%token<intval> NUMBER

%token<intval> TIMESEQ DIVEQ MODEQ SHLEQ SHREQ ANDEQ OREQ XOREQ PLUSEQ MINUSEQ INDSEL PLUSPLUS MINUSMINUS SHL SHR 
%token<intval> LTEQ GTEQ EQEQ NOTEQ LOGAND LOGOR INLINE INT LONG REGISTER RESTRICT _COMPLEX _IMAGINARY
%token<intval> AUTO BREAK CASE CHAR CONST ELLIPSIS CONTINUE DEFAULT DO DOUBLE ELSE ENUM EXTERN FLOAT FOR GOTO IF 
%token<intval> RETURN SHORT SIGNED SIZEOF STATIC STRUCT SWITCH TYPEDEF UNION UNSIGNED VOID VOLATILE WHILE _BOOL  

%type<intval> type-specifier storage-class-specifier struct-or-union struct-or-union-specifier enum-specifier type-qualifier
%type<astNode> function-call postfix-decrement postfix-increment unary-address-expr unary-bitwise-negation unary-decrement
%type<astNode> unary-increment unary-indirection-expr unary-logical-negation unary-negative unary-positive sizeof-expr 
%type<astNode> assignment-expression compound-statement parenthesized-expression postfix-member-access subscript-expression
%type<astNode> cast-expression unary-expression equality-expression relational-expression shift-expression  postfix-expression
%type<astNode> additive-expression multiplicative-expression inclusive-OR-expression exclusive-OR-expression type-conversion
%type<astNode> AND-expression logical-OR-expression logical-AND-expression constant-expression conditional-expression
%type<astNode> type-name abstract-declarator specifier-qualifier-list pointer direct-abstract-declarator enumation-constant
%type<astNode> parameter-type-list parameter-list parameter-declaration declaration-specifiers jump-statement
%type<astNode> declaration statement labeled-statement expression-statement selection-statement iteration-statement
%type<astNode> struct-declaration type-qualifier-list struct-declarator-list struct-declarator enumerator-list enumerator
%type<astNode> identifier-list primary-expression argument-expr-list expression block-item-list block-item function-definition
%type<astNode> init-declarator-list init-declarator initializer initializer-list declarator direct-declarator function-def-spec


%start translation-unit

%%


translation-unit
    : top-level-declaration
    | translation-unit top-level-declaration
    ;

top-level-declaration
    : function-definition
    | declaration
    ;
    
function-definition
	: function-def-spec '{'     {   // Entering function scope -> create a new symbol table
                                    //fprintf(stderr, "\t- - - Entering new scope on line: %d - - -\n", linenum);
                                    currTable = new_symTable(SCOPE_FUNCTION, filename, linenum, currTable);
                                }
        block-item-list '}'     { // After handling all the statements/declarations, go back to parent scope
                                    currTable = destroy_symTable(currTable);
                                    //fprintf(stderr, "Exiting scope on line: %d\n", linenum);
                                    $$ = $4;
                                    //fprintf(stderr, "Debugging for function '%s'\n", $1->left->attributes.identname);
                                    //print_AST($4);
                                    printf("\n%s:\n",$1->left->attributes.identname );
                                    genQuads_function($4);
                                }
	;

function-def-spec
    : declarator                            {   
                                                $$ = reverse_AST($1, AST_INSERT_LEFT);
                                            }
    | declaration-specifiers declarator     { // Go to left-most node of the specifier if it's a storage class specifier
                                                struct astNode *specifier = $1;
                                                while (specifier->type == AST_STORAGE){
                                                    specifier = specifier->left;
                                                }
                                                
                                                // Insert the declarator ($2) as extension of the left-most node of the specifier
                                                specifier = insert_astNode(specifier, $2, AST_INSERT_LEFT);
                                                
                                                $$ = reverse_AST(specifier, AST_INSERT_LEFT);
                                                
                                                if ($1->type == AST_STORAGE) {
                                                    struct astNode *tmp = $$->left;
                                                    struct astNode *this = $1;
                                                    while (this->left->type == AST_STORAGE){
                                                        this = this->left;
                                                    }
                                                    this->left = tmp;
                                                    $$->left = $1;
                                                }
                                            }
    | declarator declaration-list
    | declaration-specifiers declarator declaration-specifiers
    ;

primary-expression
    : IDENT                 { struct astNode *node = getSymbol(currTable, $1);
                                if ( node == NULL) {
                                    //fprintf(stderr, "%s:%d: (primary-expr:IDENT) Error: undefined variable '%s'\n", filename, linenum, $1);
                                    node = new_astNode(AST_VAR);
                                    node->scope = currTable->scope;
                                    node->attributes.linenum = linenum;
                                    node->attributes.varNum = 0;
                                    node->attributes.identname = strdup($1);
                                    strcpy(node->filename, filename);
                                    int ret = insertSymbol(currTable, $1, node);
                                    //fprintf(stderr, "SECONDARY INSERT RETURNED: %d\n", ret);
                                }
                                
                                $$ = node;
                            }
    | NUMBER                { struct astNode *node = new_astNode(AST_NUM);
                                node->attributes.val = yylval.intval;
                                strcpy(node->filename, filename);
                                $$ = node;
                            }
    | CHARLIT               { struct astNode *node = new_astNode(AST_CHAR);
                                node->attributes.val = (int) yylval.charval;
                                strcpy(node->filename, filename);
                                $$ = node;
                            }
    | STRING                { struct astNode *node = new_astNode(AST_STRING);
                                //printf(".LC%d:\n", stringCount);
                                //printf("\t.string \"%s\"\n", yylval.stringval);
                                strcpy(node->attributes.stringval, yylval.stringval);
                                strcpy(node->filename, filename);
                                $$ = node;
                                
                                //fprintf(stderr, "STRING -- Primary Expr\n");
                            }
    | parenthesized-expression 
    ;

parenthesized-expression
    : '(' expression ')'    { $$ = $2;}
    
postfix-expression
    : primary-expression    { //fprintf(stderr, "(Inside postfix-expr:primary-expr\n");
                                $$ = $1; 
                            }
    | subscript-expression 
    | function-call 
    | type-conversion
    | postfix-member-access
    | postfix-increment 
    | postfix-decrement
    ; 

subscript-expression
    : postfix-expression '[' expression ']'         { //fprintf(stderr, "(Inside postfix-expr:[expr]\n");
                                                        struct astNode *node = new_astNode(AST_UNOP);
                                                        node->attributes.op = '*';
                                                        
                                                        // Treat array indexing as offset to pointer to base
                                                        struct astNode *offset = new_astNode(AST_BINOP);
                                                        offset->attributes.op = '+';
                                                        offset->left = $1;
                                                        offset->right = $3;
                                                        
                                                        node->left = offset;
                                                        strcpy(node->filename, filename);
                                                        $$ = node;
                                                    }
    ;
    
function-call
    : postfix-expression '(' ')'                    { struct astNode *node = new_astNode(AST_FN);
                                                        node->left = $1;
                                                        node->attributes.size = 0;
                                                        node->attributes.linenum = linenum;
                                                        strcpy(node->filename, filename);
                                                        $$ = node; 
                                                    }
    | postfix-expression '(' argument-expr-list ')' { struct astNode *node = new_astNode(AST_FN);  
                                                        node->left = $1;
                                                        node->right = $3;
                                                        int size = 0;
                                                        struct astNode *parent = $3;
                                                        while (parent != NULL) {
                                                            parent = parent->next;
                                                            size++;
                                                        }
                                                        node->attributes.op = 
                                                        node->attributes.size = size;
                                                        node->attributes.linenum = linenum;
                                                        strcpy(node->filename, filename);
                                                        $$ = node; 
                                                    }
    ;
    
type-conversion
    : type-name '(' ')'
    | type-name '(' argument-expr-list ')'
    ;
    
postfix-member-access
    : postfix-expression '.' IDENT                  { //fprintf(stderr, "(Inside postfix-expr:.IDENT\n");
                                                        
                                                    }
    | postfix-expression INDSEL IDENT               { //fprintf(stderr, "(Inside postfix-expr:INDSEL->IDENT\n");
                                                        
                                                    }
    ;
    
postfix-increment
    : postfix-expression PLUSPLUS                   { struct astNode *node = new_astNode(AST_UNOP);
                                                        node->attributes.op = PLUSPLUS;
                                                        node->left = $1;
                                                        strcpy(node->filename, filename);
                                                        $$ = node;
                                                    }
    ;
    
postfix-decrement
    : postfix-expression MINUSMINUS                 { struct astNode *node = new_astNode(AST_UNOP);
                                                        node->attributes.op = MINUSMINUS;
                                                        node->left = $1;
                                                        strcpy(node->filename, filename);
                                                        $$ = node;
                                                    }
    ;
    
argument-expr-list
    : assignment-expression
    | argument-expr-list ',' assignment-expression      { //fprintf(stderr, "ARGUMENT EXPR LIST seen.\n");
                                                            $$ = insert_astNode($1, $3, AST_INSERT_NEXT);
                                                        }
    ;

unary-expression
    : postfix-expression    { //fprintf(stderr, "(Inside unary-expr:postfix-expr\n"); 
                                $$ = $1;
                            }
    | unary-increment 
    | unary-decrement
    | unary-positive 
    | unary-negative 
    | unary-bitwise-negation 
    | unary-logical-negation
    | unary-address-expr
    | unary-indirection-expr
    | sizeof-expr 
    ;

unary-increment
    : PLUSPLUS unary-expression         { struct astNode *node = new_astNode(AST_UNOP);
                                            node->attributes.op = PLUSPLUS;
                                            node->left = $2;
                                            strcpy(node->filename, filename);
                                            $$ = node;
                                        }
    ;
    
unary-decrement
    : MINUSMINUS unary-expression       { struct astNode *node = new_astNode(AST_UNOP);
                                            node->attributes.op = MINUSMINUS;
                                            node->left = $2;
                                            strcpy(node->filename, filename);
                                            $$ = node;
                                        }
    ;

unary-positive
    : '+' cast-expression               { struct astNode *node = new_astNode(AST_UNOP);
                                            node->attributes.op = '+';
                                            node->left = $2;
                                            strcpy(node->filename, filename);
                                            $$ = node;
                                        }
    ;
    
unary-negative
    : '-' cast-expression               { struct astNode *node = new_astNode(AST_UNOP);
                                            node->attributes.op = '-';
                                            node->left = $2;
                                            strcpy(node->filename, filename);
                                            $$ = node;
                                        }
    ;
    
unary-bitwise-negation
    : '~' cast-expression               { struct astNode *node = new_astNode(AST_UNOP);
                                            node->attributes.op = '~';
                                            node->left = $2;
                                            strcpy(node->filename, filename);
                                            $$ = node;
                                        }
    ;
    
unary-logical-negation
    : '!' cast-expression               { struct astNode *node = new_astNode(AST_UNOP);
                                            node->attributes.op = '!';
                                            node->left = $2;
                                            strcpy(node->filename, filename);
                                            $$ = node;
                                        }
    ;
    
unary-address-expr
    : '&' cast-expression               { struct astNode *node = new_astNode(AST_UNOP);
                                            node->attributes.op = '&';
                                            node->left = $2;
                                            strcpy(node->filename, filename);
                                            $$ = node;
                                        }
    ;
    
unary-indirection-expr
    : '*' cast-expression               { struct astNode *node = new_astNode(AST_UNOP);
                                            node->attributes.op = '*';
                                            node->left = $2;
                                            strcpy(node->filename, filename);
                                            $$ = node;
                                        }
    ;
    
sizeof-expr
    : SIZEOF '(' type-name ')'          { struct astNode *node = new_astNode(AST_UNOP);
                                            node->attributes.op = SIZEOF;
                                            node->left = $3;
                                            strcpy(node->filename, filename);
                                            $$ = node;
                                        }
    | SIZEOF unary-expression           { struct astNode *node = new_astNode(AST_UNOP);
                                            node->attributes.op = SIZEOF;
                                            node->left = $2;
                                            strcpy(node->filename, filename);
                                            $$ = node;
                                        }
    ;
    
cast-expression
    : unary-expression                          { //fprintf(stderr, "(Inside cast-expr:unary-expr\n");
                                                    $$ = $1;
                                                }
    | '(' type-name ')' cast-expression         { $$ = $4; }
    ;
    
multiplicative-expression
    : cast-expression                                   { //fprintf(stderr, "(Inside multiplicative-expr:cast-expr\n");
                                                        
                                                        }
    | multiplicative-expression '*' cast-expression     { struct astNode *node = new_astNode(AST_BINOP);
                                                            node->attributes.op = '*';
                                                            node->left = $1;
                                                            node->right = $3;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
    | multiplicative-expression '/' cast-expression     { struct astNode *node = new_astNode(AST_BINOP);
                                                            node->attributes.op = '/';
                                                            node->left = $1;
                                                            node->right = $3;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
    | multiplicative-expression '%' cast-expression     { struct astNode *node = new_astNode(AST_BINOP);
                                                            node->attributes.op = '%';
                                                            node->left = $1;
                                                            node->right = $3;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
    ; 

additive-expression
    : multiplicative-expression                             
    | additive-expression '+' multiplicative-expression     { struct astNode *node = new_astNode(AST_BINOP);
                                                                node->attributes.op = '+';
                                                                node->left = $1;
                                                                node->right = $3;
                                                                strcpy(node->filename, filename);
                                                                $$ = node;
                                                            }
    | additive-expression '-' multiplicative-expression     { struct astNode *node = new_astNode(AST_BINOP);
                                                                node->attributes.op = '-';
                                                                node->left = $1;
                                                                node->right = $3;
                                                                strcpy(node->filename, filename);
                                                                $$ = node;
                                                            }
    ;

shift-expression
    : additive-expression
    | shift-expression SHL additive-expression      { struct astNode *node = new_astNode(AST_BINOP);
                                                        node->attributes.op = SHL;
                                                        node->left = $1;
                                                        node->right = $3;
                                                        strcpy(node->filename, filename);
                                                        $$ = node;
                                                    }
    | shift-expression SHR additive-expression      { struct astNode *node = new_astNode(AST_BINOP);
                                                        node->attributes.op = SHR;
                                                        node->left = $1;
                                                        node->right = $3;
                                                        strcpy(node->filename, filename);
                                                        $$ = node;
                                                    }
    ;

relational-expression
    : shift-expression
    | relational-expression '<' shift-expression    { struct astNode *node = new_astNode(AST_BINOP);
                                                        node->attributes.op = '<';
                                                        node->left = $1;
                                                        node->right = $3;
                                                        strcpy(node->filename, filename);
                                                        $$ = node;
                                                    }
    | relational-expression '>' shift-expression    { struct astNode *node = new_astNode(AST_BINOP);
                                                        node->attributes.op = '>';
                                                        node->left = $1;
                                                        node->right = $3;
                                                        strcpy(node->filename, filename);
                                                        $$ = node;
                                                    }
    | relational-expression LTEQ shift-expression   { struct astNode *node = new_astNode(AST_BINOP);
                                                        node->attributes.op = LTEQ;
                                                        node->left = $1;
                                                        node->right = $3;
                                                        strcpy(node->filename, filename);
                                                        $$ = node;
                                                    }
    | relational-expression GTEQ shift-expression   { struct astNode *node = new_astNode(AST_BINOP);
                                                        node->attributes.op = GTEQ;
                                                        node->left = $1;
                                                        node->right = $3;
                                                        strcpy(node->filename, filename);
                                                        $$ = node;
                                                    }
    ;

equality-expression
    : relational-expression
    | equality-expression EQEQ relational-expression	{ struct astNode *node = new_astNode(AST_BINOP);
                                                            node->attributes.op = EQEQ;
                                                            node->left = $1;
                                                            node->right = $3;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
    | equality-expression NOTEQ relational-expression	{ struct astNode *node = new_astNode(AST_BINOP);
                                                            node->attributes.op = NOTEQ;
                                                            node->left = $1;
                                                            node->right = $3;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
    ;

AND-expression
    : equality-expression
    | AND-expression '&' equality-expression        { struct astNode *node = new_astNode(AST_BINOP);
                                                        node->attributes.op = '&';
                                                        node->left = $1;
                                                        node->right = $3;
                                                        strcpy(node->filename, filename);
                                                        $$ = node;
                                                    }
    ;
    
exclusive-OR-expression
    : AND-expression
    | exclusive-OR-expression '^' AND-expression    { struct astNode *node = new_astNode(AST_BINOP);
                                                        node->attributes.op = '^';
                                                        node->left = $1;
                                                        node->right = $3;
                                                        strcpy(node->filename, filename);
                                                        $$ = node;
                                                    }
    ;
    
inclusive-OR-expression
    : exclusive-OR-expression
    | inclusive-OR-expression '|' exclusive-OR-expression   { struct astNode *node = new_astNode(AST_BINOP);
                                                                node->attributes.op = '|';
                                                                node->left = $1;
                                                                node->right = $3;
                                                                strcpy(node->filename, filename);
                                                                $$ = node;
                                                            }
    ;
    
logical-AND-expression
    : inclusive-OR-expression
    | logical-AND-expression LOGAND inclusive-OR-expression { struct astNode *node = new_astNode(AST_BINOP);
                                                                node->attributes.op = LOGAND;
                                                                node->left = $1;
                                                                node->right = $3;
                                                                strcpy(node->filename, filename);
                                                                $$ = node;
                                                            }
    ;
    
logical-OR-expression
    : logical-AND-expression
    | logical-OR-expression LOGOR logical-AND-expression    { struct astNode *node = new_astNode(AST_BINOP);
                                                                node->attributes.op = LOGOR;
                                                                node->left = $1;
                                                                node->right = $3;
                                                                strcpy(node->filename, filename);
                                                                $$ = node;
                                                            }
    ;
    
conditional-expression
    : logical-OR-expression
    | logical-OR-expression '?' expression ':' conditional-expression	{ struct astNode *node = new_astNode(AST_TERNOP);
                                                                            node->attributes.op = '?';
                                                                            node->condition = $1;
                                                                            node->left = $3;
                                                                            node->right = $5;
                                                                            strcpy(node->filename, filename);
                                                                            $$ = node;
                                                                        }
    ;
    
assignment-expression
    : conditional-expression                            { //fprintf(stderr, "(Inside assign-expr:conditional-expr\n");
                                                            $$ = $1;
                                                        }
    | unary-expression '=' assignment-expression        { //fprintf(stderr, "(Inside assign-expr:unary=assign\n"); 
                                                            struct astNode *node = new_astNode(AST_ASSIGN);
                                                            node->attributes.op = '=';
                                                            node->left = $1;
                                                            node->right = $3;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
    | unary-expression TIMESEQ assignment-expression    { //fprintf(stderr, "(Inside assign-expr:unary=assign\n"); 
                                                            struct astNode *node = new_astNode(AST_ASSIGN);
                                                            node->attributes.op = TIMESEQ;
                                                            node->left = $1;
                                                            struct astNode *intermed = new_astNode(AST_BINOP);
                                                            intermed->attributes.op = '*';
                                                            intermed->left = $1;
                                                            intermed->right = $3;
                                                            node->left = intermed;
                                                            strcpy(node->filename, filename);
                                                            strcpy(intermed->filename, filename);
                                                            $$ = node;
                                                        }
    | unary-expression DIVEQ assignment-expression      { //fprintf(stderr, "(Inside assign-expr:unary=assign\n"); 
                                                            struct astNode *node = new_astNode(AST_ASSIGN);
                                                            node->attributes.op = DIVEQ;
                                                            node->left = $1;
                                                            struct astNode *intermed = new_astNode(AST_BINOP);
                                                            intermed->attributes.op = '/';
                                                            intermed->left = $1;
                                                            intermed->right = $3;
                                                            node->left = intermed;
                                                            strcpy(node->filename, filename);
                                                            strcpy(intermed->filename, filename);
                                                            $$ = node;
                                                        }
    | unary-expression MODEQ assignment-expression      { //fprintf(stderr, "(Inside assign-expr:unary=assign\n"); 
                                                            struct astNode *node = new_astNode(AST_ASSIGN);
                                                            node->attributes.op = MODEQ;
                                                            node->left = $1;
                                                            struct astNode *intermed = new_astNode(AST_BINOP);
                                                            intermed->attributes.op = '%';
                                                            intermed->left = $1;
                                                            intermed->right = $3;
                                                            node->left = intermed;
                                                            strcpy(node->filename, filename);
                                                            strcpy(intermed->filename, filename);
                                                            $$ = node;
                                                        }
    | unary-expression PLUSEQ assignment-expression     { //fprintf(stderr, "(Inside assign-expr:unary=assign\n"); 
                                                            struct astNode *node = new_astNode(AST_ASSIGN);
                                                            node->attributes.op = PLUSEQ;
                                                            node->left = $1;
                                                            struct astNode *intermed = new_astNode(AST_BINOP);
                                                            intermed->attributes.op = '+';
                                                            intermed->left = $1;
                                                            intermed->right = $3;
                                                            node->left = intermed;
                                                            strcpy(node->filename, filename);
                                                            strcpy(intermed->filename, filename);
                                                            $$ = node;
                                                        }
    | unary-expression MINUSEQ assignment-expression    { //fprintf(stderr, "(Inside assign-expr:unary=assign\n"); 
                                                            struct astNode *node = new_astNode(AST_ASSIGN);
                                                            node->attributes.op = MINUSEQ;
                                                            node->left = $1;
                                                            struct astNode *intermed = new_astNode(AST_BINOP);
                                                            intermed->attributes.op = '-';
                                                            intermed->left = $1;
                                                            intermed->right = $3;
                                                            node->left = intermed;
                                                            strcpy(node->filename, filename);
                                                            strcpy(intermed->filename, filename);
                                                            $$ = node;
                                                        }
    | unary-expression SHREQ assignment-expression      { //fprintf(stderr, "(Inside assign-expr:unary=assign\n"); 
                                                            struct astNode *node = new_astNode(AST_ASSIGN);
                                                            node->attributes.op = SHREQ;
                                                            node->left = $1;
                                                            struct astNode *intermed = new_astNode(AST_BINOP);
                                                            intermed->attributes.op = SHR;
                                                            intermed->left = $1;
                                                            intermed->right = $3;
                                                            node->left = intermed;
                                                            strcpy(node->filename, filename);
                                                            strcpy(intermed->filename, filename);
                                                            $$ = node;
                                                        }
    | unary-expression SHLEQ assignment-expression      { //fprintf(stderr, "(Inside assign-expr:unary=assign\n"); 
                                                            struct astNode *node = new_astNode(AST_ASSIGN);
                                                            node->attributes.op = SHLEQ;
                                                            node->left = $1;
                                                            struct astNode *intermed = new_astNode(AST_BINOP);
                                                            intermed->attributes.op = SHL;
                                                            intermed->left = $1;
                                                            intermed->right = $3;
                                                            node->left = intermed;
                                                            strcpy(node->filename, filename);
                                                            strcpy(intermed->filename, filename);
                                                            $$ = node;
                                                        }  
    | unary-expression ANDEQ assignment-expression      { //fprintf(stderr, "(Inside assign-expr:unary=assign\n"); 
                                                            struct astNode *node = new_astNode(AST_ASSIGN);
                                                            node->attributes.op = ANDEQ;
                                                            node->left = $1;
                                                            struct astNode *intermed = new_astNode(AST_BINOP);
                                                            intermed->attributes.op = '&';
                                                            intermed->left = $1;
                                                            intermed->right = $3;
                                                            node->left = intermed;
                                                            strcpy(node->filename, filename);
                                                            strcpy(intermed->filename, filename);
                                                            $$ = node;
                                                        }
    | unary-expression XOREQ assignment-expression      { //fprintf(stderr, "(Inside assign-expr:unary=assign\n"); 
                                                            struct astNode *node = new_astNode(AST_ASSIGN);
                                                            node->attributes.op = XOREQ;
                                                            node->left = $1;
                                                            struct astNode *intermed = new_astNode(AST_BINOP);
                                                            intermed->attributes.op = '^';
                                                            intermed->left = $1;
                                                            intermed->right = $3;
                                                            node->left = intermed;
                                                            strcpy(node->filename, filename);
                                                            strcpy(intermed->filename, filename);
                                                            $$ = node;
                                                        }   
    | unary-expression OREQ assignment-expression       { //fprintf(stderr, "(Inside assign-expr:unary=assign\n"); 
                                                            struct astNode *node = new_astNode(AST_ASSIGN);
                                                            node->attributes.op = OREQ;
                                                            node->left = $1;
                                                            struct astNode *intermed = new_astNode(AST_BINOP);
                                                            intermed->attributes.op = '|';
                                                            intermed->left = $1;
                                                            intermed->right = $3;
                                                            node->left = intermed;
                                                            strcpy(node->filename, filename);
                                                            strcpy(intermed->filename, filename);
                                                            $$ = node;
                                                        }   
    ;

expression
    : assignment-expression                             { //fprintf(stderr, "(Inside expr:assign-expr\n");
                                                            $$ = $1;
                                                        }
    | expression ',' assignment-expression      
    ;

constant-expression
    : conditional-expression
    ;
    
declaration
    : declaration-specifiers ';'                        
    | declaration-specifiers init-declarator-list ';'   
    ;

declaration-specifiers
    : storage-class-specifier                           { //fprintf(stderr, "STORAGE-specifier SEEN\n"); 
                                                            struct astNode *storageNode = new_astNode(AST_STORAGE);
                                                            storageNode->attributes.storage = $1;
                                                            strcpy(storageNode->filename, filename);
                                                            $$ = storageNode;
                                                        }
    | storage-class-specifier declaration-specifiers    { //fprintf(stderr, "STORAGE-specifier with declarations SEEN\n"); 
                                                            struct astNode *storageNode = new_astNode(AST_STORAGE);
                                                            storageNode->attributes.storage = $1;
                                                            strcpy(storageNode->filename, filename);
                                                            
                                                            $$ = insert_astNode(storageNode, $2, AST_INSERT_LEFT);
                                                        }
    | type-specifier                                    { 
                                                            //fprintf(stderr, "TYPE-specifier SEEN\n"); 
                                                            struct astNode *node = new_astNode(AST_TYPE);
                                                            node->attributes.type = $1;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
    | type-specifier declaration-specifiers             { //fprintf(stderr, "TYPE-specifier with declarations SEEN\n"); 
                                                            struct astNode *typeNode = new_astNode(AST_TYPE);
                                                            typeNode->attributes.type = $1;
                                                            fprintf(stderr, "Type = %d\n", $1);
                                                            strcpy(typeNode->filename, filename);
                                                            $$ = insert_astNode($2, typeNode, AST_INSERT_LEFT);
                                                        }
    | type-qualifier                                    { /*
                                                            //fprintf(stderr, "TYPE-qualifier SEEN\n"); 
                                                            struct astNode *node = new_astNode(AST_QUALIFIER);
                                                            node->attributes.type = $1;
                                                            strcpy(node->filename, filename);
                                                            $$ = node; */
                                                        }
    | type-qualifier declaration-specifiers             { /*
                                                            //fprintf(stderr, "TYPE-qualifer SEEN\n"); 
                                                            struct astNode *typeNode = new_astNode(AST_QUALIFIER);
                                                            typeNode->attributes.type = $1;
                                                            strcpy(typeNode->filename, filename); */
                                                            // Ignoring type-qualifers
                                                            $$ = $2;
                                                        }
    ;

init-declarator-list
    : init-declarator                                   { $$ = $1; }
    | init-declarator-list ',' init-declarator          {   
                                                            $$ = insert_astNode($1, $3, AST_INSERT_NEXT);
                                                        }
    ;

init-declarator
    : declarator
    | declarator '=' initializer        { //fprintf(stderr, "init-declarator seen (declarator = initializer)\n");
                                            struct astNode *node = new_astNode(AST_ASSIGN);
                                            node->attributes.op = '=';
                                            node->left = $1;
                                            node->right = $3;
                                            strcpy(node->filename, filename);
                                            $$ = node;
                                        }
    ;
    
storage-class-specifier
    : AUTO 
    | EXTERN 
    | REGISTER 
    | STATIC 
    | TYPEDEF 
    ;

type-specifier
    : VOID          { $$ = KW_VOID; }
    | CHAR          { $$ = KW_CHAR; }
    | SHORT         { $$ = KW_SHORT; }
    | INT           { $$ = KW_INT; }
    | LONG          { $$ = KW_LONG; }
    | FLOAT         { $$ = KW_FLOAT; }
    | DOUBLE        { $$ = KW_DOUBLE; }
    | SIGNED        { $$ = KW_SIGNED; }
    | UNSIGNED      { $$ = KW_UNSIGNED; }
    | struct-or-union-specifier 
    | enum-specifier     
    ;

struct-or-union-specifier
	: struct-or-union '{' struct-declaration-list '}'
	| struct-or-union IDENT '{' struct-declaration-list '}'
	| struct-or-union IDENT
	;

struct-or-union
	: STRUCT 
	| UNION 
	;

struct-declaration-list
	: struct-declaration
	| struct-declaration-list struct-declaration
	;

struct-declaration
	: specifier-qualifier-list struct-declarator-list ';'   { $$ = $1; }
	;

specifier-qualifier-list
    : type-specifier specifier-qualifier-list               { //fprintf(stderr, "TYPE-qualifier SEEN\n"); 
                                                                struct astNode *node = new_astNode(AST_QUALIFIER);
                                                                node->attributes.type = $1;
                                                                strcpy(node->filename, filename);
                                                                
                                                                $$ = $2;
                                                            }
    | type-specifier                                        { //fprintf(stderr, "TYPE-specifier SEEN\n"); 
                                                                struct astNode *node = new_astNode(AST_TYPE);
                                                                node->attributes.type = $1;
                                                                strcpy(node->filename, filename);
                                                                $$ = node;
                                                            }
    | type-qualifier specifier-qualifier-list               { //fprintf(stderr, "TYPE-qualifier SEEN\n"); 
                                                                struct astNode *node = new_astNode(AST_QUALIFIER);
                                                                node->attributes.type = $1;
                                                                strcpy(node->filename, filename);
                                                                
                                                                $$ = $2;
                                                            }
    | type-qualifier                                        { //fprintf(stderr, "TYPE-qualifier SEEN\n"); 
                                                                struct astNode *node = new_astNode(AST_QUALIFIER);
                                                                node->attributes.type = $1;
                                                                strcpy(node->filename, filename);
                                                                $$ = node;
                                                            }
    ;

struct-declarator-list
	: struct-declarator
	| struct-declarator-list ',' struct-declarator          { //fprintf(stderr, "struct declarator list seen.\n");
                                                                $$ = insert_astNode($1, $3, AST_INSERT_NEXT);
                                                            }
	;

struct-declarator
	: declarator                            
	| ':' constant-expression               { $$ = $2; 
                                            }
	| declarator ':' constant-expression    { $$ = $3; }
	;

enum-specifier
	: ENUM '{' enumerator-list '}'
	| ENUM IDENT '{' enumerator-list '}'
	| ENUM IDENT
	;

enumerator-list
	: enumerator
	| enumerator-list ',' enumerator                    { //fprintf(stderr, "ARGUMENT EXPR LIST seen.\n");
                                                            $$ = insert_astNode($1, $3, AST_INSERT_NEXT);
                                                        }
	;

enumerator
	: enumation-constant
	| enumation-constant '=' constant-expression
	;

enumation-constant
    : IDENT                                             { //fprintf(stderr, "\tENUMERATION-CONSTANT ident seen\n");
                                                            //fprintf(stderr, "INSERTING AST SYMBOL FOR '%s'\n", $1);
                                                            struct astNode *node = new_astNode(AST_VAR);
                                                            node->scope = currTable->scope;
                                                            node->attributes.linenum = linenum;
                                                            node->attributes.varNum = 0;
                                                            node->attributes.identname = strdup($1);
                                                            strcpy(node->filename, filename);
                                                            int ret = insertSymbol(currTable, $1, node);
                                                            if (ret == 1) {
                                                                // Symbol already exists
                                                                struct astNode *old = getSymbol(currTable, $1);
                                                                //fprintf(stderr, "%s:%d: (insert-ident) Error: Redeclaration of '%s'; previously declared on line %d.\n", filename, linenum, $1, (int) (old->attributes.linenum));
                                                                $$ = NULL;
                                                            }
                                                            
                                                            if (ret == 2) {
                                                                //fprintf(stderr, "%s:%d: (insert-ident) Error: Cannot add symbol for IDENT '%s'; symbol table is full.\n", filename, linenum, $1);
                                                                $$ = NULL;
                                                            }
                                                            
                                                            else {
                                                                //struct astNode *test = getSymbol(currTable, $1);
                                                                //fprintf(stderr, "\t\tGET SYMBOL AFTER DECLARING = %p\n", test);
                                                                $$ = node;
                                                            }
                                                        }
    ;
    
type-qualifier
    : CONST 
    | VOLATILE 
    ;

declarator
    : pointer direct-declarator
    | direct-declarator             { $$ = $1; }
    ;

direct-declarator
    : IDENT                                             { //fprintf(stderr, "\tDIRECT-DECLR ident seen\n");
                                                            //fprintf(stderr, "INSERTING AST SYMBOL FOR '%s'\n", $1);
                                                            struct astNode *node = new_astNode(AST_VAR);
                                                            node->scope = currTable->scope;
                                                            node->attributes.linenum = linenum;
                                                            node->attributes.varNum = 0;
                                                            node->attributes.identname = strdup($1);
															strcpy(node->filename, filename);
                                                            int ret = insertSymbol(currTable, $1, node);
                                                            if (ret == 1) {
                                                                // Symbol already exists
                                                                struct astNode *old = getSymbol(currTable, $1);
                                                                //fprintf(stderr, "%s:%d: (insert-ident) Error: Redeclaration of '%s'; previously declared on line %d.\n", filename, linenum, $1, (int) (old->attributes.linenum));
                                                            }
                                                            
                                                            if (ret == 2) {
                                                                //fprintf(stderr, "%s:%d: (insert-ident) Error: Cannot add symbol for IDENT '%s'; symbol table is full.\n", filename, linenum, $1);
                                                            }
                                                            
                                                            else {
                                                                //struct astNode *test = getSymbol(currTable, $1);
                                                                //fprintf(stderr, "\t\tGET SYMBOL AFTER DECLARING = %p\n", test);
                                                                $$ = node;
                                                            }
                                                        }
    | '(' declarator ')'                                { //fprintf(stderr, "Parenthesized declarator seen\n");
                                                            $$ = $2; }
    | direct-declarator '[' constant-expression ']'     { //fprintf(stderr, "Array declarator with const expr seen, but not implemented yet.\n");
                                                        }
    | direct-declarator '[' ']'                         { //fprintf(stderr, "Array declarator with const expr seen, but not implemented yet.\n");
                                                        }
    | direct-declarator '(' parameter-type-list ')'     { //fprintf(stderr, "Function direct-declarator with parameters seen.\n");
                                                            struct astNode *node = new_astNode(AST_FN);
                                                            node->left = $1;
                                                            node->right = $3;
                                                            node->attributes.linenum = linenum;
                                                            node->attributes.returnType = $1->attributes.storage;
                                                            strcpy(node->filename, filename);
                                                            int size = 0;
                                                            struct astNode *parent = $3;
                                                            while (parent != NULL) {
                                                                parent = parent->next;
                                                                size++;
                                                            }
                                                            node->attributes.size = size;
                                                            
                                                            $$ = insert_astNode(node, $1, AST_INSERT_LEFT);
                                                        } 
    | direct-declarator '(' identifier-list ')'         { //fprintf(stderr, "Function direct-declarator with ident list seen.\n");
                                                            struct astNode *node = new_astNode(AST_FN);
                                                            node->left = $1;
                                                            node->right = $3;
                                                            strcpy(node->filename, filename);
                                                            
                                                            int size = 0;
                                                            struct astNode *parent = $3;
                                                            while (parent != NULL) {
                                                                parent = parent->next;
                                                                size++;
                                                            }
                                                            node->attributes.size = size;
                                                            node->attributes.linenum = linenum;
                                                            $$ = insert_astNode(node, $1, AST_INSERT_LEFT);
                                                        }
    | direct-declarator '(' ')'                         { //fprintf(stderr, "Function direct-declarator alone () seen.\n");
                                                            struct astNode *node = new_astNode(AST_FN);
                                                            node->left = $1;
                                                            node->attributes.linenum = linenum;
                                                            node->attributes.size = 0;
                                                            strcpy(node->filename, filename);
                                                            node->attributes.linenum = linenum;
                                                            $$ = insert_astNode(node, $1, AST_INSERT_LEFT);
                                                        }
    ;
 
pointer
    : '*'                                   { //fprintf(stderr, "POINTER * \n");
                                                $$ = NULL; }
    | '*' type-qualifier-list               { //fprintf(stderr, "POINTER * type-qualifier-list seen \n");
                                                $$ = $2; }
    | '*' pointer                           { //fprintf(stderr, "POINTER * pointer \n");
                                                $$ = $2; }
    | '*' type-qualifier-list  pointer      { //fprintf(stderr, "POINTER * type-qualifier-list pointer \n");
                                                $$ = $3; }
    ;

type-qualifier-list
    : type-qualifier                        { //fprintf(stderr, "TYPE-qualifer SEEN\n"); 
                                                struct astNode *node = new_astNode(AST_QUALIFIER);
                                                node->attributes.type = $1;
                                                strcpy(node->filename, filename);
                                                $$ = node;
                                            }
    | type-qualifier-list type-qualifier    { // Push the type-qualifier (CONST or VOLATILE) onto the list
                                                struct astNode *list = $1;
                                                struct astNode *newItem = (struct astNode *)$2;
                                                if (list != NULL) {
                                                    $$ = insert_astNode(list, newItem, AST_INSERT_NEXT);
                                                }
                                                else {
                                                    $$ = NULL;
                                                }
                                            }
    ;

parameter-type-list
    : parameter-list
    | parameter-list ',' ELLIPSIS           { //fprintf(stderr, "parameter type list with ELLIPSIS seen.\n");
                                                $$ = insert_astNode($1, NULL, AST_INSERT_NEXT);
                                            }
    ;

parameter-list
    : parameter-declaration
    | parameter-list ',' parameter-declaration      { //fprintf(stderr, "paramet list with parameter-declaration seen.\n");
                                                        $$ = insert_astNode($1, $3, AST_INSERT_NEXT);
                                                    }
    ;

parameter-declaration
    : declaration-specifiers declarator
    | declaration-specifiers abstract-declarator
    | declaration-specifiers
    ;

identifier-list
    : IDENT                         { //fprintf(stderr, "\tDIRECT-DECLR ident (list) seen\n");
                                        struct astNode *node = new_astNode(AST_VAR);
                                        node->scope = currTable->scope;
                                        node->attributes.linenum = linenum;
                                        node->attributes.varNum = 0;
                                        node->attributes.identname = strdup($1);
                                        strcpy(node->filename, filename);
                                        
                                        int ret = insertSymbol(currTable, $1, node);
                                        if (ret == 1) {
                                            // Symbol already exists
                                            struct astNode *old = getSymbol(currTable, $1);
                                            //fprintf(stderr, "%s:%d: (insert-ident) Error: Redeclaration of '%s'; previously declared on line %d.\n", filename, linenum, $1, (int) (old->attributes.linenum));
                                        }
                                        
                                        if (ret == 2) {
                                            //fprintf(stderr, "%s:%d: (insert-ident) Error: Cannot add symbol for IDENT '%s'; symbol table is full.\n", filename, linenum, $1);
                                        }
                                    }
    | identifier-list ',' IDENT     { //fprintf(stderr, "\tDIRECT-DECLR ident (list + ',')seen\n");
                                        struct astNode *node = new_astNode(AST_VAR);
                                        node->scope = currTable->scope;
                                        node->attributes.linenum = linenum;
                                        node->attributes.varNum = 0;
                                        node->attributes.identname = strdup($3);
                                        strcpy(node->filename, filename);
                                        
                                        int ret = insertSymbol(currTable, $3, node);
                                        if (ret == 1) {
                                            // Symbol already exists
                                            struct astNode *old = getSymbol(currTable, $3);
                                            //fprintf(stderr, "%s:%d: (insert-ident) Error: Redeclaration of '%s'; previously declared on line %d.\n", filename, linenum, $3, (int) (old->attributes.linenum));
                                        }
                                        
                                        if (ret == 2) {
                                            //fprintf(stderr, "%s:%d: (insert-ident) Error: Cannot add symbol for IDENT '%s'; symbol table is full.\n", filename, linenum, $3);
                                        }
                                        
                                        $$ = insert_astNode($1, node, AST_INSERT_NEXT);
                                    }
    ;
    
type-name
    : specifier-qualifier-list
    | specifier-qualifier-list abstract-declarator
    ;

abstract-declarator
    : pointer
    | direct-abstract-declarator
    | pointer direct-abstract-declarator
    ;
   
direct-abstract-declarator
    : '(' abstract-declarator ')'                               { $$ = $2; }
    | '[' ']'                                                   { $$ = NULL; }
    | '[' constant-expression ']'                               { $$ = $2; }
    | direct-abstract-declarator '[' ']'                        { $$ = $1; }
    | direct-abstract-declarator '[' constant-expression ']'    { $$ = $1; }
    | '(' ')'                                                   { $$ = NULL; }
    | '(' parameter-type-list ')'                               { $$ = $2; }    
    | direct-abstract-declarator '(' ')'                        { $$ = $1; }
    | direct-abstract-declarator '(' parameter-type-list ')'    { $$ = $1; }
    ;
 
initializer
    : assignment-expression             { }
    | '{' initializer-list '}'          { $$ = $2; }
    | '{' initializer-list ',' '}'      { $$ = $2; }
    ;

initializer-list
    : initializer
    | initializer-list ',' initializer  { //fprintf(stderr, "initializer-list seen.\n");
                                            $$ = insert_astNode($1, $3, AST_INSERT_NEXT);
                                        }
    ;

statement
    : labeled-statement
    | compound-statement
    | expression-statement
    | selection-statement
    | iteration-statement
    | jump-statement
    ;

labeled-statement
	: IDENT ':' statement                       { $$ = NULL; }
	| CASE constant-expression ':' statement    { $$ = NULL; }
	| DEFAULT ':' statement                     { $$ = NULL; }
	;

compound-statement
    : '{' '}'               { $$ = NULL; }
    | '{'                   { // Entering block scope -> create a new symbol table
                                //fprintf(stderr, "\t- - - Entering new scope on line: %d - - -\n", linenum);
                                currTable = new_symTable(SCOPE_BLOCK, filename, linenum, currTable);
                            }
        block-item-list '}' { // After handling all the statements/declarations, go back to parent scope
                                currTable = destroy_symTable(currTable);
                                //fprintf(stderr, "\t- - - Exiting scope on line: %d - - -\n", linenum);
                                $$ = $3;
                            }
    ;

block-item-list
    : block-item 
    | block-item-list block-item        { // Push the block-item (declaration or statement) onto the list
                                            $$ = insert_astNode($1, $2, AST_INSERT_NEXT);
                                        }
    ;


block-item
    : declaration       
    | statement         
    ;

declaration-list
    : declaration
    | declaration-list declaration
    ;
    

expression-statement
    : ';'               { $$ = NULL; }
    | expression ';'    { $$ = $1; }
    ;

selection-statement
	: IF '(' expression ')' statement                   { //fprintf(stderr, "IF selection statement seen\n"); 
                                                            struct astNode *node = new_astNode(AST_IF);
                                                            node->attributes.type = $1;
                                                            node->condition = $3;
                                                            node->if_true = $5;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
	| IF '(' expression ')' statement ELSE statement    { //fprintf(stderr, "IF+ELSE selection statement seen\n"); 
                                                            struct astNode *node = new_astNode(AST_IFELSE);
                                                            node->attributes.type = $6;
                                                            node->condition = $3;
                                                            node->if_true = $5;
                                                            node->else_true = $7;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
	| SWITCH '(' expression ')' statement               { $$ = NULL; }
	;

iteration-statement
	: WHILE '(' expression ')' statement                { //fprintf(stderr, "WHILE iteration statement seen\n"); 
                                                            struct astNode *node = new_astNode(AST_WHILE);
                                                            node->attributes.type = $1;
                                                            node->condition = $3;
                                                            node->if_true = $5;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
	| DO statement WHILE '(' expression ')' ';'         { //fprintf(stderr, "DO+WHILE iteration statement seen\n"); 
                                                            struct astNode *node = new_astNode(AST_DO);
                                                            node->attributes.type = $1;
                                                            node->condition = $5;
                                                            node->if_true = $2;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
    | FOR '('  ';'  ';'  ')' statement                  { //fprintf(stderr, "FOR (1) iteration statement seen\n");
                                                            struct astNode *node = new_astNode(AST_FOR);
                                                            node->attributes.type = $1;
                                                            node->if_true = $6;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
    | FOR '('  ';'  ';' expression ')' statement        { //fprintf(stderr, "FOR (2) iteration statement seen\n");
                                                            struct astNode *node = new_astNode(AST_FOR);
                                                            node->attributes.type = $1;
                                                            node->loopCondition = $5;
                                                            node->if_true = $7;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
    | FOR '('  ';' expression ';'  ')' statement        { //fprintf(stderr, "FOR (3) iteration statement seen\n");
                                                            struct astNode *node = new_astNode(AST_FOR);
                                                            node->attributes.type = $1;
                                                            node->condition = $4;
                                                            node->if_true = $7;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
    | FOR '(' expression ';'  ';'  ')' statement        { //fprintf(stderr, "FOR (4) iteration statement seen\n");
                                                            struct astNode *node = new_astNode(AST_FOR);
                                                            node->attributes.type = $1;
                                                            node->initCondition = $3;
                                                            node->if_true = $7;
                                                            strcpy(node->filename, filename);
                                                            $$ = node;
                                                        }
    | FOR '('  ';' expression ';' expression ')' statement      { //fprintf(stderr, "FOR (5) iteration statement seen\n");
                                                                    struct astNode *node = new_astNode(AST_FOR);
                                                                    node->attributes.type = $1;
                                                                    node->condition = $4;
                                                                    node->loopCondition = $6;
                                                                    node->if_true = $8;
                                                                    strcpy(node->filename, filename);
                                                                    $$ = node;
                                                                }
    | FOR '(' expression ';'  ';' expression ')' statement      { //fprintf(stderr, "FOR (6) iteration statement seen\n");
                                                                    struct astNode *node = new_astNode(AST_FOR);
                                                                    node->attributes.type = $1;
                                                                    node->initCondition = $3;
                                                                    node->loopCondition = $6;
                                                                    node->if_true = $8;
                                                                    strcpy(node->filename, filename);
                                                                    $$ = node;
                                                                }
    | FOR '(' expression ';' expression ';'  ')' statement      { //fprintf(stderr, "FOR (7) iteration statement seen\n");
                                                                    struct astNode *node = new_astNode(AST_FOR);
                                                                    node->attributes.type = $1;
                                                                    node->initCondition = $3;
                                                                    node->condition = $5;
                                                                    node->if_true = $8;
                                                                    strcpy(node->filename, filename);
                                                                    $$ = node;
                                                                }
    | FOR '(' expression ';' expression ';' expression ')' statement    { //fprintf(stderr, "FOR (8) iteration statement seen\n");
                                                                            struct astNode *node = new_astNode(AST_FOR);
                                                                            node->attributes.type = $1;
                                                                            node->initCondition = $3;
                                                                            node->condition = $5;
                                                                            node->loopCondition = $7;
																			node->if_true = $9;
                                                                            strcpy(node->filename, filename);
                                                                            $$ = node;
                                                                        }
	;

jump-statement
	: GOTO IDENT ';'            { $$ = NULL; }
	| CONTINUE ';'              { $$ = NULL; }
	| BREAK ';'                 { $$ = NULL; }
	| RETURN ';'                { //fprintf(stderr, "RETURN jump statement seen\n"); 
                                    struct astNode *node = new_astNode(AST_RETURN);
                                    node->attributes.type = $1;
                                    strcpy(node->filename, filename);
                                    $$ = node;
                                }
	| RETURN expression ';'     { //fprintf(stderr, "RETURN jump statement seen\n"); 
                                    struct astNode *node = new_astNode(AST_RETURN);
                                    node->attributes.type = $1;
                                    node->left = $2;
                                    strcpy(node->filename, filename);
                                    $$ = node;
                                }
	;
    
%%

void yyerror(const char *s) {
	fprintf(stderr, "ERROR IN BISON: %s on line: %d\nyylval.stringval = %s\n", s, linenum, yylval.stringval);
}

main() {
	yydebug = 0;
    currTable = new_symTable(SCOPE_FILE, filename, linenum, NULL);
    yyparse();
    fprintf(stderr, "Parsing completed.\n");
}
