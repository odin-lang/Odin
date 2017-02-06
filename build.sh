#!/bin/bash

release_mode=0

warnings_to_disable="-Wno-attributes -Wno-implicit-function-declaration -Wno-incompatible-pointer-types"
libraries="-pthread -ldl -lm"
other_args=""

if [ "$release_mode" -eq "0" ]; then
	other_args="${other_args} -g -fno-inline-functions -fno-inline-small-functions"
fi

gcc src/main.c ${warnings_to_disable} ${libraries} ${other_args} -o odin
