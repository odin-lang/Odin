/*
Implementation of the LEB128 variable integer encoding as used by DWARF encoding and DEX files, among others.

Author of this Odin package: Jeroen van Rijn

Example:
	package main

	import "core:encoding/varint"
	import "core:fmt"

	main :: proc() {
		buf: [varint.LEB128_MAX_BYTES]u8

		value := u128(42)

		encode_size, encode_err := varint.encode_uleb128(buf[:], value)
		assert(encode_size == 1 && encode_err == .None)

		fmt.printf("Encoded as %v\n", buf[:encode_size])
		decoded_val, decode_size, decode_err := varint.decode_uleb128(buf[:])

		assert(decoded_val == value && decode_size == encode_size && decode_err == .None)
		fmt.printf("Decoded as %v, using %v byte%v\n", decoded_val, decode_size, "" if decode_size == 1 else "s")
	}
*/
package encoding_varint
