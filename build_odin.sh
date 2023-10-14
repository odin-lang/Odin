#!/usr/bin/env bash
set -eu

: ${CPPFLAGS=}
: ${CXX=clang++}
: ${CXXFLAGS=}
: ${LDFLAGS=}
: ${LLVM_CONFIG=llvm-config}

CPPFLAGS="$CPPFLAGS -DODIN_VERSION_RAW=\"dev-$(date +"%Y-%m")\""
CXXFLAGS="$CXXFLAGS -std=c++14"
DISABLED_WARNINGS="-Wno-switch -Wno-macro-redefined -Wno-unused-value"
LDFLAGS="$LDFLAGS -pthread -lm -lstdc++"

LLVM_VERSION="$($LLVM_CONFIG --version)"
LLVM_VERSION_MAJOR="$(echo $LLVM_VERSION | awk -F. '{print $1}')"
LLVM_VERSION_MINOR="$(echo $LLVM_VERSION | awk -F. '{print $2}')"
LLVM_VERSION_PATCH="$(echo $LLVM_VERSION | awk -F. '{print $3}')"
OS_ARCH="$(uname -m)"
OS_NAME="$(uname -s)"

error() {
	printf "ERROR: %s\n" "$1"
	exit 1
}

if [ -d ".git" ] && [ -n "$(command -v git)" ]; then
	GIT_SHA=($(git show --pretty='%h'--no-patch --no-notes HEAD))
	CPPFLAGS="$CPPFLAGS -DGIT_SHA=\"$GIT_SHA\""
fi

if [ $LLVM_VERSION_MAJOR -lt 11 ] ||
	([ $LLVM_VERSION_MAJOR -gt 14 ] && [ $LLVM_VERSION_MAJOR -lt 17 ]); then
	error "Invalid LLVM version $LLVM_VERSION: must be 11, 12, 13, 14 or 17"
fi

case "$OS_NAME" in
Darwin)
	if [ "$OS_ARCH" == "arm64" ]; then
		if [ $LLVM_VERSION_MAJOR -lt 13 ] || [ $LLVM_VERSION_MAJOR -gt 17 ]; then
			error "Darwin Arm64 requires LLVM 13, 14 or 17"
		fi
	fi

	CXXFLAGS="$CXXFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS -liconv -ldl -framework System"
	LDFLAGS="$LDFLAGS -lLLVM-C"
	;;
FreeBSD)
	CXXFLAGS="$CXXFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS $($LLVM_CONFIG --libs core native --system-libs)"
	;;
Linux)
	CXXFLAGS="$CXXFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS -ldl -Wl,-rpath=$($LLVM_CONFIG --libdir)"
	LDFLAGS="$LDFLAGS $($LLVM_CONFIG --libs core native --system-libs --libfiles)"
	;;
OpenBSD)
	CXXFLAGS="$CXXFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS -liconv"
	LDFLAGS="$LDFLAGS $($LLVM_CONFIG --libs core native --system-libs)"
	;;
*)
	error "Platform \"OS_NAME\" unsupported"
	;;
esac

build_odin() {
	case $1 in
	debug)
		EXTRAFLAGS="-g"
		;;
	release)
		EXTRAFLAGS="-O3"
		;;
	release-native)
		if [ "OS_ARCH" == "arm64" ]; then
			# Use preferred flag for Arm (ie arm64 / aarch64 / etc)
			EXTRAFLAGS="-O3 -mcpu=native"
		else
			# Use preferred flag for x86 / amd64
			EXTRAFLAGS="-O3 -march=native"
		fi
		;;
	nightly)
		EXTRAFLAGS="-DNIGHTLY -O3"
		;;
	*)
		error "Build mode \"$1\" unsupported!"
		;;
	esac

	set -x
	$CXX src/main.cpp src/libtommath.cpp $DISABLED_WARNINGS $CPPFLAGS $CXXFLAGS $EXTRAFLAGS $LDFLAGS -o odin
	set +x
}

run_demo() {
	./odin run examples/demo/demo.odin -file
}

if [[ $# -eq 0 ]]; then
	build_odin debug
	run_demo
elif [[ $# -eq 1 ]]; then
	case $1 in
	report)
		[ ! -f "./odin" ] && build_odin debug
		./odin report
		;;
	*)
		build_odin $1
		;;
	esac
	run_demo
else
	error "Too many arguments!"
fi
