#!/usr/bin/env bash

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
if [[ "$OSTYPE" == "darwin"* ]]; then
	INSTALL_DIR="../lib/darwin"
	mkdir -p "$INSTALL_DIR" build/x86_64 build/arm64

	# Building box3d for amd64
	for src in src/*.c; do
		obj="build/x86_64/$(basename "${src%.c}.o")"
		clang -c -O2 -std=c17 -fPIC \
			-arch x86_64 \
			-mmacosx-version-min=11.0 \
			-Iinclude \
			"$src" -o "$obj"
	done

	# Building box3d for arm64
	for src in src/*.c; do
		obj="build/arm64/$(basename "${src%.c}.o")"
		clang -c -O2 -std=c17 -fPIC \
			-arch arm64 \
			-mmacosx-version-min=11.0 \
			-Iinclude \
			"$src" -o "$obj"
	done

	# Turn them into their respective *.a files
	ar rcs "$INSTALL_DIR/libbox3d_x86_64.a" build/x86_64/*.o
	ar rcs "$INSTALL_DIR/libbox3d_arm64.a"  build/arm64/*.o

	ranlib "$INSTALL_DIR/libbox3d_x86_64.a"
	ranlib "$INSTALL_DIR/libbox3d_arm64.a"

	# Bundle them into a universal library
	lipo -create \
		"$INSTALL_DIR/libbox3d_x86_64.a" \
		"$INSTALL_DIR/libbox3d_arm64.a" \
		-output "$INSTALL_DIR/$LIB_NAME"

	# Clean up the single arch .a files and build temp
	rm "$INSTALL_DIR/libbox3d_x86_64.a" "$INSTALL_DIR/libbox3d_arm64.a"
	rm -rf build

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
	OS="linux"
	LIB_DIR="../lib/${OS}-${ARCH}"
	mkdir -p "$LIB_DIR"
	cc -c -O2 -std=c17 -fPIC -Iinclude src/*.c
	ar rcs "$LIB_DIR/$LIB_NAME" *.o
	rm -f *.o

else
	echo "Error: Unsupported operating system: $OSTYPE"
	exit 1
fi