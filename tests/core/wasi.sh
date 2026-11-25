#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")/../.."
ROOT="$(pwd -P)"
FLAGS="-build-mode:test -target:wasi_wasm32 -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -disallow-do -define:ODIN_TEST_FANCY=false -define:ODIN_TEST_FAIL_ON_BAD_MEMORY=true"

NORMAL_PACKAGES="
	bytes
	container
	crypto/bigint
	crypto/x509
	diff
	encoding/asn1
	encoding/base32
	encoding/base64
	encoding/cbor
	encoding/csv
	encoding/endian
	encoding/entity
	encoding/hex
	encoding/hxa
	encoding/ini
	encoding/json
	encoding/json/differential
	encoding/json/user_unmarshaler
	encoding/pem
	encoding/uuid
	encoding/varint
	encoding/xml
	flags
	fmt
	hash
	io
	math/big
	math/big_cutoffs
	math/bits
	math/fixed
	math/linalg/hlsl
	math/noise
	mem
	odin
	os
	path/filepath
	reflect
	runtime
	slice
	sort
	strconv
	strings
	terminal/ansi
	text/edit
	text/i18n
	text/match
	text/regex
	text/scanner
	unicode
"

SPEED_PACKAGES="
	compress
	crypto
	crypto/noise
	crypto/wycheproof
	crypto/x509_limbo
"

python3 tests/core/download_assets.py tests/core/assets

TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT
FAILED=""

run_package() {
	echo "tests/core/$1"
	if ./odin build "tests/core/$1" $FLAGS $2 -out:"$TEMP/test.wasm" && wasmtime run --dir "$ROOT::$ROOT" --dir "$TEMP::/tmp" --dir "$TEMP::." "$TEMP/test.wasm"; then
		return 0
	fi
	FAILED="$FAILED $1"
}

for package in $NORMAL_PACKAGES; do
	run_package "$package" ""
done
for package in $SPEED_PACKAGES; do
	run_package "$package" -o:speed
done

if [ -n "$FAILED" ]; then
	echo "Failed:$FAILED"
	exit 1
fi
