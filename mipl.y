/*
	mipl.y - a bison specification for the MIPL language

	Author: Nathan Jarus
	Class: CS 5500

*/

%{
#include <cstdio>
#define PRINT_RULES 1

	int lines = 0;

	void printRule(const char* lhs, const char* rhs);
	void printToken(const char* token, const char* lexeme);
	
	int yyerror(const char* s);

	const char* MAX_INT_STR = "2147483647";
	
	extern "C" {
		int yyparse(void);
		int yylex(void);
		int yywrap() { return 1; }
	}

%}

%token T_ASSIGN T_MULT T_PLUS T_MINUS T_DIV T_AND T_OR T_NOT T_LT T_GT T_LE T_GE T_EQ T_NE T_VAR T_ARRAY T_OF T_BOOL T_CHAR T_INT T_PROG T_PROC T_BEGIN T_END T_WHILE T_DO T_IF T_READ T_WRITE T_TRUE T_FALSE T_LBRACK T_RBRACK T_SCOLON T_COLON T_LPAREN T_RPAREN T_COMMA T_DOT T_DOTDOT T_INTCONST T_CHARCONST T_UNKNOWN T_IDENT 

%nonassoc T_THEN T_ELSE

%start N_START

%%

N_START : N_PROG 
	{
		printRule("N_START", "N_PROG");
		printf("\n-- Completed parsing --\n\n");
		return 0;
	}
;

N_PROG_LBL : T_PROG
	{
		printRule("N_RPOG_LBL", "T_PROG");
	}
;

N_PROG : N_PROG_LBL T_IDENT T_SCOLON N_BLOCK
	{
		printRule("N_PROG", "N_PROG_LBL T_IDENT T_SCOLON N_BLOCK");
	}
;

N_BLOCK : N_VAR_DEC_PART N_PROC_DEC_PART N_STMT_PART
	{
		printRule("N_PROG", "N_VAR_DEC_PART N_PROC_DEC_PART N_STMT_PART");
	}
;

N_VAR_DEC_PART : /* epsilon */
	{
		printRule("N_VAR_DEC_PART", "epsilon");
	}
| T_VAR N_VAR_DEC T_SCOLON N_VAR_DEC_LIST
	{ 
		printRule("N_VAR_DEC_PART", "T_VAR N_VAR_DEC T_SCOLON N_VAR_DEC_LIST");
	}
;

N_VAR_DEC_LIST : /* epsilon */
	{
		printRule("N_VAR_DEC_LIST", "epsilon");
	}
| N_VAR_DEC T_SCOLON N_VAR_DEC_LIST
	{
		printRule("N_VAR_DEC_LIST", "N_VAR_DEC T_SCOLON N_VAR_DEC_LIST");
	}
;

N_VAR_DEC : T_IDENT N_IDENT_LIST T_COLON N_TYPE
	{
		printRule("N_VAR_DEC", "T_IDENT N_IDENT_LIST T_COLON N_TYPE");
	}
;

N_IDENT : T_IDENT
	{
		printRule("N_IDENT", "T_IDENT");
	}
;

N_IDENT_LIST : /* epsilon */
	{
		printRule("N_IDENT_LIST", "epsilon");
	} 
| T_COMMA N_IDENT N_IDENT_LIST
	{
		printRule("N_IDENT_LIST", "T_COMMA N_IDENT N_IDENT_LIST");
	}
;

N_TYPE : N_SIMPLE
	{
		printRule("N_TYPE", "N_SIMPLE");
	}
| N_ARRAY
	{
		printRule("N_TYPE", "N_ARRAY");
	}
;

N_ARRAY : T_ARRAY T_LBRACK N_IDX_RANGE T_RBRACK T_OF N_SIMPLE
	{
		printRule("N_ARRAY", "T_ARRAY T_LBRACK N_IDX_RANGE T_RBRACK T_OF N_SIMPLE");
	}
;

N_IDX : N_INTCONST 
	{
		printRule("N_IDX", "N_INTCONST");
	}
;

N_IDX_RANGE : N_IDX T_DOTDOT N_IDX
	{
		printRule("N_IDX_RANGE", "N_IDX T_DOTDOT N_IDX");
	}
;

N_SIMPLE : T_INT
	{
		printRule("N_SIMPLE", "T_INT");
	}
| T_CHAR
	{
		printRule("N_SIMPLE", "T_CHAR");
	}
| T_BOOL
	{
		printRule("N_SIMPLE", "T_BOOL");
	}
;

N_PROC_DEC_PART : /* epsilon */
	{
		printRule("N_PROC_DEC_PART", "epsilon");
	}
| N_PROC_DEC T_SCOLON N_PROC_DEC_PART
	{
		printRule("N_PROC_DEC_PART", "N_PROC_DEC T_SCOLON N_PROC_DEC_PART");
	}
;

N_PROC_DEC : N_PROCHDR N_BLOCK
	{
		printRule("N_PROC_DEC", "N_PROCHDR N_BLOCK");
	}
;

N_PROCHDR : T_PROC T_IDENT T_SCOLON
	{
		printRule("N_PROCHDR", "T_PROC T_IDENT T_SCOLON");
	}
;

N_STMT_PART : N_COMPOUND
	{
		printRule("N_STMT_PART", "N_COMPOUND");
	}
;

N_COMPOUND : T_BEGIN N_STMT N_STMT_LST T_END
	{
		printRule("N_COMPOUND", "T_BEGIN N_STMT N_STMT_LST T_END");
	}
;

N_STMT_LST : /* epsilon */
	{
		printRule("N_STMT_LST", "epsilon");
	}
| T_SCOLON N_STMT N_STMT_LST
	{
		printRule("N_STMT_LST", "T_SCOLON N_STMT N_STMT_LST");
	}
;

N_STMT : N_ASSIGN
	{
		printRule("N_STMT", "N_ASSIGN");
	}
| N_PROC_STMT
	{
		printRule("N_STMT", "N_PROC_STMT");
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
	}
;

N_PROC_STMT : N_PROC_IDENT
	{
		printRule("N_PROC_STMT", "N_PROC_IDENT");
	}
;

N_PROC_IDENT : T_IDENT
	{
		printRule("N_PROC_IDENT", "T_IDENT");
	}
;

N_READ : T_READ T_LPAREN N_INPUT_VAR N_INPUT_LST T_RPAREN
	{
		printRule("N_READ", "T_READ T_LPAREN N_INPUT_VAR N_INPUT_LST T_RPAREN");
	}
;

N_INPUT_LST : /* epsilon */
	{
		printRule("N_INPUT_LIST", "epsilon");
	}						
| T_COMMA N_INPUT_VAR N_INPUT_LST
	{
		printRule("N_INPUT_LST", "T_COMMA N_INPUT_VAR N_INPUT_LST");
	}
;

N_INPUT_VAR : N_VARIABLE
	{
		printRule("N_INPUT_VAR", "N_VARIABLE");
	}
;

N_WRITE : T_WRITE T_LPAREN N_OUTPUT N_OUTPUT_LST T_RPAREN
	{
		printRule("N_WRITE", "T_WRITE T_LPAREN N_OUTPUT N_OUTPUT_LST T_RPAREN");
	}
;

N_OUTPUT_LST : /* epsilon */
	{
		printRule("N_OUTPUT_LIST", "epsilon");
	}						
| T_COMMA N_OUTPUT N_OUTPUT_LST
	{
		printRule("N_OUTPUT_LST", "T_COMMA N_OUTPUT N_OUTPUT_LST");
	}
;

N_OUTPUT : N_EXPR
	{
		printRule("N_OUTPUT", "N_EXPR");
	}
;

N_CONDITION : T_IF N_EXPR T_THEN N_STMT
	{
		printRule("N_CONDITION", "T_IF N_EXPR T_THEN N_STMT");
	}
| T_IF N_EXPR T_THEN N_STMT T_ELSE N_STMT
	{
		printRule("N_CONDITION", "T_IF N_EXPR T_THEN N_STMT T_ELSE N_STMT");
	}
;

N_WHILE : T_WHILE N_EXPR T_DO N_STMT
	{
		printRule("N_WHILE", "T_WHILE N_EXPR T_DO N_STMT");
	}
;

N_EXPR : N_SIMPLE_EXPR
	{
		printRule("N_EXPR", "N_SIMPLE_EXPR");
	}
| N_SIMPLE_EXPR N_REL_OP N_SIMPLE_EXPR
	{
		printRule("N_EXPR", "N_SIMPLE_EXPR N_REL_OP N_SIMPLE_EXPR");
	}
;

N_SIMPLE_EXPR : N_TERM N_ADD_OP_LST
	{
		printRule("N_SIMPLE_EXPR", "N_TERM N_ADD_OP_LST");
	}
;

N_ADD_OP_LST : /* epsilon */
	{
		printRule("N_ADD_OP_LST", "epsilon");
	}
| N_ADD_OP N_TERM N_ADD_OP_LST
	{
		printRule("N_ADD_OP_LST", "N_ADD_OP N_TERM N_ADD_OP_LST");
	}
;

N_TERM : N_FACTOR N_MULT_OP_LST
	{
		printRule("N_TERM", "N_FACTOR N_MULT_OP_LST");
	}
;

N_MULT_OP_LST : /* epsilon */
	{
		printRule("N_MULT_OP_LST", "epsilon");
	}
| N_MULT_OP N_FACTOR N_MULT_OP_LST
	{
		printRule("N_MULT_OP_LST", "N_MULT_OP N_FACTOR N_MULT_OP_LST");
	}
;

N_FACTOR : N_SIGN N_VARIABLE 
	{
		printRule("N_FACTOR", "N_SIGN N_VARIABLE");
	}
| N_CONST
	{
		printRule("N_FACTOR", "N_CONST");
	}
| T_LPAREN N_EXPR T_RPAREN
	{
		printRule("N_FACTOR", "T_LPAREN N_EXPR T_RPAREN");
	}
| T_NOT N_FACTOR
	{
		printRule("N_FACTOR", "T_NOT N_FACTOR");
	}
;

N_SIGN : /* epsilon */
	{
		printRule("N_SIGN", "epsilon");
	}
| T_PLUS
	{
		printRule("N_SIGN", "T_PLUS");
	}
| T_MINUS
	{
		printRule("N_SIGN", "T_MINUS");
	}
;

N_ADD_OP : T_PLUS
	{
		printRule("N_ADD_OP", "T_PLUS");
	}
| T_MINUS
	{
		printRule("N_ADD_OP", "T_MINUS");
	}
| T_OR
	{
		printRule("N_ADD_OP", "T_OR");
	}
;

N_MULT_OP : T_MULT
	{
		printRule("N_MULT_OP", "T_MULT");
	}
| T_DIV
	{
		printRule("N_MULT_OP", "T_DIV");
	}
| T_AND
	{
		printRule("N_MULT_OP", "T_AND");
	}
;

N_REL_OP : T_LT
	{
		printRule("N_REL_OP", "T_LT");
	}
| T_LE
	{
		printRule("N_REL_OP", "T_LE");
	}
| T_NE
	{
		printRule("N_REL_OP", "T_NE");
	}
| T_EQ
	{
		printRule("N_REL_OP", "T_EQ");
	}
| T_GT
	{
		printRule("N_REL_OP", "T_GT");
	}
| T_GE
	{
		printRule("N_REL_OP", "T_GE");
	}
;

N_VARIABLE : N_ENTIRE_VAR
	{
		printRule("N_VARIABLE", "N_ENTIRE_VAR");
	}
| N_IDX_VAR
	{
		printRule("N_VARIABLE", "N_IDX_VAR");
	}
;

N_IDX_VAR : N_ARRAY_VAR T_LBRACK N_EXPR T_RBRACK
	{
		printRule("N_IDX_VAR", "N_ARRAY_VAR T_LBRACK N_EXPR T_RBRACK");
	}
;

N_ARRAY_VAR : N_ENTIRE_VAR
	{
		printRule("N_ARRAY_VAR", "N_ENTIRE_VAR");
	}
;

N_ENTIRE_VAR : N_VAR_IDENT
	{
		printRule("N_ENTIRE_VAR", "N_VAR_IDENT");
	}
;

N_VAR_IDENT : T_IDENT
	{
		printRule("N_VAR_IDENT", "T_IDENT");
	}
;

N_CONST : N_INTCONST
	{
		printRule("N_CONST", "N_INTCONST");
	}
| T_CHARCONST
	{
		printRule("N_CONST", "T_CHARCONST");
	}
| N_BOOLCONST
	{
		printRule("N_CONST", "N_BOOLCONST");
	}
;

N_INTCONST : N_SIGN T_INTCONST
	{
		printRule("N_INTCONST", "N_SIGN T_INTCONST");
	}
;

N_BOOLCONST : T_TRUE
	{
		printRule("N_BOOLCONST", "T_TRUE");
	}
| T_FALSE
	{
		printRule("N_BOOLCONST", "T_FALSE");
	}
;

%%

#include "lex.yy.c"
extern FILE* yyin;

void printToken(const char* token, const char* lexeme) {
	printf("TOKEN: %s\tLEXEME: %s\n", token, lexeme);
}

void printRule(const char* lhs, const char* rhs) {
#ifdef PRINT_RULES
	printf("%s -> %s", lhs, rhs);
#endif
}

int yyerror(const char* s) {
	printf("Line %d: syntax error", lines);
}

int main() {
	do {
		yyparse();
	} while(!feof(yyin));

	return 0;
}

