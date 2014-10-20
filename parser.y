/*
      hw5_parser.y

 	Specifications for the HW #5 language, bison input file.

      To create the executable:

        flex hw5_parser.l
        bison hw5_parser.y
        g++ hw5_parser.tab.c -o hw5_parser

      To execute without debugging output:
        hw5_parser inputFileName

      To execute with debugging output:
        hw5_parser inputFileName -d
 */

/*
 *	Declaration section.
 */
%{
#include <stdio.h>
#include <iostream>
#include <vector>
#include <map>
#include<list>

using namespace std;

int lineNum = 1; 
bool DEBUG  = true;

typedef vector<int> SUBSCRIPT_INFO;

map<char, SUBSCRIPT_INFO> symbolTable;
SUBSCRIPT_INFO currentSubscriptInfo;  

void addEntryToSymbolTable(char id, SUBSCRIPT_INFO subscriptInfo);
SUBSCRIPT_INFO findEntryInSymbolTable(char id);
void outputSubscriptInfo(SUBSCRIPT_INFO v);

void prRule(const char*, const char*);

enum operator {
	ASSIGNMENT,
	ADD,
	MULTIPLY,
	GT,
	GE,
	EQ,
	LE,
	LT,
	NE,
	IFT,
	IFF,
	GOTO
};

enum type {
	VAR,
	TEMP,
	LABEL
};

struct operand {
	type t;
	union o {
		char var;
		unsigned int temp;
		unsigned int label;
	};
};

struct triple {
	operator op;
	operand result;
	operand op1;
	operand op2;
};	

list<triple> intermediates;

void printOp(const operand& o) {
	switch(o.t) {
		case VAR:
			printf("%c", o.o.var);
			break;
		case TEMP:
			printf("T%d", o.o.temp);
			break;
		case LABEL:
			printf("L%d", o.o.label);
			break;
	}
}

void printLbl(unsigned int l) {
	printf("L%d:\n", l);
}

/* ugh */
void printTriple(const triple& t) {
	switch(t.op) {
		case ASSIGNMENT:
			printOp(t.result);
			printf(" = ");
			printOp(t.op1);
			break;
		case ADD:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" + ");
printOp(t.op2);
break;
case MULTIPLY:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" * ");
printOp(t.op2);
break;
case GT:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" > ");
printOp(t.op2);
break;
case GE:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" >= ");
printOp(t.op2);
break;
case EQ:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" == ");
printOp(t.op2);
break;
	case LE:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" <= ");
printOp(t.op2);
break;
	case LT:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" < ");
printOp(t.op2);
break;
	case NE:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" != ");
printOp(t.op2);
break;
	case IFT:
printf("If ");
printOp(t.op1);
printf(" == true goto ");
printOp(t.op2);
break;
	case IFF:
printf("If ");
printOp(t.op1);
printf(" == false goto ");
printOp(t.op2);
break;
	case GOTO:
printf("goto ");
printOp(t.op1);
break;
}

printf("\n");
}
	
int yyerror(const char* s) {
  printf("Line %d: %s\n", lineNum, s);
  return(1);
}

extern "C" {
    int yyparse(void);
    int yylex(void);
    int yywrap() {return 1;}
}

%}

%union {
  char ch;
  int num;
};

/*
 *	Token declarations
*/
%token  LPAREN RPAREN LBRACK RBRACK
%token  SEMICOL ADD ASSIGN
%token  GT LT NE GE LE EQ
%token  VAR LCURLY RCURLY
%token  IF THEN ELSE WHILE TRUE FALSE 
%token  INTCONST IDENT UNKNOWN

%type <num> INTCONST 
%type	<ch> IDENT 

/*
 *	Starting point.
 */
%start		P

/*
 *	Translation rules.
 */
%%
P	: VAR V LCURLY C RCURLY
	{
	prRule("P", "var V { C }");
      if (DEBUG)
	  printf("\n---- Completed parsing ----\n\n");
	}
	;
V   : /* epsilon */
	{
	prRule("V", "epsilon");
	}
      | IDENT N SEMICOL
 	{
	addEntryToSymbolTable($1, currentSubscriptInfo);
	currentSubscriptInfo.clear( );
	}
      V
      {
      prRule("V", "id N ; V");
      }
      ;
N	: LBRACK INTCONST RBRACK N
	{
	prRule("N", "[ INTCONST ] N");
	currentSubscriptInfo.insert(currentSubscriptInfo.begin(), $2);
	}
	| /* epsilon */
	{
	prRule("N", "epsilon");
	}
	;
C	: S SEMICOL C
	{
	prRule("C", "S ; C");
	}
	| /* epsilon */
	{
	prRule("C", "epsilon");
	}
	;
S	: A
	{
	prRule("S", "A ;");
	}
	| F
	{
	prRule("S", "F");
	}
	| W
	{
	prRule("S", "W");
	}
	;  
A	: IDENT ASSIGN E
	{
	prRule("A", "id = E");
	SUBSCRIPT_INFO s = findEntryInSymbolTable($1);
	if (DEBUG) {
        printf("\n*** Found %c in symbol table\n", $1);
        if (s.size() > 0) {
          printf("*** This array has the following subscriptInfo:\n");
          outputSubscriptInfo(s);
        }
        printf("\n");
      }
	}
	| L ASSIGN E
	{
	prRule("A", "L = E");
	}
	;
F	: IF LPAREN B RPAREN THEN S ELSE S
	{
	prRule("F", "if ( B ) then S else S");
	}
	; 
W	: WHILE LPAREN B RPAREN S
	{
	prRule("S", "while ( B ) S");
	}
	;
E	: E ADD INTCONST
	{
	prRule("E", "E + INTCONST");
	}
	| IDENT
	{
	prRule("E", "id");
	SUBSCRIPT_INFO s = findEntryInSymbolTable($1);
	if (DEBUG) {
        printf("\n*** Found %c in symbol table\n", $1);
        if (s.size() > 0) {
          printf("*** This array has the following subscriptInfo:\n");
          outputSubscriptInfo(s);
        }
	  printf("\n");
      }
	}
	| L
	{
	prRule("E", "L");
	}
	| INTCONST
	{
	prRule("E", "INTCONST");
	}
	;
L	: IDENT LBRACK E RBRACK
      {
	prRule("L", "id [ E ]");
	SUBSCRIPT_INFO s = findEntryInSymbolTable($1);
	if (DEBUG) {
        printf("\n*** Found %c in symbol table\n", $1);
        if (s.size() > 0) {
          printf("*** This array has the following subscriptInfo:\n");
          outputSubscriptInfo(s);
        }
	  printf("\n");
      }
	}
	| L LBRACK E RBRACK
	{
	prRule("L", "L [ E ]");
	}
	;
B	: E R E
      {
	prRule("B", "E R E");
	}
	| TRUE
      {
	prRule("B", "true");
	}
	| FALSE
      {
	prRule("B", "false");
	}
	;                              
R	: GT
	{
	prRule("R", ">");
	}
      | LT
	{
	prRule("R", "<");
	}
      | NE
	{
	prRule("R", "!=");
	}
	| GE
	{
	prRule("R", ">=");
	}
      | LE
	{
	prRule("R", "<=");
	}
      | EQ
	{
	prRule("R", "==");
	}
	;
%%

#include "lex.yy.c"
extern FILE *yyin;

void prRule(const char* lhs, const char* rhs) {
  if (DEBUG) printf("%s -> %s\n", lhs, rhs);
    return;
}

// Add symbol table entry x to the symbol table.
void addEntryToSymbolTable(char id, SUBSCRIPT_INFO subscriptInfo) {
  // Make sure there isn't already an entry with the same name
  map<char, SUBSCRIPT_INFO>::iterator itr;
  if ((itr = symbolTable.find(id)) == symbolTable.end()) 
    symbolTable.insert(make_pair(id, subscriptInfo));
  else yyerror("Multiply defined identifier!");
  if (DEBUG) {
    printf("\n>>> Added %c to symbol table\n", id);
    if (subscriptInfo.size() > 0) {
      printf(">>> with the following subscriptInfo:\n");
      outputSubscriptInfo(subscriptInfo);
    }
  }
}

// Return the subscript info for symbol table entry id.
SUBSCRIPT_INFO findEntryInSymbolTable(char id) {
  map<char, SUBSCRIPT_INFO>::iterator itr;
  if ((itr = symbolTable.find(id)) == symbolTable.end())
    yyerror("Undefined identifier!");
  else return(itr->second);
}

// Output the contents of a vector of int's.
void outputSubscriptInfo(SUBSCRIPT_INFO s) {  
  for (int i = 0; i < s.size(); i++)
    printf("     s[%d] = %d\n", i, s[i]);
}

int main(int argc, char** argv) {
  if (argc < 2) {
    printf("Specify an input file in the command line!\n");
    exit(1);
  }
  yyin = fopen(argv[1], "r");

  // Did the command line specify the option for 
  // including debugging output?
  if (argc > 2)
    DEBUG = true;
  else DEBUG = false;

  do {
	yyparse();
  } while (!feof(yyin));

  return 0;
}
