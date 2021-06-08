NELUA=nelua
NFLAGS=--no-color -Pnogc -Pnochecks -Pnocstaticassert
CFLAGS=-Os
CC=gcc

all: forkmon.so

test:
	LD_PRELOAD=./forkmon.so FORKMON_FILTER="%.lua$$" lua tests/example.lua

forkmon.so: forkmon.c
	$(CC) forkmon.c -o forkmon.so $(CFLAGS) -fPIC -shared -ldl
	strip forkmon.so

forkmon.c: forkmon.nelua sys.nelua
	nelua $(NFLAGS) -o forkmon.c forkmon.nelua

prebuilt: forkmon.so
	cp forkmon.so bin/linux64/

clean:
	rm -f forkmon.so

clean-all:
	rm -f forkmon.so
	rm -f forkmon.c
	rm -f bin/linux64/forkmon.so
