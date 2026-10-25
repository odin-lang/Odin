#!/bin/sh
set -e

cc=${CC:-cc}
ar=${AR:-ar}
ODIN_ROOT=${ODIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}

cd "$ODIN_ROOT/vendor/kb_text_shape/src" || exit 1

if [ "$(uname -s)" = 'Darwin' ]; then
	# One universal (x86_64 + arm64) library, which is also shipped as lib/darwin/kb_text_shape.a
	mkdir -p ../lib/darwin
	$cc -arch x86_64 -c -O2 -fPIC kb_text_shape.c -o kb_text_shape-x86_64.o -mmacosx-version-min=10.12
	$cc -arch arm64  -c -O2 -fPIC kb_text_shape.c -o kb_text_shape-arm64.o  -mmacosx-version-min=10.12
	lipo -create kb_text_shape-x86_64.o kb_text_shape-arm64.o -output ../lib/darwin/kb_text_shape.a
else
	mkdir -p ../lib
	$cc -O2 -fPIC -c kb_text_shape.c
	$ar -rcs ../lib/kb_text_shape.a kb_text_shape.o
fi
rm ./*.o
