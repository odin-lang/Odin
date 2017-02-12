#!/bin/bash

release_mode=0

warnings_to_disable="-Wno-attributes -Wno-implicit-function-declaration -Wno-incompatible-pointer-types -Wno-switch -Wno-pointer-sign -Wno-tautological-constant-out-of-range-compare -Wno-autological-compare"
libraries="-pthread -ldl -lm"
other_args="-x c"
compiler="gcc"

if [ "$release_mode" -eq "0" ]; then
	other_args="${other_args} -g -fno-inline-functions"
fi
if [[ "$(uname)" == "Darwin" ]]; then

	# Set compiler to clang on MacOS
	# MacOS provides a symlink to clang called gcc, but it's nice to be explicit here.
	compiler="clang"

	other_args="${other_args} -liconv"
fi

${compiler} src/main.c ${warnings_to_disable} ${libraries} ${other_args} -o odin
