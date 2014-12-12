TESTDIR=tests

TESTFILES=$(wildcard $(TESTDIR)/*.txt)
OUTFILES=$(TESTFILES:.txt=.result)

CC=clang++

CFLAGS=-g -Wno-switch `llvm-config-3.4 --cxxflags --libs core`

LDFLAGS=`llvm-config-3.4 --ldflags --libs core`

.PHONY: all clean submit

all: IRGen

lex.yy.c: mipl.l
	flex mipl.l

mipl.tab.c: lex.yy.c mipl.y
	bison mipl.y

IRGen: mipl.tab.c llvm-helpers.h varinfo.h scope.h
	${CC} ${CFLAGS} mipl.tab.c ${LDFLAGS} -o $@

clean: cleantest
	-rm mipl.tab.c
	-rm lex.yy.c
	-rm IRGen
	${MAKE} -C clean

submit:
	cp mipl.l wiselyjarusn.l
	cp mipl.y wiselyjarusn.y
