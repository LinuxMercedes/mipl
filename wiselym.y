/* -*- mode: bison-mode */

/**
 * CS 356 Assignment 4: Semantic analysis for MIPL
 *
 * Description: This is a bison parser definition for the MIPL parser
 *
 * Author: Michael Wisely
 * Date: October 8, 2014
 */


%{

/**
 * C Declarations
 * ==============
 */

#include <stdio.h>
#include <list>
#include "string_list.h"
#include "symbol_table_stack.h"

#define PRINT_TOKENS     0
#define PRINT_RULES      0
#define PRINT_SCOPE_INFO 0

extern "C" {
    int yyparse(void);
    int yylex(void);
    int yywrap() { return 1; }
}

typedef enum {
    INTEGER = 0,
    BOOLEAN = 1,
    CHARACTER = 2,
    PROCEDURE = 3,
    PROGRAM = 4,
    ARRAY = 5
} primitive_type;

typedef enum {
    ARITHMETIC = 0,
    LOGICAL = 1,
    UNKNOWN_OP = 2
} operation_type;

typedef enum {
    POSITIVE = 0,
    NEGATIVE = 1,
    UNSPECIFIED = 2
} sign_type;

static const char* primitive_type_names[] = {
    "INTEGER",
    "BOOLEAN",
    "CHAR",
    "PROCEDURE",
    "PROGRAM",
    "ARRAY"
};

typedef struct {
    int start;
    int end;
} index_range;

typedef struct {
    primitive_type type;

    /* To help with Arrays */
    index_range range;
    primitive_type array_type;
} type_info;

void printRule(const char *lhs, const char *rhs);
void enterNewScope();
void exitScope();
void addSymbol(type_info type, char* identifier);
void checkIdent(char* identifier);
void bail(const char* msg);
int yyerror(const char *s);

SymbolTableStack symbols;

%}

/**
 * Bison Declarations
 * ==================
 */

%union {
    int ival;
    char* text;
    index_range range;
    operation_type operation;
    sign_type sign;
    type_info typeInfo;
    string_list_node* idents;
};

%token T_AND
%token T_ARRAY
%token T_ASSIGN
%token T_BEGIN
%token T_BOOL
%token T_CHAR
%token T_CHARCONST
%token T_COLON
%token T_COMMA
%token T_DIV
%token T_DO
%token T_DOT
%token T_DOTDOT
%token T_END
%token T_EQ
%token T_FALSE
%token T_GE
%token T_GT
%token T_IDENT
%token T_IF
%token T_INT
%token T_INTCONST
%token T_LBRACK
%token T_LE
%token T_LPAREN
%token T_LT
%token T_MINUS
%token T_MULT
%token T_NE
%token T_NOT
%token T_OF
%token T_OR
%token T_PLUS
%token T_PROC
%token T_PROG
%token T_RBRACK
%token T_READ
%token T_RPAREN
%token T_SCOLON
%token T_TRUE
%token T_VAR
%token T_WHILE
%token T_WRITE
%token UNKNOWN

%nonassoc T_THEN
%nonassoc T_ELSE

%type   <text>          T_IDENT N_IDENT
%type   <ival>          N_IDX N_INTCONST T_INTCONST
%type   <operation>     N_MULTOP N_ADDOP N_MULTOPLST N_ADDOPLST
%type   <sign>          N_SIGN
%type   <typeInfo>      N_TYPE N_ARRAY N_SIMPLE N_CONST N_BOOLCONST N_EXPR N_SIMPLEEXPR N_FACTOR N_TERM N_OUTPUT N_VARIABLE N_IDXVAR N_ARRAYVAR N_ENTIREVAR N_VARIDENT N_INPUTVAR N_PROCIDENT
%type   <idents>        N_IDENTLST
%type   <range>         N_IDXRANGE

%start N_START

%%

/**
 * Grammar Rules
 * =============
 */

N_START : N_PROG
                {
                    printRule("N_START", "N_PROG");
                    printf("\n---- Completed parsing ----\n");
                }
    ;

N_PROGLBL : T_PROG
                {
                    printRule("N_PROGLBL", "T_PROG");
                }
    ;

N_PROG : N_PROGLBL
                {
                    enterNewScope();
                }
         T_IDENT T_SCOLON
                {
                    printRule("N_PROG", "N_PROGLBL T_IDENT T_SCOLON N_BLOCK T_DOT");

                    type_info p;
                    p.type = PROGRAM;
                    addSymbol(p, $3);
                }
         N_BLOCK T_DOT
                {
                    exitScope();
                }
    ;

N_BLOCK : N_VARDECPART N_PROCDECPART N_STMTPART
                {
                    printRule("N_BLOCK", "N_VARDECPART N_PROCDECPART N_STMTPART");
                }
    ;

N_VARDECPART : /* epsilon */
                {
                    printRule("N_VARDECPART", "epsilon");
                }

             | T_VAR N_VARDEC T_SCOLON N_VARDECLST
                {
                    printRule("N_VARDECPART", "T_VAR N_VARDEC T_SCOLON N_VARDECLST");
                }
    ;

N_VARDECLST : N_VARDEC T_SCOLON N_VARDECLST
                {
                    printRule("N_VARDECLST", "N_VARDEC T_SCOLON N_VARDECLST");
                }

            | /* epsilon */
                {
                    printRule("N_VARDECLST", "epsilon");
                }
    ;

N_VARDEC : N_IDENT N_IDENTLST T_COLON N_TYPE
                {
                    printRule("N_VARDEC", "N_IDENT N_IDENTLST T_COLON N_TYPE");

                    string_list_node *l = addString($2, $1);
                    string_list_node *p = l;
                    while(p != NULL) {
                        addSymbol($4, p->string);
                        p = p->next;
                    }
                    deleteStringList(l);
                }
    ;

N_IDENT : T_IDENT
                {
                    printRule("N_IDENT", "T_IDENT");
                    $$ = $1;
                }
    ;

N_IDENTLST : T_COMMA N_IDENT N_IDENTLST
                {
                    printRule("N_IDENTLST", "T_COMMA N_IDENT N_IDENTLST");
                    $$ = addString($3, $2);
                }

          | /* epsilon */
                {
                    printRule("N_IDENTLST", "epsilon");
                    $$ = newStringList();
                }
    ;

N_TYPE : N_SIMPLE
                {
                    printRule("N_TYPE", "N_SIMPLE");
                    $$ = $1;
                }

     | N_ARRAY
                {
                    printRule("N_TYPE", "N_ARRAY");
                    $$ = $1;
                }
    ;

N_ARRAY : T_ARRAY T_LBRACK N_IDXRANGE T_RBRACK T_OF N_SIMPLE
                {
                    printRule("N_ARRAY", "T_ARRAY T_LBRACK N_IDXRANGE T_RBRACK T_OF N_SIMPLE");
                    $$.type = ARRAY;
                    $$.range = $3;
                    $$.array_type = $6.type;
                }
    ;

N_IDX : N_INTCONST
                {
                    printRule("N_IDX", "N_INTCONST");
                    $$ = $1;
                }
    ;

N_IDXRANGE : N_IDX T_DOTDOT N_IDX
                {
                    printRule("N_IDXRANGE", "N_IDX T_DOTDOT N_IDX");
                    if ($1 > $3) {
                        bail("Start index must be less than or equal to end index of array");
                    }
                    $$.start = $1;
                    $$.end = $3;
                }
    ;

N_SIMPLE : T_INT
                {
                    printRule("N_SIMPLE", "T_INT");
                    $$.type = INTEGER;
                }

       | T_CHAR
                {
                    printRule("N_SIMPLE", "T_CHAR");
                    $$.type = CHARACTER;
                }

       | T_BOOL
                {
                    printRule("N_SIMPLE", "T_BOOL");
                    $$.type = BOOLEAN;
                }
    ;

N_PROCDECPART : N_PROCDEC T_SCOLON N_PROCDECPART
                {
                    printRule("N_PROCDECPART", "N_PROCDEC T_SCOLON N_PROCDECPART");
                }

              | /* epsilon */
                {
                    printRule("N_PROCDECPART", "epsilon");
                }
    ;

N_PROCDEC : N_PROCHDR N_BLOCK
                {
                    printRule("N_PROCDEC", "N_PROCHDR N_BLOCK");
                    exitScope();
                }
    ;

N_PROCHDR : T_PROC T_IDENT T_SCOLON
                {
                    printRule("N_PROCHDR", "T_PROC T_IDENT T_SCOLON");

                    type_info t;
                    t.type = PROCEDURE;
                    addSymbol(t, $2);
                    enterNewScope();
                }
    ;

N_STMTPART : N_COMPOUND
                {
                    printRule("N_STMTPART", "N_COMPOUND");
                }
    ;

N_COMPOUND : T_BEGIN N_STMT N_STMTLST T_END
                {
                    printRule("N_COMPOUND", "T_BEGIN N_STMT N_STMTLST T_END");
                }
    ;

N_STMTLST : T_SCOLON N_STMT N_STMTLST
                {
                    printRule("N_STMTLST", "T_SCOLON N_STMT N_STMTLST");
                }

         | /* epsilon */
                {
                    printRule("N_STMTLST", "epsilon");
                }
    ;

N_STMT : N_ASSIGN
                {
                    printRule("N_STMT", "N_ASSIGN");
                }

     | N_PROCSTMT
                {
                    printRule("N_STMT", "N_PROCSTMT");
                }

     | N_READ
                {
                    printRule("N_STMT", "N_READ");
                }

     | N_WRITE
                {
                    printRule("N_STMT", "N_WRITE");
                }

     | N_CONDITION
                {
                    printRule("N_STMT", "N_CONDITION");
                }

     | N_WHILE
                {
                    printRule("N_STMT", "N_WHILE");
                }

     | N_COMPOUND
                {
                    printRule("N_STMT", "N_COMPOUND");
                }
    ;

N_ASSIGN : N_VARIABLE T_ASSIGN N_EXPR
                {
                    printRule("N_ASSIGN", "N_VARIABLE T_ASSIGN N_EXPR");
                    if ($1.type == ARRAY) {
                        bail("Cannot make assignment to an array");
                    }
                    if ($1.type != $3.type) {
                        bail("Expression must be of same type as variable");
                    }
                }
    ;

N_PROCSTMT : N_PROCIDENT
                {
                    printRule("N_PROCSTMT", "N_PROCIDENT");
                }
    ;

N_PROCIDENT : T_IDENT
                {
                    printRule("N_PROCIDENT", "T_IDENT");
                    checkIdent($1);
                    Var var = symbols.get($1);
                    $$.type = (primitive_type) var.type;
                }
    ;

N_READ : T_READ T_LPAREN N_INPUTVAR N_INPUTLST T_RPAREN
                {
                    printRule("N_READ", "T_READ T_LPAREN N_INPUTVAR N_INPUTLST T_RPAREN");
                    if ($3.type != INTEGER && $3.type != CHARACTER) {
                        bail("Input variable must be of type integer or char");
                    }
                }
    ;

N_INPUTLST : T_COMMA N_INPUTVAR N_INPUTLST
                {
                    printRule("N_INPUTLST", ", N_INPUTVAR N_INPUTLST");
                    if ($2.type != INTEGER && $2.type != CHARACTER) {
                        bail("Input variable must be of type integer or char");
                    }
                }

          | /* epsilon */
                {
                    printRule("N_INPUTLST", "epsilon");
                }
    ;

N_INPUTVAR : N_VARIABLE
                {
                    printRule("N_INPUTVAR", "N_VARIABLE");
                    $$ = $1;
                }
    ;

N_WRITE : T_WRITE T_LPAREN N_OUTPUT N_OUTPUTLST T_RPAREN
                {
                    printRule("N_WRITE", "T_WRITE T_LPAREN N_OUTPUT N_OUTPUTLST T_RPAREN");
                    if ($3.type != INTEGER && $3.type != CHARACTER) {
                        bail("Output expression must be of type integer or char");
                    }
                }
    ;

N_OUTPUTLST : T_COMMA N_OUTPUT N_OUTPUTLST
                {
                    printRule("N_OUTPUTLST", "T_COMMA N_OUTPUT N_OUTPUTLST");
                    if ($2.type != INTEGER && $2.type != CHARACTER) {
                        bail("Output expression must be of type integer or char");
                    }
                }

           | /* epsilon */
                {
                    printRule("N_OUTPUTLST", "epsilon");
                }
    ;

N_OUTPUT : N_EXPR
                {
                    printRule("N_OUTPUT", "N_EXPR");
                    $$ = $1;
                }
    ;

N_CONDITION : T_IF N_EXPR T_THEN N_STMT
                {
                    printRule("N_CONDITION", "T_IF N_EXPR T_THEN N_STMT");
                    if ($2.type != BOOLEAN) {
                        bail("Expression must be of type boolean");
                    }
                }

          | T_IF N_EXPR T_THEN N_STMT T_ELSE N_STMT
                {
                    printRule("N_CONDITION", "T_IF N_EXPR T_THEN N_STMT T_ELSE N_STMT");
                    if ($2.type != BOOLEAN) {
                        bail("Expression must be of type boolean");
                    }
                }
    ;

N_WHILE : T_WHILE N_EXPR
                {
                    if ($2.type != BOOLEAN) {
                        bail("Expression must be of type boolean");
                    }
                }
          T_DO N_STMT
                {
                    printRule("N_WHILE", "T_WHILE N_EXPR T_DO N_STMT");
                }
    ;

N_EXPR : N_SIMPLEEXPR
                {
                    printRule("N_EXPR", "N_SIMPLEEXPR");
                    $$ = $1;
                }

     | N_SIMPLEEXPR N_RELOP N_SIMPLEEXPR
                {
                    printRule("N_EXPR", "N_SIMPLEEXPR N_RELOP N_SIMPLEEXPR");
                    if ($1.type != $3.type) {
                        bail("Expressions must both be int, or both char, or both boolean");
                    }

                    $$.type = BOOLEAN;
                }
    ;

N_SIMPLEEXPR : N_TERM N_ADDOPLST
                {
                    printRule("N_SIMPLEEXPR", "N_TERM N_ADDOPLST");

                    $$ = $1;

                    if ($1.type == BOOLEAN) {
                        if ($2 == ARITHMETIC) {
                            bail("Expression must be of type boolean");
                        }
                    }
                    if ($1.type == INTEGER) {
                        if ($2 == LOGICAL) {
                            bail("Expression must be of type integer");
                        }
                    }
                }
    ;

N_ADDOPLST : N_ADDOP N_TERM N_ADDOPLST
                {
                    printRule("N_ADDOPLST", "N_ADDOP N_TERM N_ADDOPLST");
                    $$ = $1;

                    if ($1 == LOGICAL) {
                        if ($2.type != BOOLEAN || $3 == ARITHMETIC) {
                            bail("Expression must be of type boolean");
                        }
                    }

                    if ($1 == ARITHMETIC) {
                        if ($2.type != INTEGER || $3 == LOGICAL) {
                            bail("Expression must be of type integer");
                        }
                    }
                }

           | /* epsilon */
                {
                    printRule("N_ADDOPLST", "epsilon");
                    $$ = UNKNOWN_OP;
                }
    ;

N_TERM : N_FACTOR N_MULTOPLST
                {
                    printRule("N_TERM", "N_FACTOR N_MULTOPLST");
                    $$ = $1;

                    if ($1.type == BOOLEAN) {
                        if ($2 == ARITHMETIC) {
                            bail("Expression must be of type boolean");
                        }
                    }
                    if ($1.type == INTEGER) {
                        if ($2 == LOGICAL) {
                            bail("Expression must be of type integer");
                        }
                    }
                }
    ;

N_MULTOPLST : N_MULTOP N_FACTOR N_MULTOPLST
                {
                    printRule("N_MULTOPLST", "N_MULTOP N_FACTOR N_MULTOPLST");
                    $$ = $1;

                    if ($1 == LOGICAL) {
                        if ($2.type != BOOLEAN || $3 == ARITHMETIC) {
                            bail("Expression must be of type boolean");
                        }
                    }

                    if ($1 == ARITHMETIC) {
                        if ($2.type != INTEGER || $3 == LOGICAL) {
                            bail("Expression must be of type integer");
                        }
                    }
                }

            | /* epsilon */
                {
                    printRule("N_MULTOPLST", "epsilon");
                    $$ = UNKNOWN_OP;
                }
    ;

N_FACTOR : N_SIGN N_VARIABLE
                {
                    printRule("N_FACTOR", "N_SIGN N_VARIABLE");
                    if ($2.type != INTEGER && $1 != UNSPECIFIED) {
                        bail("Expression must be of type integer");
                    }
                    $$.type = (primitive_type) $2.type;
                }

       | N_CONST
                {
                    printRule("N_FACTOR", "N_CONST");
                    $$ = $1;
                }

       | T_LPAREN N_EXPR T_RPAREN
                {
                    printRule("N_FACTOR", "T_LPAREN N_EXPR T_RPAREN");
                    $$ = $2;
                }

       | T_NOT N_FACTOR
                {
                    printRule("N_FACTOR", "T_NOT N_FACTOR");
                    if ($2.type != BOOLEAN) {
                        bail("Expression must be of type boolean");
                    }

                    $$.type = BOOLEAN;
                }
    ;

N_SIGN : T_PLUS
                {
                    printRule("N_SIGN", "T_PLUS");
                    $$ = POSITIVE;
                }

     | T_MINUS
                {
                    printRule("N_SIGN", "T_MINUS");
                    $$ = NEGATIVE;
                }

     | /* epsilon */
                {
                    printRule("N_SIGN", "epsilon");
                    $$ = UNSPECIFIED;
                }
    ;

N_ADDOP : N_ADDOP_ARITHMETIC
                {
                    printRule("N_ADDOP", "N_ADDOP_ARITHMETIC");
                    $$ = ARITHMETIC;
                }

        | N_ADDOP_LOGICAL
                {
                    printRule("N_ADDOP", "N_ADDOP_LOGICAL");
                    $$ = LOGICAL;
                }
        ;

N_ADDOP_ARITHMETIC : T_PLUS
                {
                    printRule("N_ADDOP_ARITHMETIC", "T_PLUS");
                }

        | T_MINUS
                {
                    printRule("N_ADDOP_ARITHMETIC", "T_MINUS");
                }
       ;

N_ADDOP_LOGICAL : T_OR
                {
                    printRule("N_ADDOP_LOGICAL", "T_OR");
                }
        ;

N_MULTOP : N_MULTOP_ARITHMETIC
                {
                    printRule("N_MULTOP", "N_MULTOP_ARITHMETIC");
                    $$ = ARITHMETIC;
                }

        | N_MULTOP_LOGICAL
                {
                    printRule("N_MULTOP", "N_MULTOP_LOGICAL");
                    $$ = LOGICAL;
                }
        ;


N_MULTOP_ARITHMETIC : T_MULT
                {
                    printRule("N_MULTOP_ARITHMETIC", "T_MULT");
                }

        | T_DIV
                {
                    printRule("N_MULTOP_ARITHMETIC", "T_DIV");
                }
        ;

N_MULTOP_LOGICAL : T_AND
                {
                    printRule("N_MULTOP_LOGICAL", "T_AND");
                }
    ;

N_RELOP : T_LT
                {
                    printRule("N_RELOP", "T_LT");
                }

       | T_LE
                {
                    printRule("N_RELOP", "T_LE");
                }

       | T_NE
                {
                    printRule("N_RELOP", "T_NE");
                }

       | T_EQ
                {
                    printRule("N_RELOP", "T_EQ");
                }

       | T_GT
                {
                    printRule("N_RELOP", "T_GT");
                }

       | T_GE
                {
                    printRule("N_RELOP", "T_GE");
                }
    ;

N_VARIABLE : N_ENTIREVAR
                {
                    printRule("N_VARIABLE", "N_ENTIREVAR");
                    $$ = $1;
                }

         | N_IDXVAR
                {
                    printRule("N_VARIABLE", "N_IDXVAR");
                    $$ = $1;
                }
    ;

N_IDXVAR : N_ARRAYVAR T_LBRACK N_EXPR T_RBRACK
                {
                    printRule("N_IDXVAR", "N_ARRAYVAR T_LBRACK N_EXPR T_RBRACK");
                    if ($1.type != ARRAY) {
                        bail("Indexed variable must be of array type");
                    }
                    if ($3.type != INTEGER) {
                        bail("Index expression must be of type integer");
                    }
                    $$.type = $1.array_type;
                }
    ;

N_ARRAYVAR : N_ENTIREVAR
                {
                    printRule("N_ARRAYVAR", "N_ENTIREVAR");
                    $$ = $1;
                }
    ;

N_ENTIREVAR : N_VARIDENT
                {
                    printRule("N_ENTIREVAR", "N_VARIDENT");
                    $$ = $1;
                }
    ;

N_VARIDENT : T_IDENT
                {
                    printRule("N_VARIDENT", "T_IDENT");
                    checkIdent($1);
                    Var var = symbols.get($1);

                    if (var.type == PROCEDURE) {
                        bail("Procedure/variable mismatch");
                    }

                    $$.type = (primitive_type) var.type;
                    $$.array_type = (primitive_type) var.array_type;
                }
    ;

N_CONST : N_INTCONST
                {
                    printRule("N_CONST", "N_INTCONST");
                    $$.type = INTEGER;
                }

      | T_CHARCONST
                {
                    printRule("N_CONST", "T_CHARCONST");
                    $$.type = CHARACTER;
                }

      | N_BOOLCONST
                {
                    printRule("N_CONST", "N_BOOLCONST");
                    $$ = $1;
                }
    ;

N_INTCONST : N_SIGN T_INTCONST
                {
                    printRule("N_INTCONST", "N_SIGN T_INTCONST");
                    switch($1) {
                    case NEGATIVE:
                        $$ = -1 * $2;
                        break;
                    case POSITIVE:
                    case UNSPECIFIED:
                        $$ = $2;
                        break;
                    }
                }
    ;

N_BOOLCONST : T_TRUE
                {
                    printRule("N_BOOLCONST", "T_TRUE");
                    $$.type = BOOLEAN;
                }

           | T_FALSE
                {
                    printRule("N_BOOLCONST", "T_FALSE");
                    $$.type = BOOLEAN;
                }
    ;

%%

/**
 * More C code, you guys
 * =====================
 */

#include "lex.yy.c"

extern FILE *yyin;

void printRule(const char *lhs, const char *rhs) {
    if (PRINT_RULES) {
        printf("%s -> %s\n", lhs, rhs);
    }
}

void addSymbol(type_info type, char* identifier) {
    const char *type_name = primitive_type_names[type.type];
    char scope_info[500];
    int offset = sprintf(scope_info, "___Adding %s to symbol table with type %s", identifier, type_name);
    Var var;

    if (type.type == ARRAY) {
        const char *array_type_name = primitive_type_names[type.array_type];
        offset += sprintf(scope_info + offset, " %d .. %d OF %s", type.range.start, type.range.end, array_type_name);
        var.array_type = type.array_type;
    }

    if (PRINT_SCOPE_INFO) {
        printf("%s\n", scope_info);
    }

    if (symbols.containsLocal(identifier)){
        bail("Multiply defined identifier");
    }

    var.ident = identifier;
    var.type = type.type;
    symbols.setLocal(identifier, var);
}

void checkIdent(char* identifier) {
    if (!symbols.contains(identifier)){
        bail("Undefined identifier");
    }
}

void enterNewScope() {
    if (PRINT_SCOPE_INFO) {
        printf("\n___Entering new scope...\n\n");
    }
    symbols.openScope();
}

void exitScope() {
    if (PRINT_SCOPE_INFO) {
        printf("\n___Exiting scope...\n\n");
    }
    symbols.closeScope();
}

void bail(const char* msg) {
    printf("Line %d: %s\n", yylineno, msg);
    exit(1);
}

int yyerror(const char *msg) {
    printf("Line %d: %s\n", yylineno, msg);
    return(1);
}

int main() {
    do {
        yyparse();
    } while (!feof(yyin));
    return 0;
}
