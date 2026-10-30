#!/usr/bin/env sh
# Builds lib/android/<abi>/miniaudio.a for every Android ABI with the NDK's clang.
# Needs ODIN_ANDROID_NDK to point at an NDK.
set -e

if [ -z "$ODIN_ANDROID_NDK" ]; then
	echo "ODIN_ANDROID_NDK is not set" >&2
	exit 1
fi

ODIN_ROOT=${ODIN_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}

# Odin's minimum Android API level.
API=29

case "$(uname -s)" in
	Linux*)               HOST=linux-x86_64 ;;
	Darwin*)              HOST=darwin-x86_64 ;;
	MINGW*|MSYS*|CYGWIN*) HOST=windows-x86_64 ;;
	*) echo "unsupported host $(uname -s)" >&2; exit 1 ;;
esac
BIN="$ODIN_ANDROID_NDK/toolchains/llvm/prebuilt/$HOST/bin"

cd "$ODIN_ROOT/vendor/miniaudio/src" || exit 1

for pair in arm64-v8a:aarch64-linux-android x86_64:x86_64-linux-android armeabi-v7a:armv7a-linux-androideabi x86:i686-linux-android; do
	abi=${pair%%:*}
	triple=${pair#*:}

	mkdir -p "../lib/android/$abi"
	"$BIN/clang" --target="$triple$API" -c -O2 -fPIC miniaudio.c -o "miniaudio_$abi.o"
	"$BIN/llvm-ar" rcs "../lib/android/$abi/miniaudio.a" "miniaudio_$abi.o"
	rm "miniaudio_$abi.o"
done
