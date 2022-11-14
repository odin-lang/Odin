all:
	mkdir -p ../lib
	$(CC) -c -O2 -Os -fPIC lib.c
	$(AR) rcs ../lib/miniz.a lib.o
	#$(CC) -fPIC -shared -Wl,-soname=miniz.so -o ../lib/miniz.so lib.o
	rm *.o
