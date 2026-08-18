#!/usr/bin/env sh
set -e

cc=${CC:-cc}
ar=${AR:-ar}
ODIN_ROOT=${ODIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}

cd "$ODIN_ROOT/vendor/miniaudio/src" || exit 1

mkdir -p ../lib
$cc -c -O2 -Os -fPIC miniaudio.c
$ar rcs ../lib/miniaudio.a miniaudio.o
#$cc -fPIC -shared -Wl,-soname=miniaudio.so -o ../lib/miniaudio.so miniaudio.o
rm *.o
