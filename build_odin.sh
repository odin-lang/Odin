#!/usr/bin/env bash
set -eu

: ${CXX=clang++}
: ${CPPFLAGS=}
: ${CXXFLAGS=}
: ${LDFLAGS=}
: ${ODIN_VERSION=dev-$(date +"%Y-%m")}
: ${GIT_SHA=}

CPPFLAGS="$CPPFLAGS -DODIN_VERSION_RAW=\"$ODIN_VERSION\""
CXXFLAGS="$CXXFLAGS -std=c++14"
LDFLAGS="$LDFLAGS -pthread -lm -lstdc++"

if [ -d ".git" ]; then
	GIT_SHA=$(git rev-parse --short HEAD || :)
	if [ "$GIT_SHA" ]; then
		CPPFLAGS="$CPPFLAGS -DGIT_SHA=\"$GIT_SHA\""
	fi
fi

DISABLED_WARNINGS="-Wno-switch -Wno-macro-redefined -Wno-unused-value"
OS=$(uname)

panic() {
	printf "%s\n" "$1"
	exit 1
}

version() { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

config_darwin() {
	local ARCH=$(uname -m)
	: ${LLVM_CONFIG=llvm-config}

	# allow for arm only llvm's with version 13
	if [ "${ARCH}" == "arm64" ]; then
		MIN_LLVM_VERSION=("13.0.0")
	else
		# allow for x86 / amd64 all llvm versions beginning from 11
		MIN_LLVM_VERSION=("11.1.0")
	fi

	if [ $(version $($LLVM_CONFIG --version)) -lt $(version $MIN_LLVM_VERSION) ]; then
		if [ "${ARCH}" == "arm64" ]; then
			panic "Requirement: llvm-config must be base version 13 for arm64"
		else
			panic "Requirement: llvm-config must be base version greater than 11 for amd64/x86"
		fi
	fi

	MAX_LLVM_VERSION=("14.999.999")
	if [ $(version $($LLVM_CONFIG --version)) -gt $(version $MAX_LLVM_VERSION) ]; then
		echo "Tried to use " $(which $LLVM_CONFIG) "version" $($LLVM_CONFIG --version)
		panic "Requirement: llvm-config must be base version smaller than 15"
	fi

	LDFLAGS="$LDFLAGS -liconv -ldl -framework System"
	CXXFLAGS="$CXXFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS -lLLVM-C"
}

config_freebsd() {
	: ${LLVM_CONFIG=}

	if [ ! "$LLVM_CONFIG" ]; then
		if [ -x "$(command -v llvm-config11)" ]; then
			LLVM_CONFIG=llvm-config11
		elif [ -x "$(command -v llvm-config12)" ]; then
			LLVM_CONFIG=llvm-config12
		elif [ -x "$(command -v llvm-config13)" ]; then
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
		if [ -x "$(command -v llvm-config)" ]; then
			LLVM_CONFIG=llvm-config
		elif [ -x "$(command -v llvm-config-11)" ]; then
			LLVM_CONFIG=llvm-config-11
		elif [ -x "$(command -v llvm-config-11-64)" ]; then
			LLVM_CONFIG=llvm-config-11-64
		elif [ -x "$(command -v llvm-config-14)" ]; then
			LLVM_CONFIG=llvm-config-14
		else
			panic "Unable to find LLVM-config"
		fi
	fi

	MIN_LLVM_VERSION=("11.0.0")
	if [ $(version $($LLVM_CONFIG --version)) -lt $(version $MIN_LLVM_VERSION) ]; then
		echo "Tried to use " $(which $LLVM_CONFIG) "version" $($LLVM_CONFIG --version)
		panic "Requirement: llvm-config must be base version greater than 11"
	fi

	MAX_LLVM_VERSION=("14.999.999")
	if [ $(version $($LLVM_CONFIG --version)) -gt $(version $MAX_LLVM_VERSION) ]; then
		echo "Tried to use " $(which $LLVM_CONFIG) "version" $($LLVM_CONFIG --version)
		panic "Requirement: llvm-config must be base version smaller than 15"
	fi

	LDFLAGS="$LDFLAGS -ldl"
	CXXFLAGS="$CXXFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS $($LLVM_CONFIG --libs core native --system-libs --libfiles) -Wl,-rpath=\$ORIGIN"

	# Creates a copy of the llvm library in the build dir, this is meant to support compiler explorer.
	# The annoyance is that this copy can be cluttering the development folder. TODO: split staging folders
	# for development and compiler explorer builds
	cp $(readlink -f $($LLVM_CONFIG --libfiles)) ./
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
		;;
	esac

	set -x
	$CXX src/main.cpp src/libtommath.cpp $DISABLED_WARNINGS $CPPFLAGS $CXXFLAGS $EXTRAFLAGS $LDFLAGS -o odin
	set +x
}

run_demo() {
	./odin run examples/demo/demo.odin -file
}

have_which() {
	if ! command -v which > /dev/null 2>&1 ; then
		panic "Could not find \`which\`"
	fi
}

have_which

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
	;;
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
