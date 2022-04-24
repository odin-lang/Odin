ODIN=../../odin
ODINFLAGS=
OUT_FILE=test_binary.bin

OS=$(shell uname)

ifeq ($(OS), OpenBSD)
    ODINFLAGS:=$(ODINFLAGS) -extra-linker-flags:-L/usr/local/lib
endif

all: botan_test

botan_test:
	$(ODIN) run botan -out=$(OUT_FILE) -o:speed -no-bounds-check $(ODINFLAGS)
