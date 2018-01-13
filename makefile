objfiles = mparser.tab.o lex.yy.o hash.o symtable.o ast.o quads.o

miragecompiler.out: $(objfiles)
	gcc -o miragecompiler.out $(objfiles)

genassembly.out: assembly.cpp
	g++ assembly.cpp -o genassembly.out

mparser.tab.c: mparser.y
	bison -d -v --report=itemset mparser.y

lex.yy.c: mflexer.l
	flex mflexer.l

mparser.tab.o: mparser.tab.c
	gcc -c mparser.tab.c

lex.yy.o: lex.yy.c
	gcc -c lex.yy.c

symtable.o: symtable.c symtable.h
	gcc -c symtable.c

ast.o: ast.c ast.h
	gcc -c ast.c

hash.o: hash.c hash.h
	gcc -c hash.c

quads.o: quads.c quads.h
	gcc -c quads.c

clean:
	rm a.* mparser.tab.c mparser.tab.h lex.yy.c $(objfiles)

testassembly:
	./genassembly.out < simplequads.txt > simpleassembly.s && cat simpleassembly.s && gcc -m32 simpleassembly.s

