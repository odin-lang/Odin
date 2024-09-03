/*
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/

package encoding_varint

// In theory we should use the bigint package. In practice, varints bigger than this indicate a corrupted file.
// Instead we'll set limits on the values we'll encode/decode
// 18 * 7 bits = 126, which means that a possible 19th byte may at most be `0b0000_0011`.
LEB128_MAX_BYTES :: 19

Error :: enum {
	None             = 0,
	Buffer_Too_Small = 1,
	Value_Too_Large  = 2,
}

// Decode a slice of bytes encoding an unsigned LEB128 integer into value and number of bytes used.
// Returns `size` == 0 for an invalid value, empty slice, or a varint > 18 bytes.
decode_uleb128_buffer :: proc(buf: []u8) -> (val: u128, size: int, err: Error) {
	if len(buf) == 0 {
		return 0, 0, .Buffer_Too_Small
	}

	for v in buf {
		val, size, err = decode_uleb128_byte(v, size, val)
		if err != .Buffer_Too_Small {
			return
		}
	}

	if err == .Buffer_Too_Small {
		val, size = 0, 0
	}
	return
}

// Decodes an unsigned LEB128 integer into value a byte at a time.
// Returns `.None` when decoded properly, `.Value_Too_Large` when they value
// exceeds the limits of a u128, and `.Buffer_Too_Small` when it's not yet fully decoded.
decode_uleb128_byte :: proc(input: u8, offset: int, accumulator: u128) -> (val: u128, size: int, err: Error) {
	size = offset + 1

	// 18 * 7 bits = 126, which means that a possible 19th byte may at most be 0b0000_0011.
	if size > LEB128_MAX_BYTES || size == LEB128_MAX_BYTES && input > 0b0000_0011 {
		return 0, 0, .Value_Too_Large
	}

	val = accumulator | u128(input & 0x7f) << uint(offset * 7)

	if input < 128 {
		// We're done
		return
	}

	// If the buffer runs out before the number ends, return an error.
	return val, size, .Buffer_Too_Small
}
decode_uleb128 :: proc {decode_uleb128_buffer, decode_uleb128_byte}

// Decode a slice of bytes encoding a signed LEB128 integer into value and number of bytes used.
// Returns `size` == 0 for an invalid value, empty slice, or a varint > 18 bytes.
decode_ileb128_buffer :: proc(buf: []u8) -> (val: i128, size: int, err: Error) {
	if len(buf) == 0 {
		return 0, 0, .Buffer_Too_Small
	}

	for v in buf {
		val, size, err = decode_ileb128_byte(v, size, val)
		if err != .Buffer_Too_Small {
			return
		}
	}

	if err == .Buffer_Too_Small {
		val, size = 0, 0
	}
	return
}

// Decode a a signed LEB128 integer into value and number of bytes used, one byte at a time.
// Returns `size` == 0 for an invalid value, empty slice, or a varint > 18 bytes.
decode_ileb128_byte :: proc(input: u8, offset: int, accumulator: i128) -> (val: i128, size: int, err: Error) {
	size = offset + 1
	shift := uint(offset * 7)

	// 18 * 7 bits = 126, which including sign means we can have a 19th byte.
	if size > LEB128_MAX_BYTES || size == LEB128_MAX_BYTES && input > 0x7f {
		return 0, 0, .Value_Too_Large
	}

	val = accumulator | i128(input & 0x7f) << shift

	if input < 128 {
		if input & 0x40 == 0x40 {
			val |= max(i128) << (shift + 7)
		}
		return val, size, .None
	}
	return val, size, .Buffer_Too_Small
}
decode_ileb128 :: proc{decode_ileb128_buffer, decode_ileb128_byte}

// Encode `val` into `buf` as an unsigned LEB128 encoded series of bytes.
// `buf` must be appropriately sized.
encode_uleb128 :: proc(buf: []u8, val: u128) -> (size: int, err: Error) {
	val := val

	for {
		size += 1

		if size > len(buf) {
			return 0, .Buffer_Too_Small
		}

		low := val & 0x7f
		val >>= 7

		if val > 0 {
			low |= 0x80 // more bytes to follow
		}
		buf[size - 1] = u8(low)

		if val == 0 { break }
	}
	return
}

// Encode `val` into `buf` as a signed LEB128 encoded series of bytes.
// `buf` must be appropriately sized.
encode_ileb128 :: proc(buf: []u8, val: i128) -> (size: int, err: Error) {
	SIGN_MASK :: i128(1) << 121 // sign extend mask

	val, more := val, true

	for more {
		size += 1

		if size > len(buf) {
			return 0, .Buffer_Too_Small
		}

		low := val & 0x7f
		val >>= 7

		low = (low ~ SIGN_MASK) - SIGN_MASK

		if (val == 0 && low & 0x40 != 0x40) || (val == -1 && low & 0x40 == 0x40) {
			more = false
		} else {
			low |= 0x80
		}

		buf[size - 1] = u8(low)
	}
	return
}
