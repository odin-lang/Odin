DISABLED_WARNINGS=-Wno-switch -Wno-pointer-sign -Wno-tautological-constant-out-of-range-compare -Wno-tautological-compare -Wno-macro-redefined
LDFLAGS=-pthread -ldl -lm -lstdc++
CFLAGS=-std=c++11
CC=clang

OS=$(shell uname)

ifeq ($(OS), Darwin)
	LDFLAGS:=$(LDFLAGS) -liconv
endif

all: debug demo

demo:
	./odin run examples/demo/demo.odin

debug:
	$(CC) src/main.cpp $(DISABLED_WARNINGS) $(CFLAGS) -g $(LDFLAGS) -o odin

release:
	$(CC) src/main.cpp $(DISABLED_WARNINGS) $(CFLAGS) -O3 -march=native $(LDFLAGS) -o odin



