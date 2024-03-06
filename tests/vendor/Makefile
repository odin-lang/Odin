ODIN=../../odin
ODINFLAGS=

OS=$(shell uname)

ifeq ($(OS), OpenBSD)
    ODINFLAGS:=$(ODINFLAGS) -extra-linker-flags:-L/usr/local/lib
endif

all:
