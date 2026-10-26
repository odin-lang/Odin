#!/usr/bin/env sh
# Tests that `vendor:sdl3` and its satellite libraries (SDL3_image, SDL3_mixer, SDL3_net, SDL3_ttf) link, and prints their versions.
# Here these are the system's libraries, so they can be any version and the versions are only printed: install the SDL3, SDL3_image,
# SDL3_mixer, SDL3_net and SDL3_ttf development packages first (on macOS: `brew install sdl3 sdl3_image sdl3_mixer sdl3_net sdl3_ttf`).
# Every library has its own test-*.odin file, which is tested on its own, so a library that isn't installed fails its own test and
# doesn't stop the others. The exit code is non-zero if any of them failed.
set -u

cd "$(dirname "$0")"

# Homebrew's libraries are not where the linker looks
flags=""
if [ "$(uname -s)" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
	flags="-extra-linker-flags:-L$(brew --prefix)/lib"
fi

failed=""
for file in test-*.odin; do
	echo
	echo "==== $file"
	log="${file%.odin}.log"
	# shellcheck disable=SC2086
	odin test "$file" -file $flags -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -define:ODIN_TEST_FAIL_ON_BAD_MEMORY=true >"$log" 2>&1
	code=$?
	cat "$log"
	# A test that could not even start, for example because a shared library is missing, does not make `odin test` fail: it has to say it finished.
	grep -q "Finished" "$log" || code=1
	if [ "$code" -ne 0 ]; then
		failed="$failed $file"
	fi
	rm -f "${file%.odin}" "$log"
done

echo
if [ -n "$failed" ]; then
	echo "FAILED:$failed"
	exit 1
fi
echo "All SDL3 tests passed."
