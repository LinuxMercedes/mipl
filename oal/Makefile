CC=g++

CFLAGS=-g

.PHONY: all oal_interpreter clean test cleantest submit

all: oal_interpreter

lex.yy.c: oal.l
	flex oal.l

oal.tab.c: lex.yy.c oal.y
	bison oal.y

oal_interpreter: oal.tab.c
	${CC} ${CFLAGS} oal.tab.c -o $@

clean: cleantest
	-rm oal.tab.c
	-rm lex.yy.c
	-rm oal_interpreter
