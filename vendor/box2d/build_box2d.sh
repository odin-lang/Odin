#!/usr/bin/env bash
set -eu

VERSION="3.0.0"
RELEASE="https://github.com/erincatto/box2d/archive/refs/tags/v$VERSION.tar.gz"

cd "$(odin root)"/vendor/box2d

curl -O -L "$RELEASE"
tar -xzvf "v$VERSION.tar.gz"

cd "box2d-$VERSION"

FLAGS="-DCMAKE_BUILD_TYPE=Release -DBOX2D_SAMPLES=OFF -DBOX2D_VALIDATE=OFF -DBOX2D_UNIT_TESTS=OFF"

case "$(uname -s)" in
Darwin)
	export MACOSX_DEPLOYMENT_TARGET="11" 

	case "$(uname -m)" in
	"x86_64" | "amd64")
		rm -rf build
		mkdir build
		cmake $FLAGS -DBOX2D_AVX2=ON -DCMAKE_OSX_ARCHITECTURES=x86_64 -S . -B build
		cmake --build build
		cp build/src/libbox2d.a ../lib/box2d_darwin_amd64_avx2.a

		rm -rf build
		mkdir build
		cmake $FLAGS -DBOX2D_AVX2=OFF -DCMAKE_OSX_ARCHITECTURES=x86_64 -S . -B build
		cmake --build build
		cp build/src/libbox2d.a ../lib/box2d_darwin_amd64_sse2.a
		;;
	*)
		rm -rf build
		mkdir build
		cmake $FLAGS -DCMAKE_OSX_ARCHITECTURES=arm64 -S . -B build
		cmake --build build
		cp build/src/libbox2d.a ../lib/box2d_darwin_arm64.a
		;;
	esac
	;;
*)
	case "$(uname -m)" in
	"x86_64" | "amd64")
		rm -rf build
		mkdir build
		cmake $FLAGS -DBOX2D_AVX2=ON -S . -B build
		cmake --build build
		cp build/src/libbox2d.a ../lib/box2d_other_amd64_avx2.a

		rm -rf build
		mkdir build
		cmake $FLAGS -DBOX2D_AVX2=OFF -S . -B build
		cmake --build build
		cp build/src/libbox2d.a ../lib/box2d_other_amd64_sse2.a
		;;
	*)
		rm -rf build
		mkdir build
		cmake $FLAGS -DCMAKE_OSX_ARCHITECTURES=arm64 -S . -B build
		cmake --build build
		cp build/src/libbox2d.a ../lib/box2d_other.a
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
set -e

rm -rf v3.0.0.tar.gz
rm -rf box2d-3.0.0
