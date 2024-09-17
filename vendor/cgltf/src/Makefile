OS=$(shell uname)

ifeq ($(OS), Darwin)
all: darwin
else
all: unix
endif

wasm:
	mkdir -p ../lib
	$(CC) -c -Os --target=wasm32 --sysroot=$(shell odin root)/vendor/libc cgltf.c -o ../lib/cgltf_wasm.o

unix:
	mkdir -p ../lib
	$(CC) -c -O2 -Os -fPIC cgltf.c 	
	$(AR) rcs ../lib/cgltf.a        cgltf.o
	rm *.o

darwin:
	mkdir -p ../lib/darwin
	$(CC) -arch x86_64 -c -O2 -Os -fPIC cgltf.c -o cgltf-x86_64.o -mmacosx-version-min=10.12
	$(CC) -arch arm64  -c -O2 -Os -fPIC cgltf.c -o cgltf-arm64.o -mmacosx-version-min=10.12
	lipo -create cgltf-x86_64.o cgltf-arm64.o -output ../lib/darwin/cgltf.a
	rm *.o
