
TESTDIR=tests

TESTFILES=$(wildcard $(TESTDIR)/*.txt)
OUTFILES=$(TESTFILES:.txt=.result)

CC=g++

CFLAGS=-g -std=c++11

.PHONY: all parser clean test cleantest 

all: parser

lex.yy.c: mipl.l
	flex mipl.l

mipl.tab.c: lex.yy.c mipl.y
	bison mipl.y

varinfo.o: varinfo.cpp varinfo.h
	${CC} ${CFLAGS} -c varinfo.cpp

scope.o: scope.cpp scope.h
	${CC} ${CFLAGS} -c scope.cpp

parser: mipl.tab.c scope.o varinfo.o
	${CC} ${CFLAGS} mipl.tab.c varinfo.o scope.o -o parser

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

