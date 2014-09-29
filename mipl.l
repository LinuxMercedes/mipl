/*
	 mipl.l - a flex specification for the MIPL language

	Author: Nathan Jarus
	Class: CS 5500

*/

%option yylineno

%{

#include <string.h>

%}

INTCONST [0-9]+
CHARCONST '.'
INVALIDCHARCONST ''?
IDENT [a-zA-Z_][a-zA-Z0-9_]*
WHITESPACE [ \t]+
NEWLINE [\r\n]

%x comment 
%%

"(*" { /* Comment handling */
	BEGIN(comment);
}

<comment>[^*\n]* {} /* Match everything not a * */

<comment>"*"+[^*)\n]* {} /* Match *s not followed by ) */

<comment>"\n" {}

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

\. {
	printToken("T_DOT", yytext);
	return T_DOT;
}

\.\. {
	printToken("T_DOTDOT", yytext);
	return T_DOTDOT;
}

{INTCONST} {
	/* Eat leading zeros, but keep them for printing */
	/* I'm pretty sure this could have been done with a nice call to strtol... */
	char* text = yytext;
	while(*text == '0' && *(text + 1) != '\0') {
		text++;
	}

	if(strlen(text) < strlen(MAX_INT_STR)) {
		printToken("T_INTCONST", yytext);
		yylval.integer = atol(yytext);
		return T_INTCONST;
	}
	else if(strlen(text) > strlen(MAX_INT_STR)) {
		printf("**** Invalid integer constant: %s\n", yytext);
		return T_UNKNOWN;
	}
	else {
		for(unsigned int i = 0; i < strlen(MAX_INT_STR); i++) {
			if(MAX_INT_STR[i] > text[i]) {
				break;
			}
			else if(MAX_INT_STR[i] < text[i]) {
				printf("**** Invalid integer constant: %s\n", yytext);
				return T_UNKNOWN;
			}
		}

		printToken("T_INTCONST", yytext);
		yylval.integer = atol(yytext);
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
	yylval.text = strdup(yytext);
	return T_IDENT;
}

{WHITESPACE} {}

{NEWLINE} {}

. {
	printToken("UNKNOWN", yytext);
	return T_UNKNOWN;
}

%%


