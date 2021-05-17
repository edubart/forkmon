NELUA=nelua
NFLAGS=--no-color -Pnogc -Pnochecks -Pnocstaticassert
CFLAGS=-Os
CC=gcc

all: forkmonhook.so

test:
	LD_PRELOAD=./forkmonhook.so FORKMON_FILTER="%.lua$$" lua tests/example.lua

forkmonhook.so: forkmonhook.c
	$(CC) forkmonhook.c -o forkmonhook.so $(CFLAGS) -fPIC -shared -ldl

forkmonhook.c: forkmonhook.nelua sys.nelua
	nelua $(NFLAGS) -o forkmonhook.c forkmonhook.nelua

clean:
	rm -f forkmonhook.so
