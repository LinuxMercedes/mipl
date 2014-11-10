
TESTDIR=tests

TESTFILES=$(wildcard $(TESTDIR)/*.dat)
OUTFILES=$(TESTFILES:.dat=.result)

CC=g++

CFLAGS=-g

.PHONY: all parser clean test cleantest submit

all: parser

lex.yy.c: parser.l
	flex parser.l

parser.tab.c: lex.yy.c parser.y
	bison parser.y

parser: parser.tab.c
	${CC} ${CFLAGS} parser.tab.c -o parser

clean: cleantest
	-rm parser.tab.c
	-rm lex.yy.c
	-rm parser

test: cleantest parser $(OUTFILES) 
	@echo "[+] All tests passed!"

%.result : %.dat %.out
	./parser $< --debug > $@
	#diff -b $(word 2, $^) $@

cleantest:
	-rm $(TESTDIR)/*.result

submit:
	cp parser.l jarusn.l
	cp parser.y jarusn.y

