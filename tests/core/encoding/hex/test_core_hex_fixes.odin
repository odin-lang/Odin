package test_core_hex

import "base:runtime"
import "core:encoding/hex"
import "core:io"
import "core:strings"
import "core:testing"

@(private="file")
Short_Writer :: struct {
	sb:       strings.Builder,
	per_call: int,
	limit:    int,
}

@(private="file")
short_writer_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	w := (^Short_Writer)(stream_data)
	#partial switch mode {
	case .Write:
		k := min(len(p), w.per_call)
		if w.limit >= 0 {
			room := w.limit - strings.builder_len(w.sb)
			if room <= 0 {
				return 0, .EOF
			}
			k = min(k, room)
		}
		strings.write_bytes(&w.sb, p[:k])
		return i64(k), nil
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Unsupported
}

@(private="file")
encode_with :: proc(w: ^Short_Writer, src: []byte, upper: bool) -> io.Error {
	strings.builder_reset(&w.sb)
	writer := io.Writer{procedure = short_writer_proc, data = w}
	if upper {
		return hex.encode_upper_into_writer(writer, src)
	}
	return hex.encode_into_writer(writer, src)
}

@(test)
test_fix_short_writes :: proc(t: ^testing.T) {
	src: [300]byte
	for &b, i in src {
		b = byte(i * 7 + 3)
	}
	lower := hex.encode(src[:])
	defer delete(lower)
	upper := hex.encode_upper(src[:])
	defer delete(upper)

	w := Short_Writer{limit = -1}
	strings.builder_init(&w.sb)
	defer strings.builder_destroy(&w.sb)
	for per_call in ([]int{1, 2, 3, 255, 256, 257, 1000}) {
		w.per_call = per_call
		err := encode_with(&w, src[:], false)
		testing.expectf(t, err == nil && strings.to_string(w.sb) == string(lower), "encode_into_writer, %d bytes per write: %v", per_call, err)
		err = encode_with(&w, src[:], true)
		testing.expectf(t, err == nil && strings.to_string(w.sb) == string(upper), "encode_upper_into_writer, %d bytes per write: %v", per_call, err)
	}
}

@(test)
test_fix_writer_error :: proc(t: ^testing.T) {
	src := []byte{0xab, 0xcd, 0xef}
	lower := "abcdef"
	upper := "ABCDEF"
	w := Short_Writer{per_call = 1}
	strings.builder_init(&w.sb)
	defer strings.builder_destroy(&w.sb)
	for limit in 0..<len(lower) {
		w.limit = limit
		err := encode_with(&w, src, false)
		testing.expectf(t, err == .EOF && strings.to_string(w.sb) == lower[:limit], "encode_into_writer, limit %d: %q, %v", limit, strings.to_string(w.sb), err)
		err = encode_with(&w, src, true)
		testing.expectf(t, err == .EOF && strings.to_string(w.sb) == upper[:limit], "encode_upper_into_writer, limit %d: %q, %v", limit, strings.to_string(w.sb), err)
	}
}

@(test)
test_fix_encode_length_overflow :: proc(t: ^testing.T) {
	huge := transmute([]byte)runtime.Raw_Slice{data = nil, len = max(int) / 2 + 1}
	res, err := hex.encode(huge)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect(t, res == nil)
	res, err = hex.encode_upper(huge)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect(t, res == nil)
}

@(test)
test_fix_decode_errors :: proc(t: ^testing.T) {
	cases := []struct {
		src: string,
		err: hex.Error,
	}{
		{"",     nil},
		{"aB",   nil},
		{"a",    .Invalid_Length},
		{"abc",  .Invalid_Length},
		{"zzz",  .Invalid_Length},
		{"zz",   .Invalid_Character},
		{"0g",   .Invalid_Character},
		{"g0",   .Invalid_Character},
		{"abcz", .Invalid_Character},
		{"ab/0", .Invalid_Character},
	}
	for c in cases {
		decoded, err := hex.decode(transmute([]byte)c.src)
		testing.expectf(t, err == c.err, "decode(%q): %v, want %v", c.src, err, c.err)
		if err != nil {
			testing.expectf(t, decoded == nil, "decode(%q) failed but returned %v", c.src, decoded)
		}
		delete(decoded)
	}
}

@(test)
test_fix_decode_allocation_failure :: proc(t: ^testing.T) {
	cases := []struct {
		src: string,
		err: hex.Error,
	}{
		{"",     nil},
		{"abc",  .Invalid_Length},
		{"abcd", .Out_Of_Memory},
		{"zz",   .Out_Of_Memory},
	}
	for c in cases {
		decoded, err := hex.decode(transmute([]byte)c.src, runtime.nil_allocator())
		testing.expectf(t, err == c.err, "decode(%q, nil_allocator): %v, want %v", c.src, err, c.err)
		testing.expectf(t, decoded == nil, "decode(%q, nil_allocator) returned %v", c.src, decoded)
	}
}
