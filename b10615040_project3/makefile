# yayayay
all: compiler

compiler: lex.yy.cpp y.tab.cpp SymbolTable.hpp CodeGenerator.hpp
	g++ y.tab.cpp SymbolTable.hpp CodeGenerator.hpp -o compiler -ll -ly -std=c++11

lex.yy.cpp: my_scanner.l
	lex -o lex.yy.cpp my_scanner.l

y.tab.cpp: my_parser.y
	yacc -d my_parser.y -o y.tab.cpp

clean:
	rm my_parser lex.yy.* y.tab.*

run: compiler
	./compiler $(file).scala
	./javaa/javaa $(file).jasm
	java $(file)
