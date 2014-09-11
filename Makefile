
TESTDIR=tests

TESTFILES=$(wildcard $(TESTDIR)/*.txt)
OUTFILES=$(TESTFILES:.txt=.result)

.PHONY: all parser clean test cleantest 

all: parser

lex.yy.c: mipl.l
	flex mipl.l

mipl.tab.c: lex.yy.c mipl.y
	bison mipl.y

parser: mipl.tab.c
	g++ -g mipl.tab.c -o parser

clean: cleantest
	-rm mipl.tab.c
	-rm lex.yy.c
	-rm parser

test: cleantest parser $(OUTFILES) 
	@echo "[+] All tests passed!"

%.result : %.txt %.txt.out
	-@./parser < $< > $@
	diff -b $(word 2, $^) $@

cleantest:
	-rm $(TESTDIR)/*.result

