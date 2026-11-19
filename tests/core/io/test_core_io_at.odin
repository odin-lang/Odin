package test_core_io

import "core:bytes"
import "core:io"
import "core:os"
import "core:strings"
import "core:testing"

@(private="file")
Chunked_Reader :: struct {
	r:           bytes.Reader,
	chunk:       int,
	has_read_at: bool,
	hiccups:     int,
	pending:     int,
}

@(private="file")
chunked_reader_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	c := (^Chunked_Reader)(stream_data)
	inner := bytes.reader_to_stream(&c.r)
	#partial switch mode {
	case .Read:
		if c.pending < c.hiccups {
			c.pending += 1
			return 0, nil
		}
		c.pending = 0
		return inner.procedure(inner.data, .Read, p[:min(len(p), c.chunk)], offset, whence)
	case .Read_At:
		if !c.has_read_at {
			return 0, .Unsupported
		}
		if c.pending < c.hiccups {
			c.pending += 1
			return 0, nil
		}
		c.pending = 0
		return inner.procedure(inner.data, .Read_At, p[:min(len(p), c.chunk)], offset, whence)
	case .Seek, .Size:
		return inner.procedure(inner.data, mode, p, offset, whence)
	case .Query:
		if c.has_read_at {
			return io.query_utility({.Read, .Read_At, .Seek, .Size, .Query})
		}
		return io.query_utility({.Read, .Seek, .Size, .Query})
	}
	return 0, .Unsupported
}

@(private="file")
chunked_reader_init :: proc(c: ^Chunked_Reader, data: []byte, chunk: int, has_read_at: bool) -> io.Stream {
	bytes.reader_init(&c.r, data)
	c.chunk = chunk
	c.has_read_at = has_read_at
	return {procedure = chunked_reader_proc, data = c}
}

@(private="file")
Chunked_Writer :: struct {
	data:     [64]byte,
	pos:      i64,
	size:     i64,
	chunk:    int,
	stuck:    bool,
	stuck_at: i64,
}

@(private="file")
chunked_writer_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	c := (^Chunked_Writer)(stream_data)
	#partial switch mode {
	case .Write:
		if c.stuck && c.pos >= c.stuck_at {
			return 0, nil
		}
		if c.pos >= i64(len(c.data)) {
			return 0, .Short_Write
		}
		m := copy(c.data[c.pos:], p[:min(len(p), c.chunk)])
		c.pos += i64(m)
		c.size = max(c.size, c.pos)
		return i64(m), nil
	case .Seek:
		abs: i64
		switch whence {
		case .Start:   abs = offset
		case .Current: abs = c.pos + offset
		case .End:     abs = c.size + offset
		case:          return 0, .Invalid_Whence
		}
		if abs < 0 {
			return 0, .Invalid_Offset
		}
		c.pos = abs
		return abs, nil
	case .Query:
		return io.query_utility({.Write, .Seek, .Query})
	}
	return 0, .Unsupported
}

@(private="file")
expect_position :: proc(t: ^testing.T, s: io.Stream, expected: i64, loc := #caller_location) {
	pos, err := io.seek(s, 0, .Current)
	testing.expect_value(t, pos, expected, loc = loc)
	testing.expect_value(t, err, nil, loc = loc)
}

@test
test_read_at_fallback :: proc(t: ^testing.T) {
	data: [100]byte
	for i in 0..<len(data) {
		data[i] = byte(i)
	}

	c: Chunked_Reader
	s := chunked_reader_init(&c, data[:], 7, false)
	testing.expect_value(t, io.query(s), io.Stream_Mode_Set{.Read, .Seek, .Size, .Query})

	pos, seek_err := io.seek(s, 10, .Start)
	testing.expect_value(t, pos, 10)
	testing.expect_value(t, seek_err, nil)

	buf: [64]byte
	n, err := io.read_at(s, buf[:4], 20)
	testing.expect_value(t, n, 4)
	testing.expect_value(t, err, nil)
	testing.expect(t, bytes.equal(buf[:4], data[20:24]))
	expect_position(t, s, 10)

	n, err = io.read_at(s, buf[:], 36)
	testing.expect_value(t, n, 64)
	testing.expect_value(t, err, nil)
	testing.expect(t, bytes.equal(buf[:], data[36:]))
	expect_position(t, s, 10)

	n, err = io.read_at(s, buf[:], 50)
	testing.expect_value(t, n, 50)
	testing.expect_value(t, err, io.Error.EOF)
	testing.expect(t, bytes.equal(buf[:50], data[50:]))
	expect_position(t, s, 10)

	n, err = io.read_at(s, buf[:16], 100)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, io.Error.EOF)
	expect_position(t, s, 10)

	n, err = io.read_at(s, buf[:16], 200)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, io.Error.EOF)
	expect_position(t, s, 10)

	n, err = io.read_at(s, buf[:16], -1)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, io.Error.Invalid_Offset)
	expect_position(t, s, 10)

	n_read: int
	n, err = io.read_at(s, buf[:16], 0, &n_read)
	testing.expect_value(t, n, 16)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, n_read, 16)
	testing.expect(t, bytes.equal(buf[:16], data[:16]))
	expect_position(t, s, 10)

	n, err = io.read(s, buf[:4])
	testing.expect_value(t, n, 4)
	testing.expect_value(t, err, nil)
	testing.expect(t, bytes.equal(buf[:4], data[10:14]))
}

@test
test_read_at_fallback_stall :: proc(t: ^testing.T) {
	data: [100]byte
	for i in 0..<len(data) {
		data[i] = byte(i)
	}

	for hiccups in ([]int{3, 100, 101, max(int)}) {
		c: Chunked_Reader
		s := chunked_reader_init(&c, data[:], 7, false)
		c.hiccups = hiccups
		pos, seek_err := io.seek(s, 10, .Start)
		testing.expect_value(t, pos, 10)
		testing.expect_value(t, seek_err, nil)

		buf: [64]byte
		n, err := io.read_at(s, buf[:], 30)
		if hiccups > 100 {
			testing.expect_value(t, n, 0)
			testing.expect_value(t, err, io.Error.No_Progress)
		} else {
			testing.expect_value(t, n, 64)
			testing.expect_value(t, err, nil)
			testing.expect(t, bytes.equal(buf[:], data[30:94]))
		}
		expect_position(t, s, 10)
	}
}

@test
test_read_full_at :: proc(t: ^testing.T) {
	data: [100]byte
	for i in 0..<len(data) {
		data[i] = byte(i) ~ 0xa5
	}

	for has_read_at in ([]bool{false, true}) {
		c: Chunked_Reader
		s := chunked_reader_init(&c, data[:], 7, has_read_at)

		_, seek_err := io.seek(s, 3, .Start)
		testing.expect_value(t, seek_err, nil)

		buf: [64]byte
		n, err := io.read_full_at(s, buf[:16], 30)
		testing.expect_value(t, n, 16)
		testing.expect_value(t, err, nil)
		testing.expect(t, bytes.equal(buf[:16], data[30:46]))

		n, err = io.read_full_at(s, buf[:], 36)
		testing.expect_value(t, n, 64)
		testing.expect_value(t, err, nil)
		testing.expect(t, bytes.equal(buf[:], data[36:]))

		n, err = io.read_full_at(s, buf[:], 50)
		testing.expect_value(t, n, 50)
		testing.expect_value(t, err, io.Error.Unexpected_EOF)
		testing.expect(t, bytes.equal(buf[:50], data[50:]))

		n, err = io.read_full_at(s, buf[:16], 100)
		testing.expect_value(t, n, 0)
		testing.expect_value(t, err, io.Error.EOF)

		n, err = io.read_full_at(s, buf[:0], 100)
		testing.expect_value(t, n, 0)
		testing.expect_value(t, err, nil)

		expect_position(t, s, 3)
	}
}

@test
test_os_file_read_at_past_end :: proc(t: ^testing.T) {
	data: [100]byte
	for i in 0..<len(data) {
		data[i] = byte(i) + 1
	}

	f, create_err := os.create_temp_file("", "odin-io-read-at-*")
	if create_err != nil {
		testing.fail_now(t, "could not create temporary file")
	}
	name := strings.clone(os.name(f), context.temp_allocator)
	defer os.remove(name)
	defer os.close(f)

	s := os.to_stream(f)
	n, err := io.write(s, data[:])
	testing.expect_value(t, n, len(data))
	testing.expect_value(t, err, nil)

	buf: [64]byte
	n, err = io.read_at(s, buf[:], 50)
	testing.expect_value(t, n, 50)
	testing.expect_value(t, err, io.Error.EOF)
	testing.expect(t, bytes.equal(buf[:50], data[50:]))

	n, err = io.read_at(s, buf[:16], 100)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, io.Error.EOF)

	n, err = io.read_full_at(s, buf[:16], 30)
	testing.expect_value(t, n, 16)
	testing.expect_value(t, err, nil)
	testing.expect(t, bytes.equal(buf[:16], data[30:46]))

	n, err = io.read_full_at(s, buf[:], 50)
	testing.expect_value(t, n, 50)
	testing.expect_value(t, err, io.Error.Unexpected_EOF)

	n, err = io.read_full_at(s, buf[:16], 200)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, io.Error.EOF)
}

@test
test_write_at_fallback :: proc(t: ^testing.T) {
	c := Chunked_Writer{chunk = 7}
	s := io.Stream{procedure = chunked_writer_proc, data = &c}
	testing.expect_value(t, io.query(s), io.Stream_Mode_Set{.Write, .Seek, .Query})

	n, err := io.write_full(s, transmute([]byte)string("0123456789"))
	testing.expect_value(t, n, 10)
	testing.expect_value(t, err, nil)

	pos, seek_err := io.seek(s, 5, .Start)
	testing.expect_value(t, pos, 5)
	testing.expect_value(t, seek_err, nil)

	src := "abcdefghijklmnop"
	n_written: int
	n, err = io.write_at(s, transmute([]byte)src, 20, &n_written)
	testing.expect_value(t, n, 16)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, n_written, 16)
	testing.expect_value(t, string(c.data[20:36]), src)
	testing.expect_value(t, string(c.data[:10]), "0123456789")
	testing.expect_value(t, c.size, 36)
	expect_position(t, s, 5)

	n, err = io.write_at(s, transmute([]byte)string("XY"), 2)
	testing.expect_value(t, n, 2)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, string(c.data[:10]), "01XY456789")
	expect_position(t, s, 5)

	n, err = io.write_at(s, transmute([]byte)src, -1)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, io.Error.Invalid_Offset)
	expect_position(t, s, 5)

	n, err = io.write_at(s, transmute([]byte)src, 56)
	testing.expect_value(t, n, 8)
	testing.expect_value(t, err, io.Error.Short_Write)
	testing.expect_value(t, string(c.data[56:]), src[:8])
	expect_position(t, s, 5)

	n, err = io.write_string(s, "Q")
	testing.expect_value(t, n, 1)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, string(c.data[:10]), "01XY4Q6789")
}

@test
test_read_full_stall :: proc(t: ^testing.T) {
	data: [100]byte
	for i in 0..<len(data) {
		data[i] = byte(i) ~ 0x5a
	}

	for has_read_at in ([]bool{false, true}) {
		for hiccups in ([]int{0, 3, 100, 101, max(int)}) {
			c: Chunked_Reader
			s := chunked_reader_init(&c, data[:], 7, has_read_at)
			c.hiccups = hiccups

			buf: [64]byte
			n, err := io.read_full(s, buf[:])
			if hiccups > 100 {
				testing.expectf(t, n == 0 && err == .No_Progress, "read_full, %d hiccups: %d %v", hiccups, n, err)
			} else {
				testing.expectf(t, n == 64 && err == nil, "read_full, %d hiccups: %d %v", hiccups, n, err)
				testing.expect(t, bytes.equal(buf[:], data[:64]))
			}

			c.pending = 0
			buf = {}
			n, err = io.read_full_at(s, buf[:], 30)
			if hiccups > 100 {
				testing.expectf(t, n == 0 && err == .No_Progress, "read_full_at %v, %d hiccups: %d %v", has_read_at, hiccups, n, err)
			} else {
				testing.expectf(t, n == 64 && err == nil, "read_full_at %v, %d hiccups: %d %v", has_read_at, hiccups, n, err)
				testing.expect(t, bytes.equal(buf[:], data[30:94]))
			}
		}
	}
}

@test
test_copy_stall :: proc(t: ^testing.T) {
	data: [100]byte
	for i in 0..<len(data) {
		data[i] = byte(i) * 3
	}

	for hiccups in ([]int{0, 3, 100, 101, max(int)}) {
		c: Chunked_Reader
		s := chunked_reader_init(&c, data[:], 7, false)
		c.hiccups = hiccups
		out := strings.builder_make()
		defer strings.builder_destroy(&out)
		written, err := io.copy(strings.to_writer(&out), s)
		if hiccups > 100 {
			testing.expectf(t, written == 0 && err == .No_Progress, "%d hiccups: %d %v", hiccups, written, err)
		} else {
			testing.expectf(t, written == 100 && err == nil, "%d hiccups: %d %v", hiccups, written, err)
			testing.expect(t, bytes.equal(out.buf[:], data[:]))
		}
	}
}

@test
test_write_full_stall :: proc(t: ^testing.T) {
	src := "0123456789abcdef"
	for stuck_at in ([]i64{0, 7, 14}) {
		c := Chunked_Writer{chunk = 7, stuck = true, stuck_at = stuck_at}
		s := io.Stream{procedure = chunked_writer_proc, data = &c}
		n, err := io.write_full(s, transmute([]byte)src)
		testing.expectf(t, i64(n) == stuck_at && err == .Short_Write, "stuck at %d: %d %v", stuck_at, n, err)
		testing.expect_value(t, string(c.data[:n]), src[:n])
	}

	c := Chunked_Writer{chunk = 7, stuck = true, stuck_at = 10}
	s := io.Stream{procedure = chunked_writer_proc, data = &c}
	pos, seek_err := io.seek(s, 1, .Start)
	testing.expect_value(t, pos, 1)
	testing.expect_value(t, seek_err, nil)
	n, err := io.write_at(s, transmute([]byte)src, 3)
	testing.expect_value(t, n, 7)
	testing.expect_value(t, err, io.Error.Short_Write)
	testing.expect_value(t, string(c.data[3:10]), src[:7])
	expect_position(t, s, 1)
}
