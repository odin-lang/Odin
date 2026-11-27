package encoding_varint

/*
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/

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
// Bytes after the varint are ignored. An empty slice, or one that ends before the varint does,
// returns `0, 0, .Buffer_Too_Small`. A varint longer than `LEB128_MAX_BYTES`, or a value that
// doesn't fit a `u128`, returns `0, 0, .Value_Too_Large`.
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

// Decodes an unsigned LEB128 integer one byte at a time: pass `offset` and `accumulator` 0 for
// the first byte, then the `size` and `val` returned for the previous one.
// Returns `.None` when decoded and `.Buffer_Too_Small` while more bytes are needed.
// A value that doesn't fit a `u128`, or a varint longer than `LEB128_MAX_BYTES`,
// returns `0, 0, .Value_Too_Large`.
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
// Bytes after the varint are ignored. An empty slice, or one that ends before the varint does,
// returns `0, 0, .Buffer_Too_Small`. A varint longer than `LEB128_MAX_BYTES`, or a value that
// doesn't fit an `i128`, returns `0, 0, .Value_Too_Large`.
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

// Decodes a signed LEB128 integer one byte at a time: pass `offset` and `accumulator` 0 for
// the first byte, then the `size` and `val` returned for the previous one.
// Returns `.None` when decoded and `.Buffer_Too_Small` while more bytes are needed.
// A value that doesn't fit an `i128`, or a varint longer than `LEB128_MAX_BYTES`,
// returns `0, 0, .Value_Too_Large`.
decode_ileb128_byte :: proc(input: u8, offset: int, accumulator: i128) -> (val: i128, size: int, err: Error) {
	size = offset + 1
	shift := uint(offset * 7)

	// 18 * 7 bits = 126, so the 19th byte holds bits 126 to 132. Bits 127 to 132 must all
	// equal the sign, which leaves 0x00, 0x01, 0x7e and 0x7f.
	if size > LEB128_MAX_BYTES || size == LEB128_MAX_BYTES && input != 0x00 && input != 0x01 && input != 0x7e && input != 0x7f {
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

// Encode `val` into `buf` as an unsigned LEB128 encoded series of bytes, and return the number
// of bytes written. A `buf` of `LEB128_MAX_BYTES` always suffices. A shorter one that can't hold
// the encoding returns `0, .Buffer_Too_Small`, with all of `buf` overwritten.
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

// Encode `val` into `buf` as a signed LEB128 encoded series of bytes, and return the number
// of bytes written. A `buf` of `LEB128_MAX_BYTES` always suffices. A shorter one that can't hold
// the encoding returns `0, .Buffer_Too_Small`, with all of `buf` overwritten.
encode_ileb128 :: proc(buf: []u8, val: i128) -> (size: int, err: Error) {
	val, more := val, true

	for more {
		size += 1

		if size > len(buf) {
			return 0, .Buffer_Too_Small
		}

		low := val & 0x7f
		val >>= 7

		if (val == 0 && low & 0x40 != 0x40) || (val == -1 && low & 0x40 == 0x40) {
			more = false
		} else {
			low |= 0x80
		}

		buf[size - 1] = u8(low)
	}
	return
}
