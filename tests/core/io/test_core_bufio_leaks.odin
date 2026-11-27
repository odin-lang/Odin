package test_core_io
import "core:bufio"
import "core:io"
import "core:strings"
import "core:testing"

@(test)
test_leak_bufio_reader_empty_buffer :: proc(t: ^testing.T) {
	sr: strings.Reader
	r: bufio.Reader
	bufio.reader_init_with_buf(&r, strings.to_reader(&sr, "abc"), nil)

	p: [4]byte
	n, err := bufio.reader_read(&r, p[:2])
	testing.expect_value(t, err, nil)
	testing.expect_value(t, n, 2)
	testing.expect_value(t, string(p[:n]), "ab")
	testing.expect_value(t, bufio.reader_unread_byte(&r), io.Error.Invalid_Unread)

	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	written, write_err := bufio.reader_write_to(&r, strings.to_writer(&sb))
	testing.expect_value(t, write_err, io.Error.Buffer_Full)
	testing.expect_value(t, written, 0)
	testing.expect_value(t, strings.to_string(sb), "")

	n, err = bufio.reader_read(&r, p[:])
	testing.expect_value(t, err, nil)
	testing.expect_value(t, string(p[:n]), "c")
}
