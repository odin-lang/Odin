#!/usr/bin/env sh
set -e

cc=${CC:-cc}
ar=${AR:-ar}
ODIN_ROOT=${ODIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}

cd "$ODIN_ROOT/vendor/miniaudio/src" || exit 1

if [ "$(uname -s)" = 'Darwin' ]; then
	# One universal (x86_64 + arm64) library, which is also shipped as lib/darwin/miniaudio.a
	mkdir -p ../lib/darwin
	$cc -arch x86_64 -c -O2 -Os -fPIC miniaudio.c -o miniaudio-x86_64.o -mmacosx-version-min=10.12
	$cc -arch arm64  -c -O2 -Os -fPIC miniaudio.c -o miniaudio-arm64.o  -mmacosx-version-min=10.12
	lipo -create miniaudio-x86_64.o miniaudio-arm64.o -output ../lib/darwin/miniaudio.a
else
	mkdir -p ../lib
	$cc -c -O2 -Os -fPIC miniaudio.c
	$ar rcs ../lib/miniaudio.a miniaudio.o
	#$cc -fPIC -shared -Wl,-soname=miniaudio.so -o ../lib/miniaudio.so miniaudio.o
fi
rm *.o
