#!/usr/bin/env sh
set -eu

: ${CPPFLAGS=}
: ${CXX=clang++}
: ${CXXFLAGS=}
: ${LDFLAGS=}
: ${LLVM_CONFIG=}

CPPFLAGS="$CPPFLAGS -DODIN_VERSION_RAW=\"dev-$(date +"%Y-%m")\""
CXXFLAGS="$CXXFLAGS -std=c++14"
DISABLED_WARNINGS="-Wno-switch -Wno-macro-redefined -Wno-unused-value"
LDFLAGS="$LDFLAGS -pthread -lm -lstdc++"
OS_ARCH="$(uname -m)"
OS_NAME="$(uname -s)"

if [ -d ".git" ] && [ -n "$(command -v git)" ]; then
	GIT_SHA=$(git show --pretty='%h' --no-patch --no-notes HEAD)
	CPPFLAGS="$CPPFLAGS -DGIT_SHA=\"$GIT_SHA\""
fi

error() {
	printf "ERROR: %s\n" "$1"
	exit 1
}

if [ -z "$LLVM_CONFIG" ]; then
	# darwin, linux, openbsd
	if   [ -n "$(command -v llvm-config-17)" ]; then LLVM_CONFIG="llvm-config-17"
	elif [ -n "$(command -v llvm-config-14)" ]; then LLVM_CONFIG="llvm-config-14"
	elif [ -n "$(command -v llvm-config-13)" ]; then LLVM_CONFIG="llvm-config-13"
	elif [ -n "$(command -v llvm-config-12)" ]; then LLVM_CONFIG="llvm-config-12"
	elif [ -n "$(command -v llvm-config-11)" ]; then LLVM_CONFIG="llvm-config-11"
	# freebsd
	elif [ -n "$(command -v llvm-config17)" ]; then  LLVM_CONFIG="llvm-config-17"
	elif [ -n "$(command -v llvm-config14)" ]; then  LLVM_CONFIG="llvm-config-14"
	elif [ -n "$(command -v llvm-config13)" ]; then  LLVM_CONFIG="llvm-config-13"
	elif [ -n "$(command -v llvm-config12)" ]; then  LLVM_CONFIG="llvm-config-12"
	elif [ -n "$(command -v llvm-config11)" ]; then  LLVM_CONFIG="llvm-config-11"
	# fallback
	elif [ -n "$(command -v llvm-config)" ]; then LLVM_CONFIG="llvm-config"
	else
		error "No llvm-config command found. Set LLVM_CONFIG to proceed."
	fi
fi

LLVM_VERSION="$($LLVM_CONFIG --version)"
LLVM_VERSION_MAJOR="$(echo $LLVM_VERSION | awk -F. '{print $1}')"
LLVM_VERSION_MINOR="$(echo $LLVM_VERSION | awk -F. '{print $2}')"
LLVM_VERSION_PATCH="$(echo $LLVM_VERSION | awk -F. '{print $3}')"

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
	LDFLAGS="$LDFLAGS -liconv -ldl -framework System -lLLVM"
	;;
FreeBSD)
	CXXFLAGS="$CXXFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS $($LLVM_CONFIG --libs core native --system-libs)"
	;;
Linux)
	CXXFLAGS="$CXXFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS -ldl $($LLVM_CONFIG --libs core native --system-libs --libfiles)"
	# Copy libLLVM*.so into current directory for linking
	# NOTE: This is needed by the Linux release pipeline!
	cp $(readlink -f $($LLVM_CONFIG --libfiles)) ./
	LDFLAGS="$LDFLAGS -Wl,-rpath=\$ORIGIN"
	;;
OpenBSD)
	CXXFLAGS="$CXXFLAGS $($LLVM_CONFIG --cxxflags --ldflags)"
	LDFLAGS="$LDFLAGS -liconv"
	LDFLAGS="$LDFLAGS $($LLVM_CONFIG --libs core native --system-libs)"
	;;
*)
	error "Platform \"$OS_NAME\" unsupported"
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
		if [ "$OS_ARCH" == "arm64" ]; then
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
	./odin run examples/demo/demo.odin -file -- Hellope World
}

if [ $# -eq 0 ]; then
	build_odin debug
	run_demo
elif [ $# -eq 1 ]; then
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
