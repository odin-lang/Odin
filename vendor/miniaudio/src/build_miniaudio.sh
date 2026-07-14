#!/usr/bin/env sh

cc=${CC:-cc}
ar=${AR:-ar}

mkdir -p ../lib
$cc -c -O2 -Os -fPIC miniaudio.c
$ar rcs ../lib/miniaudio.a miniaudio.o
#$cc -fPIC -shared -Wl,-soname=miniaudio.so -o ../lib/miniaudio.so miniaudio.o
rm *.o
