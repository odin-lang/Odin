package test_core_io

import "core:io"
import "core:strings"
import "core:testing"

@(test)
test_stage_writer :: proc(t: ^testing.T) {
	sb := strings.builder_make(context.temp_allocator)
	buf: [8]byte
	s: io.Stage_Writer
	w := io.stage_writer_init(&s, strings.to_writer(&sb), buf[:])

	// Writes stay in the stage until it is full
	io.write_string(w, "abc")
	io.write_string(w, "defgh")
	testing.expect_value(t, strings.to_string(sb), "")

	// A write that does not fit writes the stage out first
	io.write_string(w, "ij")
	testing.expect_value(t, strings.to_string(sb), "abcdefgh")

	// A write larger than the stage goes straight through, after what was staged
	io.write_string(w, "0123456789")
	testing.expect_value(t, strings.to_string(sb), "abcdefghij0123456789")

	io.write_string(w, "xy")
	testing.expect_value(t, io.stage_writer_flush(&s), nil)
	testing.expect_value(t, strings.to_string(sb), "abcdefghij0123456789xy")

	// .Flush writes the stage out too
	io.write_byte(w, 'z')
	io.flush(w)
	testing.expect_value(t, strings.to_string(sb), "abcdefghij0123456789xyz")
	testing.expect_value(t, s.lost, 0)
	testing.expect_value(t, s.err, nil)
}

// A writer that stops accepting keeps a prefix. The rest is counted in `lost`, and its first error is kept.
@(test)
test_stage_writer_short :: proc(t: ^testing.T) {
	backing: [5]byte
	sb := strings.builder_from_bytes(backing[:])
	buf: [4]byte
	s: io.Stage_Writer
	w := io.stage_writer_init(&s, strings.to_writer(&sb), buf[:])

	n, err := io.write_string(w, "abcdefg")
	testing.expect_value(t, n, 7)
	testing.expect_value(t, err, nil)

	io.write_string(w, "hi")
	testing.expect_value(t, io.stage_writer_flush(&s), io.Error.EOF)
	testing.expect_value(t, strings.to_string(sb), "abcde")
	testing.expect_value(t, s.lost, 4)
}
