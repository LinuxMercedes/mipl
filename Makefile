TESTDIR=tests

TESTFILES=$(wildcard $(TESTDIR)/*.txt)
OUTFILES=$(TESTFILES:.txt=.result)

CC=clang++

CFLAGS=-g -Wno-switch `llvm-config-3.4 --cxxflags --libs core`

LDFLAGS=`llvm-config-3.4 --ldflags --libs core`

.PHONY: all clean test cleantest submit

all: parser

lex.yy.c: mipl.l
	flex mipl.l

mipl.tab.c: lex.yy.c mipl.y
	bison mipl.y

parser: mipl.tab.c llvm-helpers.h varinfo.h scope.h
	${CC} ${CFLAGS} mipl.tab.c ${LDFLAGS} -o parser

clean: cleantest
	-rm mipl.tab.c
	-rm lex.yy.c
	-rm parser
	${MAKE} -C clean

test: cleantest parser $(OUTFILES)
	@echo "[+] All tests passed!"

%.result : %.txt %.oal FORCE
	-@./parser $< > $@
	diff -b -w --side-by-side $(word 2, $^) $@

FORCE:

cleantest:
	-rm $(TESTDIR)/*.result

submit:
	cp mipl.l jarusn.l
	cp mipl.y jarusn.y
