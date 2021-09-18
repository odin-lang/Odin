all:
	mkdir -p ../lib
	gcc -c -O2 -Os -fPIC miniaudio.c
	ar rcs ../lib/miniaudio.a miniaudio.o
	#gcc -fPIC -shared -Wl,-soname=miniaudio.so -o ../lib/miniaudio.so miniaudio.o
	rm *.o
