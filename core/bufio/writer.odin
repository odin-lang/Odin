package bufio

import "core:io"
import "core:mem"
import "core:unicode/utf8"
// import "core:bytes"

// Writer is a buffered wrapper for an io.Writer
Writer :: struct {
	buf:            []byte,
	buf_allocator:  mem.Allocator,

	wr: io.Writer,
	n: int,

	err: io.Error,

	max_consecutive_empty_writes: int,

}

writer_init :: proc(b: ^Writer, wr: io.Writer, size: int = DEFAULT_BUF_SIZE, allocator := context.allocator) {
	size := size
	size = max(size, MIN_READ_BUFFER_SIZE)
	writer_reset(b, wr)
	b.buf_allocator = allocator
	b.buf = make([]byte, size, allocator)
}

writer_init_with_buf :: proc(b: ^Writer, wr: io.Writer, buf: []byte) {
	writer_reset(b, wr)
	b.buf_allocator = {}
	b.buf = buf
}

// writer_destroy destroys the underlying buffer with its associated allocator IFF that allocator has been set
writer_destroy :: proc(b: ^Writer) {
	delete(b.buf, b.buf_allocator)
	b^ = {}
}

// writer_size returns the size of underlying buffer in bytes
writer_size :: proc(b: ^Writer) -> int {
	return len(b.buf)
}

writer_reset :: proc(b: ^Writer, w: io.Writer) {
	b.wr = w
	b.n = 0
	b.err = nil
}


// writer_flush writes any buffered data into the underlying io.Writer
writer_flush :: proc(b: ^Writer) -> io.Error {
	if b.err != nil {
		return b.err
	}
	if b.n == 0 {
		return nil
	}

	n, err := io.write(b.wr, b.buf[0:b.n])
	if n < b.n && err == nil {
		err = .Short_Write
	}
	if err != nil {
		if n > 0 && n < b.n {
			copy(b.buf[:b.n-n], b.buf[n : b.n])
		}
		b.n -= n
		b.err = err
		return err
	}
	b.n = 0
	return nil
}

// writer_available returns how many bytes are unused in the buffer
writer_available :: proc(b: ^Writer) -> int {
	return len(b.buf) - b.n
}

// writer_buffered returns the number of bytes that have been writted into the current buffer
writer_buffered :: proc(b: ^Writer) -> int {
	return b.n
}

// writer_write writes the contents of p into the buffer
// It returns the number of bytes written
// If n < len(p), it will return an error explaining why the write is short
writer_write :: proc(b: ^Writer, p: []byte) -> (n: int, err: io.Error) {
	p := p
	for len(p) > writer_available(b) && b.err == nil {
		m: int
		if writer_buffered(b) == 0 {
			m, b.err = io.write(b.wr, p)
			if m < 0 && b.err == nil {
				b.err = .Negative_Write
				break
			}
		} else {
			m = copy(b.buf[b.n:], p)
			b.n += m
			writer_flush(b)
		}
		n += m
		p = p[m:]
	}
	if b.err != nil {
		return n, b.err
	}
	m := copy(b.buf[b.n:], p)
	b.n += m
	m += n
	return m, nil
}

// writer_write_byte writes a single byte
writer_write_byte :: proc(b: ^Writer, c: byte) -> io.Error {
	if b.err != nil {
		return b.err
	}
	if writer_available(b) <= 0 && writer_flush(b) != nil {
		return b.err
	}
	b.buf[b.n] = c
	b.n += 1
	return nil
}

// writer_write_rune writes a single unicode code point, and returns the number of bytes written with any error
writer_write_rune :: proc(b: ^Writer, r: rune) -> (size: int, err: io.Error) {
	if r < utf8.RUNE_SELF {
		err = writer_write_byte(b, byte(r))
		size = 0 if err != nil else 1
		return
	}
	if b.err != nil {
		return 0, b.err
	}

	buf: [4]u8

	n := writer_available(b)
	if n < utf8.UTF_MAX {
		writer_flush(b)
		if b.err != nil {
			return 0, b.err
		}
		n = writer_available(b)
		if n < utf8.UTF_MAX {
			// this only happens if the buffer is very small
			w: int
			buf, w = utf8.encode_rune(r)
			return writer_write(b, buf[:w])
		}
	}

	buf, size = utf8.encode_rune(r)
	copy(b.buf[b.n:], buf[:size])
	b.n += size
	return
}

// writer_write_string writes a string into the buffer
// It returns the number of bytes written
// If n < len(p), it will return an error explaining why the write is short
writer_write_string :: proc(b: ^Writer, s: string) -> (int, io.Error) {
	return writer_write(b, transmute([]byte)s)
}

// writer_read_from is to support io.Reader_From types
// If the underlying writer supports the io,read_from, and b has no buffered data yet,
// this procedure calls the underlying read_from implementation without buffering
writer_read_from :: proc(b: ^Writer, r: io.Reader) -> (n: i64, err: io.Error) {
	if b.err != nil {
		return 0, b.err
	}
	for {
		if writer_available(b) == 0 {
			writer_flush(b) or_return
		}
		if b.max_consecutive_empty_writes <= 0 {
			b.max_consecutive_empty_writes = DEFAULT_MAX_CONSECUTIVE_EMPTY_READS
		}

		m: int
		nr := 0
		for nr < b.max_consecutive_empty_writes {
			m, err = io.read(r, b.buf[b.n:])
			if m != 0 || err != nil {
				break
			}
			nr += 1
		}
		if nr == b.max_consecutive_empty_writes {
			return n, .No_Progress
		}
		b.n += m
		n += i64(m)
		if err != nil {
			break
		}
	}

	if err == .EOF {
		if writer_available(b) == 0 {
			err = writer_flush(b)
		} else {
			err = nil
		}
	}
	return
}



// writer_to_stream converts a Writer into an io.Stream
writer_to_stream :: proc(b: ^Writer) -> (s: io.Stream) {
	s.data = b
	s.procedure = _writer_proc
	return
}

// writer_to_stream converts a Writer into an io.Stream
writer_to_writer :: proc(b: ^Writer) -> (s: io.Writer) {
	return writer_to_stream(b)
}



_writer_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	b := (^Writer)(stream_data)
	#partial switch mode {
	case .Flush:
		err = writer_flush(b)
		return
	case .Write:
		n_int: int
		n_int, err = writer_write(b, p)
		n = i64(n_int)
		return
	case .Destroy:
		writer_destroy(b)
		return
	case .Query:
		return io.query_utility({.Flush, .Write, .Destroy, .Query})
	}
	return 0, .Empty
}
