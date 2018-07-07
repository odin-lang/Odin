DISABLED_WARNINGS=-Wno-switch -Wno-writable-strings -Wno-tautological-compare -Wno-macro-redefined #-Wno-pointer-sign -Wno-tautological-constant-out-of-range-compare  
LDFLAGS=-pthread -ldl -lm -lstdc++
CFLAGS=-std=c++11
CC=clang

OS=$(shell uname)

ifeq ($(OS), DARWIN)
	LDFLAGS=$(LDFLAGS) -liconv
endif

all: debug demo

demo:
	./odin run examples/demo

debug:
	$(CC) src/main.cpp $(DISABLED_WARNINGS) $(CFLAGS) -g $(LDFLAGS) -o odin

release:
	$(CC) src/main.cpp $(DISABLED_WARNINGS) $(CFLAGS) -O3 -march=native $(LDFLAGS) -o odin
	

	
