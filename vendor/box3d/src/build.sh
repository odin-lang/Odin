#!/usr/bin/env bash
set -e

cc=${CC:-cc}
ar=${AR:-ar}
ranlib=${RANLIB:-ranlib}
lipo=${LIPO:-lipo}
wasm_cc=${WASM_CC:-clang}
wasm_ld=${WASM_LD:-wasm-ld}
ODIN_ROOT=${ODIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}

cd "$ODIN_ROOT/vendor/box3d/src" || exit 1

LIB_NAME="libbox3d.a"
# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
	x86_64|amd64)
		ARCH="amd64"
		;;
	arm64|aarch64)
		ARCH="arm64"
		;;
	*)
		echo "Error: Unsupported architecture: $ARCH"
		exit 1
		;;
esac

# Detect OS
case "$(uname -s)" in
Darwin)
	INSTALL_DIR="../lib/darwin"
	mkdir -p "$INSTALL_DIR" build/x86_64 build/arm64

	# Building box3d for amd64
	for src in src/*.c; do
		obj="build/x86_64/$(basename "${src%.c}.o")"
		$cc -c -O2 -std=c17 -fPIC \
			-arch x86_64 \
			-mmacosx-version-min=11.0 \
			-Iinclude \
			"$src" -o "$obj"
	done

	# Building box3d for arm64
	for src in src/*.c; do
		obj="build/arm64/$(basename "${src%.c}.o")"
		$cc -c -O2 -std=c17 -fPIC \
			-arch arm64 \
			-mmacosx-version-min=11.0 \
			-Iinclude \
			"$src" -o "$obj"
	done

	# Turn them into their respective *.a files
	$ar rcs "$INSTALL_DIR/libbox3d_x86_64.a" build/x86_64/*.o
	$ar rcs "$INSTALL_DIR/libbox3d_arm64.a" build/arm64/*.o

	$ranlib "$INSTALL_DIR/libbox3d_x86_64.a"
	$ranlib "$INSTALL_DIR/libbox3d_arm64.a"
	
	# Bundle them into a universal library
	$lipo -create \
		"$INSTALL_DIR/libbox3d_x86_64.a" \
		"$INSTALL_DIR/libbox3d_arm64.a" \
		-output "$INSTALL_DIR/$LIB_NAME"

	# Clean up the single arch .a files and build temp
	rm "$INSTALL_DIR/libbox3d_x86_64.a" "$INSTALL_DIR/libbox3d_arm64.a"
	rm -rf build
	;;
Linux)
	LIB_DIR="../lib/linux-$ARCH"
	mkdir -p "$LIB_DIR" build
	for src in src/*.c; do
		obj="build/$(basename "${src%.c}.o")"
		$cc -c -O2 -std=c17 -fPIC -Iinclude "$src" -o "$obj"
	done
	# Clean up old library in case `ar` is tempted to preserve old symbols
	rm -f "$LIB_DIR/$LIB_NAME"
	$ar rcs "$LIB_DIR/$LIB_NAME" build/*.o
	$ranlib "$LIB_DIR/$LIB_NAME"
	rm -rf build
	;;
*)

	echo "Error: Unsupported operating system: $(uname -s)"
	exit 1
	;;
esac

echo "Building Box3D for wasm32"
mkdir -p build/wasm
for src in src/*.c; do
	obj="build/wasm/$(basename "${src%.c}.o")"
	"$wasm_cc" -c -O3 -std=gnu17 --target=wasm32 \
		--sysroot="$ODIN_ROOT/vendor/libc-shim" \
		-Iinclude \
		-include wasm_compat.h \
		-DBOX3D_DISABLE_SIMD \
		-DNDEBUG \
		"$src" -o "$obj"
done
"$wasm_cc" -c -O3 -std=gnu17 --target=wasm32 \
	--sysroot="$ODIN_ROOT/vendor/libc-shim" \
	-Iinclude \
	-include wasm_compat.h \
	-DBOX3D_DISABLE_SIMD \
	-DNDEBUG \
	wasm_compat.c -o build/wasm/wasm_compat.o
"$wasm_ld" -r -o ../lib/box3d_wasm.o build/wasm/*.o
rm -rf build/wasm
