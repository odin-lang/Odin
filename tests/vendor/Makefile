ODIN=../../odin
ODINFLAGS=

OS=$(shell uname)

ifeq ($(OS), OpenBSD)
    ODINFLAGS:=$(ODINFLAGS) -extra-linker-flags:-L/usr/local/lib
endif

all: botan_test

botan_test:
	$(ODIN) run botan -o:speed -no-bounds-check $(ODINFLAGS) -out=vendor_botan
