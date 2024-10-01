package test_core_varint

import "core:encoding/varint"
import "core:testing"
import "core:slice"
import "core:math/rand"

NUM_RANDOM_TESTS_PER_BYTE_SIZE :: 10_000

@(test)
test_uleb :: proc(t: ^testing.T) {
	buf: [varint.LEB128_MAX_BYTES]u8

	for vector in ULEB_Vectors {
		val, size, err := varint.decode_uleb128(vector.encoded)

		testing.expectf(t, size == vector.size && val == vector.value, "Expected %02x to decode to %v consuming %v bytes, got %v and %v", vector.encoded, vector.value, vector.size, val, size)
		testing.expectf(t, err == vector.error, "Expected decoder to return error %v, got %v for vector %v", vector.error, err, vector)

		if err == .None { // Try to roundtrip
			size, err = varint.encode_uleb128(buf[:], vector.value)

			testing.expectf(t, size == vector.size && slice.simple_equal(vector.encoded, buf[:size]), "Expected %v to encode to %02x, got %02x", vector.value, vector.encoded, buf[:size])
		}
	}
}

@(test)
test_ileb :: proc(t: ^testing.T) {
	buf: [varint.LEB128_MAX_BYTES]u8

	for vector in ILEB_Vectors {
		val, size, err := varint.decode_ileb128(vector.encoded)

		testing.expectf(t, size == vector.size && val == vector.value, "Expected %02x to decode to %v consuming %v bytes, got %v and %v", vector.encoded, vector.value, vector.size, val, size)
		testing.expectf(t, err == vector.error, "Expected decoder to return error %v, got %v", vector.error, err)

		if err == .None { // Try to roundtrip
			size, err = varint.encode_ileb128(buf[:], vector.value)

			testing.expectf(t, size == vector.size && slice.simple_equal(vector.encoded, buf[:size]), "Expected %v to encode to %02x, got %02x", vector.value, vector.encoded, buf[:size])
		}
	}
}

@(test)
test_random :: proc(t: ^testing.T) {
	buf: [varint.LEB128_MAX_BYTES]u8

	for num_bytes in 1..=uint(16) {
		for _ in 0..=NUM_RANDOM_TESTS_PER_BYTE_SIZE {
			unsigned, signed := get_random(num_bytes)
			{
				encode_size, encode_err := varint.encode_uleb128(buf[:], unsigned)
				testing.expectf(t, encode_err == .None, "%v failed to encode as an unsigned LEB128 value, got %v", unsigned, encode_err)

				decoded, decode_size, decode_err := varint.decode_uleb128(buf[:])
				testing.expectf(t, decode_err == .None && decode_size == encode_size && decoded == unsigned, "Expected %02x to decode as %v, got %v", buf[:encode_size], unsigned, decoded)
			}

			{
				encode_size, encode_err := varint.encode_ileb128(buf[:], signed)
				testing.expectf(t, encode_err == .None, "%v failed to encode as a signed LEB128 value, got %v", signed, encode_err)

				decoded, decode_size, decode_err := varint.decode_ileb128(buf[:])
				testing.expectf(t, decode_err == .None && decode_size == encode_size && decoded == signed, "Expected %02x to decode as %v, got %v, err: %v", buf[:encode_size], signed, decoded, decode_err)
			}
		}
	}
}

@(private)
get_random :: proc(byte_count: uint) -> (u: u128, i: i128) {
	assert(byte_count >= 0 && byte_count <= size_of(u128))

	for _ in 1..=byte_count {
		u <<= 8
		u |= u128(rand.uint32() & 0xff)
	}

	bias := i128(1 << (byte_count * 7)) - 1
	i     = i128(u) - bias

	return
}

ULEB_Test_Vector :: struct {
	encoded: []u8,
	value:   u128,
	size:    int,
	error:   varint.Error,
}

ULEB_Vectors :: []ULEB_Test_Vector{
	{ []u8{0x00},             0,         1, .None },
	{ []u8{0x7f},             127,       1, .None },
	{ []u8{0xE5, 0x8E, 0x26}, 624485,    3, .None },
	{ []u8{0x80},             0,         0, .Buffer_Too_Small },
	{ []u8{},                 0,         0, .Buffer_Too_Small },

	{ []u8{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x03}, max(u128), 19, .None },
}

ILEB_Test_Vector :: struct {
	encoded: []u8,
	value:   i128,
	size:    int,
	error:   varint.Error,
}

ILEB_Vectors :: []ILEB_Test_Vector{
	{ []u8{0x00},             0,       1, .None },
	{ []u8{0x3f},             63,      1, .None },
	{ []u8{0x40},             -64,     1, .None },
	{ []u8{0xC0, 0xBB, 0x78}, -123456, 3, .None },
	{ []u8{},                 0,       0, .Buffer_Too_Small },

	{ []u8{0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x7e}, min(i128), 19, .None },
	{ []u8{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01}, max(i128), 19, .None },
}