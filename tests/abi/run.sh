#!/usr/bin/env bash
set -eu

# The ABI comparator.
#
# Every check is "Odin agrees with the platform C compiler"
#
#   ./run.sh
#   ./run.sh linux_riscv64 riscv64-linux-gnu \
#       "-extra-linker-flags:-fuse-ld=/usr/bin/riscv64-linux-gnu-gcc-12 -static -Wl,-static" -no-rpath
#
# For a target with no cross libc -- i386, arm32 -- see `cross.sh`, which builds
# the same corpus freestanding.

TARGET=${1:-}
TRIPLE=${2:-}
if [ $# -gt 2 ]; then shift 2; else shift $#; fi   # anything else goes to `odin test`

here=$(cd "$(dirname "$0")" && pwd)
: "${ODIN:=$here/../../odin}"
: "${CLANG:=clang}"
COMMON="-define:ODIN_TEST_FANCY=false -file -vet -strict-style -ignore-unused-defineables"

CC_TARGET=""; [ -n "$TRIPLE" ] && CC_TARGET="--target=$TRIPLE"
ODIN_TARGET=""; [ -n "$TARGET" ] && ODIN_TARGET="-target:$TARGET"

# Ask the C compiler which tiers it actually has, the Odin side must have the same answer or
# it references symbols the C side never emitted ( eg `__int128` does not exist on i386).
macros=$($CLANG $CC_TARGET -dM -E -x c /dev/null 2>/dev/null)
tier() { case "$macros" in *"$1"*) echo true ;; *) echo false ;; esac; }
TIERS="-define:ABI_TIER_GNU=$(tier __GNUC__) -define:ABI_TIER_F16=$(tier __FLT16_MANT_DIG__) -define:ABI_TIER_I128=$(tier __SIZEOF_INT128__)"

rm -rf "$here/build"
mkdir -p "$here/build"
trap 'rm -rf "$here/build"' EXIT   # also on failure, where `set -e` would skip it
pushd "$here/build" > /dev/null

set -x

python3 ../gen.py .

# `-w` because the corpus deliberately uses zero-length arrays and empty
# structs; both are the extensions under test.
$CLANG $CC_TARGET -c abi_corpus.c -o abi_corpus_c.o -w
$ODIN test abi_corpus.odin $COMMON $ODIN_TARGET $TIERS "$@"

set +x

popd > /dev/null
