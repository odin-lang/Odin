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


# Cleaned BEFORE, not after: the generated corpus is left in place so it can be
# read after a failure. CI throws the tree away anyway.
rm -rf "$here/build"
mkdir -p "$here/build"
pushd "$here/build" > /dev/null

set -x

python3 ../gen.py .

# Ask the C compiler which tiers it has, by preprocessing the generated `build-cross/tiers.c`. 
# The Odin side must use the same tiers or it references symbols C never emitted.
have() { $CLANG $CC_TARGET -E tiers.c 2>/dev/null | grep -q "ABI_YES_$1" && echo true || echo false; }
TIERS="-define:ABI_TIER_GNU=$(have GNU) -define:ABI_TIER_F16=$(have F16) -define:ABI_TIER_I128=$(have I128)"

# `-w` because the corpus deliberately uses zero-length arrays and empty
# structs; both are the extensions under test.
$CLANG $CC_TARGET -c abi_corpus.c -o abi_corpus_c.o -w
$ODIN test abi_corpus.odin $COMMON $ODIN_TARGET $TIERS "$@"

set +x

popd > /dev/null
