NFLAGS=--no-color --release -Pnogc -Pnochecks
all:
	nelua $(NFLAGS) -o forkmonhook.so forkmonhook.nelua
	LD_PRELOAD=./forkmonhook.so nelua -t hello.nelua
