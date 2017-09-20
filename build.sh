#!/bin/bash

release_mode=0

warnings_to_disable="-std=c++11 -g -Wno-switch -Wno-pointer-sign -Wno-tautological-constant-out-of-range-compare -Wno-tautological-compare -Wno-macro-redefined -Wno-writable-strings"
libraries="-pthread -ldl -lm -lstdc++"
other_args=""
compiler="clang"

if [ "$release_mode" -eq "0" ]; then
	other_args="${other_args} -g -fno-inline-functions"
fi
if [[ "$(uname)" == "Darwin" ]]; then

	# Set compiler to clang on MacOS
	# MacOS provides a symlink to clang called gcc, but it's nice to be explicit here.
	compiler="clang"

	other_args="${other_args} -liconv"
fi

${compiler} src/main.cpp ${warnings_to_disable} ${libraries} ${other_args} -o odin && ./odin run examples/demo.odin
