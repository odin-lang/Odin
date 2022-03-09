#!/bin/bash
set -eu

GIT_SHA=$(git rev-parse --short HEAD)
DISABLED_WARNINGS="-Wno-switch -Wno-macro-redefined -Wno-unused-value"
LDFLAGS="-pthread -lm -lstdc++"
CFLAGS="-std=c++14 -DGIT_SHA=\"$GIT_SHA\""
CFLAGS="$CFLAGS -DODIN_VERSION_RAW=\"dev-$(date +"%Y-%m")\""
CC=clang
OS=$(uname)

panic() {
	printf "%s\n" "$1"
	exit 1
}

config_darwin() {
	ARCH=$(uname -m)
	LLVM_CONFIG=llvm-config

	# allow for arm only llvm's with version 13
	if [ ARCH == arm64 ]; then
		LLVM_VERSIONS="13.%.%"
	else
		# allow for x86 / amd64 all llvm versions begining from 11
		LLVM_VERSIONS="13.%.%" "12.0.1" "11.1.0"
	fi

    if [ $($LLVM_CONFIG --version | grep -E $(LLVM_VERSION_PATTERN)) == 0 ]; then
		if [ ARCH == arm64 ]; then
			panic "Requirement: llvm-config must be base version 13 for arm64"
		else
			panic "Requirement: llvm-config must be base version greater than 11 for amd64/x86"
		fi
	fi

	LDFLAGS="$LDFLAGS -liconv -ldl"
	CFLAGS="$CFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS -lLLVM-C"
}

config_openbsd() {
	LLVM_CONFIG=/usr/local/bin/llvm-config

	LDFLAGS="$LDFLAGS -liconv"
	CFLAGS="$CFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS $($LLVM_CONFIG --libs core native --system-libs)"
}

config_linux() {
	LLVM_CONFIG=llvm-config

	LDFLAGS="$LDFLAGS -ldl"
	CFLAGS="$CFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS $($LLVM_CONFIG --libs core native --system-libs)"
}

build_odin() {
	set -x
	$CC src/main.cpp src/libtommath.cpp $DISABLED_WARNINGS $CFLAGS $EXTRAFLAGS $LDFLAGS -o odin
	set +x
}

run_demo() {
	./odin run examples/demo/demo.odin
}

case $OS in
Linux)
	config_linux
	;;
Darwin)
	config_darwin
	;;
OpenBSD)
	config_openbsd
	;;
esac

if [[ $# -eq 0 ]]; then
	EXTRAFLAGS="-g"

	build_odin
	run_demo

	exit 0
fi

if [[ $# -eq 1 ]]; then
	case $1 in
	report)
		EXTRAFLAGS="-g"
		build_odin
		./odin report
		exit 0
		;;
	debug)
		EXTRAFLAGS="-g"
		;;
	release)
		EXTRAFLAGS="-O3"
		;;
	release_native)
		EXTRAFLAGS="-O3 -march=native"
		;;
	nightly)
		EXTRAFLAGS="-DNIGHTLY -O3"
		;;
	*)
		panic "Unsupported build option!"
		;;
	esac

	build_odin
	run_demo

	exit 0
fi
