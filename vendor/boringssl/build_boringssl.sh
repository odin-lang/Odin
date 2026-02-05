#!/usr/bin/env bash
set -eu

BORINGSSL_SRC="${BORINGSSL_SRC:-../boringssl}"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${BORINGSSL_SRC}/build"

if [[ ! -d "${BORINGSSL_SRC}" ]]; then
	printf "error: BORINGSSL_SRC not found: %s\n" "${BORINGSSL_SRC}" 1>&2
	exit 1
fi

cmake -S "${BORINGSSL_SRC}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release
cmake --build "${BUILD_DIR}" --target ssl crypto

mkdir -p "${ROOT_DIR}/include/openssl" "${ROOT_DIR}/lib"
rsync -a "${BORINGSSL_SRC}/include/openssl/" "${ROOT_DIR}/include/openssl/"
cp -a "${BUILD_DIR}/libssl.a" "${BUILD_DIR}/libcrypto.a" "${ROOT_DIR}/lib/"
