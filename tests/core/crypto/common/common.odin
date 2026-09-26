package test_crypto_common

import "core:bytes"
import "core:encoding/base64"
import "core:encoding/hex"

// Common helpers for cryptography tests.

Hex_Bytes :: string

hexbytes_compare :: proc(x: Hex_Bytes, b: []byte, allocator := context.allocator) -> bool {
	dst := hexbytes_decode(x)
	defer delete(dst)

	return bytes.equal(dst, b)
}

hexbytes_decode :: proc(x: Hex_Bytes, allocator := context.allocator) -> []byte {
	dst, ok := hex.decode(transmute([]byte)(x), allocator)
	if !ok {
		panic("Hex_Bytes: invalid hex encoding")
	}

	return dst
}

Jwk_Bytes :: string

jwkbytes_decode :: proc(s: Jwk_Bytes, allocator := context.allocator) -> []byte {
	dst, err := base64.decode(s, base64.DEC_URL_TABLE, allocator = allocator)
	if err != nil {
		panic("Jwk_Bytes: invalid hex encoding")
	}

	return dst
}
