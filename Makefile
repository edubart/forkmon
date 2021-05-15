all:
	nelua fmonhook.nelua -o fmonhook.so -Pnochecks --no-color
	LD_PRELOAD=./fmonhook.so nelua -t hello.nelua
