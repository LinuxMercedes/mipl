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
#include <stack>

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
	GOTO,
	L,
	V
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
  bool operator< (const operand& rhs) const {
		if(t == rhs.t) {
			if(t == VARIABLE) {
				return o.var < rhs.o.var;
			}
			else {
				return o.val < rhs.o.val;
			}
		}
		return t < rhs.t;
	}
};

struct triple {
	oper op;
	operand result;
	operand op1;
	operand op2;
};	

vector<triple> code;
list<unsigned int> labels;

unsigned int temp = 1;
unsigned int label = 1;

unsigned int subscript = 0;
SUBSCRIPT_INFO subscripts; 

void addLbl(const unsigned int l) {
	triple t;
	t.op = L;
	t.op1.t = LABEL;
	t.op1.o.label = l;
	code.push_back(t);
}

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
case ARRAY_ASS: /* This is broken but who cares */
	printOp(t.op1);
printf("[");
printOp(t.op2);
printf("]");
printf(" = ");
printOp(t.result);
break;
case ARRAY_ACC:
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
printf("if ");
printOp(t.op1);
printf(" == true goto ");
printOp(t.op2);
break;
	case IFF:
printf("if ");
printOp(t.op1);
printf(" == false goto ");
printOp(t.op2);
break;
	case GOTO:
printf("goto ");
printOp(t.op1);
break;
case L:
printf("L%d:", t.op1.o.label);
break;
}

printf("\n");
}

/*
 * Code Optimization
 */

struct node {
	oper op;
	operand var;
	bool alive;
	bool visited;
};

struct edge {
	unsigned int f;
	unsigned int t;
};

struct DAG {
	vector<node> nodes;
	vector<vector<edge> > op;
	vector<triple> labels;
	unsigned int go;
	unsigned int start;
	unsigned int end;
};

vector<unsigned int> get_parent_idxs(unsigned int node, DAG& d) {
	vector<unsigned int> parents;
	for(unsigned int j = 0; j < d.op.size(); j++) {
		for(unsigned int k = 0; k < d.op[j].size(); k++) {
			if(d.op[j][k].t == node) {
				if(DEBUG) printf("Parent %d of %d: %d\n", j, node, d.op[j][k].f);
				parents.push_back(k);
			}
		}
	}

	return parents;
}

vector<unsigned int> get_child_idxs(unsigned int node, DAG& d) {
	vector<unsigned int> parents;
	for(unsigned int j = 0; j < d.op.size(); j++) {
		for(unsigned int k = 0; k < d.op[j].size(); k++) {
			if(d.op[j][k].f == node) {
				if(DEBUG) printf("Child %d of %d: %d\n", j, node, d.op[j][k].t);
				parents.push_back(d.op[j][k].t);
			}
		}
	}

	return parents;
}

vector<edge> get_parents(vector<unsigned int>& idxs, DAG& d) {
	vector<edge> parents;
	for(unsigned int i = 0; i < idxs.size(); i++) {
		parents.push_back(d.op[i][idxs[i]]);
	}
	
	return parents;
}

unsigned int get_val(operand& o, map<operand, unsigned int>& values, DAG& d) {
	map<operand, unsigned int>::iterator it = values.find(o);
	if(DEBUG) printOp(o);
	if(DEBUG) printf("\n");

	if(it == values.end()) {
		node n = {V, o, true, false};
		d.nodes.push_back(n);
		values[o] = d.nodes.size() - 1;
		return d.nodes.size() - 1;
	}
	else {
		return it->second;
	}
}

unsigned int update_val(operand& o, map<operand, unsigned int>& values, DAG& d, unsigned int node) {
	if(values.count(o)) {
		d.nodes[values[o]].alive = false;
	}
	return values[o] = node;
}

vector<DAG> makeDAGs() {
	vector<DAG> dags;

	list<unsigned int> leaders;
	if(DEBUG) printf("\nBlock leaders are as follows:\n");
	if(DEBUG) printf("(%d)\n", 0);
	leaders.push_back(0);	

	bool nextleader = false;
	for(unsigned int i = 1; i < code.size(); i++) {
		if(nextleader && leaders.back() != i) {
			if(DEBUG) printf("(%d)\n", i);
			leaders.push_back(i);
			nextleader = false;
		}

		switch(code[i].op) {
			case L:
				if(leaders.back() != i) {
					if(DEBUG) printf("(%d)\n", i);
					leaders.push_back(i);
				}
				break;
			case IFT:
			case IFF:
			case GOTO:
				nextleader = true;
				break;
		}
	}			

	if(DEBUG) printf("\n\nBlocks are as follows:\n");
	DAG d;
	unsigned int blocknum = 0;
	bool startset = false;
	for(list<unsigned int>::iterator it = leaders.begin(); it != leaders.end();) {
		unsigned int start = *it;
		it++;
		unsigned int end = it == leaders.end() ? code.size() - 1 : *it - 1;
	
		if(DEBUG) printf("B%d: (%d) - (%d)\n", blocknum++, start, end);
		/* Handle duplicate labels */
		if(start == end && code[start].op == L) {
			if(!startset) {	
				d.start = start;
				startset = true;
			}
			d.labels.push_back(code[start]);
			continue;
		}

		if(!startset) {
			d.start = start;
		}
		d.end = end;
		d.nodes.clear();
		d.op.resize(3);
		d.go = 0;
		startset = false;
		map<operand, unsigned int> values;

		for(unsigned int i = start; i <= end; i++) {
			switch(code[i].op) {
				case L: {
					d.labels.push_back(code[i]);
					break;
				}
				case GOTO: {
					d.go = code[i].op1.o.label;
					break;
				}
				/* Three-child instrs */
				case ARRAY_ASS: {
					unsigned int val = get_val(code[i].result, values, d);
					unsigned int idx = get_val(code[i].op2, values, d);
					unsigned int n = d.nodes.size();
					unsigned int arr = update_val(code[i].op1, values, d, n);
	
					node no = {code[i].op, code[i].op1, true, false};
					edge idxe = {idx,n};
					//edge arre = {arr,n};
					edge vale = {val,n};

					d.nodes.push_back(no);
					d.op[1].push_back(idxe);
					//d.op[1].push_back(arre);
					d.op[0].push_back(vale);
				
					break;
				}
				case ARRAY_ACC:
				case ADDITION:
				case MULTIPLICATION:
				case GREATER_THAN:
				case GREATER_EQUAL:
				case EQUAL:
				case LESS_EQUAL:
				case LESS_THAN:
				case NOT_EQUAL: {
					unsigned int op2 = get_val(code[i].op2, values, d);
					unsigned int op1 = get_val(code[i].op1, values, d);

					unsigned int n = d.nodes.size();
					unsigned int res = update_val(code[i].result, values, d, n);
					edge e2 = {op2, n};
					edge e1 = {op1, n};
					d.op[1].push_back(e2);
					d.op[0].push_back(e1);
					node no = {code[i].op, code[i].result, true, false};
					d.nodes.push_back(no);
					break;
				}
				case ASSIGNMENT: {
					unsigned int val = get_val(code[i].op1, values, d);
					unsigned int n = d.nodes.size();
					unsigned int res = update_val(code[i].result, values, d, n);
				
					edge e = {val, n};
					d.op[0].push_back(e);
					node no = {code[i].op, code[i].result, true, false};
					d.nodes.push_back(no);
					break;
				}
				case IFT:
				case IFF: {
					edge e = {get_val(code[i].op1, values, d), d.nodes.size()};
					d.op[0].push_back(e);
					node no = {code[i].op, code[i].op2, true, false};
					d.nodes.push_back(no);
					
					break;
				}
			}
		}
		
		dags.push_back(d);

		/* clean up dag object for next dag */
		d.nodes.clear();
		d.op.clear();
		d.labels.clear();
		d.go = 0;
	}
	
	if(d.labels.size()) {
		dags.push_back(d);
	}	
	return dags;	
}

vector<triple> makeTAC(vector<DAG>& dags) {
	vector<triple> tac;
	
	for(unsigned int i = 0; i < dags.size(); i++) {
		if(DEBUG) printf("Dag %d\n", i);
		for(unsigned int l = 0; l < dags[i].labels.size(); l++) {
			tac.push_back(dags[i].labels[l]);
		}

/* 
 * Create a list of values from the dag (they will have no parents).
 * Mark these parents as visited. 
 * For each value, push its unvisited children onto a stack.
 * Pop the first child off the stack. 
   * If its parents are visited, generate the appropriate TACs, mark it visited, and push its children onto the stack. 
	 * Otherwise, push it onto the stack, then push its parents onto the stack. 
 * Repeat until the stack is empty.
 * Repeat for all values.
 */

		// TODO delete me
		for(unsigned int f = 0; f < dags[i].nodes.size(); f++) {
			node n = dags[i].nodes[f];
			if(DEBUG) printf("Node %d: ", f);
			if(DEBUG) printOp(n.var);
			if(DEBUG) printf(" %d\n", n.op);
		}
		for(unsigned int g = 0; g < dags[i].op.size(); g++) {
			if(DEBUG) printf("Edge list %d:\n", g);
			for(unsigned int f = 0; f < dags[i].op[g].size(); f++) {
				if(DEBUG) printf("Edge from %d to %d\n", dags[i].op[g][f].f, dags[i].op[g][f].t);
			}
		}

		vector<unsigned int> values;
		for(unsigned int d = 0; d < dags[i].nodes.size(); d++) {
			if(dags[i].nodes[d].op == V) {
				dags[i].nodes[d].visited = true;
				values.push_back(d);
			}
		}

		for(unsigned int v = 0; v < values.size(); v++) {
			if(DEBUG) printf("Value: %d\n", values[v]);

			bool all_visited = true;
			for(unsigned int n = 0; n < dags[i].nodes.size(); n++) {
				all_visited &= dags[i].nodes[n].visited;
			}
			if(all_visited) break;

			stack<unsigned int> unvisited;
			vector<unsigned int> children = get_child_idxs(values[v], dags[i]);

			for(unsigned int c = children.size(); c > 0; c--) {
				if(dags[i].nodes[children[c-1]].visited == false) {
					if(DEBUG) printf("push1 %d\n", children[c-1]);
					unvisited.push(children[c-1]);
				}
			}

			while(unvisited.size()) {
				/* So sometimes we eval something before we said we would */
				while(unvisited.size() && dags[i].nodes[unvisited.top()].visited) {
					unvisited.pop();
				}
				if(unvisited.size() == 0) break;

				vector<unsigned int> parents = get_parent_idxs(unvisited.top(), dags[i]);
				bool can_eval = true;
				for(unsigned int p = 0; p < parents.size(); p++) {
					unsigned int parent_idx = dags[i].op[p][parents[p]].f;
					if(dags[i].nodes[parent_idx].visited == false) {
						can_eval = false;
						if(DEBUG) printf("push2 %d\n", parent_idx);
						unvisited.push(parent_idx);
					}
				}
				if(can_eval) {
					unsigned int n = unvisited.top();
					if(DEBUG) printf("Evaling node %d\n", n);
					unvisited.pop();

					dags[i].nodes[n].visited = true;

					triple t;
					t.op = dags[i].nodes[n].op;
					switch(t.op) {
						case ARRAY_ASS: {
							unsigned int idx = dags[i].op[1][parents[1]].f;
							unsigned int val = dags[i].op[0][parents[0]].f;
							t.result = dags[i].nodes[val].var;
							t.op1 = dags[i].nodes[n].var;
							t.op2 = dags[i].nodes[idx].var;
							break;
						}
						case IFT:
						case IFF: {
							unsigned int val = dags[i].op[0][parents[0]].f;
							t.op1 = dags[i].nodes[val].var;
							t.op2 = dags[i].nodes[n].var;
							break;
						}
						case ASSIGNMENT: {
							unsigned int val = dags[i].op[0][parents[0]].f;
							t.op1 = dags[i].nodes[val].var;
							t.result = dags[i].nodes[n].var;
							break;
						}
						default: {
							unsigned int op1 = dags[i].op[0][parents[0]].f;	
							unsigned int op2 = dags[i].op[1][parents[1]].f;	
							t.op1 = dags[i].nodes[op1].var;
							t.op2 = dags[i].nodes[op2].var;
							t.result = dags[i].nodes[n].var;
							break;
						}
					}
					tac.push_back(t);
					
					/* Add children of the node we just evaluated */
					vector<unsigned int> children = get_child_idxs(n, dags[i]);

					for(unsigned int c = children.size(); c > 0; c--) {
						if(dags[i].nodes[children[c-1]].visited == false) {
							if(DEBUG) printf("push3 %d\n", children[c-1]);
							unvisited.push(children[c-1]);
						}
					}
				}
			}
		}

/* Additional notes:
 * Nodes need a vector of vars, not just one. Need to make sure that this doesn't fuck up anything important.
 * ^ is a terrible idea, just put the assignments in the DAG anyway
 * Change int width from 4 to 1.
 */

		if(dags[i].go > 0) {
			triple g;
			g.op = GOTO;
			g.op1.t = LABEL;
			g.op1.o.label = dags[i].go;
			tac.push_back(g);
		}
	}

	for(unsigned int i = 0; i < dags.size(); i++) {
		for(unsigned int j = 0; j < dags[i].nodes.size(); j++) {
			dags[i].nodes[j].visited = false;
		}
	}

	if(DEBUG) printf("TAC: %d\n", tac.size());
	return tac;
}

bool modified = false;

void fold_consts(DAG& d) {
	for(unsigned int i = 0; i < d.nodes.size(); i++) {
		vector<unsigned int> p_idxs = get_parent_idxs(i, d);
		vector<edge> parents = get_parents(p_idxs, d);

		/* Remove constant operations */
		if(parents.size() == 2 && d.nodes[parents[0].f].var.t == VALUE && d.nodes[parents[1].f].var.t == VALUE) {	

			bool operating = true;
			int v1 = d.nodes[parents[0].f].var.o.val;
			int v2 = d.nodes[parents[1].f].var.o.val;
			int res = 0;
			switch(d.nodes[i].op) {
				case ADDITION:
					res = v1 + v2;
					break;
				case MULTIPLICATION:
					res = v1 * v2;
					break;
				case GREATER_THAN:
					res = v1 > v2;
					break;
				case GREATER_EQUAL:
					res = v1 >= v2;
					break;
				case EQUAL:
					res = v1 == v2;
					break;
				case LESS_EQUAL:
					res = v1 <= v2;
					break;
				case LESS_THAN:
					res = v1 < v2;
					break;
				case NOT_EQUAL: 
					res = v1 != v2;
					break;
				default:
					operating = false;
					break;
			}

			if(operating) {
				d.nodes[i].op = V;
				d.nodes[i].var.t = VALUE;
				d.nodes[i].var.o.val = res;

				d.op[0].erase(d.op[0].begin() + p_idxs[0]);
				d.op[1].erase(d.op[1].begin() + p_idxs[1]);
				modified = true;
			}
		}

	}
}

bool is_value(DAG& d, unsigned int node, int value) {
	return d.nodes[node].op == V && d.nodes[node].var.o.val == value;
}

void alg_simp(DAG& d) {
	for(unsigned int i = 0; i < d.nodes.size(); i++) {
		vector<unsigned int> p_idxs = get_parent_idxs(i, d);
		vector<edge> parents = get_parents(p_idxs, d);
		bool operating = true;
		int value = 0;
		switch(d.nodes[i].op) {
			case ADDITION:
				value = 0;
				break;
			case MULTIPLICATION:
				value = 1;
				break;
			default:
				operating = false;
				break;
		}
		if(operating) {
			modified = true;
			if(is_value(d, parents[0].f, value)) {
				d.nodes[i].op = ASSIGNMENT;
				d.op[0].erase(d.op[0].begin() + p_idxs[0]);
				d.op[0].push_back(d.op[1][p_idxs[1]]);
				d.op[1].erase(d.op[1].begin() + p_idxs[1]);
			}
			else if(is_value(d, parents[1].f, value)) {
				d.nodes[i].op = ASSIGNMENT;
				d.op[1].erase(d.op[1].begin() + p_idxs[1]);
			}
		}
	}
}

void common_subexpr(DAG& d) {

}

void remove_const_tempvars(DAG& d) {
	/* Remove constant assignments to temp vars */
	for(unsigned int i = 0; i < d.nodes.size(); i++) {
		vector<unsigned int> p_idxs = get_parent_idxs(i, d);
		vector<edge> parents = get_parents(p_idxs, d);
		if(d.nodes[i].op == ASSIGNMENT && d.nodes[i].var.t == TEMP && d.nodes[parents[0].f].var.t == VALUE) {
			d.nodes[i].op = V;
			d.nodes[i].var.t = VALUE;
			d.nodes[i].var.o.val = d.nodes[parents[0].f].var.o.val;

			d.op[0].erase(d.op[0].begin() + p_idxs[0]);
		}
	}
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

	$$ = t.result;
	}
	| L ASSIGN E
	{
	prRule("A", "L = E");
	$1.op = ARRAY_ASS;
	$1.result = $3;
	code.push_back($1);
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

	}
		S ELSE 
	{
		triple t;
		t.op = GOTO;
		t.op1.t = LABEL;
		t.op1.o.label = label;
		code.push_back(t);

		addLbl(labels.back());
		labels.pop_back();
	
		labels.push_back(label++);
	}
		S
	{
	prRule("F", "if ( B ) then S else S");
	addLbl(labels.back());
	labels.pop_back();
	}
	; 
W	: WHILE LPAREN 
	{
		addLbl(label);
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

	addLbl(after);

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

	subscript = 0;
	subscripts = s;

	unsigned int sz = 1;
	for(unsigned int j = subscript + 1; j < s.size(); j++) {
		sz *= s[j];
	}

	triple t;
	t.op = MULTIPLICATION;
	t.op1 = $3;
	t.op2.t = VALUE;
	t.op2.o.val = sz;
	t.result.t = TEMP;
	t.result.o.temp = temp++;

	code.push_back(t);

	$$.op1.t = VARIABLE;
	$$.op1.o.var = $1;
	$$.op2 = t.result;

	}
	| L LBRACK E RBRACK
	{
	prRule("L", "L [ E ]");
	
	subscript++;

	unsigned int sz = 1;
	for(unsigned int j = subscript + 1; j < subscripts.size(); j++) {
		sz *= subscripts[j];
	}

	/* Calculate size */
	triple t;
	t.op = MULTIPLICATION;
	t.op1 = $3;
	t.op2.t = VALUE;
	t.op2.o.val = sz;
	t.result.t = TEMP;
	t.result.o.temp = temp++;

	code.push_back(t);

	/* Add to previously calculated size */
	triple t2;
	t2.op = ADDITION;
	t2.op1 = $1.op2;
	t2.op2 = t.result;
	t2.result.t = TEMP;
	t2.result.o.temp = temp++;

	code.push_back(t2);

	/* This is the C++ equivalent of smallpox blankets */
	$$.op1 = $1.op1;
	$$.op2 = t2.result;
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

	//DEBUG = true;

  do {
		yyparse();
  } while (!feof(yyin));

	printf("List of instructions:\n");
	for(unsigned int i = 0; i < code.size(); i++) {
		printf("(%d) ", i);
		printTriple(code[i]);
	}

	vector<DAG> dags = makeDAGs();

	for(unsigned int i = 0; i < dags.size(); i++) {
		do {
			modified = false;
			printf("Executing constantFolding for (%d) - (%d)\n", dags[i].start, dags[i].end);
			fold_consts(dags[i]);
			printf("Executing algebraicSimplification for (%d) - (%d)\n", dags[i].start, dags[i].end);
			alg_simp(dags[i]);
			printf("Executing commonSubexprElimination for (%d) - (%d)\n", dags[i].start, dags[i].end);
			common_subexpr(dags[i]);

			vector<triple> tac = makeTAC(dags);
			for(unsigned int i = 0; i < tac.size(); i++) {
				printf("(%d) ", i);
				printTriple(tac[i]);
			}
	
			break; //TODO: Remove me!
		} while(modified);

		printf("\nEliminating temp vars that have constant value\n");
		remove_const_tempvars(dags[i]);
	}

	vector<triple> tac = makeTAC(dags);

	printf("\nNew list of optimized instructions:\n");
	for(unsigned int i = 0; i < tac.size(); i++) {
		printf("(%d) ", i);
		printTriple(tac[i]);
	}

  return 0;
}
