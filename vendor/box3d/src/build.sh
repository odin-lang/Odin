#!/usr/bin/env bash

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
	OS="darwin"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
	OS="linux"
else
	echo "Error: Unsupported operating system: $OSTYPE"
	exit 1
fi

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

LIB_DIR="../lib/${OS}-${ARCH}"
mkdir -p "$LIB_DIR"
cc -c -O2 -std=c17 -fPIC -Iinclude src/*.c
ar rcs "$LIB_DIR/libbox3d.a" *.o
rm -f *.o