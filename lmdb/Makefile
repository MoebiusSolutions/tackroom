compile:	helper
	ponyc -p ./

all:	compile

debug:	helper
	ponyc --debug -p ./

helper:
	gcc -Wall -c helper.c -o helper.o
	ar rv libhelper.a helper.o

clean:
	rm -f libhelper.a helper.o

