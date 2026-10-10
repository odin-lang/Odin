#!/usr/bin/env bash
set -eu

# This file runs most of the tests that the CI would run.
# It omits time-intensive optimized core library tests and Wycheproof tests.

here=$(cd "$(dirname "$0")" && pwd)
: "${ODIN:=$here/odin}"

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

# Run ABI tests
(
	cd "$here/tests/abi"
	ABI_CFLAGS= ./run.sh
	ABI_CFLAGS=-O2 ./run.sh -o:speed
)
