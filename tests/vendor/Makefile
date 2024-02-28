ODIN=../../odin
ODINFLAGS=
OS ?= $(shell uname -s)
OS != uname -s

BSDFLAG != echo $(OS) | grep -E 'FreeBSD|OpenBSD' > /dev/null && echo -extra-linker-flags:-L/usr/local/lib

ODINFLAGS := $(ODINFLAGS) $(BSDFLAG)
all: botan_test

botan_test:
	$(ODIN) run botan -o:speed -no-bounds-check $(ODINFLAGS) -out=vendor_botan
