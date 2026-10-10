#!/usr/bin/env bash
set -eu

# This file runs most of the tests that the CI would run.
# It omits time-intensive optimized core library tests and Wycheproof tests.

here=$(cd "$(dirname "$0")" && pwd)
: "${ODIN:=$here/odin}"

SLIM=
for arg in "$@"; do
	case "$arg" in
		slim)
			SLIM=1
			;;
		no-clang)
			export ODIN_TESTS_NO_CLANG=1
			;;
		*)
			echo "Unrecognized argument: $arg"
			exit 1
			;;
	esac
done

if [[ -z "${ODIN_TESTS_NO_CLANG:-}" ]]; then
	if ! clang --version >/dev/null 2>&1; then
		echo "ERROR: clang is not present. Some tests require this."
		echo "Note: You can disable tests that require clang by specifying the \"no-clang\" argument, or setting ODIN_TESTS_NO_CLANG=1"
		# TODO: Can we figure out how to make everything work with gcc as well when ODIN_TESTS_NO_CLANG is set?
		exit 1
	fi
fi

# Check examples/all
"$ODIN" check "$here/examples/all" -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do

# Check examples/all/sdl3
"$ODIN" check "$here/examples/all/sdl3" -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do -no-entry-point

# Internals tests
(
	cd "$here/tests/internal"
	"$ODIN" test . -all-packages -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -define:ODIN_TEST_FAIL_ON_BAD_MEMORY=true -sanitize:address
)

# Normal Core library tests
(
	cd "$here/tests/core"
	"$ODIN" test normal.odin -file -all-packages -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -define:ODIN_TEST_FAIL_ON_BAD_MEMORY=true -sanitize:address
)

# Vendor library tests
vendor_build="$here/tests/vendor/build"
mkdir -p "$vendor_build"
cp "$here"/vendor/lua/5.4/linux/*.so "$vendor_build"/
# We are possibly on Windows, so copy the DLLs as well.
cp "$here"/vendor/lua/5.4/windows/*.dll "$vendor_build"/
(
	cd "$vendor_build"
	LD_LIBRARY_PATH="$vendor_build${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$ODIN" test .. -all-packages -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -define:ODIN_TEST_FAIL_ON_BAD_MEMORY=true -sanitize:address
)
rm -rf "$vendor_build"

# Check issues
(
	cd "$here/tests/issues"
	./run.sh
)

# The ABI tests can be disabled because they require clang at the moment.
#   TODO: Maybe try to make them work with msvc as well?
if [[ -z "${ODIN_TESTS_NO_CLANG:-}" ]]; then
	# Run ABI tests
	(
		cd "$here/tests/abi"
		ABI_CFLAGS= ./run.sh
		ABI_CFLAGS=-O2 ./run.sh -o:speed
	)
fi

# More extensive tests (non-slim):
if [[ -z "${SLIM:-}" ]]; then

	echo "Running extended tests..."

	# Optimized Core library tests
	(
		cd "$here/tests/core"
		"$ODIN" test speed.odin -o:speed -file -all-packages -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -define:ODIN_TEST_FAIL_ON_BAD_MEMORY=true
	)

	# Wycheproof tests
	(
		cd "$here/tests/core"
		"$ODIN" test crypto/wycheproof -vet -vet-tabs -strict-style -vet-style -vet-cast -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -o:speed
	)

	# Noise Protocol Framework tests
	(
		cd "$here/tests/core"
		"$ODIN" test crypto/noise -vet -vet-tabs -strict-style -vet-style -vet-cast -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -o:speed
	)

	# X.509 limbo tests
	(
		cd "$here/tests/core"
		"$ODIN" test crypto/x509_limbo -vet -vet-tabs -strict-style -vet-style -vet-cast -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -o:speed
	)

	echo "SUCCESS:  Extended tests have been executed successfully."
	echo "Note: You can call  \"run_tests slim\"  to omit some of the slower tests."

else
	echo "SUCCESS:  Slim tests have been executed successfully."

fi

if [[ -n "${ODIN_TESTS_NO_CLANG:-}" ]]; then
	echo "WARNING:  ODIN_TESTS_NO_CLANG specified - ABI tests have been skipped."
fi
