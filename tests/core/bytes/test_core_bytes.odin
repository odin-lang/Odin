package test_core_bytes

import "core:bytes"
import "core:io"
import "core:slice"
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
test_split_multi_mixed_lengths :: proc(t: ^testing.T) {
	// Delimiters of different lengths must all be matched at their own length.
	delims := [][]byte{transmute([]byte)string("::"), transmute([]byte)string(",")}
	s := transmute([]byte)string("a::b,c")
	res := bytes.split_multi(s, delims)
	defer delete(res)
	if testing.expect_value(t, len(res), 3) {
		testing.expect_value(t, string(res[0]), "a")
		testing.expect_value(t, string(res[1]), "b")
		testing.expect_value(t, string(res[2]), "c")
	}

	// Delimiter longer than the shortest one at the very end of the input.
	delims2 := [][]byte{transmute([]byte)string(","), transmute([]byte)string("::")}
	res2 := bytes.split_multi(transmute([]byte)string("a::b"), delims2)
	defer delete(res2)
	if testing.expect_value(t, len(res2), 2) {
		testing.expect_value(t, string(res2[0]), "a")
		testing.expect_value(t, string(res2[1]), "b")
	}
}

@test
test_split_multi_empty :: proc(t: ^testing.T) {
	buf := []byte{'a', ','}
	res := bytes.split_multi(buf[2:], [][]byte{buf[1:]})
	defer delete(res)
	testing.expect_value(t, len(res), 0)

	res2 := bytes.split_multi(buf, [][]byte{buf[:0]})
	defer delete(res2)
	testing.expect_value(t, len(res2), 0)
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

@(private="file")
Hiccup_Reader :: struct {
	data:    []byte,
	pos:     int,
	hiccups: int,
	pending: int,
}

@(private="file")
hiccup_reader_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	h := (^Hiccup_Reader)(stream_data)
	#partial switch mode {
	case .Read:
		if h.pending < h.hiccups {
			h.pending += 1
			return 0, nil
		}
		h.pending = 0
		if h.pos >= len(h.data) {
			return 0, .EOF
		}
		m := copy(p[:min(len(p), 7)], h.data[h.pos:])
		h.pos += m
		return i64(m), nil
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

@test
test_buffer_read_from_stall :: proc(t: ^testing.T) {
	data := "Empty reads between every chunk of this input."
	for hiccups in ([]int{0, 3, 100, 101, max(int)}) {
		h := Hiccup_Reader{data = transmute([]byte)data, hiccups = hiccups}
		b: bytes.Buffer
		defer bytes.buffer_destroy(&b)
		n, err := bytes.buffer_read_from(&b, io.Stream{procedure = hiccup_reader_proc, data = &h})
		if hiccups > 100 {
			testing.expectf(t, n == 0 && err == .No_Progress, "%d hiccups: %d %v", hiccups, n, err)
		} else {
			testing.expectf(t, n == i64(len(data)) && err == nil, "%d hiccups: %d %v", hiccups, n, err)
			testing.expect_value(t, bytes.buffer_to_string(&b), data)
		}
	}
}
