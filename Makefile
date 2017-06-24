all:
	lex FirstLex.l
	gcc lex.yy.c -lfl -o ba
clean:
	rm lex.yy.c
	rm ba
