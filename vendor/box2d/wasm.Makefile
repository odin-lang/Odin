# Custom Makefile to build box2d for Odin's WASM targets.
# I tried to make a cmake toolchain file for this / use cmake but this is far easier.
# NOTE: We are pretending to be emscripten to box2d so it takes WASM code paths, but we don't actually use emscripten.

# CC = $(shell brew --prefix llvm)/bin/clang
# LD = $(shell brew --prefix llvm)/bin/wasm-ld

VERSION   = 3.0.0
SRCS      = $(wildcard box2d-$(VERSION)/src/*.c)
OBJS_SIMD = $(SRCS:.c=_simd.o)
OBJS      = $(SRCS:.c=.o)
SYSROOT   = $(shell odin root)/vendor/libc
CFLAGS    = -Ibox2d-$(VERSION)/include -Ibox2d-$(VERSION)/Extern/simde --target=wasm32 -D__EMSCRIPTEN__ -DNDEBUG -O3 --sysroot=$(SYSROOT)

all: lib/box2d_wasm.o lib/box2d_wasm_simd.o clean

%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@

%_simd.o: %.c
	$(CC) -c $(CFLAGS) -msimd128 $< -o $@

lib/box2d_wasm.o: $(OBJS)
	$(LD) -r -o lib/box2d_wasm.o $(OBJS)

lib/box2d_wasm_simd.o: $(OBJS_SIMD)
	$(LD) -r -o lib/box2d_wasm_simd.o $(OBJS_SIMD)

clean:
	rm -rf $(OBJS) $(OBJS_SIMD)

.PHONY: clean
