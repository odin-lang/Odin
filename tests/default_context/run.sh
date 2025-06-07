#!/usr/bin/env sh
# The program will panic if anything fails, which should be enough to trigger the CI.
set -e

readonly ODIN=../../odin

# The default context must be able to be found no matter what our linkage
# situation is. By testing the various optimization modes, we can detect if
# there are any issues with everyday usage.
#
# Normally, the compiler builds with separate modules for compilation speed,
# but when a higher optimization level is used to make a release build, we
# switch to a single module build. This can have consequences for the linkage
# state of symbols.
$ODIN build shared -build-mode:dll

$ODIN run .               -define:TEST_TAG="main:default/default"
$ODIN run . -o:none       -define:TEST_TAG="main:none/default"
$ODIN run . -o:size       -define:TEST_TAG="main:size/default"
$ODIN run . -o:speed      -define:TEST_TAG="main:speed/default"
$ODIN run . -o:aggressive -define:TEST_TAG="main:aggressive/default"

$ODIN run .               -define:TEST_TAG="shared:default/default"    -define:USE_SHARED_CONTEXT=true
$ODIN run . -o:none       -define:TEST_TAG="shared:none/default"       -define:USE_SHARED_CONTEXT=true
$ODIN run . -o:size       -define:TEST_TAG="shared:size/default"       -define:USE_SHARED_CONTEXT=true
$ODIN run . -o:speed      -define:TEST_TAG="shared:speed/default"      -define:USE_SHARED_CONTEXT=true
$ODIN run . -o:aggressive -define:TEST_TAG="shared:aggressive/default" -define:USE_SHARED_CONTEXT=true

$ODIN build shared -build-mode:dll -o:speed

$ODIN run .               -define:TEST_TAG="main:default/speed"
$ODIN run . -o:none       -define:TEST_TAG="main:none/speed"
$ODIN run . -o:size       -define:TEST_TAG="main:size/speed"
$ODIN run . -o:speed      -define:TEST_TAG="main:speed/speed"
$ODIN run . -o:aggressive -define:TEST_TAG="main:aggressive/speed"

$ODIN run .               -define:TEST_TAG="shared:default/speed"    -define:USE_SHARED_CONTEXT=true
$ODIN run . -o:none       -define:TEST_TAG="shared:none/speed"       -define:USE_SHARED_CONTEXT=true
$ODIN run . -o:size       -define:TEST_TAG="shared:size/speed"       -define:USE_SHARED_CONTEXT=true
$ODIN run . -o:speed      -define:TEST_TAG="shared:speed/speed"      -define:USE_SHARED_CONTEXT=true
$ODIN run . -o:aggressive -define:TEST_TAG="shared:aggressive/speed" -define:USE_SHARED_CONTEXT=true

# Here we'll explicitly test mixing module modes.

$ODIN build shared -build-mode:dll -use-separate-modules

$ODIN run .               -define:TEST_TAG="main:default/separate"
$ODIN run .               -define:TEST_TAG="main:separate/separate" -use-separate-modules

$ODIN build shared -build-mode:dll -use-single-module

$ODIN run .               -define:TEST_TAG="main:default/single"
$ODIN run .               -define:TEST_TAG="main:single/single" -use-single-module

set +e

# Darwin
rm -f shared.dylib
# Every other *nix-like
rm -f shared.so
