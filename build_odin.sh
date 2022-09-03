#!/usr/bin/env bash
set -eu

: ${CXX=clang++}
: ${CPPFLAGS=}
: ${CXXFLAGS=}
: ${LDFLAGS=}
: ${ODIN_VERSION=dev-$(date +"%Y-%m")}

CPPFLAGS="$CPPFLAGS -DODIN_VERSION_RAW=\"$ODIN_VERSION\""
CXXFLAGS="$CXXFLAGS -std=c++14"
LDFLAGS="$LDFLAGS -pthread -lm -lstdc++"

GIT_SHA=$(git rev-parse --short HEAD || :)
if [ "$GIT_SHA" ]; then CPPFLAGS="$CPPFLAGS -DGIT_SHA=\"$GIT_SHA\""; fi

DISABLED_WARNINGS="-Wno-switch -Wno-macro-redefined -Wno-unused-value"
OS=$(uname)

panic() {
	printf "%s\n" "$1"
	exit 1
}

version() { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

config_darwin() {
	ARCH=$(uname -m)
	: ${LLVM_CONFIG=llvm-config}

	# allow for arm only llvm's with version 13
	if [ ARCH == arm64 ]; then
		MIN_LLVM_VERSION=("13.0.0")
	else
		# allow for x86 / amd64 all llvm versions beginning from 11
		MIN_LLVM_VERSION=("11.1.0")
	fi

	if [ $(version $($LLVM_CONFIG --version)) -lt $(version $MIN_LLVM_VERSION) ]; then
		if [ ARCH == arm64 ]; then
			panic "Requirement: llvm-config must be base version 13 for arm64"
		else
			panic "Requirement: llvm-config must be base version greater than 11 for amd64/x86"
		fi
	fi

	LDFLAGS="$LDFLAGS -liconv -ldl"
	CXXFLAGS="$CXXFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS -lLLVM-C"
}

config_freebsd() {
	: ${LLVM_CONFIG=}

	if [ ! "$LLVM_CONFIG" ]; then
		if which llvm-config11 > /dev/null 2>&1; then
			LLVM_CONFIG=llvm-config11
		elif which llvm-config12 > /dev/null 2>&1; then
			LLVM_CONFIG=llvm-config12
		elif which llvm-config13 > /dev/null 2>&1; then
			LLVM_CONFIG=llvm-config13
		else
			panic "Unable to find LLVM-config"
		fi
	fi

	CXXFLAGS="$CXXFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS $($LLVM_CONFIG --libs core native --system-libs)"
}

config_openbsd() {
	: ${LLVM_CONFIG=/usr/local/bin/llvm-config}

	LDFLAGS="$LDFLAGS -liconv"
	CXXFLAGS="$CXXFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS $($LLVM_CONFIG --libs core native --system-libs)"
}

config_linux() {
	: ${LLVM_CONFIG=}

	if [ ! "$LLVM_CONFIG" ]; then
		if which llvm-config > /dev/null 2>&1; then
			LLVM_CONFIG=llvm-config
		elif which llvm-config-11 > /dev/null 2>&1; then
			LLVM_CONFIG=llvm-config-11
		elif which llvm-config-11-64 > /dev/null 2>&1; then
			LLVM_CONFIG=llvm-config-11-64
		else
			panic "Unable to find LLVM-config"
		fi
	fi

	MIN_LLVM_VERSION=("11.0.0")
	if [ $(version $($LLVM_CONFIG --version)) -lt $(version $MIN_LLVM_VERSION) ]; then
		echo "Tried to use " $(which $LLVM_CONFIG) "version" $($LLVM_CONFIG --version)
		panic "Requirement: llvm-config must be base version greater than 11"
	fi

	LDFLAGS="$LDFLAGS -ldl"
	CXXFLAGS="$CXXFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS $($LLVM_CONFIG --libs core native --system-libs)"
}

build_odin() {
	case $1 in
	debug)
		EXTRAFLAGS="-g"
		;;
	release)
		EXTRAFLAGS="-O3"
		;;
	release-native)
		EXTRAFLAGS="-O3 -march=native"
		;;
	nightly)
		EXTRAFLAGS="-DNIGHTLY -O3"
		;;
	*)
		panic "Build mode unsupported!"
	esac

	set -x
	$CXX src/main.cpp src/libtommath.cpp $DISABLED_WARNINGS $CPPFLAGS $CXXFLAGS $EXTRAFLAGS $LDFLAGS -o odin
	set +x
}

run_demo() {
	./odin run examples/demo/demo.odin -file
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
FreeBSD)
	config_freebsd
	;;
*)
	panic "Platform unsupported!"
esac

if [[ $# -eq 0 ]]; then
	build_odin debug
	run_demo
	exit 0
fi

if [[ $# -eq 1 ]]; then
	case $1 in
	report)
		if [[ ! -f "./odin" ]]; then
			build_odin debug
		fi

		./odin report
		exit 0
		;;
	*)
		build_odin $1
		;;
	esac

	run_demo
	exit 0
else
	panic "Too many arguments!"
fi
