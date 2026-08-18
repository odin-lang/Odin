#!/bin/sh
set -e

cc=${CC:-cc}
ar=${AR:-ar}
ODIN_ROOT=${ODIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}

cd "$ODIN_ROOT/vendor/kb_text_shape/src" || exit 1

mkdir -p "../lib"
$cc -O2 -fPIC -c kb_text_shape.c
$ar -rcs ../lib/kb_text_shape.a kb_text_shape.o
rm ./*.o
