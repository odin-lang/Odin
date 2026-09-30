#!/usr/bin/env sh
set -e

cc=${CC:-cc}
ar=${AR:-ar}
ODIN_ROOT=${ODIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}

cd "$ODIN_ROOT/vendor/cgltf/src" || exit 1

build_wasm() {
	mkdir -p ../lib
	$cc -c -Os --target=wasm32 --sysroot="$ODIN_ROOT/vendor/libc-shim" cgltf.c -o ../lib/cgltf_wasm.o
}

build_unix() {
	mkdir -p ../lib
	$cc -c -O2 -Os -fPIC cgltf.c 	
	$ar rcs ../lib/cgltf.a        cgltf.o
	rm ./*.o
}

build_darwin() {
	mkdir -p ../lib/darwin
	$cc -arch x86_64 -c -O2 -Os -fPIC cgltf.c -o cgltf-x86_64.o -mmacosx-version-min=10.12
	$cc -arch arm64  -c -O2 -Os -fPIC cgltf.c -o cgltf-arm64.o -mmacosx-version-min=10.12
	lipo -create cgltf-x86_64.o cgltf-arm64.o -output ../lib/darwin/cgltf.a
	rm ./*.o
}

case $1 in
wasm)
	build_wasm ;;
unix)
	build_unix ;;
darwin)
	build_darwin ;;
*)
	if [ "$(uname -s)" = 'Darwin' ]; then
		build_darwin
	else
		build_unix
	fi ;;
esac
