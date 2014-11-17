TESTDIR=tests

TESTFILES=$(wildcard $(TESTDIR)/*.txt)
OUTFILES=$(TESTFILES:.txt=.result)

CC=g++

CFLAGS=-g

.PHONY: all parser clean test cleantest submit

all: parser

lex.yy.c: mipl.l
	flex mipl.l

mipl.tab.c: lex.yy.c mipl.y
	bison mipl.y

parser: mipl.tab.c
	${CC} ${CFLAGS} mipl.tab.c -o parser

clean: cleantest
	-rm mipl.tab.c
	-rm lex.yy.c
	-rm parser

test: cleantest parser $(OUTFILES)
	@echo "[+] All tests passed!"

%.result : %.txt %.oal
	-@./parser $< > $@
	diff -b --side-by-side $(word 2, $^) $@

cleantest:
	-rm $(TESTDIR)/*.result

submit:
	cp mipl.l jarusn.l
	cp mipl.y jarusn.y
