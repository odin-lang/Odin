#!/bin/sh

WARNINGS_DISABLE="-Wno-attributes -Wno-implicit-function-declaration -Wno-incompatible-pointer-types"
LIBRARIES="-pthread -ldl -lm"

gcc src/main.c ${WARNINGS_DISABLE} ${LIBRARIES} -o odin
