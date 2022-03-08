/*
	Implementation of the LEB128 variable integer encoding as used by DWARF encoding and DEX files, among others.

	Author of this Odin package: Jeroen van Rijn

	Example:
		```odin
		import "core:encoding/varint"
		import "core:fmt"

		main :: proc() {
			buf: [varint.LEB128_MAX_BYTES]u8

			value := u128(42)

			encode_size, encode_err := varint.encode_uleb128(buf[:], value)
			assert(encode_size == 1 && encode_err == .None)

			fmt.println(buf[:encode_size])

			decoded_val, decode_size, decode_err := varint.decode_uleb128(buf[:encode_size])
			assert(decoded_val == value && decode_size == encode_size && decode_err == .None)
		}
		```

*/
package varint