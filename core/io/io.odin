// package io provides basic interfaces for generic data stream primitives.
// The purpose of this package is wrap existing data structures and their
// operations into an abstracted stream interface.
package io

import "base:intrinsics"
import "core:unicode/utf8"

// Seek whence values
Seek_From :: enum {
	Start   = 0, // seek relative to the origin of the file
	Current = 1, // seek relative to the current offset
	End     = 2, // seek relative to the end
}

Error :: enum i32 {
	// No Error
	None = 0,

	// EOF is the error returned by `read` when no more input is available
	EOF,

	// Unexpected_EOF means that EOF was encountered in the middle of reading a fixed-sized block of data
	Unexpected_EOF,

	// Short_Write means that a write accepted fewer bytes than requested but failed to return an explicit error
	Short_Write,

	// Invalid_Write means that a write returned an impossible count
	Invalid_Write,

	// Short_Buffer means that a read/write required a longer buffer than was provided
	Short_Buffer,

	// No_Progress is returned by some implementations of `io.Reader` when many calls
	// to `read` have failed to return any data or error.
	// This is usually a sign of a broken `io.Reader` implementation
	No_Progress,

	Invalid_Whence,
	Invalid_Offset,
	Invalid_Unread,

	Negative_Read,
	Negative_Write,
	Negative_Count,
	Buffer_Full,

	// Unknown means that an error has occurred but cannot be categorized
	Unknown,

	// Empty is returned when a procedure has not been implemented for an io.Stream
	Empty = -1,
}

Stream_Mode :: enum {
	Close,
	Flush,
	Read,
	Read_At,
	Write,
	Write_At,
	Seek,
	Size,
	Destroy,
	Query, // query what modes are available
}

Stream_Mode_Set :: distinct bit_set[Stream_Mode; i64]

Stream_Proc :: #type proc(stream_data: rawptr, mode: Stream_Mode, p: []byte, offset: i64, whence: Seek_From) -> (n: i64, err: Error)

Stream :: struct {
	procedure: Stream_Proc,
	data:      rawptr,
}

Reader             :: Stream
Writer             :: Stream
Closer             :: Stream
Flusher            :: Stream
Seeker             :: Stream

Read_Writer        :: Stream
Read_Closer        :: Stream
Read_Write_Closer  :: Stream
Read_Write_Seeker  :: Stream

Write_Closer       :: Stream
Write_Seeker       :: Stream
Write_Flusher      :: Stream
Write_Flush_Closer :: Stream

Reader_At          :: Stream
Writer_At          :: Stream


destroy :: proc(s: Stream) -> (err: Error) {
	_ = flush(s)
	_ = close(s)
	if s.procedure != nil {
		_, err = s.procedure(s.data, .Destroy, nil, 0, nil)
	} else {
		err = .Empty
	}
	return
}

query :: proc(s: Stream) -> (set: Stream_Mode_Set) {
	if s.procedure != nil {
		n, _ := s.procedure(s.data, .Query, nil, 0, nil)
		set = transmute(Stream_Mode_Set)n
		if set != nil {
			set += {.Query}
		}
	}
	return
}

query_utility :: #force_inline proc "contextless" (set: Stream_Mode_Set) -> (n: i64, err: Error) {
	return transmute(i64)set, nil
}

_i64_err :: #force_inline proc "contextless" (n: int, err: Error) -> (i64, Error) {
	return i64(n), err
}


// read reads up to len(p) bytes into s. It returns the number of bytes read and any error if occurred.
//
// When read encounters an .EOF or error after successfully reading n > 0 bytes, it returns the number of
// bytes read along with the error.
read :: proc(s: Reader, p: []byte, n_read: ^int = nil) -> (n: int, err: Error) {
	if s.procedure != nil {
		n64: i64
		n64, err = s.procedure(s.data, .Read, p, 0, nil)
		n = int(n64)
		if n_read != nil { n_read^ += n }
	} else {
		err = .Empty
	}
	return
}

// write writes up to len(p) bytes into s. It returns the number of bytes written and any error if occurred.
write :: proc(s: Writer, p: []byte, n_written: ^int = nil) -> (n: int, err: Error) {
	if s.procedure != nil {
		n64: i64
		n64, err = s.procedure(s.data, .Write, p, 0, nil)
		n = int(n64)
		if n_written != nil { n_written^ += n }
	} else {
		err = .Empty
	}
	return
}

// seek sets the offset of the next read or write to offset.
//
// .Start means seek relative to the origin of the file.
// .Current means seek relative to the current offset.
// .End means seek relative to the end.
//
// seek returns the new offset to the start of the file/stream, and any error if occurred.
seek :: proc(s: Seeker, offset: i64, whence: Seek_From) -> (n: i64, err: Error) {
	if s.procedure != nil {
		n, err = s.procedure(s.data, .Seek, nil, offset, whence)
	} else {
		err = .Empty
	}
	return
}

// The behaviour of close after the first call is stream implementation defined.
// Different streams may document their own behaviour.
close :: proc(s: Closer) -> (err: Error) {
	if s.procedure != nil {
		_, err = s.procedure(s.data, .Close, nil, 0, nil)
	}
	return
}

flush :: proc(s: Flusher) -> (err: Error) {
	if s.procedure != nil {
		_, err = s.procedure(s.data, .Flush, nil, 0, nil)
	}
	return
}

// size returns the size of the stream. If the stream does not support querying its size, 0 will be returned.
size :: proc(s: Stream) -> (n: i64, err: Error) {
	if s.procedure != nil {
		n, err = s.procedure(s.data, .Size, nil, 0, nil)
		if err == .Empty {
			n = 0
			curr := seek(s, 0, .Current) or_return
			end  := seek(s, 0, .End)     or_return
			seek(s, curr, .Start)        or_return
			n = end
		}
	} else {
		err = .Empty
	}
	return
}



// read_at reads len(p) bytes into p starting with the provided offset in the underlying Reader_At stream r.
// It returns the number of bytes read and any error if occurred.
//
// When read_at returns n < len(p), it returns a non-nil Error explaining why.
//
// If n == len(p), err may be either nil or .EOF
read_at :: proc(r: Reader_At, p: []byte, offset: i64, n_read: ^int = nil) -> (n: int, err: Error) {
	if r.procedure != nil {
		n64: i64
		n64, err = r.procedure(r.data, .Read_At, p, offset, nil)
		if err != .Empty {
			n = int(n64)
		} else {
			curr := seek(r, offset, .Current) or_return
			n, err = read(r, p)
			_, err1 := seek(r, curr, .Start)
			if err1 != nil && err == nil {
				err = err1
			}
		}
		if n_read != nil { n_read^ += n }
	} else {
		err = .Empty
	}
	return
}

// write_at writes len(p) bytes into p starting with the provided offset in the underlying Writer_At stream w.
// It returns the number of bytes written and any error if occurred.
//
// If write_at is writing to a Writer_At which has a seek offset, then write_at should not affect the underlying
// seek offset.
write_at :: proc(w: Writer_At, p: []byte, offset: i64, n_written: ^int = nil) -> (n: int, err: Error) {
	if w.procedure != nil {
		n64: i64
		n64, err = w.procedure(w.data, .Write_At, p, offset, nil)
		if err != .Empty {
			n = int(n64)
		} else {
			curr := seek(w, offset, .Current) or_return
			n, err = write(w, p)
			_, err1 := seek(w, curr, .Start)
			if err1 != nil && err == nil {
				err = err1
			}
		}
		if n_written != nil { n_written^ += n }
	} else {
		err = .Empty
	}
	return
}

// read_byte reads and returns the next byte from r.
read_byte :: proc(r: Reader, n_read: ^int = nil) -> (b: byte, err: Error) {
	buf: [1]byte
	_, err = read(r, buf[:], n_read)
	b = buf[0]
	return
}

write_byte :: proc(w: Writer, c: byte, n_written: ^int = nil) -> Error {
	buf: [1]byte
	buf[0] = c
	write(w, buf[:], n_written) or_return
	return nil
}

// read_rune reads a single UTF-8 encoded Unicode codepoint and returns the rune and its size in bytes.
read_rune :: proc(br: Reader, n_read: ^int = nil) -> (ch: rune, size: int, err: Error) {
	defer if err == nil && n_read != nil {
		n_read^ += size
	}

	b: [utf8.UTF_MAX]byte
	_, err = read(br, b[:1])

	s0 := b[0]
	ch = rune(s0)
	size = 1
	if err != nil {
		return
	}
	if ch < utf8.RUNE_SELF {
		return
	}
	x := utf8.accept_sizes[s0]
	if x >= 0xf0 {
		mask := rune(x) << 31 >> 31
		ch = ch &~ mask | utf8.RUNE_ERROR&mask
		return
	}
	sz := int(x&7)
	size, err = read(br, b[1:sz])
	if err != nil || size+1 < sz {
		ch = utf8.RUNE_ERROR
		return
	}

	ch, size = utf8.decode_rune(b[:sz])
	return
}

// write_string writes the contents of the string s to w.
write_string :: proc(s: Writer, str: string, n_written: ^int = nil) -> (n: int, err: Error) {
	return write(s, transmute([]byte)str, n_written)
}

// write_rune writes a UTF-8 encoded rune to w.
write_rune :: proc(s: Writer, r: rune, n_written: ^int = nil) -> (size: int, err: Error) {
	defer if err == nil && n_written != nil {
		n_written^ += size
	}
	if r < utf8.RUNE_SELF {
		err = write_byte(s, byte(r))
		if err == nil {
			size = 1
		}
		return
	}
	buf, w := utf8.encode_rune(r)
	return write(s, buf[:w])
}


// read_full expected exactly len(buf) bytes from r into buf.
read_full :: proc(r: Reader, buf: []byte) -> (n: int, err: Error) {
	return read_at_least(r, buf, len(buf))
}


// read_at_least reads from r into buf until it has read at least min bytes. It returns the number
// of bytes copied and an error if fewer bytes were read. `.EOF` is only returned if no bytes were read.
// `.Unexpected_EOF` is returned when an `.EOF ` is returned by the passed Reader after reading
// fewer than min bytes. If len(buf) is less than min, `.Short_Buffer` is returned.
read_at_least :: proc(r: Reader, buf: []byte, min: int) -> (n: int, err: Error) {
	if len(buf) < min {
		return 0, .Short_Buffer
	}
	for n < min && err == nil {
		nn: int
		nn, err = read(r, buf[n:])
		n += nn
	}

	if n >= min {
		err = nil
	} else if n > 0 && err == .EOF {
		err = .Unexpected_EOF
	}
	return
}

// write_full writes until the entire contents of `buf` has been written or an error occurs.
write_full :: proc(w: Writer, buf: []byte) -> (n: int, err: Error) {
	return write_at_least(w, buf, len(buf))
}

// write_at_least writes at least `buf[:min]` to the writer and returns the amount written.
// If an error occurs before writing everything it is returned.
write_at_least :: proc(w: Writer, buf: []byte, min: int) -> (n: int, err: Error) {
	if len(buf) < min {
		return 0, .Short_Buffer
	}
	for n < min && err == nil {
		nn: int
		nn, err = write(w, buf[n:])
		n += nn
	}
	return
}

// copy copies from src to dst till either EOF is reached on src or an error occurs
// It returns the number of bytes copied and the first error that occurred whilst copying, if any.
copy :: proc(dst: Writer, src: Reader) -> (written: i64, err: Error) {
	return _copy_buffer(dst, src, nil)
}

// copy_buffer is the same as copy except that it stages through the provided buffer (if one is required)
// rather than allocating a temporary one on the stack through `intrinsics.alloca`
// If buf is `nil`, it is allocate through `intrinsics.alloca`; otherwise if it has zero length, it will panic
copy_buffer :: proc(dst: Writer, src: Reader, buf: []byte) -> (written: i64, err: Error) {
	if buf != nil && len(buf) == 0 {
		panic("empty buffer in io.copy_buffer")
	}
	return _copy_buffer(dst, src, buf)
}



// copy_n copies n bytes (or till an error) from src to dst.
// It returns the number of bytes copied and the first error that occurred whilst copying, if any.
// On return, written == n IFF err == nil
copy_n :: proc(dst: Writer, src: Reader, n: i64) -> (written: i64, err: Error) {
	nsrc := limited_reader_init(&Limited_Reader{}, src, n)
	written, err = copy(dst, nsrc)
	if written == n {
		return n, nil
	}
	if written < n && err == nil {
		// src stopped early and must have been an EOF
		err = .EOF
	}
	return
}


@(private)
_copy_buffer :: proc(dst: Writer, src: Reader, buf: []byte) -> (written: i64, err: Error) {
	if dst.procedure == nil || src.procedure == nil {
		return 0, .Empty
	}
	buf := buf
	if buf == nil {
		DEFAULT_SIZE :: 4 * 1024
		size := DEFAULT_SIZE
		if src.procedure == _limited_reader_proc {
			l := (^Limited_Reader)(src.data)
			if i64(size) > l.n {
				if l.n < 1 {
					size = 1
				} else {
					size = int(l.n)
				}
			}
		}
		// NOTE(bill): alloca is fine here
		buf = intrinsics.alloca(size, 2*align_of(rawptr))[:size]
	}
	for {
		nr, er := read(src, buf)
		if nr > 0 {
			nw, ew := write(dst, buf[0:nr])
			if nw > 0 {
				written += i64(nw)
			}
			if ew != nil {
				err = ew
				break
			}
			if nr != nw {
				err = .Short_Write
				break
			}
		}
		if er != nil {
			if er != .EOF {
				err = er
			}
			break
		}
	}
	return
}
