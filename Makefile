GIT_SHA=$(shell git rev-parse --short HEAD)
DISABLED_WARNINGS=-Wno-switch -Wno-macro-redefined -Wno-unused-value
LDFLAGS=-pthread -lm -lstdc++
CFLAGS=-std=c++14 -DGIT_SHA=\"$(GIT_SHA)\"
CFLAGS:=$(CFLAGS) -DODIN_VERSION_RAW=\"dev-$(shell date +"%Y-%m")\"
CC=clang

OS=$(shell uname)

ifeq ($(OS), Darwin)

    ARCH=$(shell uname -m)
    LLVM_CONFIG=llvm-config

    # allow for arm only llvm's with version 13
    ifeq ($(ARCH), arm64)
        LLVM_VERSIONS = "13.%.%"
    else
    # allow for x86 / amd64 all llvm versions begining from 11
        LLVM_VERSIONS = "13.%.%" "12.0.1" "11.1.0"
    endif

    LLVM_VERSION_PATTERN_SEPERATOR = )|(
    LLVM_VERSION_PATTERNS_ESCAPED_DOT = $(subst .,\.,$(LLVM_VERSIONS))
    LLVM_VERSION_PATTERNS_REPLACE_PERCENT = $(subst %,.*,$(LLVM_VERSION_PATTERNS_ESCAPED_DOT))
    LLVM_VERSION_PATTERN_REMOVE_ELEMENTS = $(subst " ",$(LLVM_VERSION_PATTERN_SEPERATOR),$(LLVM_VERSION_PATTERNS_REPLACE_PERCENT))
    LLMV_VERSION_PATTERN_REMOVE_SINGLE_STR = $(subst ",,$(LLVM_VERSION_PATTERN_REMOVE_ELEMENTS))
    LLVM_VERSION_PATTERN = "^(($(LLMV_VERSION_PATTERN_REMOVE_SINGLE_STR)))"

    ifeq ($(shell $(LLVM_CONFIG) --version | grep -E $(LLVM_VERSION_PATTERN)),)
        ifeq ($(ARCH), arm64)
            $(error "Requirement: llvm-config must be base version 13 for arm64")
        else
            $(error "Requirement: llvm-config must be base version greater than 11 for amd64/x86")
        endif
    endif

    LDFLAGS:=$(LDFLAGS) -liconv -ldl
    CFLAGS:=$(CFLAGS) $(shell $(LLVM_CONFIG) --cxxflags --ldflags)
    LDFLAGS:=$(LDFLAGS) -lLLVM-C
endif
ifeq ($(OS), Linux)
    LLVM_CONFIG=llvm-config-11
    ifneq ($(shell which llvm-config-11 2>/dev/null),)
        LLVM_CONFIG=llvm-config-11
    else ifneq ($(shell which llvm-config-11-64 2>/dev/null),)
        LLVM_CONFIG=llvm-config-11-64
    else
        ifeq ($(shell $(LLVM_CONFIG) --version | grep '^11\.'),)
            $(error "Requirement: llvm-config must be version 11")
        endif
    endif

    LDFLAGS:=$(LDFLAGS) -ldl
    CFLAGS:=$(CFLAGS) $(shell $(LLVM_CONFIG) --cxxflags --ldflags)
    LDFLAGS:=$(LDFLAGS) $(shell $(LLVM_CONFIG) --libs core native --system-libs)
endif
ifeq ($(OS), OpenBSD)
    LLVM_CONFIG=/usr/local/bin/llvm-config

    LDFLAGS:=$(LDFLAGS) -liconv
    CFLAGS:=$(CFLAGS) $(shell $(LLVM_CONFIG) --cxxflags --ldflags)
    LDFLAGS:=$(LDFLAGS) $(shell $(LLVM_CONFIG) --libs core native --system-libs)
endif

all: debug demo

demo:
	./odin run examples/demo/demo.odin

report:
	./odin report

debug:
	$(CC) src/main.cpp src/libtommath.cpp $(DISABLED_WARNINGS) $(CFLAGS) -g $(LDFLAGS) -o odin

release:
	$(CC) src/main.cpp src/libtommath.cpp $(DISABLED_WARNINGS) $(CFLAGS) -O3 $(LDFLAGS) -o odin

release_native:
	$(CC) src/main.cpp src/libtommath.cpp $(DISABLED_WARNINGS) $(CFLAGS) -O3 -march=native $(LDFLAGS) -o odin

nightly:
	$(CC) src/main.cpp src/libtommath.cpp $(DISABLED_WARNINGS) $(CFLAGS) -DNIGHTLY -O3 $(LDFLAGS) -o odin
