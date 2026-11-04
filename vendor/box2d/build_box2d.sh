#!/usr/bin/env bash
set -eu

VERSION="3.2.0"
RELEASE="https://github.com/erincatto/box2d/archive/refs/tags/v$VERSION.tar.gz"

cd "$(dirname "$0")"

curl -O -L "$RELEASE"
tar -xzvf "v$VERSION.tar.gz"

cd "box2d-$VERSION"

cc=${CC:-cc}
ar=${AR:-ar}

# Single precision, like the bindings. Box2D 3.2 selects AVX2 or SSE2 at run time (contact_solver_w8.c turns AVX2 on for
# itself), so there is one library per platform.
FLAGS="-c -O2 -DNDEBUG -ffp-contract=off -std=gnu17 -fPIC -Iinclude -Isrc"

# compile <extra flags> <output prefix>: compile every source into <output prefix>-<name>.o
compile() {
	for source in src/*.c; do
		name="$(basename "$source" .c)"
		$cc $FLAGS $1 "$source" -o "$2-$name.o"
	done
}

case "$(uname -s)" in
Darwin)
	# One universal (x86_64 + arm64) library
	archives=()
	for arch in x86_64 arm64; do
		compile "-arch $arch -mmacosx-version-min=11.0" "$arch"
		$ar rcs "box2d-$arch.a" "$arch"-*.o
		archives+=("box2d-$arch.a")
		rm -f "$arch"-*.o
	done
	lipo -create "${archives[@]}" -output ../lib/box2d_darwin.a
	;;
*)
	compile "" box2d
	$ar rcs box2d.a box2d-*.o
	case "$(uname -m)" in
	"x86_64" | "amd64")
		cp box2d.a ../lib/box2d_other_amd64.a
		;;
	*)
		cp box2d.a ../lib/box2d_other.a
		;;
	esac
	;;
esac

cd ..

set +e
make -f wasm.Makefile
if [[ $? -ne 0 ]]; then
	printf "\e[30;43mwarning:\e[0m Native Box2D libraries were built successfully, the WASM build failed, likely because your default C compiler and/or linker doesn't support WASM, you can set the CC and LD environment variables to point to a compiler and linker that support it\n"
fi
make -f wasm.Makefile clean
set -e

rm -rf "v$VERSION.tar.gz"
rm -rf box2d-"$VERSION"
