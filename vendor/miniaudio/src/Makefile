all:
	mkdir -p ../lib
	$(CC) -c -O2 -Os -fPIC miniaudio.c
	$(AR) rcs ../lib/miniaudio.a miniaudio.o
	#$(CC) -fPIC -shared -Wl,-soname=miniaudio.so -o ../lib/miniaudio.so miniaudio.o
	rm *.o
