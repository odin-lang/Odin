/*
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/

// package varint implements variable length integer encoding and decoding
// using the LEB128 format as used by DWARF debug and other file formats
package varint

// Decode a slice of bytes encoding an unsigned LEB128 integer into value and number of bytes used.
// Returns `size` == 0 for an invalid value, empty slice, or a varint > 16 bytes.
// In theory we should use the bigint package. In practice, varints bigger than this indicate a corrupted file.
decode_uleb128 :: proc(buf: []u8) -> (val: u128, size: int) {
	more := true

	for v, i in buf {
		size = i + 1

		if size > size_of(u128) {
			return
		}

		val |= u128(v & 0x7f) << uint(i * 7)

		if v < 128 {
			more = false
			break
		}
	}

	// If the buffer runs out before the number ends, return an error.
	if more {
		return 0, 0
	}
	return
}

// Decode a slice of bytes encoding a signed LEB128 integer into value and number of bytes used.
// Returns `size` == 0 for an invalid value, empty slice, or a varint > 16 bytes.
// In theory we should use the bigint package. In practice, varints bigger than this indicate a corrupted file.
decode_ileb128 :: proc(buf: []u8) -> (val: i128, size: int) {
	shift: uint

	if len(buf) == 0 {
		return
	}

	for v in buf {
		size += 1
		if size > size_of(i128) {
			return
		}

		val |= i128(v & 0x7f) << shift
		shift += 7

		if v < 128 { break }
	}

	if buf[size - 1] & 0x40 == 0x40 {
		val |= max(i128) << shift
	}
	return
}