package bufio

import "core:io"
import "core:mem"
import "core:unicode/utf8"
import "core:bytes"

// Reader is a buffered wrapper for an io.Reader
Reader :: struct {
	buf:            []byte,
	buf_allocator:  mem.Allocator,

	rd:             io.Reader, // reader
	r, w:           int, // read and write positions for buf

	err:            io.Error,

	last_byte:      int, // last byte read, invalid is -1
	last_rune_size: int, // size of last rune read, invalid is -1

	max_consecutive_empty_reads: int,
}


DEFAULT_BUF_SIZE :: 4096

@(private)
MIN_READ_BUFFER_SIZE :: 16
@(private)
DEFAULT_MAX_CONSECUTIVE_EMPTY_READS :: 128

reader_init :: proc(b: ^Reader, rd: io.Reader, size: int = DEFAULT_BUF_SIZE, allocator := context.allocator) {
	size := size
	size = max(size, MIN_READ_BUFFER_SIZE)
	reader_reset(b, rd)
	b.buf_allocator = allocator
	b.buf = make([]byte, size, allocator)
}

reader_init_with_buf :: proc(b: ^Reader, rd: io.Reader, buf: []byte) {
	reader_reset(b, rd)
	b.buf_allocator = {}
	b.buf = buf
}

// reader_destroy destroys the underlying buffer with its associated allocator IFF that allocator has been set
reader_destroy :: proc(b: ^Reader) {
	delete(b.buf, b.buf_allocator)
	b^ = {}
}

reader_size :: proc(b: ^Reader) -> int {
	return len(b.buf)
}

reader_reset :: proc(b: ^Reader, r: io.Reader) {
	b.rd = r
	b.r, b.w = 0, 0
	b.err = nil
	b.last_byte      = -1
	b.last_rune_size = -1
}

@(private)
_reader_read_new_chunk :: proc(b: ^Reader) -> io.Error {
	if b.r > 0 {
		copy(b.buf, b.buf[b.r:b.w])
		b.w -= b.r
		b.r = 0
	}

	if b.w >= len(b.buf) {
		return .Buffer_Full
	}

	if b.max_consecutive_empty_reads <= 0 {
		b.max_consecutive_empty_reads = DEFAULT_MAX_CONSECUTIVE_EMPTY_READS
	}

	// read new data, and try a limited number of times
	for i := b.max_consecutive_empty_reads; i > 0; i -= 1 {
		n, err := io.read(b.rd, b.buf[b.w:])
		if n < 0 {
			return err if err != nil else .Negative_Read
		}
		b.w += n
		if err != nil {
			b.err = err
			return nil
		}
		if n > 0 {
			return nil
		}
	}
	b.err = .No_Progress
	return nil
}

@(private)
_reader_consume_err :: proc(b: ^Reader) -> io.Error {
	err := b.err
	b.err = nil
	return err
}

// reader_peek returns the next n bytes without advancing the reader
// The bytes stop being valid on the next read call
// If reader_peek returns fewer than n bytes, it also return an error
// explaining why the read is short
// The error will be .Buffer_Full if n is larger than the internal buffer size
reader_peek :: proc(b: ^Reader, n: int) -> (data: []byte, err: io.Error) {
	n := n

	if n < 0 {
		return nil, .Negative_Count
	}
	b.last_byte = -1
	b.last_rune_size = -1

	for b.w-b.r < n && b.w-b.r < len(b.buf) && b.err == nil {
		_reader_read_new_chunk(b) or_return
	}

	if n > len(b.buf) {
		return b.buf[b.r : b.w], .Buffer_Full
	}

	if available := b.w - b.r; available < n {
		n = available
		err = _reader_consume_err(b)
		if err == nil {
			err = .Buffer_Full
		}
	}

	return b.buf[b.r : b.r+n], err
}

// reader_buffered returns the number of bytes that can be read from the current buffer
reader_buffered :: proc(b: ^Reader) -> int {
	return b.w - b.r
}

// reader_discard skips the next n bytes, and returns the number of bytes that were discarded
reader_discard :: proc(b: ^Reader, n: int) -> (discarded: int, err: io.Error) {
	if n < 0 {
		return 0, .Negative_Count
	}
	if n == 0 {
		return
	}

	remaining := n
	for {
		skip := reader_buffered(b)
		if skip == 0 {
			_reader_read_new_chunk(b) or_return
			skip = reader_buffered(b)
		}
		skip = min(skip, remaining)
		b.r += skip
		remaining -= skip
		if remaining == 0 {
			return n, nil
		}
		if b.err != nil {
			return n - remaining, _reader_consume_err(b)
		}
	}

	return
}

// reader_read reads data into p
// The bytes are taken from at most one read on the underlying Reader, which means n may be less than len(p)
reader_read :: proc(b: ^Reader, p: []byte) -> (n: int, err: io.Error) {
	n = len(p)
	if n == 0 {
		if reader_buffered(b) > 0 {
			return 0, nil
		}
		return 0, _reader_consume_err(b)
	}
	if b.r == b.w {
		if b.err != nil {
			return 0, _reader_consume_err(b)
		}

		if len(p) >= len(b.buf) {
			n, b.err = io.read(b.rd, p)
			if n < 0 {
				return 0, b.err if b.err != nil else .Negative_Read
			}

			if n > 0 {
				b.last_byte = int(p[n-1])
				b.last_rune_size = -1
			}
			return n, _reader_consume_err(b)
		}

		b.r, b.w = 0, 0
		n, b.err = io.read(b.rd, b.buf)
		if n < 0 {
			return 0, b.err if b.err != nil else .Negative_Read
		}
		if n == 0 {
			return 0, _reader_consume_err(b)
		}
		b.w += n
	}

	n = copy(p, b.buf[b.r:b.w])
	b.r += n
	b.last_byte = int(b.buf[b.r-1])
	b.last_rune_size = -1
	return n, nil
}

// reader_read_byte reads and returns a single byte
// If no byte is available, it return an error
reader_read_byte :: proc(b: ^Reader) -> (c: byte, err: io.Error) {
	b.last_rune_size = -1
	for b.r == b.w {
		if b.err != nil {
			return 0, _reader_consume_err(b)
		}
		_reader_read_new_chunk(b) or_return
	}
	c = b.buf[b.r]
	b.r += 1
	b.last_byte = int(c)
	return
}

// reader_unread_byte unreads the last byte. Only the most recently read byte can be unread
reader_unread_byte :: proc(b: ^Reader) -> io.Error {
	if b.last_byte < 0 || b.r == 0 && b.w > 0 {
		return .Invalid_Unread
	}
	if b.r > 0 {
		b.r -= 1
	} else {
		// b.r == 0 && b.w == 0
		b.w = 1
	}
	b.buf[b.r] = byte(b.last_byte)
	b.last_byte = -1
	b.last_rune_size = -1
	return nil
}

// reader_read_rune reads a single UTF-8 encoded unicode character
// and returns the rune and its size in bytes
// If the encoded rune is invalid, it consumes one byte and returns utf8.RUNE_ERROR (U+FFFD) with a size of 1
reader_read_rune :: proc(b: ^Reader) -> (r: rune, size: int, err: io.Error) {
	for b.r+utf8.UTF_MAX > b.w &&
	    !utf8.full_rune(b.buf[b.r:b.w]) &&
	    b.err == nil &&
	    b.w-b.w < len(b.buf) {
		_reader_read_new_chunk(b) or_return
	}

	b.last_rune_size = -1
	if b.r == b.w {
		return 0, 0, _reader_consume_err(b)
	}
	r, size = rune(b.buf[b.r]), 1
	if r >= utf8.RUNE_SELF {
		r, size = utf8.decode_rune(b.buf[b.r : b.w])
	}
	b.r += size
	b.last_byte = int(b.buf[b.r-1])
	b.last_rune_size = size
	return
}

// reader_unread_rune unreads the last rune. Only the most recently read rune can be unread
reader_unread_rune :: proc(b: ^Reader) -> io.Error {
	if b.last_rune_size < 0 || b.r < b.last_rune_size {
		return .Invalid_Unread
	}
	b.r -= b.last_rune_size
	b.last_byte = -1
	b.last_rune_size = -1
	return nil
}

reader_write_to :: proc(b: ^Reader, w: io.Writer) -> (n: i64, err: io.Error) {
	write_buf :: proc(b: ^Reader, w: io.Writer) -> (i64, io.Error) {
		n, err := io.write(w, b.buf[b.r:b.w])
		if n < 0 {
			return 0, err if err != nil else .Negative_Write
		}
		b.r += n
		return i64(n), err
	}

	n = write_buf(b, w) or_return

	m: i64
	if b.w-b.r < len(b.buf) {
		_reader_read_new_chunk(b) or_return
	}

	for b.r < b.w {
		m, err = write_buf(b, w)
		n += m // this needs to be done before returning
		if err != nil {
			return
		}
		_reader_read_new_chunk(b) or_return
	}

	if b.err == .EOF {
		b.err = nil
	}

	err = _reader_consume_err(b)
	return
}



// reader_to_stream converts a Reader into an io.Stream
reader_to_stream :: proc(b: ^Reader) -> (s: io.Stream) {
	s.data = b
	s.procedure = _reader_proc
	return
}



@(private)
_reader_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	b := (^Reader)(stream_data)
	#partial switch mode {
	case .Read:
		return io._i64_err(reader_read(b, p))
	case .Destroy:
		reader_destroy(b)
		return
	case .Query:
		return io.query_utility({.Read, .Destroy, .Query})
	}
	return 0, .Empty
}

//
// Utility procedures
//


// reader_read_slice reads until the first occurrence of delim from the reader
// It returns a slice pointing at the bytes in the buffer
// The bytes stop being valid at the next read
// If reader_read_slice encounters an error before finding a delimiter
// reader_read_slice fails with error .Buffer_Full if the buffer fills without a delim
// Because the data returned from reader_read_slice will be overwritten on the
// next IO operation, reader_read_bytes or reader_read_string is usually preferred
//
// reader_read_slice returns err != nil if and only if line does not end in delim
//
reader_read_slice :: proc(b: ^Reader, delim: byte) -> (line: []byte, err: io.Error) {
	s := 0
	for {
		if i := bytes.index_byte(b.buf[b.r+s : b.w], delim); i >= 0 {
			i += s
			line = b.buf[b.r:][:i+1]
			b.r += i + 1
			break
		}

		if b.err != nil {
			line = b.buf[b.r : b.w]
			b.r = b.w
			err = _reader_consume_err(b)
			break
		}

		if reader_buffered(b) >= len(b.buf) {
			b.r = b.w
			line = b.buf
			err = .Buffer_Full
			break
		}

		s = b.w - b.r

		_reader_read_new_chunk(b) or_break
	}

	if i := len(line)-1; i >= 0 {
		b.last_byte = int(line[i])
		b.last_rune_size = -1
	}

	return
}

// reader_read_bytes reads until the first occurrence of delim from the Reader
// It returns an allocated slice containing the data up to and including the delimiter
reader_read_bytes :: proc(b: ^Reader, delim: byte, allocator := context.allocator) -> (buf: []byte, err: io.Error) {
	full: [dynamic]byte
	full.allocator = allocator

	frag: []byte
	for {
		e: io.Error
		frag, e = reader_read_slice(b, delim)
		if e == nil {
			break
		}
		if e != .Buffer_Full {
			err = e
			break
		}

		append(&full, ..frag)
	}
	append(&full, ..frag)
	return full[:], err
}

// reader_read_string reads until the first occurrence of delim from the Reader
// It returns an allocated string containing the data up to and including the delimiter
reader_read_string :: proc(b: ^Reader, delim: byte, allocator := context.allocator) -> (string, io.Error) {
	buf, err := reader_read_bytes(b, delim, allocator)
	return string(buf), err
}
