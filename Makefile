
TESTDIR=tests

TESTFILES=$(wildcard $(TESTDIR)/*.txt)
OUTFILES=$(TESTFILES:.txt=.result)

.PHONY: all lexer parser clean test cleantest 

all: lexer

lex.yy.c: mipl.l
	flex mipl.l

mfpl.tab.c: lex.yy.c mipl.y
	bison mipl.y

lexer: lex.yy.c
	gcc lex.yy.c -std=c99 -o lexer

parser: mfpl.tab.c
	g++ -g mfpl.tab.c -o parser

clean: cleantest
	-rm mipl.tab.c
	-rm lex.yy.c
	-rm lexer

test: cleantest lexer $(OUTFILES) 
	@echo "[+] All tests passed!"

%.result : %.txt %.txt.out
	-@./lexer < $< > $@
	diff -b $(word 2, $^) $@

cleantest:
	-rm $(TESTDIR)/*.result

