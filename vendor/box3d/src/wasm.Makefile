# Build the vendored Box3D C sources for Odin's WASM targets.

ODIN_ROOT  ?= ../../..
SYSROOT    = $(ODIN_ROOT)/vendor/libc-shim
SRCS       = $(wildcard src/*.c)
OBJS       = $(patsubst src/%.c,build/wasm/%.o,$(SRCS))
COMPAT_OBJ = build/wasm/wasm_compat.o
CFLAGS     = -O3 -std=gnu17 --target=wasm32 --sysroot=$(SYSROOT) -Iinclude \
	-include wasm_compat.h -DBOX3D_DISABLE_SIMD -DNDEBUG

all: ../lib/box3d_wasm.o

build/wasm/%.o: src/%.c
	@mkdir -p build/wasm
	$(CC) -c $(CFLAGS) $< -o $@

$(COMPAT_OBJ): wasm_compat.c
	@mkdir -p build/wasm
	$(CC) -c $(CFLAGS) $< -o $@

../lib/box3d_wasm.o: $(OBJS) $(COMPAT_OBJ)
	$(LD) -r -o $@ $(OBJS) $(COMPAT_OBJ)

clean:
	rm -rf build/wasm

.PHONY: all clean
