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