/*
      oal.y

 	Specifications for the OAL language, YACC input file.
 	CS 356.

      To compile and run:

        flex oal.l
        bison oal.y
        g++ oal.tab.c
        a.out oalInputFileName
 */

/*
 *	Declaration section.
 */
%{
#include <stdio.h>
#include <string.h>
#include <list>
#include <stack>
#include <vector>
using namespace std;

#define DEBUG 0   // set to non-zero to see debugging output

char	*entryLabel = 0;

int lineNum = 1;
int instrxCount = 0;
int entryPointInstrxNum = -1, haltPointInstrxNum = -1;
int displaySize = 0;

// Arithmetic stack holds integers and memory locations 
// (offset & level)
typedef struct { int val1, val2; } arithmeticStackElt;
stack< arithmeticStackElt> arithmeticStack;   

// Execution stack holds instructions locations, display values, 
// and local var values. We're using a vector instead of a stack
// per se; assume it "grows" in index sequence 0, 1, 2, ...
// where 0 is the stack "bottom."
vector<int> executionStack; 

// Display holds execution stack indices and global var values
vector<int> display;

// Individual instructions stored; will reference "instruction  
// location" by vector index
typedef void (*ptrToFunction) (int, int, int&);
typedef struct { int op1, op2; ptrToFunction f; } instrx;
vector<instrx> instructions;

// Keep track of defined labels and "jump to" labels 
// for semantic analysis
std::list<char*> jumpLocations;
std::list<char*> definedLabels;

// Maintain index into instructions vector for each label
typedef struct { char* labelName; int instrxNum; } labelInfo;
std::list<labelInfo> labelInstrxNums;

// Function prototypes
void addInstruction(ptrToFunction f, int op1 = -1, int op2 = -1);
void lc(int op1, int op2, int& instrxNum);
void la(int op1, int op2, int& instrxNum);
void lv(int op1, int op2, int& instrxNum);
void iwrite(int op1, int op2, int& instrxNum);
void cwrite(int op1, int op2, int& instrxNum);
void iread(int op1, int op2, int& instrxNum);
void cread(int op1, int op2, int& instrxNum);
void add(int op1, int op2, int& instrxNum);
void mult(int op1, int op2, int& instrxNum);
void div(int op1, int op2, int& instrxNum);
void sub(int op1, int op2, int& instrxNum);
void mod(int op1, int op2, int& instrxNum);
void and_op(int op1, int op2, int& instrxNum);
void or_op(int op1, int op2, int& instrxNum);
void eq_op(int op1, int op2, int& instrxNum);
void ne_op(int op1, int op2, int& instrxNum);
void lt_op(int op1, int op2, int& instrxNum);
void le_op(int op1, int op2, int& instrxNum);
void gt_op(int op1, int op2, int& instrxNum);
void ge_op(int op1, int op2, int& instrxNum);
void binaryOperation(int opCode);
void not_op(int op1, int op2, int& instrxNum);
void neg_op(int op1, int op2, int& instrxNum);
void unaryOperation(int opCode);
void st(int op1, int op2, int& instrxNum);
void deref(int op1, int op2, int& instrxNum);
void push(int op1, int op2, int& instrxNum);
void pop(int op1, int op2, int& instrxNum);
void asp(int op1, int op2, int& instrxNum);
void save(int op1, int op2, int& instrxNum);
void jp(int op1, int op2, int& instrxNum);
void jt(int op1, int op2, int& instrxNum);
void jf(int op1, int op2, int& instrxNum);
void js(int op1, int op2, int& instrxNum);
void ji(int op1, int op2, int& instrxNum);
void labelInstrx(int op1, int op2, int& instrxNum);

// Maintain a list each label ("L.xx") and its
// index into the instructions vector 
void addLabelInstrxNum(char* labelName, int instrxNum);
int findLabelInstrxNum(char* labelName);

// Maintain lists of labels defined and jumped to
void addLabel(char* x, std::list<char*> &L);
bool findLabel(char* x, std::list<char*> L);
bool checkLabels();

// Debugging, initialization, yacc support, etc. functions
void dumpExecutionStack();
void bail(const char *s);
void initDisplay();
void performEvaluation();

void ignoreComment(void);
void prRule(const char *, const char *);

int yyerror(const char *s) {
  printf("%d: %s\n", lineNum, s);
}

extern "C" {
    int yyparse(void);
    int yylex(void);
    int yywrap() {return 1;}
}

%}

%union {
  int	num;
  char *text;
  struct { int offset, level; } memLoc;
};

/*
 *	Token declarations
*/
%token  T_COLON  T_JP  T_JF  T_JT  T_JS  T_JI  T_BSS  T_ASP
%token  T_PUSH  T_POP  T_SAVE  T_LC  T_LV  T_LA  T_DEREF  T_ST
%token  T_ADD  T_SUB  T_MULT  T_DIV	 T_MOD  T_AND  T_OR T_COMMA
%token  T_EQ  T_NE  T_LT  T_LE  T_GT  T_GE  T_NEG  T_NOT T_END
%token  T_CREAD  T_IREAD  T_CWRITE  T_IWRITE  T_INIT  T_HALT  
%token  T_NCONST  T_PCONST  T_UNKNOWN T_LABEL  T_ENTRY

%type	<text> T_LABEL T_ENTRY N_ENTRYPOINT_LABEL
%type <num> N_INTCONST T_NCONST T_PCONST N_JUMP_OP
%type <memLoc> N_MEMORY_LOC

/*
 *	Starting point.
 */
%start		N_START

/*
 *	Translation rules.
 */
%%
N_START			: N_PROG
					{
					prRule("N_START", "N_PROG");
				     	if (DEBUG)
					  printf("\n---- Completed parsing ----\n\n");
					return 0;
					}
				;
N_PROG			: N_INIT N_GLOBAL N_DISPLAY_BSS N_EXEC_CODE_LABEL N_EXEC_CODE
                          N_ENTRYPOINT_LABEL N_MAIN_CODE N_HALT N_STACK_LABEL N_STACK_BSS 
                          T_END
					{
					prRule("N_PROG", "N_INIT N_GLOBAL N_DISPLAY N_EXEC_CODE...");
					}
				;
N_INIT			: T_INIT T_LABEL T_COMMA T_PCONST T_COMMA T_LABEL T_COMMA T_LABEL 
                          T_COMMA T_LABEL 
					{
					entryLabel = strdup($10);
                           addLabel(strdup($2), jumpLocations);
                           addLabel(strdup($6), jumpLocations);
                           addLabel(strdup($8), jumpLocations);
                           addLabel(entryLabel, jumpLocations);
					prRule("N_INIT",
						  "T_INIT T_LABEL T_COMMA T_PCONST T_COMMA...");
					}
				;
N_LABEL_INSTRX		: T_LABEL T_COLON 
					{
					prRule("N_LABEL_INSTRX", 
				            "T_LABEL T_COLON");
                           if (findLabel(strdup($1),
                                         definedLabels))
                             bail("Duplicate label definition found!"); 
                           addLabel(strdup($1), definedLabels);
                           addLabelInstrxNum(strdup($1),
					                 instrxCount);
                           addInstruction(labelInstrx);
					}
                        ;
N_GLOBAL			: N_LABEL_INSTRX 
					{
					prRule("N_GLOBAL", "N_LABEL_INSTRX");
					}
				;
N_EXEC_CODE_LABEL  	: N_LABEL_INSTRX 
					{
					prRule("N_EXEC_CODE_LABEL",
			                  "N_LABEL_INSTRX");
					}
				;
N_ENTRYPOINT_LABEL 	: T_ENTRY T_COLON 
					{
					$$ = $1;
                           if (findLabel(strdup($1),
				                   definedLabels))
                             bail("Duplicate label definition found!"); 
                           addLabel(strdup($1), definedLabels);
                           entryPointInstrxNum = instrxCount;
                           addLabelInstrxNum(strdup($1),
				                       instrxCount);
                           addInstruction(labelInstrx);
					prRule("N_ENTRYPOINT_LABEL",
				             "T_ENTRY T_COLON");
					}
				;
N_STACK_LABEL 		: N_LABEL_INSTRX 
					{
					prRule("N_STACK_LABEL",
				            "N_LABEL_INSTRX");
					}
				;
N_DISPLAY_BSS  		: T_BSS T_PCONST
					{
					prRule("N_DISPLAY_BSS", "T_PCONST");
                           displaySize = $2;
					}
				;
N_STACK_BSS  		: T_BSS T_PCONST
					{
					prRule("N_STACK_BSS", "T_PCONST");
					}
				;
N_HALT  		      : T_HALT
					{
					prRule("N_HALT", "T_HALT");
                           haltPointInstrxNum = instrxCount;
                           addInstruction(labelInstrx);  
					}
				;
N_EXEC_CODE  		: N_INSTRX_LIST
					{
					prRule("N_EXEC_CODE",
					       "N_INSTRX_LIST");
					}
				;
N_MAIN_CODE  		: N_INSTRX_LIST
					{
					prRule("N_MAIN_CODE",
					       "N_INSTRX_LIST");
					}
				;
N_INSTRX_LIST		: /* epsilon */ 
					{
					prRule("N_INSTRX_LIST", "epsilon");
					}
				| N_INSTRX_LIST N_INSTRX
					{
					prRule("N_INSTRX_LIST", 
						 "N_INSTRX_LIST N_INSTRX");
					}
				;
N_INSTRX			: N_JUMP_INSTRX
					{
					prRule("N_INSTRX", "N_JUMP_INSTRX");
					}
				| N_LABEL_INSTRX
					{
					prRule("N_INSTRX", "N_LABEL_INSTRX");
					}
				| N_STACK_INSTRX
					{
					prRule("N_INSTRX", "N_STACK_INSTRX");
					}
				| N_BINARY_OP
					{
					prRule("N_INSTRX", "N_BINARY_OP");
					}
				| N_UNARY_OP
					{
					prRule("N_INSTRX", "N_UNARY_OP");
					}
				| N_INPUT_INSTRX
					{
					prRule("N_INSTRX", "N_INPUT_INSTRX");
					}
				| N_OUTPUT_INSTRX
					{
					prRule("N_INSTRX", "N_OUTPUT_INSTRX");
					}
				;
N_INTCONST  		: T_NCONST
					{
					prRule("N_INTCONST", "T_NCONST");
                           $$ = $1;
					}
				| T_PCONST
					{
					prRule("N_INTCONST", "T_PCONST");
                           $$ = $1;
					}
				;
N_MEMORY_LOC  		: N_INTCONST T_COMMA T_PCONST
					{
					prRule("N_MEMORY_LOC", 
			                  "N_INTCONST T_COMMA T_PCONST");
                           $$.offset = $1;
                           $$.level = $3;
					}
				;
N_JUMP_INSTRX  		: N_JUMP_OP T_LABEL
					{
                            prRule("N_JUMP_INSTRX", 
					        "N_JUMP_OP T_LABEL");
                            ptrToFunction f;
                            addLabel(strdup($2), jumpLocations);
                            switch ($1) {
                               case T_JP: f = jp; break;
                               case T_JF: f = jf; break;
                               case T_JT: f = jt; break;
                               case T_JS: f = js; break;
                            };
                            addInstruction(f, 
							    strtol($2 + 2, 0, 10));
					}
				| T_JI
					{
					prRule("N_JUMP_INSTRX", "T_JI");
                           addInstruction(ji);
					}
				;
N_JUMP_OP  		: T_JP
					{
                            prRule("N_JUMP_OP", "T_JP");
                            $$ = T_JP;
					}
				| T_JF
					{
					prRule("N_JUMP_OP", "T_JF");
                           $$ = T_JF;
					}
				| T_JT
					{
					prRule("N_JUMP_OP", "T_JT");
                           $$ = T_JT;
					}
				| T_JS
					{
					prRule("N_JUMP_OP", "T_JS");
                           $$ = T_JS;
					}
				;
N_BINARY_OP	 	: T_ADD
					{
					prRule("N_BINARY_OP", "T_ADD");
                           addInstruction(add);
					}
				| T_SUB
					{
					prRule("N_BINARY_OP", "T_SUB");
                           addInstruction(sub);
					}
				| T_MULT
					{
					prRule("N_BINARY_OP", "T_MULT");
                           addInstruction(mult);
					}
				| T_DIV
					{
					prRule("N_BINARY_OP", "T_DIV");
                           addInstruction(div);
					}
				| T_MOD
					{
					prRule("N_BINARY_OP", "T_MOD");
                           addInstruction(mod);
					}
				| T_AND
					{
					prRule("N_BINARY_OP", "T_AND");
                           addInstruction(and_op);
					}
				| T_OR
					{
					prRule("N_BINARY_OP", "T_OR");
                           addInstruction(or_op);
					}
				| T_EQ
					{
					prRule("N_BINARY_OP", "T_EQ");
                           addInstruction(eq_op);
					}
				| T_NE
					{
					prRule("N_BINARY_OP", "T_NE");
                           addInstruction(ne_op);
					}
				| T_LT
					{
					prRule("N_BINARY_OP", "T_LT");
                           addInstruction(lt_op);
					}
				| T_LE
					{
					prRule("N_BINARY_OP", "T_LE");
                           addInstruction(le_op);
					}
				| T_GT
					{
					prRule("N_BINARY_OP", "T_GT");
                           addInstruction(gt_op);
					}
				| T_GE
					{
					prRule("N_BINARY_OP", "T_GE");
                           addInstruction(ge_op);
					}
				;
N_UNARY_OP	 		: T_NEG
					{
					prRule("N_UNARY_OP", "T_NEG");
                              addInstruction(neg_op);
					}
				| T_NOT
					{
					prRule("N_UNARY_OP", "T_NOT");
                           addInstruction(not_op);
					}
				;
N_INPUT_INSTRX 		: T_CREAD
					{
					prRule("N_INPUT_INSTRX", "T_CREAD");
                           addInstruction(cread);
					}
				| T_IREAD
					{
					prRule("N_INPUT_INSTRX", "T_IREAD");
                           addInstruction(iread);
					}
				;
N_OUTPUT_INSTRX 		: T_CWRITE
					{
					prRule("N_OUTPUT_INSTRX", "T_CWRITE");
                           addInstruction(cwrite);
					}
				| T_IWRITE
					{
					prRule("N_OUTPUT_INSTRX", "T_IWRITE");
                           addInstruction(iwrite);
					}
				;
N_STACK_INSTRX  		: N_ASP_INSTRX
					{
					prRule("N_STACK_INSTRX",
				            "N_ASP_INSTRX");
					}
				| N_PUSH_INSTRX
					{
					prRule("N_STACK_INSTRX",
					       "N_PUSH_INSTRX");
					}
				| N_POP_INSTRX
					{
					prRule("N_STACK_INSTRX",
					       "N_POP_INSTRX");
					}
				| N_SAVE_INSTRX
					{
					prRule("N_STACK_INSTRX",
					       "N_SAVE_INSTRX");
					}
				| N_LC_INSTRX
					{
					prRule("N_STACK_INSTRX",
					       "N_LC_INSTRX");
					}
				| N_LV_INSTRX
					{
					prRule("N_STACK_INSTRX",
						  "N_LV_INSTRX");
					}
				| N_LA_INSTRX
					{
					prRule("N_STACK_INSTRX",
						  "N_LA_INSTRX");
					}
				| T_ST
					{
					prRule("N_STACK_INSTRX", "T_ST");
                           addInstruction(st);
					}
				| T_DEREF
					{
					prRule("N_STACK_INSTRX", "T_DEREF");
                           addInstruction(deref);
					}
				;
N_ASP_INSTRX  		: T_ASP N_INTCONST
					{
					prRule("N_ASP_INSTRX", 
						 "T_ASP N_INTCONST");
                           addInstruction(asp, $2);
					}
				;
N_PUSH_INSTRX  		: T_PUSH N_MEMORY_LOC
					{
					prRule("N_PUSH_INSTRX", 
					       "T_PUSH N_MEMORY_LOC");
                           addInstruction(push, $2.offset,
						         $2.level);
					}
				;
N_POP_INSTRX  		: T_POP N_MEMORY_LOC
					{
					prRule("N_POP_INSTRX", 
						  "T_POP N_MEMORY_LOC");
                           addInstruction(pop, $2.offset,
						         $2.level);
					}
				;
N_SAVE_INSTRX  		: T_SAVE N_MEMORY_LOC
					{
					prRule("N_SAVE_INSTRX", 
						  "T_SAVE N_MEMORY_LOC");
                           addInstruction(save, $2.offset,
							   $2.level);
					}
				;
N_LC_INSTRX  		: T_LC N_INTCONST
					{
					prRule("N_LC_INSTRX", 
						  "T_LC N_INTCONST");
                           addInstruction(lc, $2);
					}
				;
N_LV_INSTRX  		: T_LV N_MEMORY_LOC
					{
					prRule("N_LV_INSTRX", 
						  "T_LV N_MEMORY_LOC");
					}
				;
N_LA_INSTRX  		: T_LA N_MEMORY_LOC
					{
					prRule("N_LA_INSTRX", 
						 "T_LA N_MEMORY_LOC");
                           addInstruction(la, $2.offset,
							   $2.level);
					}
				;
%%

#include "lex.yy.c"

extern FILE *yyin;

// Add instruction (as specified by f, op1, op2) to 
// instructions vector
void addInstruction(ptrToFunction f, int op1, int op2) {
  instrx i;
  i.op1 = op1;
  i.op2 = op2;
  i.f = f;
  instructions.push_back(i);
  instrxCount++;
}

// Push value op1 onto arithmetic stack
void lc(int op1, int op2, int& instrxNum) {
  arithmeticStackElt stackElt;
  stackElt.val1 = op1;
  stackElt.val2 = op2; 
  arithmeticStack.push(stackElt);
  instrxNum++;
}

// Push address of memory location (op1, op2) 
// onto arithmetic stack
void la(int op1, int op2, int& instrxNum) {
  arithmeticStackElt stackElt;
  stackElt.val1 = op1;
  stackElt.val2 = op2; 
  arithmeticStack.push(stackElt);
  instrxNum++;
}

// Push value stored at memory location (op1, op2) 
// onto arithmetic stack
void lv(int op1, int op2, int& instrxnum) {
  la(op1, op2, instrxnum);
  instrxnum--;   // because la will increment instrxNum
  deref(-1, -1, instrxnum);  // deref also increments instrxNum
}

// Pop an integer from arithmetic stack and output
void iwrite(int op1, int op2, int& instrxNum) {
  if (arithmeticStack.empty())
    bail("Arithmetic stack is empty in iwrite!"); 
  arithmeticStackElt stackElt = arithmeticStack.top();
  arithmeticStack.pop();
  printf("%d", stackElt.val1);
  instrxNum++;
}

// Pop a char from arithmetic stack and output
void cwrite(int op1, int op2, int& instrxNum) {
  if (arithmeticStack.empty())
    bail("Arithmetic stack is empty in iwrite!"); 
  arithmeticStackElt stackElt = arithmeticStack.top();
  arithmeticStack.pop();
  if (stackElt.val1 == 92)  // '\' is ASCII 47
    printf("\n");
  else printf("%c", stackElt.val1);
  instrxNum++;
}

// Read an integer from input, and push its value 
// onto arithmetic stack
void iread(int op1, int op2, int& instrxNum) {
  int x;
  scanf("%d", &x);
  arithmeticStackElt stackElt;
  stackElt.val1 = x;
  stackElt.val2 = -1;
  arithmeticStack.push(stackElt);
  instrxNum++;
}

// Read a char from input, and push its value 
// onto arithmetic stack
void cread(int op1, int op2, int& instrxNum) {
  int x;
  scanf("%c", &x);
  arithmeticStackElt stackElt;
  stackElt.val1 = x;
  stackElt.val2 = -1;
  arithmeticStack.push(stackElt);
  instrxNum++;
}

// Pop top of arithmetic stack, and push the value in 
// that address back onto the arithmetic stack
void deref(int op1, int op2, int& instrxNum) {
  if (arithmeticStack.empty())
    bail("Arithmetic stack is empty in deref!");
  arithmeticStackElt stackElt = arithmeticStack.top();
  arithmeticStack.pop();
  if (stackElt.val2 == -1)
    bail("Attempting to deref a constant!");
  
  arithmeticStackElt newStackElt;
  if (stackElt.val2 == 0)
     newStackElt.val1 = display[stackElt.val1];
  else newStackElt.val1 = 
         executionStack[1 + display[stackElt.val2] +
                            stackElt.val1];
  newStackElt.val2 = -1;

  arithmeticStack.push(newStackElt);
  instrxNum++;
}

// Pop 2 elements off arithmetic stack, and store value of 1st  
// element popped in the address contained in the 2nd 
// element popped
void st(int op1, int op2, int& instrxNum) {
  if (arithmeticStack.empty())
    bail("Arithmetic stack is empty in st!");
  arithmeticStackElt stackElt1 = arithmeticStack.top();
  arithmeticStack.pop();
  if (stackElt1.val2 != -1)
    bail("Invalid value in st!");

  if (arithmeticStack.empty())
    bail("Arithmetic stack is empty in st!");  
  arithmeticStackElt stackElt2 = arithmeticStack.top();
  arithmeticStack.pop();
  if (stackElt2.val2 == -1)
    bail("Invalid address in st!");

  if (stackElt2.val2 == 0)
     display[stackElt2.val1] = stackElt1.val1;
  else executionStack[1 + display[stackElt2.val2] +
                               stackElt2.val1] = stackElt1.val1;

  instrxNum++;
}

// Add/remove op1 elements to/from execution stack 
void asp(int op1, int op2, int& instrxNum) {
  if (DEBUG) {
    printf("\nIn asp instrxNum = %d op1 = %d\n", instrxNum, op1);
    dumpExecutionStack();
  }
  if (op1 < 0) {
    for (int i = 0; i < abs(op1); i++)
      executionStack.pop_back();
  } else {
          for (int i = 0; i < op1; i++)
            executionStack.push_back(0);
  }
  instrxNum++;
}

// Push value in specified memory location (op1, op2) 
// onto execution stack
void push(int op1, int op2, int& instrxNum) {
  int x;
  if (op2 == 0)
     x = display[op1];
  else x = executionStack[1 + display[op2] + op1];
  executionStack.push_back(x);
  instrxNum++;
}

// Pop value from top of execution stack, storing it in 
// memory location (op1, op2)
void pop(int op1, int op2, int& instrxNum) {
  if (executionStack.empty())
    bail("Execution stack is empty during pop!");
  int x = executionStack.back();
  executionStack.pop_back(); 
  if (op2 == 0)
     display[op1] = x;
  else executionStack[1 + display[op2] + op1] = x;
  instrxNum++;
}

// Save current value of execution stack top in memory 
// location (op1, op2)
void save(int op1, int op2, int& instrxNum) {
  int x = executionStack.size( ) - 1;
  if (DEBUG) {
    printf("In save instrxNum = %d and x = %d\n", instrxNum, x);
    dumpExecutionStack();
  }
  if (x < 0)
    bail("Execution stack empty during save!");
  if (op2 == 0)
     display[op1] = x;
  else executionStack[1 + display[op2] + op1] = x;
  instrxNum++;
}

// Jump to label specified by op1; stacks remain unchanged
void jp(int op1, int op2, int& instrxNum) {
  if (DEBUG)
    printf("\nIn jp with instrxNum = %d\n", instrxNum);
  char buf[20];
  sprintf(buf, "L.%d", op1);
  instrxNum = findLabelInstrxNum(buf);
  if (DEBUG)
    printf("jp is jumping to instrxNum %d\n", instrxNum);
  if (instrxNum == -1)
    bail("Attempted jump to undefined label!");
}

// Pop top of arithmetic stack; if true, 
// jump to label location (op1)
void jt(int op1, int op2, int& instrxNum) {
  if (arithmeticStack.empty())
    bail("Arithmetic stack is empty in jt!");
  arithmeticStackElt stackElt = arithmeticStack.top();
  arithmeticStack.pop();

  if (stackElt.val2 != -1)
    bail("Can't test an address equal to 'true' in jt!");
  if (stackElt.val1 != 0)
    jp(op1, op2, instrxNum);
  else instrxNum++;
}

// Pop top of arithmetic stack; if false, jump to 
// label location (op1)
void jf(int op1, int op2, int& instrxNum) {
  if (arithmeticStack.empty())
    bail("Arithmetic stack is empty in jf!");
  arithmeticStackElt stackElt = arithmeticStack.top();
  arithmeticStack.pop();

  if (stackElt.val2 != -1)
    bail("Can't test an address equal to 'false' during jf!");
  if (stackElt.val1 == 0)
    jp(op1, op2, instrxNum);
  else instrxNum++;
}

// Jump to label (op1); push address of next instruction 
// onto execution stack
void js(int op1, int op2, int& instrxNum) {
  if (DEBUG) {
    printf("\nIn js with instrxNum = %d\n", instrxNum);
    dumpExecutionStack();
  }
  executionStack.push_back(instrxNum+1);
  jp(op1, op2, instrxNum);
}

// Pop a location off execution stack, and transfer 
// control to location popped
void ji(int op1, int op2, int& instrxNum) {
  if (DEBUG)
    dumpExecutionStack();
  if (executionStack.empty())
    bail("Execution stack is empty during ji!");
  instrxNum = executionStack.back();
  executionStack.pop_back(); 
  if (DEBUG)
    printf("ji has set instrxNum to %d\n", instrxNum);
}

// All binary operations (add, mult, sub, div, mod, and, or, 
// .eq., .ne., .lt., .le., .gt., .ge.) pop 2 elements off 
// arithmetic stack, perform the operation, and 
// push result onto arithmetic stack

void add(int op1, int op2, int& instrxNum) {
  binaryOperation(T_ADD);
  instrxNum++;
}

void sub(int op1, int op2, int& instrxNum) {
  binaryOperation(T_SUB);
  instrxNum++;
}

void mult(int op1, int op2, int& instrxNum) {
  binaryOperation(T_MULT);
  instrxNum++;
}

void div(int op1, int op2, int& instrxNum) {
  binaryOperation(T_DIV);
  instrxNum++;
}

void mod(int op1, int op2, int& instrxNum) {
  binaryOperation(T_MOD);
  instrxNum++;
}

void and_op(int op1, int op2, int& instrxNum) {
  binaryOperation(T_AND);
  instrxNum++;
}

void or_op(int op1, int op2, int& instrxNum) {
  binaryOperation(T_OR);
  instrxNum++;
}

void eq_op(int op1, int op2, int& instrxNum) {
  binaryOperation(T_EQ);
  instrxNum++;
}

void ne_op(int op1, int op2, int& instrxNum) {
  binaryOperation(T_NE);
  instrxNum++;
}

void lt_op(int op1, int op2, int& instrxNum) {
  binaryOperation(T_LT);
  instrxNum++;
}

void le_op(int op1, int op2, int& instrxNum) {
  binaryOperation(T_LE);
  instrxNum++;
}

void gt_op(int op1, int op2, int& instrxNum) {
  binaryOperation(T_GT);
  instrxNum++;
}

void ge_op(int op1, int op2, int& instrxNum) {
  binaryOperation(T_GE);
  instrxNum++;
}

// Generalized function to perform any binary operation
// indicated by opCode (i.e., a particular operator token)
void binaryOperation(int opCode) {
  if (arithmeticStack.empty())
    bail("Arithmetic stack is empty during binary operation!");
  arithmeticStackElt stackElt1 = arithmeticStack.top();
  arithmeticStack.pop();

  if (arithmeticStack.empty())
    bail("Arithmetic stack is empty during binary operation!");  
  arithmeticStackElt stackElt2 = arithmeticStack.top();
  arithmeticStack.pop();

  if ((stackElt1.val2 != -1) && (stackElt2.val2 != -1)) 
    bail("Cannot perform binary operation on two addresses!"); 
  else {
        switch (opCode) {
          case T_ADD : stackElt1.val1 = stackElt2.val1 +
                                        stackElt1.val1;
                       break;
          case T_SUB : stackElt1.val1 = stackElt2.val1 -
                                        stackElt1.val1;
                       break;
          case T_MULT: stackElt1.val1 = stackElt2.val1 *
                                        stackElt1.val1;
                       break;
          case T_DIV : if (stackElt1.val1 == 0)
                         bail("Cannot divide by zero!");
                       stackElt1.val1 = stackElt2.val1 /
                                        stackElt1.val1;
                       break;
          case T_MOD : if (stackElt1.val1 == 0)
                         bail("Cannot mod by zero!");
                       stackElt1.val1 = stackElt2.val1 %
                                        stackElt1.val1;
                       break;
          case T_AND : if (stackElt1.val1 && stackElt2.val1)
                         stackElt1.val1 = 1;
                       else stackElt1.val1 = 0;
                       break;
          case T_OR  : if (stackElt1.val1 || stackElt2.val1)
                         stackElt1.val1 = 1;
                       else stackElt1.val1 = 0;
                       break;
          case T_EQ  : if (stackElt1.val1 == stackElt2.val1)
                         stackElt1.val1 = 1;
                       else stackElt1.val1 = 0;
                       break;
          case T_NE  : if (stackElt1.val1 != stackElt2.val1)
                         stackElt1.val1 = 1;
                       else stackElt1.val1 = 0;
                       break;
          case T_LT  : if (stackElt2.val1 < stackElt1.val1)
                         stackElt1.val1 = 1;
                       else stackElt1.val1 = 0;
                       break;
          case T_LE  : if (stackElt2.val1 <= stackElt1.val1)
                         stackElt1.val1 = 1;
                       else stackElt1.val1 = 0;
                       break;
          case T_GT  : if (stackElt2.val1 > stackElt1.val1)
                         stackElt1.val1 = 1;
                       else stackElt1.val1 = 0;
                       break;
          case T_GE  : if (stackElt2.val1 >= stackElt1.val1)
                         stackElt1.val1 = 1;
                       else stackElt1.val1 = 0;
                       break;
          default  :   bail("Invalid operator in binaryOperation!");
        }
        if (stackElt2.val2 != -1) 
          stackElt1.val2 = stackElt2.val2; 
        arithmeticStack.push(stackElt1);
  }
}

// All unary operations (neg, not) pop one element off
// arithmetic stack, perform the operation, and push 
// result onto arithmetic stack

void neg_op(int op1, int op2, int& instrxNum) {
  unaryOperation(T_NEG);
  instrxNum++;
}

void not_op(int op1, int op2, int& instrxNum) {
  unaryOperation(T_NOT);
  instrxNum++;
}

// Generalized function to perform any unary operation
// indicated by opCode (i.e., a particular operator token)
void unaryOperation(int opCode) {
  if (arithmeticStack.empty())
    bail("Arithmetic stack is empty during unary operation!");
  arithmeticStackElt stackElt = arithmeticStack.top();
  arithmeticStack.pop();

  if (stackElt.val2 != -1) 
    bail("Cannot perform unary operation on an address!"); 
  else {
        switch (opCode) {
          case T_NEG : stackElt.val1 = -stackElt.val1;
                       break;
          case T_NOT : if (stackElt.val1 == 0)
                         stackElt.val1 = 1;
                       else stackElt.val1 = 0;
                       break;
          default  :   bail("Invalid operator in unaryOperation!");
        }
        arithmeticStack.push(stackElt);
  }
}

// Label instructions (e.g., "L.xx:") just increment instrxNum
void labelInstrx(int op1, int op2, int& instrxNum) {
  instrxNum++;
}

// Output the contents of the execution stack (for debugging)
void dumpExecutionStack() {  
  printf("\nExecution stack contents:\n");
  for (int i = 0; i < executionStack.size(); i++)
    printf("  executionStack[%d] = %d\n", i, executionStack[i]);
}

// Output the specified message and terminate program execution.
void bail(const char* s) {
  printf("\n%s\n", s);
  exit(1);
}

// Initialize the display vector to be displaySize (which is
// 20 + space needed for global variables)
void initDisplay() {
  for (int i = 0; i < displaySize; i++)
    display.push_back(0);
}

// After parsing, evaluate the OAL code, starting at
// instructions[entryPointInstrxNum] and continuing until
// we reach the haltPointInstrxNum
void performEvaluation() {
  int instrxNum = entryPointInstrxNum;
  while (instrxNum < haltPointInstrxNum) {
    int op1 = instructions[instrxNum].op1;
    int op2 = instructions[instrxNum].op2;
    instructions[instrxNum].f(op1, op2, instrxNum);
  }
}

// When comment encountered during parsing, ignore
// all chars until eoln
void ignoreComment(void) {
  char c;

  // read and ignore the input until eoln
  while (((c = yyinput()) != '\n') && c != 0) ;

  ++lineNum;

  if (DEBUG) printf("  ----> FOUND A COMMENT\n");
  return;
}

// Add labelName and its instrxNum to labelInstrxNums
void addLabelInstrxNum(char* labelName, int instrxNum) {
  labelInfo info;
  info.labelName = strdup(labelName);
  info.instrxNum = instrxNum;
  labelInstrxNums.push_front(info);
}

// Find labelName in the labelInstrxNums list. If found,
// return its instrxNum; otherwise, return -1.
int findLabelInstrxNum(char* labelName) {
  std::list<labelInfo>::iterator itr = labelInstrxNums.begin();
  while (itr != labelInstrxNums.end()) {
    labelInfo info = (labelInfo) *itr;
    if (strcmp(labelName, info.labelName) == 0)
      return(info.instrxNum);
    itr++;
  }
  return(-1);  // labelNum not found (shouldn't happen!)
}

// Add label x to list L (where L is either jumpLocations
// or definedLabels)
void addLabel(char* x, std::list<char*> &L) {
  if (!findLabel(x, L)) L.push_front(x);
}

// Determine whether label x is in label list L (where
// L is either jumpLocations or definedLabels)
bool findLabel(char* x, std::list<char*> L) {
  std::list<char*>::iterator itr = L.begin();
  while (itr != L.end()) {
	if (strcmp(x, (char*) *itr) == 0) {
        return(true);
      }
	itr++;
  }
  return(false);
}

// Make sure all jumpLocations were to definedLabels
bool checkLabels( ) {
  bool labelsOK = true;
  std::list<char*>::iterator itr = jumpLocations.begin();
  while (itr != jumpLocations.end()) {
    char* x = (char*) *itr;
    if (!findLabel(x, definedLabels)) {
	  printf("There is a jump to undefined label %s\n", x);
        labelsOK = false;
    }
    itr++;
  }
  return(labelsOK);
}

// Output the production being parsed (for debugging)
void prRule(const char* lhs, const char* rhs) {
  if (DEBUG) printf("%s -> %s\n", lhs, rhs);
    return;
}

int main(int argc, char** argv) {
  if (argc < 2)
    bail("You must specify a file in the command line!");

  // Parse the input file, and generate instructions vector
  yyin = fopen(argv[1], "r");
  do {
	yyparse();
  } while (!feof(yyin));

  // Make sure all jumps were to defined labels
  bool labelsOK = checkLabels();
  jumpLocations.clear();
  definedLabels.clear();

  if (labelsOK) {
    initDisplay();
    performEvaluation();
    printf("\nProgram execution completed.\n");
  }

  return 0;
}
