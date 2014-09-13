/*
	mipl.y - a bison specification for the MIPL language

	Author: Nathan Jarus
	Class: CS 5500

*/

%{
#include <cstdio>
#define PRINT_RULES 1

	int lines = 1;

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
%nonassoc T_THEN %nonassoc T_ELSE

%start N_START

%%

N_START : N_PROG 
	{
		printRule("N_START", "N_PROG");
		printf("\n---- Completed parsing ----\n\n");
		return 0;
	}
;

N_PROGLBL : T_PROG
	{
		printRule("N_PROGLBL", "T_PROG");
	}
;

N_PROG : N_PROGLBL T_IDENT T_SCOLON N_BLOCK T_DOT
	{
		printRule("N_PROG", "N_PROGLBL T_IDENT T_SCOLON N_BLOCK T_DOT");
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

N_VARDECLST : /* epsilon */
	{
		printRule("N_VARDECLST", "epsilon");
	}
| N_VARDEC T_SCOLON N_VARDECLST
	{
		printRule("N_VARDECLST", "N_VARDEC T_SCOLON N_VARDECLST");
	}
;

N_VARDEC : N_IDENT N_IDENTLST T_COLON N_TYPE
	{
		printRule("N_VARDEC", "N_IDENT N_IDENTLST T_COLON N_TYPE");
	}
;

N_IDENT : T_IDENT
	{
		printRule("N_IDENT", "T_IDENT");
	}
;

N_IDENTLST : /* epsilon */
	{
		printRule("N_IDENTLST", "epsilon");
	} 
| T_COMMA N_IDENT N_IDENTLST
	{
		printRule("N_IDENTLST", "T_COMMA N_IDENT N_IDENTLST");
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

N_ARRAY : T_ARRAY T_LBRACK N_IDXRANGE T_RBRACK T_OF N_SIMPLE
	{
		printRule("N_ARRAY", "T_ARRAY T_LBRACK N_IDXRANGE T_RBRACK T_OF N_SIMPLE");
	}
;

N_IDX : N_INTCONST 
	{
		printRule("N_IDX", "N_INTCONST");
	}
;

N_IDXRANGE : N_IDX T_DOTDOT N_IDX
	{
		printRule("N_IDXRANGE", "N_IDX T_DOTDOT N_IDX");
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

N_PROCDECPART : /* epsilon */
	{
		printRule("N_PROCDECPART", "epsilon");
	}
| N_PROCDEC T_SCOLON N_PROCDECPART
	{
		printRule("N_PROCDECPART", "N_PROCDEC T_SCOLON N_PROCDECPART");
	}
;

N_PROCDEC : N_PROCHDR N_BLOCK
	{
		printRule("N_PROCDEC", "N_PROCHDR N_BLOCK");
	}
;

N_PROCHDR : T_PROC T_IDENT T_SCOLON
	{
		printRule("N_PROCHDR", "T_PROC T_IDENT T_SCOLON");
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

N_STMTLST : /* epsilon */
	{
		printRule("N_STMTLST", "epsilon");
	}
| T_SCOLON N_STMT N_STMTLST
	{
		printRule("N_STMTLST", "T_SCOLON N_STMT N_STMTLST");
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
	}
;

N_READ : T_READ T_LPAREN N_INPUTVAR N_INPUTLST T_RPAREN
	{
		printRule("N_READ", "T_READ T_LPAREN N_INPUTVAR N_INPUTLST T_RPAREN");
	}
;

N_INPUTLST : /* epsilon */
	{
		printRule("N_INPUTLST", "epsilon");
	}						
| T_COMMA N_INPUTVAR N_INPUTLST
	{
		printRule("N_INPUTLST", "T_COMMA N_INPUTVAR N_INPUTLST");
	}
;

N_INPUTVAR : N_VARIABLE
	{
		printRule("N_INPUTVAR", "N_VARIABLE");
	}
;

N_WRITE : T_WRITE T_LPAREN N_OUTPUT N_OUTPUTLST T_RPAREN
	{
		printRule("N_WRITE", "T_WRITE T_LPAREN N_OUTPUT N_OUTPUTLST T_RPAREN");
	}
;

N_OUTPUTLST : /* epsilon */
	{
		printRule("N_OUTPUTLST", "epsilon");
	}						
| T_COMMA N_OUTPUT N_OUTPUTLST
	{
		printRule("N_OUTPUTLST", "T_COMMA N_OUTPUT N_OUTPUTLST");
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

N_EXPR : N_SIMPLEEXPR
	{
		printRule("N_EXPR", "N_SIMPLEEXPR");
	}
| N_SIMPLEEXPR N_RELOP N_SIMPLEEXPR
	{
		printRule("N_EXPR", "N_SIMPLEEXPR N_RELOP N_SIMPLEEXPR");
	}
;

N_SIMPLEEXPR : N_TERM N_ADDOPLST
	{
		printRule("N_SIMPLEEXPR", "N_TERM N_ADDOPLST");
	}
;

N_ADDOPLST : /* epsilon */
	{
		printRule("N_ADDOPLST", "epsilon");
	}
| N_ADDOP N_TERM N_ADDOPLST
	{
		printRule("N_ADDOPLST", "N_ADDOP N_TERM N_ADDOPLST");
	}
;

N_TERM : N_FACTOR N_MULTOPLST
	{
		printRule("N_TERM", "N_FACTOR N_MULTOPLST");
	}
;

N_MULTOPLST : /* epsilon */
	{
		printRule("N_MULTOPLST", "epsilon");
	}
| N_MULTOP N_FACTOR N_MULTOPLST
	{
		printRule("N_MULTOPLST", "N_MULTOP N_FACTOR N_MULTOPLST");
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

N_ADDOP : T_PLUS
	{
		printRule("N_ADDOP", "T_PLUS");
	}
| T_MINUS
	{
		printRule("N_ADDOP", "T_MINUS");
	}
| T_OR
	{
		printRule("N_ADDOP", "T_OR");
	}
;

N_MULTOP : T_MULT
	{
		printRule("N_MULTOP", "T_MULT");
	}
| T_DIV
	{
		printRule("N_MULTOP", "T_DIV");
	}
| T_AND
	{
		printRule("N_MULTOP", "T_AND");
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
	}
| N_IDXVAR
	{
		printRule("N_VARIABLE", "N_IDXVAR");
	}
;

N_IDXVAR : N_ARRAYVAR T_LBRACK N_EXPR T_RBRACK
	{
		printRule("N_IDXVAR", "N_ARRAYVAR T_LBRACK N_EXPR T_RBRACK");
	}
;

N_ARRAYVAR : N_ENTIREVAR
	{
		printRule("N_ARRAYVAR", "N_ENTIREVAR");
	}
;

N_ENTIREVAR : N_VARIDENT
	{
		printRule("N_ENTIREVAR", "N_VARIDENT");
	}
;

N_VARIDENT : T_IDENT
	{
		printRule("N_VARIDENT", "T_IDENT");
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
	printf("%s -> %s\n", lhs, rhs);
#endif
}

int yyerror(const char* s) {
	printf("Line %d: syntax error\n", lines);
}

int main() {
	do {
		yyparse();
	} while(!feof(yyin));

	return 0;
}

