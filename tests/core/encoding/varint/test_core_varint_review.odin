package test_core_varint

import "core:encoding/varint"
import "core:testing"

@(private="file")
decode_uleb_bytewise :: proc(buf: []u8) -> (val: u128, size: int, err: varint.Error) {
	err = .Buffer_Too_Small
	for b in buf {
		val, size, err = varint.decode_uleb128(b, size, val)
		if err != .Buffer_Too_Small {
			return
		}
	}
	return 0, 0, err
}

@(private="file")
decode_ileb_bytewise :: proc(buf: []u8) -> (val: i128, size: int, err: varint.Error) {
	err = .Buffer_Too_Small
	for b in buf {
		val, size, err = varint.decode_ileb128(b, size, val)
		if err != .Buffer_Too_Small {
			return
		}
	}
	return 0, 0, err
}

@(private="file")
check_uleb_round_trip :: proc(t: ^testing.T, value: u128, want_size: int, loc := #caller_location) {
	buf: [varint.LEB128_MAX_BYTES]u8
	size, err := varint.encode_uleb128(buf[:], value)
	testing.expectf(t, err == .None && size == want_size, "encode_uleb128(%v): got %v, %v, want size %v", value, size, err, want_size, loc = loc)
	if err != .None || size != want_size {
		return
	}

	val, n, derr := varint.decode_uleb128(buf[:size])
	testing.expectf(t, val == value && n == size && derr == .None, "decode_uleb128(%02x): got %v, %v, %v, want %v", buf[:size], val, n, derr, value, loc = loc)

	val, n, derr = decode_uleb_bytewise(buf[:size])
	testing.expectf(t, val == value && n == size && derr == .None, "decode_uleb128 byte at a time (%02x): got %v, %v, %v, want %v", buf[:size], val, n, derr, value, loc = loc)

	for k in 0..<size {
		val, n, derr = varint.decode_uleb128(buf[:k])
		testing.expectf(t, val == 0 && n == 0 && derr == .Buffer_Too_Small, "decode_uleb128(%02x) truncated: got %v, %v, %v", buf[:k], val, n, derr, loc = loc)
	}

	short: [varint.LEB128_MAX_BYTES]u8
	n, err = varint.encode_uleb128(short[:size - 1], value)
	testing.expectf(t, n == 0 && err == .Buffer_Too_Small, "encode_uleb128(%v) into %v bytes: got %v, %v", value, size - 1, n, err, loc = loc)
}

@(private="file")
check_ileb_round_trip :: proc(t: ^testing.T, value: i128, want_size: int, loc := #caller_location) {
	buf: [varint.LEB128_MAX_BYTES]u8
	size, err := varint.encode_ileb128(buf[:], value)
	testing.expectf(t, err == .None && size == want_size, "encode_ileb128(%v): got %v, %v, want size %v", value, size, err, want_size, loc = loc)
	if err != .None || size != want_size {
		return
	}

	val, n, derr := varint.decode_ileb128(buf[:size])
	testing.expectf(t, val == value && n == size && derr == .None, "decode_ileb128(%02x): got %v, %v, %v, want %v", buf[:size], val, n, derr, value, loc = loc)

	val, n, derr = decode_ileb_bytewise(buf[:size])
	testing.expectf(t, val == value && n == size && derr == .None, "decode_ileb128 byte at a time (%02x): got %v, %v, %v, want %v", buf[:size], val, n, derr, value, loc = loc)

	for k in 0..<size {
		val, n, derr = varint.decode_ileb128(buf[:k])
		testing.expectf(t, val == 0 && n == 0 && derr == .Buffer_Too_Small, "decode_ileb128(%02x) truncated: got %v, %v, %v", buf[:k], val, n, derr, loc = loc)
	}

	short: [varint.LEB128_MAX_BYTES]u8
	n, err = varint.encode_ileb128(short[:size - 1], value)
	testing.expectf(t, n == 0 && err == .Buffer_Too_Small, "encode_ileb128(%v) into %v bytes: got %v, %v", value, size - 1, n, err, loc = loc)
}

@(test)
uleb128_every_7_bit_boundary :: proc(t: ^testing.T) {
	for k in 0..<128 {
		check_uleb_round_trip(t, u128(1) << uint(k), (k + 7) / 7)
	}
	for k in 0..=128 {
		value := max(u128) if k == 128 else u128(1) << uint(k) - 1
		check_uleb_round_trip(t, value, max(1, (k + 6) / 7))
	}
}

@(test)
ileb128_every_7_bit_boundary :: proc(t: ^testing.T) {
	for k in 0..<127 {
		check_ileb_round_trip(t, i128(1) << uint(k), (k + 1) / 7 + 1)
		check_ileb_round_trip(t, -(i128(1) << uint(k)) - 1, (k + 1) / 7 + 1)
	}
	for k in 0..<128 {
		value := max(i128) if k == 127 else i128(1) << uint(k) - 1
		check_ileb_round_trip(t, value, (k + 7) / 7)
	}
	for k in 0..<128 {
		value := min(i128) if k == 127 else -(i128(1) << uint(k))
		check_ileb_round_trip(t, value, (k + 7) / 7)
	}
}

@(test)
uleb128_19th_byte_limit :: proc(t: ^testing.T) {
	buf: [varint.LEB128_MAX_BYTES + 1]u8
	for fill in ([]u8{0x80, 0xff}) {
		for &b in buf[:varint.LEB128_MAX_BYTES - 1] {
			b = fill
		}
		low := u128(0) if fill == 0x80 else u128(1) << 126 - 1
		for last in 0..<256 {
			buf[varint.LEB128_MAX_BYTES - 1] = u8(last)
			input := buf[:varint.LEB128_MAX_BYTES]

			want_val:  u128
			want_size: int
			want_err := varint.Error.Value_Too_Large
			if last <= 0x03 {
				want_val, want_size, want_err = low | u128(last) << 126, varint.LEB128_MAX_BYTES, .None
			}

			val, size, err := varint.decode_uleb128(input)
			testing.expectf(t, val == want_val && size == want_size && err == want_err,
				"decode_uleb128(%02x): got %v, %v, %v, want %v, %v, %v", input, val, size, err, want_val, want_size, want_err)

			val, size, err = decode_uleb_bytewise(input)
			testing.expectf(t, val == want_val && size == want_size && err == want_err,
				"decode_uleb128 byte at a time (%02x): got %v, %v, %v, want %v, %v, %v", input, val, size, err, want_val, want_size, want_err)
		}
	}
}

@(test)
leb128_longer_than_max_bytes :: proc(t: ^testing.T) {
	buf: [varint.LEB128_MAX_BYTES + 1]u8
	for &b in buf[:varint.LEB128_MAX_BYTES] {
		b = 0x80
	}

	uval, usize, uerr := varint.decode_uleb128(buf[:])
	testing.expectf(t, uval == 0 && usize == 0 && uerr == .Value_Too_Large, "decode_uleb128(%02x): got %v, %v, %v", buf, uval, usize, uerr)
	uval, usize, uerr = decode_uleb_bytewise(buf[:])
	testing.expectf(t, uval == 0 && usize == 0 && uerr == .Value_Too_Large, "decode_uleb128 byte at a time (%02x): got %v, %v, %v", buf, uval, usize, uerr)

	ival, isize, ierr := varint.decode_ileb128(buf[:])
	testing.expectf(t, ival == 0 && isize == 0 && ierr == .Value_Too_Large, "decode_ileb128(%02x): got %v, %v, %v", buf, ival, isize, ierr)
	ival, isize, ierr = decode_ileb_bytewise(buf[:])
	testing.expectf(t, ival == 0 && isize == 0 && ierr == .Value_Too_Large, "decode_ileb128 byte at a time (%02x): got %v, %v, %v", buf, ival, isize, ierr)

	uval, usize, uerr = varint.decode_uleb128(buf[:varint.LEB128_MAX_BYTES])
	testing.expectf(t, uval == 0 && usize == 0 && uerr == .Value_Too_Large, "decode_uleb128 of 19 continuation bytes: got %v, %v, %v", uval, usize, uerr)
	ival, isize, ierr = varint.decode_ileb128(buf[:varint.LEB128_MAX_BYTES])
	testing.expectf(t, ival == 0 && isize == 0 && ierr == .Value_Too_Large, "decode_ileb128 of 19 continuation bytes: got %v, %v, %v", ival, isize, ierr)

	for offset in varint.LEB128_MAX_BYTES..=varint.LEB128_MAX_BYTES + 1 {
		uval, usize, uerr = varint.decode_uleb128(u8(0x00), offset, 0)
		testing.expectf(t, uval == 0 && usize == 0 && uerr == .Value_Too_Large, "decode_uleb128_byte(0x00, %v, 0): got %v, %v, %v", offset, uval, usize, uerr)
		ival, isize, ierr = varint.decode_ileb128(u8(0x00), offset, 0)
		testing.expectf(t, ival == 0 && isize == 0 && ierr == .Value_Too_Large, "decode_ileb128_byte(0x00, %v, 0): got %v, %v, %v", offset, ival, isize, ierr)
	}
}

Non_Minimal_Vector :: struct {
	encoded:  []u8,
	unsigned: u128,
	signed:   i128,
}

Non_Minimal_Vectors :: []Non_Minimal_Vector{
	{[]u8{0x80, 0x00},       0,      0},
	{[]u8{0x80, 0x80, 0x00}, 0,      0},
	{[]u8{0xff, 0x00},       127,    127},
	{[]u8{0xff, 0x7f},       0x3fff, -1},
	{[]u8{0xc0, 0x7f},       0x3fc0, -64},
	{[]u8{0x81, 0x80, 0x00}, 1,      1},
}

@(test)
leb128_non_minimal_encodings :: proc(t: ^testing.T) {
	for v in Non_Minimal_Vectors {
		uval, usize, uerr := varint.decode_uleb128(v.encoded)
		testing.expectf(t, uval == v.unsigned && usize == len(v.encoded) && uerr == .None, "decode_uleb128(%02x): got %v, %v, %v, want %v", v.encoded, uval, usize, uerr, v.unsigned)

		ival, isize, ierr := varint.decode_ileb128(v.encoded)
		testing.expectf(t, ival == v.signed && isize == len(v.encoded) && ierr == .None, "decode_ileb128(%02x): got %v, %v, %v, want %v", v.encoded, ival, isize, ierr, v.signed)
	}
}

@(test)
leb128_stops_at_terminator :: proc(t: ^testing.T) {
	input := []u8{0xe5, 0x8e, 0x26, 0xff, 0xff}
	uval, usize, uerr := varint.decode_uleb128(input)
	testing.expectf(t, uval == 624485 && usize == 3 && uerr == .None, "decode_uleb128(%02x): got %v, %v, %v", input, uval, usize, uerr)

	signed := []u8{0xc0, 0xbb, 0x78, 0x80}
	ival, isize, ierr := varint.decode_ileb128(signed)
	testing.expectf(t, ival == -123456 && isize == 3 && ierr == .None, "decode_ileb128(%02x): got %v, %v, %v", signed, ival, isize, ierr)
}

@(test)
leb128_encode_empty_buffer :: proc(t: ^testing.T) {
	usize, uerr := varint.encode_uleb128(nil, 0)
	testing.expectf(t, usize == 0 && uerr == .Buffer_Too_Small, "encode_uleb128(nil, 0): got %v, %v", usize, uerr)
	isize, ierr := varint.encode_ileb128(nil, 0)
	testing.expectf(t, isize == 0 && ierr == .Buffer_Too_Small, "encode_ileb128(nil, 0): got %v, %v", isize, ierr)
}

@(test)
leb128_doc_example :: proc(t: ^testing.T) {
	buf: [varint.LEB128_MAX_BYTES]u8

	value := u128(42)

	encode_size, encode_err := varint.encode_uleb128(buf[:], value)
	testing.expect(t, encode_size == 1 && encode_err == .None)

	decoded_val, decode_size, decode_err := varint.decode_uleb128(buf[:])
	testing.expect(t, decoded_val == value && decode_size == encode_size && decode_err == .None)
}
