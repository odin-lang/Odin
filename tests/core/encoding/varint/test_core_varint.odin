package test_core_varint

import "core:encoding/varint"
import "core:testing"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:math/rand"

TEST_count := 0
TEST_fail  := 0

RANDOM_TESTS :: 100

when ODIN_TEST {
	expect  :: testing.expect
	log     :: testing.log
} else {
	expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.printf("[%v] %v\n", loc, message)
			return
		}
	}
	log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

main :: proc() {
	t := testing.T{}

	test_leb128(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

@(test)
test_leb128 :: proc(t: ^testing.T) {
	buf: [varint.LEB128_MAX_BYTES]u8

	for vector in ULEB_Vectors {
		val, size, err := varint.decode_uleb128(vector.encoded)

		msg := fmt.tprintf("Expected %02x to decode to %v consuming %v bytes, got %v and %v", vector.encoded, vector.value, vector.size, val, size)
		expect(t, size == vector.size && val == vector.value, msg)

		msg  = fmt.tprintf("Expected decoder to return error %v, got %v", vector.error, err)
		expect(t, err == vector.error, msg)

		if err == .None { // Try to roundtrip
			size, err = varint.encode_uleb128(buf[:], vector.value)

			msg = fmt.tprintf("Expected %v to encode to %02x, got %02x", vector.value, vector.encoded, buf[:size])
			expect(t, size == vector.size && slice.simple_equal(vector.encoded, buf[:size]), msg)
		}
	}

	for vector in ILEB_Vectors {
		val, size, err := varint.decode_ileb128(vector.encoded)

		msg := fmt.tprintf("Expected %02x to decode to %v consuming %v bytes, got %v and %v", vector.encoded, vector.value, vector.size, val, size)
		expect(t, size == vector.size && val == vector.value, msg)

		msg  = fmt.tprintf("Expected decoder to return error %v, got %v", vector.error, err)
		expect(t, err == vector.error, msg)

		if err == .None { // Try to roundtrip
			size, err = varint.encode_ileb128(buf[:], vector.value)

			msg = fmt.tprintf("Expected %v to encode to %02x, got %02x", vector.value, vector.encoded, buf[:size])
			expect(t, size == vector.size && slice.simple_equal(vector.encoded, buf[:size]), msg)
		}
	}

	for num_bytes in 1..uint(16) {
		for _ in 0..RANDOM_TESTS {
			unsigned, signed := get_random(num_bytes)

			{
				encode_size, encode_err := varint.encode_uleb128(buf[:], unsigned)
				msg := fmt.tprintf("%v failed to encode as an unsigned LEB128 value, got %v", unsigned, encode_err)
				expect(t, encode_err == .None, msg)

				decoded, decode_size, decode_err := varint.decode_uleb128(buf[:])
				msg = fmt.tprintf("Expected %02x to decode as %v, got %v", buf[:encode_size], unsigned, decoded)
				expect(t, decode_err == .None && decode_size == encode_size && decoded == unsigned, msg)
			}

			{
				encode_size, encode_err := varint.encode_ileb128(buf[:], signed)
				msg := fmt.tprintf("%v failed to encode as a signed LEB128 value, got %v", signed, encode_err)
				expect(t, encode_err == .None, msg)

				decoded, decode_size, decode_err := varint.decode_ileb128(buf[:])
				msg = fmt.tprintf("Expected %02x to decode as %v, got %v, err: %v", buf[:encode_size], signed, decoded, decode_err)
				expect(t, decode_err == .None && decode_size == encode_size && decoded == signed, msg)
			}
		}
	}
}

get_random :: proc(byte_count: uint) -> (u: u128, i: i128) {
	assert(byte_count >= 0 && byte_count <= size_of(u128))

	for _ in 1..byte_count {
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