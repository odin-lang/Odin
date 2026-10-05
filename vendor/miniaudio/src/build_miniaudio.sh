#!/usr/bin/env sh
set -e

cc=${CC:-cc}
ar=${AR:-ar}
ODIN_ROOT=${ODIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}

cd "$ODIN_ROOT/vendor/miniaudio/src" || exit 1

mkdir -p ../lib

# `build_miniaudio.sh wasm` builds the object used by wasm32 targets, against
# vendor:libc-shim. There is no audio device or threading there; see common.odin.
if [ "$1" = "wasm" ]; then
	$cc -c -Os --target=wasm32 --sysroot="$ODIN_ROOT"/vendor/libc-shim \
		-DMA_NO_DEVICE_IO -DMA_NO_THREADING -DMA_NO_RUNTIME_LINKING \
		miniaudio.c -o ../lib/miniaudio_wasm.o
	exit 0
fi

$cc -c -O2 -Os -fPIC miniaudio.c
$ar rcs ../lib/miniaudio.a miniaudio.o
#$cc -fPIC -shared -Wl,-soname=miniaudio.so -o ../lib/miniaudio.so miniaudio.o
rm *.o
