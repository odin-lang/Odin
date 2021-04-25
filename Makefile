GIT_SHA=$(shell git rev-parse --short HEAD)
DISABLED_WARNINGS=-Wno-switch -Wno-pointer-sign -Wno-tautological-constant-out-of-range-compare -Wno-tautological-compare -Wno-macro-redefined
LDFLAGS=-pthread -ldl -lm -lstdc++
CFLAGS=-std=c++14 -DGIT_SHA=\"$(GIT_SHA)\"
CC=clang

OS=$(shell uname)

ifeq ($(OS), Darwin)
	LDFLAGS:=$(LDFLAGS) -liconv
	CFLAGS:=$(CFLAGS) $(shell llvm-config --cxxflags --ldflags)
	LDFLAGS:=$(LDFLAGS) -lLLVM-C
endif
ifeq ($(OS), Linux)
	CFLAGS:=$(CFLAGS) $(shell llvm-config-11 --cxxflags --ldflags)
	LDFLAGS:=$(LDFLAGS) $(shell llvm-config-11 --libs core native --system-libs)
endif

all: debug demo

demo:
	./odin run examples/demo/demo.odin

debug:
	$(CC) src/main.cpp $(DISABLED_WARNINGS) $(CFLAGS) -g $(LDFLAGS) -o odin

release:
	$(CC) src/main.cpp $(DISABLED_WARNINGS) $(CFLAGS) -O3 -march=native $(LDFLAGS) -o odin

nightly:
	$(CC) src/main.cpp $(DISABLED_WARNINGS) $(CFLAGS) -DNIGHTLY -O3 $(LDFLAGS) -o odin



