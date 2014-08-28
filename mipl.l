/*
	 mipl.l - a flex specification for the MIPL language

	Author: Nathan Jarus
	Class: CS 5500

*/

%{

#include <string.h>

#define T_ASSIGN 1
#define T_MULT 2
#define T_PLUS 3
#define T_MINUS 4
#define T_DIV 5
#define T_AND 6
#define T_OR 7
#define T_NOT 8
#define T_LT 9
#define T_GT 10
#define T_LE 11
#define T_GE 12
#define T_EQ 13
#define T_NE 14
#define T_VAR 15
#define T_ARRAY 16
#define T_OF 17
#define T_BOOL 18
#define T_CHAR 19
#define T_INT 20
#define T_PROG 21
#define T_PROC 22
#define T_BEGIN 23
#define T_END 24
#define T_WHILE 26
#define T_DO 27
#define T_IF 28
#define T_THEN 29
#define T_ELSE 30
#define T_READ 31
#define T_WRITE 32
#define T_TRUE 33 
#define T_FALSE 34
#define T_LBRACK 35
#define T_RBRACK 36
#define T_SCOLON 37
#define T_COLON 38
#define T_LPAREN 39
#define T_RPAREN 40
#define T_COMMA 41
#define T_DOT 42
#define T_DOTDOT 43
#define T_INTCONST 44
#define T_CHARCONST 45
#define T_UNKNOWN 46
#define T_IDENT 47

	const char* MAX_INT_STR = "2147483647";
	
	void printToken(const char* token, const char* lexeme);

%}

INTCONST [0-9]+
CHARCONST '.'
INVALIDCHARCONST ''?
IDENT [a-zA-Z_][a-zA-Z0-9_]*
WHITESPACE [ \t\r\n]+

%x comment
%%

"(*" { /* Comment handling comes first so other rules don't match inside comments */
	BEGIN(comment);
}

<comment>[^*]* {} /* Match everything not a * */
<comment>"*"+[^*)]* {} /* Match *s not followed by ) */
<comment>"*)" { /* Match *) */
	BEGIN(INITIAL);
}

":=" {
	printToken("T_ASSIGN", yytext);
	return T_ASSIGN;
}

"*" {
	printToken("T_MULT", yytext);
	return T_MULT;
}

"+" {
	printToken("T_PLUS", yytext);
	return T_PLUS;
}

"-" {
	printToken("T_MINUS", yytext);
	return T_MINUS;
}

"div" {
	printToken("T_DIV", yytext);
	return T_DIV;
}

"and" {
	printToken("T_AND", yytext);
	return T_AND;
}

"or" {
	printToken("T_OR", yytext);
	return T_OR;
}

"not" {
	printToken("T_NOT", yytext);
	return T_NOT;
}

"<" {
	printToken("T_LT", yytext);
	return T_LT;
}

">" {
	printToken("T_GT", yytext);
	return T_GT;
}

"<=" {
	printToken("T_LE", yytext);
	return T_LE;
}

">=" {
	printToken("T_GE", yytext);
	return T_GE;
}

"=" {
	printToken("T_EQ", yytext);
	return T_EQ;
}

"<>" {
	printToken("T_NE", yytext);
	return T_NE;
}

"var" {
	printToken("T_VAR", yytext);
	return T_VAR;
}

"array" {
	printToken("T_ARRAY", yytext);
	return T_ARRAY;
}

"of" {
	printToken("T_OF", yytext);
	return T_OF;
}

"boolean" {
	printToken("T_BOOL", yytext);
	return T_BOOL;
}

"char" {
	printToken("T_CHAR", yytext);
	return T_CHAR;
}

"integer" {
	printToken("T_INT", yytext);
	return T_INT;
}

"program" {
	printToken("T_PROG", yytext);
	return T_PROG;
}

"procedure" {
	printToken("T_PROC", yytext);
	return T_PROC;
}

"begin" {
	printToken("T_BEGIN", yytext);
	return T_BEGIN;
}

"end" {
	printToken("T_END", yytext);
	return T_END;
}

"while" {
	printToken("T_WHILE", yytext);
	return T_WHILE;
}

"do" { 
	printToken("T_DO", yytext);
	return T_DO;
}

"if" {
	printToken("T_IF", yytext);
	return T_IF;
}

"then" {
	printToken("T_THEN", yytext);
	return T_THEN;
}

"else" {
	printToken("T_ELSE", yytext);
	return T_ELSE;
}

"read" {
	printToken("T_READ", yytext);
	return T_READ;
}

"write" {
	printToken("T_WRITE", yytext);
	return T_WRITE;
}

"true" {
	printToken("T_TRUE", yytext);
	return T_TRUE;
}

"false" {
	printToken("T_FALSE", yytext);
	return T_FALSE;
}

"[" {
	printToken("T_LBRACK", yytext);
	return T_LBRACK;
}

"]" {
	printToken("T_RBRACK", yytext);
	return T_RBRACK;
}

";" {
	printToken("T_SCOLON", yytext);
	return T_SCOLON;
}

":" {
	printToken("T_COLON", yytext);
	return T_COLON;
}

"(" {
	printToken("T_LPAREN", yytext);
	return T_LPAREN;
}

")" {
	printToken("T_RPAREN", yytext);
	return T_RPAREN;
}

"," {
	printToken("T_COMMA", yytext);
	return T_COMMA;
}

\.\. {
	printToken("T_DOTDOT", yytext);
	return T_DOTDOT;
}

\. {
	printToken("T_DOT", yytext);
	return T_DOT;
}

{INTCONST} {
	if(strlen(yytext) < strlen(MAX_INT_STR)) {
		printToken("T_INTCONST", yytext);
		return T_INTCONST;
	}
	else if(strlen(yytext) > strlen(MAX_INT_STR)) {
		printf("**** Invalid integer constant: %s\n", yytext);
		//printToken("T_UNKNOWN", yytext);
		return T_UNKNOWN;
	}
	else {
		for(unsigned int i = 0; i < strlen(MAX_INT_STR); i++) {
			if(MAX_INT_STR[i] > yytext[i]) {
				break;
			}
			else if(MAX_INT_STR[i] < yytext[i]) {
				printf("**** Invalid integer constant: %s\n", yytext);
				//printToken("T_UNKNOWN", yytext);
				return T_UNKNOWN;
			}
		}

		printToken("T_INTCONST", yytext);
		return T_INTCONST;
	}
}

{CHARCONST} {
	printToken("T_CHARCONST", yytext);
	return T_CHARCONST;
}

{INVALIDCHARCONST} {
	printf("**** Invalid character constant: %s\n", yytext);
	return T_UNKNOWN;
}

{IDENT} {
	printToken("T_IDENT", yytext);
	return T_IDENT;
}

{WHITESPACE} {}

. {
	printToken("UNKNOWN", yytext);
	return T_UNKNOWN;
}

%%

void printToken(const char* token, const char* lexeme) {
	printf("TOKEN: %s\tLEXEME: %s\n", token, lexeme);
}

int yywrap() { return 1; }

int main() {
	while(yylex());
	return 0;
}

