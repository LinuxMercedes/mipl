/* -*- mode: bison-mode */

/**
 * CS 356 Assignment 4: Semantic analysis for MIPL
 *
 * Description: This is a flex lexer definition for the MIPL parser
 *
 * Author: Michael Wisely
 * Date: October 8, 2014
 */


/**
 * Definition Section
 * ==================
 */
%{

static const char* MAX_INT = "2147483647";

int precedingZeroes(const char* str);
int strgt(const char* a, const char* b);
void printTokenInfo(const char* name, const char* lexeme);
void printError(const char* message, const char* lexeme);

%}

/* Makes flex track our line number for us (used in parser.y) */
%option yylineno

WHITESPACE    [ \t\r\n]+
LETTER        [a-zA-Z]
DIGIT         [0-9]
INTCONST      {DIGIT}+
IDENT         ({LETTER}|"_")({LETTER}|{DIGIT}|"_")*
CHARCONST     "'"."'"

%%

  /**
   * Rules Section
   * =============
   */

"(" {
    printTokenInfo("T_LPAREN", yytext);
    return T_LPAREN;
}

")" {
    printTokenInfo("T_RPAREN", yytext);
    return T_RPAREN;
}

"*" {
    printTokenInfo("T_MULT", yytext);
    return T_MULT;
}

"+" {
    printTokenInfo("T_PLUS", yytext);
    return T_PLUS;
}

"," {
    printTokenInfo("T_COMMA", yytext);
    return T_COMMA;
}

"-" {
    printTokenInfo("T_MINUS", yytext);
    return T_MINUS;
}

"." {
    printTokenInfo("T_DOT", yytext);
    return T_DOT;
}

".." {
    printTokenInfo("T_DOTDOT", yytext);
    return T_DOTDOT;
}

":" {
    printTokenInfo("T_COLON", yytext);
    return T_COLON;
}

":=" {
    printTokenInfo("T_ASSIGN", yytext);
    return T_ASSIGN;
}

";" {
    printTokenInfo("T_SCOLON", yytext);
    return T_SCOLON;
}

"<" {
    printTokenInfo("T_LT", yytext);
    return T_LT;
}

"<=" {
    printTokenInfo("T_LE", yytext);
    return T_LE;
}

"<>" {
    printTokenInfo("T_NE", yytext);
    return T_NE;
}

"=" {
    printTokenInfo("T_EQ", yytext);
    return T_EQ;
}

">" {
    printTokenInfo("T_GT", yytext);
    return T_GT;
}

">=" {
    printTokenInfo("T_GE", yytext);
    return T_GE;
}

"[" {
    printTokenInfo("T_LBRACK", yytext);
    return T_LBRACK;
}

"]" {
    printTokenInfo("T_RBRACK", yytext);
    return T_RBRACK;
}

"and" {
    printTokenInfo("T_AND", yytext);
    return T_AND;
}

"array" {
    printTokenInfo("T_ARRAY", yytext);
    return T_ARRAY;
}

"begin" {
    printTokenInfo("T_BEGIN", yytext);
    return T_BEGIN;
}

"boolean" {
    printTokenInfo("T_BOOL", yytext);
    return T_BOOL;
}

"char" {
    printTokenInfo("T_CHAR", yytext);
    return T_CHAR;
}

"div" {
    printTokenInfo("T_DIV", yytext);
    return T_DIV;
}

"do" {
    printTokenInfo("T_DO", yytext);
    return T_DO;
}

"else" {
    printTokenInfo("T_ELSE", yytext);
    return T_ELSE;
}

"end" {
    printTokenInfo("T_END", yytext);
    return T_END;
}

"false" {
    printTokenInfo("T_FALSE", yytext);
    return T_FALSE;
}

"if" {
    printTokenInfo("T_IF", yytext);
    return T_IF;
}

"integer" {
    printTokenInfo("T_INT", yytext);
    return T_INT;
}

"not" {
    printTokenInfo("T_NOT", yytext);
    return T_NOT;
}

"of" {
    printTokenInfo("T_OF", yytext);
    return T_OF;
}

"or" {
    printTokenInfo("T_OR", yytext);
    return T_OR;
}

"procedure" {
    printTokenInfo("T_PROC", yytext);
    return T_PROC;
}

"program" {
    printTokenInfo("T_PROG", yytext);
    return T_PROG;
}

"read" {
    printTokenInfo("T_READ", yytext);
    return T_READ;
}

"then" {
    printTokenInfo("T_THEN", yytext);
    return T_THEN;
}

"true" {
    printTokenInfo("T_TRUE", yytext);
    return T_TRUE;
}

"var" {
    printTokenInfo("T_VAR", yytext);
    return T_VAR;
}

"while" {
    printTokenInfo("T_WHILE", yytext);
    return T_WHILE;
}

"write" {
    printTokenInfo("T_WRITE", yytext);
    return T_WRITE;
}

"'" {
    /* TODO Is this the best way to catch this? */
    printError("Invalid character constant", yytext);

    /* TODO what do I return here? */
    return UNKNOWN;
}

"''" {
    /* TODO Is this the best way to catch this? */
    printError("Invalid character constant", yytext);

    /* TODO what do I return here? */
    return UNKNOWN;
}

"(*" {
    int c = yyinput();
    int readAhead = 1; /* do we still need to read the next character? */
    while(c != 0) {
        if(c == '*') {
            c = yyinput();
            if(c == ')') {
                break;
            }
            readAhead = 0;
        }

        /* If we've already read from yyinput, just stick with that
         character for now. */
        if(readAhead) {
            c = yyinput();
        }
        readAhead = 1;
    }
}

{IDENT} {
    yylval.text = strdup(yytext);
    printTokenInfo("T_IDENT", yytext);
    return T_IDENT;
}

{CHARCONST} {
    printTokenInfo("T_CHARCONST", yytext);
    return T_CHARCONST;
}

{INTCONST} {
    /* If greater than this guy, bail */
    if (strgt(yytext, MAX_INT)) {
        printError("Invalid integer constant", yytext);

        /* TODO what to return here? */
        return UNKNOWN;
    }

    yylval.ival = atoi(yytext);

    printTokenInfo("T_INTCONST", yytext);
    return T_INTCONST;
}

{WHITESPACE} {
    /* Ain't nothin' here */
}

. {
    printTokenInfo("UNKNOWN", yytext);
    return UNKNOWN;
}

%%

/**
 * User Code Section
 * =================
*/

int precedingZeroes(const char* str) {
    int length = strlen(str);
    int zeroes = 0;
    for (int i = 0; i < length; i++) {
        if (str[i] == '0') {
            zeroes += 1;
        } else {
            break;
        }
    }

    return zeroes;
}

int strgt(const char* a, const char* b) {
    int a_zeroes = precedingZeroes(a);
    int b_zeroes = precedingZeroes(b);

    int length_a = strlen(a) - a_zeroes;
    int length_b = strlen(b) - b_zeroes;

    /* a's longer (without preceding 0's), so it's greater */
    if (length_a > length_b) {
        return 1;
    }

    /* a's shorter (without preceding 0's), so it's smaller */
    if (length_a < length_b) {
        return 0;
    }

    /* The strings are the same length, so start from the highest
       place, and try to find the first position (going left to right)
       that's larger or smaller. If a[i] is larger than b[i] at any
       place, then a must be a higher number. */
    /* Move the char* pointers up past the zero-padding (if there is any) */
    a = a + a_zeroes;
    b = b + b_zeroes;
    for (int i = 0; i < length_a; i++) {
        if (a[i] > b[i]) {
            return 1;
        }

        if (a[i] < b[i]) {
            return 0;
        }
    }

    /* They're equal */
    return 0;
}

void printTokenInfo(const char* tokenType, const char* lexeme) {
    if (PRINT_TOKENS) {
        printf("TOKEN: %-12sLEXEME: %s\n", tokenType, lexeme);
    }
}

void printError(const char* message, const char* lexeme) {
    printf("**** %s: %s\n", message, lexeme);
}
