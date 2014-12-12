/* -*- mode: bison; indent-tabs-mode: t; -*- */
/*
	mipl.y - a bison specification for the MIPL language

	Author: Nathan Jarus
	Class: CS 5500

*/

%{
#include <cstdio>
#include <stack>
#include <string>
#include <iostream>
#include <sstream>
#include <vector>
#include "varinfo.h"
#include "scope.h"
#include "llvm-helpers.h"

#include "llvm/Analysis/Verifier.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"

using namespace llvm;

#undef PRINT_RULES

	void printRule(const char* lhs, const char* rhs);
	void printToken(const char* token, const char* lexeme);

	int yyerror(const char* s);

	const char* MAX_INT_STR = "2147483647";

	extern "C" {
		int yyparse(void);
		int yylex(void);
		int yywrap() { return 1; }
	}

	Scope scope;

	unsigned int nest_level = 0;

	/* This might be useful for maintaining LLVM functions */
	std::stack<Function*> current_proc;

	struct IdentList {
		char* ident;
		IdentList* next;
	};

	Function *main_func, *printf_func, *scanf_func;
	Value *int_format, *char_format;
	static Module* TheModule;
	static IRBuilder<> Builder(getGlobalContext());

	Function* get_current_function();
%}

%union {
	char* text;
	VarInfo varinfo;
	TypeInfo typeinfo;
	ArrayInfo arrayinfo;
	long integer;
	IdentList* ilist;
	BasicBlock* block;
};

%token T_ASSIGN T_MULT T_PLUS T_MINUS T_DIV T_AND T_OR T_NOT T_LT T_GT T_LE T_GE T_EQ T_NE T_VAR T_ARRAY T_OF T_BOOL T_CHAR T_INT T_PROG T_PROC T_BEGIN T_END T_WHILE T_DO T_IF T_READ T_WRITE T_TRUE T_FALSE T_LBRACK T_RBRACK T_SCOLON T_COLON T_LPAREN T_RPAREN T_COMMA T_DOT T_DOTDOT T_INTCONST T_CHARCONST T_UNKNOWN T_IDENT T_THEN T_ELSE

%start N_START

%type<text> T_IDENT N_IDENT T_CHARCONST;
%type<typeinfo> N_TYPE N_ARRAY N_SIMPLE N_EXPR N_ADDOPLST N_MULTOPLST N_FACTOR N_ADDOP N_MULTOP N_RELOP N_CONST N_SIMPLEEXPR N_TERM N_OUTPUT;
%type<varinfo> N_VARIDENT N_PROCIDENT N_VARIABLE N_IDXVAR N_ENTIREVAR N_ARRAYVAR N_INPUTVAR;
%type<arrayinfo> N_IDXRANGE;
%type<integer> N_IDX N_INTCONST N_SIGN T_INTCONST N_BOOLCONST;
%type<ilist> N_IDENTLST;
%%

N_START :
	{
		main_func = CreateMain(TheModule);
		BasicBlock *BB = BasicBlock::Create(getGlobalContext(), "entry", main_func);
		Builder.SetInsertPoint(BB);
		current_proc.push(main_func);
	}
	N_PROG
	{
		printRule("N_START", "N_PROG");
		current_proc.pop();
		Builder.CreateRetVoid();
		verifyFunction(*main_func);
		TheModule->dump();
		return 0;
	}
;

N_PROGLBL : T_PROG
	{
		printRule("N_PROGLBL", "T_PROG");
	}
;

N_PROG : N_PROGLBL
	{
		scope.push();
	}
		T_IDENT T_SCOLON
	{
		printRule("N_PROG", "N_PROGLBL T_IDENT T_SCOLON N_BLOCK T_DOT");
		std::string pname($3);
		free($3);
		VarInfo v;
		v.type.type = PROGRAM;
		if(!scope.add(pname, v)) {
			yyerror("Multiply defined identifier");
		}
	}
		N_BLOCK T_DOT
	{
		scope.pop();
	}
;

N_BLOCK : N_VARDECPART
	{
		if(nest_level == 0) {
		}
		else {
		}
	}
		N_PROCDECPART N_STMTPART
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
		IdentList* it = $2;
		IdentList* del;

		VarInfo v;
		v.type = $4;
		v.level = nest_level;
		v.value = CreateEntryBlockAlloca(get_current_function(), $1, v);

		if(!scope.add(std::string($1), v)) {
			free($1);
			yyerror("Multiply defined identifier");
		}

		free($1);
		bool mult = false; /* Try to not leak memory */
		while(it != NULL) {
			v.value = CreateEntryBlockAlloca(get_current_function(), it->ident, v);

			if(!mult && !scope.add(std::string(it->ident), v)) {
				mult = true;
			}

			free(it->ident);
			del = it;
			it = it->next;
			delete del;
		}
		if(mult) {
			yyerror("Multiply defined identifier");
		}
	}
;

N_IDENT : T_IDENT
	{
		$$ = $1;
		printRule("N_IDENT", "T_IDENT");
	}
;

N_IDENTLST : /* epsilon */
	{
		$$ = NULL;
		printRule("N_IDENTLST", "epsilon");
	}
| T_COMMA N_IDENT N_IDENTLST
	{
		IdentList* il = new IdentList;
		il->ident = $2;
		il->next = $3;

		$$ = il;

		printRule("N_IDENTLST", "T_COMMA N_IDENT N_IDENTLST");
	}
;

N_TYPE : N_SIMPLE
	{
		$$ = $1;
		printRule("N_TYPE", "N_SIMPLE");
	}
| N_ARRAY
	{
		$$ = $1;
		printRule("N_TYPE", "N_ARRAY");
	}
;

N_ARRAY : T_ARRAY T_LBRACK N_IDXRANGE T_RBRACK T_OF N_SIMPLE
	{
		$$.array = $3;
		$$.type = ARRAY;
		$$.extended = $6.type;
		printRule("N_ARRAY", "T_ARRAY T_LBRACK N_IDXRANGE T_RBRACK T_OF N_SIMPLE");
	}
;

N_IDX : N_INTCONST
	{
		$$ = $1;
		printRule("N_IDX", "N_INTCONST");
	}
;

N_IDXRANGE : N_IDX T_DOTDOT N_IDX
	{
		printRule("N_IDXRANGE", "N_IDX T_DOTDOT N_IDX");

		if ($1 > $3) {
			yyerror("Start index must be less than or equal to end index of array");
		}

		$$.start = $1;
		$$.end = $3;
	}
;

N_SIMPLE : T_INT
	{
		$$.type = INT;
		printRule("N_SIMPLE", "T_INT");
	}
| T_CHAR
	{
		$$.type = CHAR;
		printRule("N_SIMPLE", "T_CHAR");
	}
| T_BOOL
	{
		$$.type = BOOL;
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
		Builder.CreateRetVoid();
		Function* this_fcn = Builder.GetInsertBlock()->getParent();
		verifyFunction(*this_fcn);

		current_proc.pop();
		Builder.SetInsertPoint(&current_proc.top()->back());
		scope.pop();
		nest_level--;
	}
;

N_PROCHDR : T_PROC T_IDENT T_SCOLON
	{
		printRule("N_PROCHDR", "T_PROC T_IDENT T_SCOLON");
		std::string pname = std::string($2);
		free($2);
		
		/* A complicated version of nothing */
		std::vector<llvm::Type*> nothing(0, llvm::Type::getVoidTy(getGlobalContext()));
		FunctionType* FT = FunctionType::get(llvm::Type::getVoidTy(getGlobalContext()), nothing, false);
		Function* F = Function::Create(FT, Function::ExternalLinkage, pname, TheModule);

		BasicBlock* entry = BasicBlock::Create(getGlobalContext(), "entry", F);
		Builder.SetInsertPoint(entry);
		current_proc.push(F);

		VarInfo p;
		p.type.type = PROCEDURE;
		p.nest_level = ++nest_level;
		p.func = F;
		
		if(!scope.add(pname, p)) {
			yyerror("Multiply defined identifier");
		}
		scope.push();	
	}
;

N_STMTPART :
	{
		if(nest_level == 0) {
		}
		else {
			/* VarInfo v = scope.get(current_proc.top()); */
		}
	}
		N_COMPOUND
	{
		if(nest_level != 0) {
			/* VarInfo v = scope.get(current_proc.top()); */
		}
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

		if($1.type.type == ARRAY) {
			yyerror("Cannot make assignment to an array");
		}

		if($1.type.type != $3.type) {
			yyerror("Expression must be of same type as variable");
		}

		Builder.CreateStore($3.value, $1.value);
	}
;

N_PROCSTMT : N_PROCIDENT
	{
		printRule("N_PROCSTMT", "N_PROCIDENT");
		for(unsigned int caller_level = $1.nest_level; caller_level <= nest_level; caller_level++) {
		}
	}
;

N_PROCIDENT : T_IDENT
	{
		printRule("N_PROCIDENT", "T_IDENT");
		$$ = scope.get(std::string($1));
		free($1);

		if($$.type.type == UNDEFINED) {
			yyerror("Undefined identifier");
		}

		if($$.type.type != PROCEDURE) {
			yyerror("Procedure/variable mismatch");
		}

		for(unsigned int caller_level = nest_level; caller_level >= $$.nest_level; caller_level--) {
		}

		Builder.CreateCall($$.func);
	}
;

N_READ : T_READ T_LPAREN N_INPUTVAR
	{
		Value *fmt = char_format;
		if($3.type.type == INT) {
			fmt = int_format;
		}

		CallInst *call = Builder.CreateCall2(scanf_func, fmt, $3.value);
		call->setTailCall(false);
	}
	N_INPUTLST T_RPAREN
	{
		printRule("N_READ", "T_READ T_LPAREN N_INPUTVAR N_INPUTLST T_RPAREN");
	}
;

N_INPUTLST : /* epsilon */
	{
		printRule("N_INPUTLST", "epsilon");
	}
| T_COMMA N_INPUTVAR
	{
		Value *fmt = char_format;
		if($2.type.type == INT) {
			fmt = int_format;
		}

		CallInst *call = Builder.CreateCall2(scanf_func, fmt, $2.value);
		call->setTailCall(false);
	}
	N_INPUTLST
	{
		printRule("N_INPUTLST", "T_COMMA N_INPUTVAR N_INPUTLST");
	}
;

N_INPUTVAR : N_VARIABLE
	{
		printRule("N_INPUTVAR", "N_VARIABLE");

		if($1.type.type != INT && $1.type.type != CHAR) {
			yyerror("Input variable must be of type integer or char");
		}

		$$ = $1;
	}
;

N_WRITE : T_WRITE T_LPAREN N_OUTPUT
	{
		Value *fmt = char_format;
		if($3.type == INT) {
			fmt = int_format;
		}

		CallInst *call = Builder.CreateCall2(printf_func, fmt, $3.value);
		call->setTailCall(false);
	}
	N_OUTPUTLST T_RPAREN
	{
		printRule("N_WRITE", "T_WRITE T_LPAREN N_OUTPUT N_OUTPUTLST T_RPAREN");
	}
;

N_OUTPUTLST : /* epsilon */
	{
		printRule("N_OUTPUTLST", "epsilon");
	}
| T_COMMA N_OUTPUT
	{
		Value *fmt = char_format;
		if($2.type == INT) {
			fmt = int_format;
		}

		CallInst *call = Builder.CreateCall2(printf_func, fmt, $2.value);
		call->setTailCall(false);
	}
	N_OUTPUTLST
	{
		printRule("N_OUTPUTLST", "T_COMMA N_OUTPUT N_OUTPUTLST");
	}
;

N_OUTPUT : N_EXPR
	{
		printRule("N_OUTPUT", "N_EXPR");

		if($1.type != INT && $1.type != CHAR) {
			yyerror("Output expression must be of type integer or char");
		}

		$$ = $1;
	}
;

N_CONDITION : T_IF N_EXPR
	{
		Value* cond = $2.value;
		cond = Builder.CreateICmpNE(cond, ConstantInt::get(getGlobalContext(), APInt(1,0)), "ifcond");
		Function* this_fcn = Builder.GetInsertBlock()->getParent();
		BasicBlock* thenBB = BasicBlock::Create(getGlobalContext(), "then", this_fcn);
		BasicBlock* elseBB = BasicBlock::Create(getGlobalContext(), "else");

		Builder.CreateCondBr(cond, thenBB, elseBB);
		Builder.SetInsertPoint(thenBB);

		$<block>$ = elseBB;
	}
		T_THEN N_STMT
	{
		BasicBlock* mergeBB = BasicBlock::Create(getGlobalContext(), "ifend");
		Builder.CreateBr(mergeBB);
		$<block>$ = mergeBB;

		Function* this_fcn = Builder.GetInsertBlock()->getParent();
		this_fcn->getBasicBlockList().push_back($<block>3);
		Builder.SetInsertPoint($<block>3);
	}
		N_ELSE
	{
		printRule("N_CONDITION", "T_IF N_EXPR T_THEN N_STMT N_ELSE");

		Builder.CreateBr($<block>6);
		Function* this_fcn = Builder.GetInsertBlock()->getParent();
		this_fcn->getBasicBlockList().push_back($<block>6);
		Builder.SetInsertPoint($<block>6);

		if($2.type != BOOL) {
			yyerror("Expression must be of type boolean");
		}
	}
;

N_ELSE : /* epsilon */
	{
		printRule("N_ELSE", "epsilon");
	}
| T_ELSE N_STMT
	{
		printRule("N_ELSE", "T_ELSE N_STMT");
	}
;

N_WHILE : T_WHILE
	{
		Function* this_fcn = Builder.GetInsertBlock()->getParent();
		BasicBlock* condBB = BasicBlock::Create(getGlobalContext(), "whilecond", this_fcn);
		Builder.CreateBr(condBB);
		Builder.SetInsertPoint(condBB);
		$<block>$ = condBB;
	}
		N_EXPR
	{
		if($3.type != BOOL) {
			yyerror("Expression must be of type boolean");
		}

		Value* cond = $3.value;
		cond = Builder.CreateICmpNE(cond, ConstantInt::get(getGlobalContext(), APInt(1,0)), "ifcond");
		Function* this_fcn = Builder.GetInsertBlock()->getParent();
		BasicBlock* whileBB = BasicBlock::Create(getGlobalContext(), "while", this_fcn);
		BasicBlock* afterBB = BasicBlock::Create(getGlobalContext(), "whileend");

		Builder.CreateCondBr(cond, whileBB, afterBB);
		Builder.SetInsertPoint(whileBB);

		$<block>$ = afterBB;
	}
		T_DO N_STMT
	{
		printRule("N_WHILE", "T_WHILE N_EXPR T_DO N_STMT");

		Builder.CreateBr($<block>2);

		Function* this_fcn = Builder.GetInsertBlock()->getParent();
		this_fcn->getBasicBlockList().push_back($<block>4);
		Builder.SetInsertPoint($<block>4);
	}
;

N_EXPR : N_SIMPLEEXPR
	{
		$$ = $1;
		printRule("N_EXPR", "N_SIMPLEEXPR");
	}
| N_SIMPLEEXPR N_RELOP N_SIMPLEEXPR
	{
		printRule("N_EXPR", "N_SIMPLEEXPR N_RELOP N_SIMPLEEXPR");

		if(($1.type != CHAR && $1.type != BOOL && $1.type != INT) || $1.type != $3.type) {
			yyerror("Expressions must both be int, or both char, or both boolean");
		}
		$$ = $2;

		switch($2.op) {
			case LT:
				$$.value = Builder.CreateICmpSLT($1.value, $3.value, "ltcmp");
				break;
			case LE:
				$$.value = Builder.CreateICmpSLE($1.value, $3.value, "lecmp");
				break;
			case NE:
				$$.value = Builder.CreateICmpNE($1.value, $3.value, "necmp");
				break;
			case EQ:
				$$.value = Builder.CreateICmpEQ($1.value, $3.value, "eqcmp");
				break;
			case GT:
				$$.value = Builder.CreateICmpSGT($1.value, $3.value, "gtcmp");
				break;
			case GE:
				$$.value = Builder.CreateICmpSGE($1.value, $3.value, "gecmp");
				break;
			default:
				std::cerr << "We should never reach this for RelOps" << std::endl;
		}

	}
;

N_SIMPLEEXPR : N_TERM N_ADDOPLST
	{
		printRule("N_SIMPLEEXPR", "N_TERM N_ADDOPLST");

		if($2.type != UNDEFINED && $1.type != $2.type) {
			switch($2.type) {
				case BOOL:
					yyerror("Expression must be of type boolean");
				case INT:
					yyerror("Expression must be of type integer");
			}
		}
		$$ = $1;
		$$.value = $1.value;

		if ($2.type != UNDEFINED) {
		    $$.value = GetOperation(Builder, $2.op, $1.value, $2.value);
		}
	}
;

N_ADDOPLST : /* epsilon */
	{
		$$.type = UNDEFINED;
		printRule("N_ADDOPLST", "epsilon");
	}
| N_ADDOP N_TERM N_ADDOPLST
	{
		printRule("N_ADDOPLST", "N_ADDOP N_TERM N_ADDOPLST");

		if(($1.type != $2.type) || ($3.type != UNDEFINED && $3.type != $1.type)) {
			switch($1.type) {
				case BOOL:
					yyerror("Expression must be of type boolean");
				case INT:
					yyerror("Expression must be of type integer");
			}
		}

		$$ = $1;
		$$.value = $2.value;

		if ($3.type != UNDEFINED) {
			$$.value = GetOperation(Builder, $3.op, $2.value, $3.value);
		}
	}
;

N_TERM : N_FACTOR N_MULTOPLST
	{
		printRule("N_TERM", "N_FACTOR N_MULTOPLST");

		if($2.type != UNDEFINED && $1.type != $2.type) {
			switch($2.type) {
				case BOOL:
					yyerror("Expression must be of type boolean");
				case INT:
					yyerror("Expression must be of type integer");
			}
		}
		$$ = $1;
		$$.value = $1.value;

		if ($2.type != UNDEFINED) {
		    $$.value = GetOperation(Builder, $2.op, $1.value, $2.value);
		}
	}
;

N_MULTOPLST : /* epsilon */
	{
		$$.type = UNDEFINED;
		printRule("N_MULTOPLST", "epsilon");
	}
| N_MULTOP N_FACTOR N_MULTOPLST
	{
		printRule("N_MULTOPLST", "N_MULTOP N_FACTOR N_MULTOPLST");

		if(($1.type != $2.type) || ($3.type != UNDEFINED && $3.type != $1.type)) {
			switch($1.type) {
				case BOOL:
					yyerror("Expression must be of type boolean");
				case INT:
					yyerror("Expression must be of type integer");
			}
		}
		$$ = $1;
		$$.value = $2.value;

		if ($3.type != UNDEFINED) {
		    $$.value = GetOperation(Builder, $3.op, $2.value, $3.value);
		}
	}
;

N_FACTOR : N_SIGN N_VARIABLE
	{
		printRule("N_FACTOR", "N_SIGN N_VARIABLE");

		if($1 != 0 && $2.type.type != INT) {
			yyerror("Expression must be of type integer");
		}
		$$ = $2.type;
		$$.value = Builder.CreateLoad($2.value);

		if($1 == -1) {
		    $$.value = Builder.CreateMul(CreateIntConst(-1), $$.value, "multmp");
		}
	}
| N_CONST
	{
		$$ = $1;
		printRule("N_FACTOR", "N_CONST");
	}
| T_LPAREN N_EXPR T_RPAREN
	{
		$$ = $2;
		printRule("N_FACTOR", "T_LPAREN N_EXPR T_RPAREN");
	}
| T_NOT N_FACTOR
	{
		printRule("N_FACTOR", "T_NOT N_FACTOR");

		if($2.type != BOOL) {
			yyerror("Expression must be of type boolean");
		}
		$$ = $2;
	}
;

N_SIGN : /* epsilon */
	{
		$$ = 0;
		printRule("N_SIGN", "epsilon");
	}
| T_PLUS
	{
		$$ = 1;
		printRule("N_SIGN", "T_PLUS");
	}
| T_MINUS
	{
		$$ = -1;
		printRule("N_SIGN", "T_MINUS");
	}
;

N_ADDOP : T_PLUS
	{
		printRule("N_ADDOP", "T_PLUS");
		$$.type = INT;
		$$.op = ADD;
	}
| T_MINUS
	{
		printRule("N_ADDOP", "T_MINUS");
		$$.type = INT;
		$$.op = SUB;
	}
| T_OR
	{
		printRule("N_ADDOP", "T_OR");
		$$.type = BOOL;
		$$.op = OR;
	}
;

N_MULTOP : T_MULT
	{
		printRule("N_MULTOP", "T_MULT");
		$$.type = INT;
		$$.op = MULT;
	}
| T_DIV
	{
		printRule("N_MULTOP", "T_DIV");
		$$.type = INT;
		$$.op = DIV;
	}
| T_AND
	{
		printRule("N_MULTOP", "T_AND");
		$$.type = BOOL;
		$$.op = AND;
	}
;

N_RELOP : T_LT
	{
		printRule("N_RELOP", "T_LT");
		$$.type = BOOL;
		$$.op = LT;
	}
| T_LE
	{
		printRule("N_RELOP", "T_LE");
		$$.type = BOOL;
		$$.op = LE;
	}
| T_NE
	{
		printRule("N_RELOP", "T_NE");
		$$.type = BOOL;
		$$.op = NE;
	}
| T_EQ
	{
		printRule("N_RELOP", "T_EQ");
		$$.type = BOOL;
		$$.op = EQ;
	}
| T_GT
	{
		printRule("N_RELOP", "T_GT");
		$$.type = BOOL;
		$$.op = GT;
	}
| T_GE
	{
		printRule("N_RELOP", "T_GE");
		$$.type = BOOL;
		$$.op = GE;
	}
;

N_VARIABLE : N_ENTIREVAR
	{
		$$ = $1;
		printRule("N_VARIABLE", "N_ENTIREVAR");
	}
| N_IDXVAR
	{
		$$ = $1;
		printRule("N_VARIABLE", "N_IDXVAR");
	}
;

N_IDXVAR : N_ARRAYVAR T_LBRACK N_EXPR T_RBRACK
	{
		printRule("N_IDXVAR", "N_ARRAYVAR T_LBRACK N_EXPR T_RBRACK");

		if($3.type != INT) {
			yyerror("Index expression must be of type integer");
		}
		$$.type.type = $1.type.extended;

		std::vector<Value*> indices;
		indices.push_back(CreateIntConst(0));
		indices.push_back($3.value);

		BasicBlock* bb = Builder.GetInsertBlock();
		$$.value = GetElementPtrInst::Create($1.value, indices, "index", bb);
	}
;

N_ARRAYVAR : N_ENTIREVAR
	{
		printRule("N_ARRAYVAR", "N_ENTIREVAR");

		if($1.type.type != ARRAY) {
			yyerror("Indexed variable must be of array type");
		}
		$$ = $1;
	}
;

N_ENTIREVAR : N_VARIDENT
	{
		$$ = $1;
		printRule("N_ENTIREVAR", "N_VARIDENT");
	}
;

N_VARIDENT : T_IDENT
	{
		printRule("N_VARIDENT", "T_IDENT");
		$$ = scope.get(std::string($1));
		free($1);
		if($$.type.type == UNDEFINED) {
			yyerror("Undefined identifier");
		}
		if($$.type.type == PROCEDURE) {
			yyerror("Procedure/variable mismatch");
		}
	}
;

N_CONST : N_INTCONST
	{
		$$.type = INT;
		$$.value = CreateIntConst($1);
		printRule("N_CONST", "N_INTCONST");
	}
| T_CHARCONST
	{
		$$.type = CHAR;

		char c = $1[1];
		if (c == '\\') {
			c = '\n';
		}

		$$.value = CreateCharConst(c);
		printRule("N_CONST", "T_CHARCONST");
	}
| N_BOOLCONST
	{
		$$.type = BOOL;
		$$.value = CreateBoolConst($1);
		printRule("N_CONST", "N_BOOLCONST");
	}
;

N_INTCONST : N_SIGN T_INTCONST
	{
		if($1 != 0) {
			$$ = $1 * $2;
		}
		else {
			$$ = $2;
		}
		printRule("N_INTCONST", "N_SIGN T_INTCONST");
	}
;

N_BOOLCONST : T_TRUE
	{
		$$ = 1;
		printRule("N_BOOLCONST", "T_TRUE");
	}
| T_FALSE
	{
		$$ = 0;
		printRule("N_BOOLCONST", "T_FALSE");
	}
;

%%

#include "lex.yy.c"
extern FILE* yyin;

void printToken(const char* token, const char* lexeme) {
#ifdef PRINT_RULES
	printf("TOKEN: %s\tLEXEME: %s\n", token, lexeme);
#endif
}

void printRule(const char* lhs, const char* rhs) {
#ifdef PRINT_RULES
	printf("%s -> %s\n", lhs, rhs);
#endif
}

Function* get_current_function(){
    if (current_proc.size() > 0) {
	return current_proc.top();
    } else {
	return main_func;
    }
}

int yyerror(const char* s) {
	printf("Line %d: %s\n", yylineno, s);
	exit(1);
}

int main(int argc, char** argv) {
	if (argc < 2) {
		printf("You must specify a file in the command line!\n");
		exit(1);
	}

	LLVMContext &Context = getGlobalContext();
	TheModule = new Module("MIPL program", Context);

	printf_func = PrintfPrototype(Context, TheModule);
	scanf_func = ScanfPrototype(Context, TheModule);
	int_format = CreateFormat(Context, TheModule, "%d");
	char_format = CreateFormat(Context, TheModule, "%c");

	yyin = fopen(argv[1], "r");

	do {
		yyparse();
	} while (!feof(yyin));

	return 0;
}
