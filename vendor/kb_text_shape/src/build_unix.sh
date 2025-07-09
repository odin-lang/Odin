#!/bin/sh
set -e

mkdir -p "../lib"
cc -O2 -c kb_text_shape.c
ar -rcs ../lib/kb_text_shape.a kb_text_shape.o
rm *.o
