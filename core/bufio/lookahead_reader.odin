package bufio

import "core:io"

// Lookahead_Reader provides io lookahead.
// This is useful for tokenizers/parsers.
// Lookahead_Reader is similar to bufio.Reader, but unlike bufio.Reader, Lookahead_Reader's buffer size
// will EXACTLY match the specified size, whereas bufio.Reader's buffer size may differ from the specified size.
// This makes sure that the buffer will not be accidentally read beyond the expected size.
Lookahead_Reader :: struct {
	r:   io.Reader,
	buf: []byte,
	n:   int,
}

lookahead_reader_init :: proc(lr: ^Lookahead_Reader, r: io.Reader, buf: []byte) -> ^Lookahead_Reader {
	lr.r = r
	lr.buf = buf
	lr.n = 0
	return lr
}

lookahead_reader_buffer :: proc(lr: ^Lookahead_Reader) -> []byte {
	return lr.buf[:lr.n]
}


// lookahead_reader_peek returns a slice of the Lookahead_Reader which holds n bytes
// If the Lookahead_Reader cannot hold enough bytes, it will read from the underlying reader to populate the rest.
// NOTE: The returned buffer is not a copy of the underlying buffer
lookahead_reader_peek :: proc(lr: ^Lookahead_Reader, n: int) -> ([]byte, io.Error) {
	switch {
	case n < 0:
		return nil, .Negative_Read
	case n > len(lr.buf):
		return nil, .Buffer_Full
	}

	n := n
	err: io.Error
	read_count: int

	if lr.n < n {
		read_count, err = io.read_at_least(lr.r, lr.buf[lr.n:], n-lr.n)
		if err == .Unexpected_EOF {
			err = .EOF
		}
	}

	lr.n += read_count

	if n > lr.n {
		n = lr.n
	}
	return lr.buf[:n], err
}

// lookahead_reader_peek_all returns a slice of the Lookahead_Reader populating the full buffer
// If the Lookahead_Reader cannot hold enough bytes, it will read from the underlying reader to populate the rest.
// NOTE: The returned buffer is not a copy of the underlying buffer
lookahead_reader_peek_all :: proc(lr: ^Lookahead_Reader) -> ([]byte, io.Error) {
	return lookahead_reader_peek(lr, len(lr.buf))
}


// lookahead_reader_consume drops the first n populated bytes from the Lookahead_Reader.
lookahead_reader_consume :: proc(lr: ^Lookahead_Reader, n: int) -> io.Error {
	switch {
	case n == 0:
		return nil
	case n < 0:
		return .Negative_Read
	case lr.n < n:
		return .Short_Buffer
	}
	copy(lr.buf, lr.buf[n:lr.n])
	lr.n -= n
	return nil
}

lookahead_reader_consume_all :: proc(lr: ^Lookahead_Reader) -> io.Error {
	return lookahead_reader_consume(lr, lr.n)
}
