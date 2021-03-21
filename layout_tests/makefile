


all: FORCE
	odin run layout2.odin
	odin run layout2.odin -opt:2
	odin run layout3.odin
	odin run layout3.odin -opt:2

	odin run layout.odin  -opt:2
	odin run layout.odin 

	odin build test.odin -build-mode:shared
	clang test.c ./test.so -o test
	./test
	odin build test.odin  -build-mode:shared -opt:2
	clang test.c ./test.so -o test
	./test

	rm layout layout2 layout3 test *.so
	
FORCE:;
