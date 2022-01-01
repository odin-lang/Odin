GIT_SHA=$(shell git rev-parse --short HEAD)
DISABLED_WARNINGS=-Wno-switch -Wno-macro-redefined -Wno-unused-value
LDFLAGS=-pthread -ldl -lm -lstdc++
CFLAGS=-std=c++14 -DGIT_SHA=\"$(GIT_SHA)\"
CFLAGS:=$(CFLAGS) -DODIN_VERSION_RAW=\"dev-$(shell date +"%Y-%m")\"
CC=clang

OS=$(shell uname)

ifeq ($(OS), Darwin)
    ARCH=$(shell uname -m)

    # LLVM Version Setting  
    LLVM_VERSION_PATTERN="^11\."
    LLVM_VERSION="11"
    ifeq ($(ARCH), arm64)
	    LLVM_VERSION="13"
        LLVM_VERSION_PATTERN="^13"
    endif

    ifeq ($(LLVM_CONFIG),)
        LLVMXX_DIR=$(and $(shell which brew),$(shell brew --prefix llvm@$(LLVM_VERSION)))
        ifneq ($(LLVMXX_DIR),)
            LLVM_CONFIG="$(LLVMXX_DIR)/bin/llvm-config"
        else
            LLVM_CONFIG=llvm-config
        endif
    endif

    ifeq ($(shell $(LLVM_CONFIG) --version | grep $(LLVM_VERSION_PATTERN)),)
        $(error "Requirement: llvm-config must be version $(LLVM_VERSION)")
    endif

    LDFLAGS:=$(LDFLAGS) -liconv
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
        ifneq ($(shell llvm-config --version | grep '^11\.'),)
            LLVM_CONFIG=llvm-config
        else
            $(error "Requirement: llvm-config must be version 11")
        endif
    endif

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
