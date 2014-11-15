.PHONY : clean

all: parser

lex.yy.c: wiselym.l
	flex $<

wiselym.tab.c: wiselym.y
	bison -v -o $@ $<

parser: wiselym.tab.c lex.yy.c symbol_table_stack.h string_list.h
	g++ -g $< -o $@

clean:
	rm -rf actual/ diffs/ *.yy.c *.tab.c *.output
