package test_core_bytes

import "core:bytes"
import "core:io"
import "core:slice"
import "core:strings"
import "core:testing"

@private SIMD_SCAN_WIDTH :: 8 * size_of(uintptr)

@test
test_index_byte_sanity :: proc(t: ^testing.T) {
	// We must be able to find the byte at the correct index.
	data := make([]u8, 2 * SIMD_SCAN_WIDTH)
	defer delete(data)
	slice.fill(data, '-')

	INDEX_MAX :: SIMD_SCAN_WIDTH - 1

	for offset in 0..<INDEX_MAX {
		for idx in 0..<INDEX_MAX {
			sub := data[offset:]
			sub[idx] = 'o'
			if !testing.expect_value(t, bytes.index_byte(sub, 'o'), idx) {
				return
			}
			if !testing.expect_value(t, bytes.last_index_byte(sub, 'o'), idx) {
				return
			}
			sub[idx] = '-'
		}
	}
}

@test
test_index_byte_empty :: proc(t: ^testing.T) {
	a: [1]u8
	testing.expect_value(t, bytes.index_byte(a[0:0], 'o'), -1)
	testing.expect_value(t, bytes.last_index_byte(a[0:0], 'o'), -1)
}

@test
test_index_byte_multiple_hits :: proc(t: ^testing.T) {
	for n in 5..<256 {
		data := make([]u8, n)
		defer delete(data)
		slice.fill(data, '-')

		data[n-1] = 'o'
		data[n-3] = 'o'
		data[n-5] = 'o'

		// Find the first one.
		if !testing.expect_value(t, bytes.index_byte(data, 'o'), n-5) {
			return
		}

		// Find the last one.
		if !testing.expect_value(t, bytes.last_index_byte(data, 'o'), n-1) {
			return
		}
	}
}

@test
test_index_byte_zero :: proc(t: ^testing.T) {
	// This test protects against false positives in uninitialized memory.
	for n in 1..<256 {
		data := make([]u8, n + 64)
		defer delete(data)
		slice.fill(data, '-')

		// Positive hit.
		data[n-1] = 0
		if !testing.expect_value(t, bytes.index_byte(data[:n], 0), n-1) {
			return
		}
		if !testing.expect_value(t, bytes.last_index_byte(data[:n], 0), n-1) {
			return
		}

		// Test for false positives.
		data[n-1] = '-'
		if !testing.expect_value(t, bytes.index_byte(data[:n], 0), -1) {
			return
		}
		if !testing.expect_value(t, bytes.last_index_byte(data[:n], 0), -1) {
			return
		}
	}
}

@test
test_last_index_byte_bounds :: proc(t: ^testing.T) {
	input := "helloworld.odin."
	assert(len(input) == 16)
	idx := bytes.last_index_byte(transmute([]byte)(input[:len(input)-1]), '.')
	testing.expect_value(t, idx, 10)
}

@test
test_buffer_read_from :: proc(t: ^testing.T) {
	r: strings.Reader
	b: bytes.Buffer
	defer bytes.buffer_destroy(&b)

	n, err := bytes.buffer_read_from(&b, strings.to_reader(&r, "hello"))
	testing.expect_value(t, n, 5)
	testing.expect_value(t, err, io.Error.None)
	testing.expect_value(t, bytes.buffer_to_string(&b), "hello")

	long := strings.repeat("0123456789", 300)
	defer delete(long)
	n, err = bytes.buffer_read_from(&b, strings.to_reader(&r, long))
	testing.expect_value(t, n, i64(len(long)))
	testing.expect_value(t, err, io.Error.None)
	testing.expect_value(t, bytes.buffer_length(&b), 5 + len(long))
	contents := bytes.buffer_to_string(&b)
	testing.expect(t, contents[:5] == "hello" && contents[5:] == long, "contents read from the reader were not preserved")
}

@test
test_buffer_write_at :: proc(t: ^testing.T) {
	B :: proc(s: string) -> []byte { return transmute([]byte)s }

	b: bytes.Buffer
	defer bytes.buffer_destroy(&b)
	bytes.buffer_write_string(&b, "0123456789")

	// overwriting inside the contents keeps the len
	n, err := bytes.buffer_write_at(&b, B("ab"), 0)
	testing.expect_value(t, n, 2)
	testing.expect_value(t, err, io.Error.None)
	testing.expect_value(t, bytes.buffer_to_string(&b), "ab23456789")

	// straddling the end extends the contents to exactly offset + len(p)
	n, err = bytes.buffer_write_at(&b, B("XYZ"), 8)
	testing.expect_value(t, n, 3)
	testing.expect_value(t, err, io.Error.None)
	testing.expect_value(t, bytes.buffer_to_string(&b), "ab234567XYZ")

	// past the end, the gap reads back as zero
	n, err = bytes.buffer_write_at(&b, B("!"), 14)
	testing.expect_value(t, n, 1)
	testing.expect_value(t, err, io.Error.None)
	testing.expect_value(t, bytes.buffer_to_string(&b), "ab234567XYZ\x00\x00\x00!")

	n, err = bytes.buffer_write_at(&b, B("?"), -1)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, io.Error.Invalid_Offset)

	// consumed bytes don't become readable again
	c: bytes.Buffer
	defer bytes.buffer_destroy(&c)
	bytes.buffer_init_allocator(&c, 0, 64)
	for i in 0..<60 {
		bytes.buffer_write_byte(&c, 'a' + byte(i % 26))
	}
	consumed: [58]byte
	bytes.buffer_read(&c, consumed[:])
	bytes.buffer_write_at(&c, B("XY"), 10)
	testing.expect_value(t, bytes.buffer_to_string(&c), "gh")
	bytes.buffer_write_at(&c, B("XY"), 62)
	testing.expect_value(t, bytes.buffer_to_string(&c), "gh\x00\x00XY")
}
