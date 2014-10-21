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
#include <list>

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

enum oper {
	ASSIGNMENT,
	ARRAY_ACC,
	ARRAY_ASS,
	ADDITION,
	MULTIPLICATION,
	GREATER_THAN,
	GREATER_EQUAL,
	EQUAL,
	LESS_EQUAL,
	LESS_THAN,
	NOT_EQUAL,
	IFT,
	IFF,
	GOTO
};

enum type {
	VARIABLE,
	TEMP,
	LABEL,
	VALUE
};

struct operand {
	type t;
	union {
		char var;
		unsigned int temp;
		unsigned int label;
		int val;
	} o;
};

struct triple {
	oper op;
	operand result;
	operand op1;
	operand op2;
};	

list<triple> code;
list<unsigned int> labels;
list<operand> subscripts;

unsigned int temp = 1;
unsigned int label = 1;

void printOp(const operand& o) {
	switch(o.t) {
		case VARIABLE:
			printf("%c", o.o.var);
			break;
		case TEMP:
			printf("t%d", o.o.temp);
			break;
		case LABEL:
			printf("L%d", o.o.label);
			break;
		case VALUE:
			printf("%d", o.o.val);	
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
case ARRAY_ACC: /* This is broken but who cares */
	printOp(t.op1);
printf("[");
printOp(t.op2);
printf("]");
printf(" = ");
printOp(t.result);
break;
case ARRAY_ASS:
	printOp(t.result);
printf(" = ");
printOp(t.op1);
printf("[");
printOp(t.op2);
printf("]");
break;
		case ADDITION:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" + ");
printOp(t.op2);
break;
case MULTIPLICATION:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" * ");
printOp(t.op2);
break;
case GREATER_THAN:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" > ");
printOp(t.op2);
break;
case GREATER_EQUAL:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" >= ");
printOp(t.op2);
break;
case EQUAL:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" == ");
printOp(t.op2);
break;
	case LESS_EQUAL:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" <= ");
printOp(t.op2);
break;
	case LESS_THAN:
			printOp(t.result);
printf(" = ");
printOp(t.op1);
printf(" < ");
printOp(t.op2);
break;
	case NOT_EQUAL:
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
	operand op;
	triple t;
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
%type <op> A E S B W F
%type <t> L R

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
	$$ = $1;
	}
	| F
	{
	prRule("S", "F");
	$$ = $1;
	}
	| W
	{
	prRule("S", "W");
	$$ = $1;
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

	operand id;
	id.t = VARIABLE;
	id.o.var = $1;

	triple t; 
	t.op = ASSIGNMENT;
	t.result = id;
	t.op1 = $3;
	code.push_back(t);

	printTriple(t);
	
	$$ = t.result;
	}
	| L ASSIGN E
	{
	prRule("A", "L = E");
	$1.op = ARRAY_ASS;
	$1.result = $3;
	code.push_back($1);
	printTriple($1);
	$$ = $1.result;	
	}
	;
F	: IF LPAREN B RPAREN THEN 
	{

	operand lbl;
	lbl.t = LABEL;
	lbl.o.label = label;

	labels.push_back(label++);

	triple t;
	t.op = IFF;
	t.op1 = $3;
	t.op2 = lbl;
	code.push_back(t);
	printTriple(t);

	}
		S ELSE 
	{
		printLbl(labels.back());
		labels.pop_back();
	}
		S
	{
	prRule("F", "if ( B ) then S else S");
	}
	; 
W	: WHILE LPAREN 
	{
		printLbl(label);
		labels.push_back(label++);
	}
		B RPAREN 
	{
	
	operand after;
	after.t = LABEL;
	after.o.label = label;
	labels.push_back(label++);

	triple t;
	t.op = IFF;
	t.op1 = $4;
	t.op2 = after;
	code.push_back(t);
	printTriple(t);
	}
		S
	{
	prRule("S", "while ( B ) S");

	unsigned int after = labels.back();
	labels.pop_back();

	operand lbl;
	lbl.t = LABEL;
	lbl.o.label = labels.back();
	labels.pop_back();

	triple t;
	t.op = GOTO;
	t.op1 = lbl;
	code.push_back(t);
	printTriple(t);

	printLbl(after);

	}
	;
E	: E ADD INTCONST
	{
	prRule("E", "E + INTCONST");

	operand result;
	result.t = TEMP;
	result.o.temp = temp++;

	operand intval;
	intval.t = VALUE;
	intval.o.val = $3;

	triple t;
	t.op = ADDITION;
	t.result = result;
	t.op1 = $1;
	t.op2 = intval;
	code.push_back(t);
	printTriple(t);

	$$ = result;
	
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

	operand o;
	o.t = VARIABLE;
	o.o.var = $1;

	$$ = o;
	}
	| L
	{
	prRule("E", "L");
	$1.op = ARRAY_ACC;
	$1.result.t = TEMP;
	$1.result.o.temp = temp++;
	code.push_back($1);
	printTriple($1);

	$$ = $1.result;
	}
	| INTCONST
	{
	prRule("E", "INTCONST");
	operand intval;
	intval.t = VALUE;
	intval.o.val = $1;
	$$ = intval;
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

	subscripts.push_front($3);
	
	list<operand> intermediates;
	unsigned int i = 0;
	for(list<operand>::iterator it = subscripts.begin(); it != subscripts.end(); it++) {
		unsigned int sz = 4;
		for(unsigned int j = i; j < s.size(); j++) {
			sz *= s[j];
		}

		triple t;
		t.op = MULTIPLICATION;
		t.op1 = *it;
		t.op2.t = VALUE;
		t.op2.o.val = sz;
		t.result.t = TEMP;
		t.result.o.temp = temp++;

		code.push_back(t);
		printTriple(t);

		intermediates.push_back(t.result);
		
		if(intermediates.size() == 2) {
			triple t; 
			t.op = ADDITION;
			t.op1 = intermediates.front();
			intermediates.pop_front();
			t.op2 = intermediates.front();
			intermediates.pop_front();
			t.result.t = TEMP;
			t.result.o.temp = temp++;
			intermediates.push_back(t.result);
		}
		i++;
	}

	/* This is the C++ equivalent of smallpox blankets */
	triple t;
	t.op1.t = VARIABLE;
	t.op1.o.var = $1;
	t.op2 = intermediates.front();
	intermediates.pop_front();

	subscripts.clear();

	$$ = t;
	}
	| L LBRACK E RBRACK
	{
	prRule("L", "L [ E ]");
	subscripts.push_front($3);
	}
	;
B	: E R E
      {
	prRule("B", "E R E");
	triple t = $2;
	t.op1 = $1;
	t.op2 = $3;
	t.result.t = TEMP;
	t.result.o.temp = temp++;
	$$ = t.result;
	code.push_back(t);
	printTriple(t);
	}
	| TRUE
      {
	prRule("B", "true");
	operand o;
	o.t = VALUE;
	o.o.val = 1;
	$$ = o;
	}
	| FALSE
      {
	prRule("B", "false");
	operand o;
	o.t = VALUE;
	o.o.val = 0;
	$$ = o;
	}
	;                              
R	: GT
	{
	prRule("R", ">");

	triple t;
	t.op = GREATER_THAN;
	$$ = t;
	}
      | LT
	{
	prRule("R", "<");

	triple t;
	t.op = LESS_THAN;
	$$ = t;
	}
      | NE
	{
	prRule("R", "!=");

	triple t;
	t.op = NOT_EQUAL;
	$$ = t;
	}
	| GE
	{
	prRule("R", ">=");

	triple t;
	t.op = GREATER_EQUAL;
	$$ = t;
	}
      | LE
	{
	prRule("R", "<=");

	triple t;
	t.op = LESS_EQUAL;
	$$ = t;
	}
      | EQ
	{
	prRule("R", "==");

	triple t;
	t.op = EQUAL;
	$$ = t;
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
