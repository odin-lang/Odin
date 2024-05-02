package bytes

import "core:io"
import "core:unicode/utf8"

MIN_READ :: 512

@(private)
SMALL_BUFFER_SIZE :: 64

// A Buffer is a variable-sized buffer of bytes with a io.Stream interface
// The zero value for Buffer is an empty buffer ready to use.
Buffer :: struct {
	buf: [dynamic]byte,
	off: int,
	last_read: Read_Op,
}

@(private)
Read_Op :: enum i8 {
	Read       = -1,
	Invalid    =  0,
	Read_Rune1 =  1,
	Read_Rune2 =  2,
	Read_Rune3 =  3,
	Read_Rune4 =  4,
}


buffer_init :: proc(b: ^Buffer, buf: []byte) {
	resize(&b.buf, len(buf))
	copy(b.buf[:], buf)
}

buffer_init_string :: proc(b: ^Buffer, s: string) {
	resize(&b.buf, len(s))
	copy(b.buf[:], s)
}

buffer_init_allocator :: proc(b: ^Buffer, len, cap: int, allocator := context.allocator) {
	if b.buf == nil {
		b.buf = make([dynamic]byte, len, cap, allocator)
		return
	}

	b.buf.allocator = allocator
	reserve(&b.buf, cap)
	resize(&b.buf, len)
}

buffer_destroy :: proc(b: ^Buffer) {
	delete(b.buf)
	buffer_reset(b)
}

buffer_to_bytes :: proc(b: ^Buffer) -> []byte {
	return b.buf[b.off:]
}

buffer_to_string :: proc(b: ^Buffer) -> string {
	if b == nil {
		return "<nil>"
	}
	return string(b.buf[b.off:])
}

buffer_is_empty :: proc(b: ^Buffer) -> bool {
	return len(b.buf) <= b.off
}

buffer_length :: proc(b: ^Buffer) -> int {
	return len(b.buf) - b.off
}

buffer_capacity :: proc(b: ^Buffer) -> int {
	return cap(b.buf)
}

buffer_reset :: proc(b: ^Buffer) {
	clear(&b.buf)
	b.off = 0
	b.last_read = .Invalid
}


buffer_truncate :: proc(b: ^Buffer, n: int) {
	if n == 0 {
		buffer_reset(b)
		return
	}
	b.last_read = .Invalid
	if n < 0 || n > buffer_length(b) {
		panic("bytes.truncate: truncation out of range")
	}
	resize(&b.buf, b.off+n)
}

@(private)
_buffer_try_grow :: proc(b: ^Buffer, n: int) -> (int, bool) {
	if l := len(b.buf); n <= cap(b.buf)-l {
		resize(&b.buf, l+n)
		return l, true
	}
	return 0, false
}

@(private)
_buffer_grow :: proc(b: ^Buffer, n: int) -> int {
	m := buffer_length(b)
	if m == 0 && b.off != 0 {
		buffer_reset(b)
	}
	if i, ok := _buffer_try_grow(b, n); ok {
		return i
	}

	if b.buf == nil && n <= SMALL_BUFFER_SIZE {
		// Fixes #2756 by preserving allocator if already set on Buffer via init_buffer_allocator
		reserve(&b.buf, SMALL_BUFFER_SIZE)
		resize(&b.buf, n)
		return 0
	}

	c := cap(b.buf)
	if n <= c/2 - m {
		copy(b.buf[:], b.buf[b.off:])
	} else if c > max(int) - c - n {
		panic("bytes.Buffer: too large")
	} else {
		resize(&b.buf, 2*c + n)
		copy(b.buf[:], b.buf[b.off:])
	}
	b.off = 0
	resize(&b.buf, m+n)
	return m
}

buffer_grow :: proc(b: ^Buffer, n: int) {
	if n < 0 {
		panic("bytes.buffer_grow: negative count")
	}
	m := _buffer_grow(b, n)
	resize(&b.buf, m)
}

buffer_write_at :: proc(b: ^Buffer, p: []byte, offset: int) -> (n: int, err: io.Error) {
	b.last_read = .Invalid
	if offset < 0 {
		err = .Invalid_Offset
		return
	}
	_, ok := _buffer_try_grow(b, offset+len(p))
	if !ok {
		_ = _buffer_grow(b, offset+len(p))
	}
	if len(b.buf) <= offset {
		return 0, .Short_Write
	}
	return copy(b.buf[offset:], p), nil
}


buffer_write :: proc(b: ^Buffer, p: []byte) -> (n: int, err: io.Error) {
	b.last_read = .Invalid
	m, ok := _buffer_try_grow(b, len(p))
	if !ok {
		m = _buffer_grow(b, len(p))
	}
	return copy(b.buf[m:], p), nil
}

buffer_write_ptr :: proc(b: ^Buffer, ptr: rawptr, size: int) -> (n: int, err: io.Error) {
	return buffer_write(b, ([^]byte)(ptr)[:size])
}

buffer_write_string :: proc(b: ^Buffer, s: string) -> (n: int, err: io.Error) {
	b.last_read = .Invalid
	m, ok := _buffer_try_grow(b, len(s))
	if !ok {
		m = _buffer_grow(b, len(s))
	}
	return copy(b.buf[m:], s), nil
}

buffer_write_byte :: proc(b: ^Buffer, c: byte) -> io.Error {
	b.last_read = .Invalid
	m, ok := _buffer_try_grow(b, 1)
	if !ok {
		m = _buffer_grow(b, 1)
	}
	b.buf[m] = c
	return nil
}

buffer_write_rune :: proc(b: ^Buffer, r: rune) -> (n: int, err: io.Error) {
	if r < utf8.RUNE_SELF {
		buffer_write_byte(b, byte(r))
		return 1, nil
	}
	b.last_read = .Invalid
	m, ok := _buffer_try_grow(b, utf8.UTF_MAX)
	if !ok {
		m = _buffer_grow(b, utf8.UTF_MAX)
	}
	res: [4]byte
	res, n = utf8.encode_rune(r)
	copy(b.buf[m:][:utf8.UTF_MAX], res[:n])
	resize(&b.buf, m+n)
	return
}

buffer_next :: proc(b: ^Buffer, n: int) -> []byte {
	n := n
	b.last_read = .Invalid
	m := buffer_length(b)
	if n > m {
		n = m
	}
	data := b.buf[b.off : b.off + n]
	b.off += n
	if n > 0 {
		b.last_read = .Read
	}
	return data
}

buffer_read :: proc(b: ^Buffer, p: []byte) -> (n: int, err: io.Error) {
	b.last_read = .Invalid
	if buffer_is_empty(b) {
		buffer_reset(b)
		if len(p) == 0 {
			return 0, nil
		}
		return 0, .EOF
	}
	n = copy(p, b.buf[b.off:])
	b.off += n
	if n > 0 {
		b.last_read = .Read
	}
	return
}

buffer_read_ptr :: proc(b: ^Buffer, ptr: rawptr, size: int) -> (n: int, err: io.Error) {
	return buffer_read(b, ([^]byte)(ptr)[:size])
}

buffer_read_at :: proc(b: ^Buffer, p: []byte, offset: int) -> (n: int, err: io.Error) {
	b.last_read = .Invalid

	if uint(offset) >= len(b.buf) {
		err = .Invalid_Offset
		return
	}
	n = copy(p, b.buf[offset:])
	if n > 0 {
		b.last_read = .Read
	}
	return
}


buffer_read_byte :: proc(b: ^Buffer) -> (byte, io.Error) {
	if buffer_is_empty(b) {
		buffer_reset(b)
		return 0, .EOF
	}
	c := b.buf[b.off]
	b.off += 1
	b.last_read = .Read
	return c, nil
}

buffer_read_rune :: proc(b: ^Buffer) -> (r: rune, size: int, err: io.Error) {
	if buffer_is_empty(b) {
		buffer_reset(b)
		return 0, 0, .EOF
	}
	c := b.buf[b.off]
	if c < utf8.RUNE_SELF {
		b.off += 1
		b.last_read = .Read_Rune1
		return rune(c), 1, nil
	}
	r, size = utf8.decode_rune(b.buf[b.off:])
	b.off += size
	b.last_read = Read_Op(i8(size))
	return
}

buffer_unread_byte :: proc(b: ^Buffer) -> io.Error {
	if b.last_read == .Invalid {
		return .Invalid_Unread
	}
	b.last_read = .Invalid
	if b.off > 0 {
		b.off -= 1
	}
	return nil
}

buffer_unread_rune :: proc(b: ^Buffer) -> io.Error {
	if b.last_read <= .Invalid {
		return .Invalid_Unread
	}
	if b.off >= int(b.last_read) {
		b.off -= int(i8(b.last_read))
	}
	b.last_read = .Invalid
	return nil
}


buffer_read_bytes :: proc(b: ^Buffer, delim: byte) -> (line: []byte, err: io.Error) {
	i := index_byte(b.buf[b.off:], delim)
	end := b.off + i + 1
	if i < 0 {
		end = len(b.buf)
		err = .EOF
	}
	line = b.buf[b.off:end]
	b.off = end
	b.last_read = .Read
	return
}

buffer_read_string :: proc(b: ^Buffer, delim: byte) -> (line: string, err: io.Error) {
	slice: []byte
	slice, err = buffer_read_bytes(b, delim)
	return string(slice), err
}

buffer_write_to :: proc(b: ^Buffer, w: io.Writer) -> (n: i64, err: io.Error) {
	b.last_read = .Invalid
	if byte_count := buffer_length(b); byte_count > 0 {
		m, e := io.write(w, b.buf[b.off:])
		if m > byte_count {
			panic("bytes.buffer_write_to: invalid io.write count")
		}
		b.off += m
		n = i64(m)
		if e != nil {
			err = e
			return
		}
		if m != byte_count {
			err = .Short_Write
			return
		}
	}
	buffer_reset(b)
	return
}

buffer_read_from :: proc(b: ^Buffer, r: io.Reader) -> (n: i64, err: io.Error) #no_bounds_check {
	b.last_read = .Invalid
	for {
		i := _buffer_grow(b, MIN_READ)
		resize(&b.buf, i)
		m, e := io.read(r, b.buf[i:cap(b.buf)])
		if m < 0 {
			err = e if e != nil else .Negative_Read
			return
		}

		resize(&b.buf, i+m)
		n += i64(m)
		if e == .EOF {
			return
		}
		if e != nil {
			err = e
			return
		}
	}
	return
}


buffer_to_stream :: proc(b: ^Buffer) -> (s: io.Stream) {
	s.data = b
	s.procedure = _buffer_proc
	return
}

@(private)
_buffer_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	b := (^Buffer)(stream_data)
	#partial switch mode {
	case .Read:
		return io._i64_err(buffer_read(b, p))
	case .Read_At:
		return io._i64_err(buffer_read_at(b, p, int(offset)))
	case .Write:
		return io._i64_err(buffer_write(b, p))
	case .Write_At:
		return io._i64_err(buffer_write_at(b, p, int(offset)))
	case .Size:
		n = i64(buffer_capacity(b))
		return
	case .Destroy:
		buffer_destroy(b)
		return
	case .Query:
		return io.query_utility({.Read, .Read_At, .Write, .Write_At, .Size, .Destroy})
	}
	return 0, .Empty
}
