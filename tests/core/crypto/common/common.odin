package test_crypto_common

import "core:bytes"
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

