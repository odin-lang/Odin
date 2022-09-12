// package io provides basic interfaces for generic data stream primitives.
// The purpose of this package is wrap existing data structures and their
// operations into an abstracted stream interface.
package io

import "core:intrinsics"
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

	// Short_Buffer means that a read required a longer buffer than was provided
	Short_Buffer,

	// No_Progress is returned by some implementations of `io.Reader` when many calls
	// to `read` have failed to return any data or error.
	// This is usually a signed of a broken `io.Reader` implementation
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

Close_Proc       :: proc(using s: Stream) -> Error
Flush_Proc       :: proc(using s: Stream) -> Error
Seek_Proc        :: proc(using s: Stream, offset: i64, whence: Seek_From) -> (n: i64, err: Error)
Size_Proc        :: proc(using s: Stream) -> i64
Read_Proc        :: proc(using s: Stream, p: []byte) -> (n: int, err: Error)
Read_At_Proc     :: proc(using s: Stream, p: []byte, off: i64) -> (n: int, err: Error)
Read_From_Proc   :: proc(using s: Stream, r: Reader) -> (n: i64, err: Error)
Read_Byte_Proc   :: proc(using s: Stream) -> (byte, Error)
Read_Rune_Proc   :: proc(using s: Stream) -> (ch: rune, size: int, err: Error)
Unread_Byte_Proc :: proc(using s: Stream) -> Error
Unread_Rune_Proc :: proc(using s: Stream) -> Error
Write_Proc       :: proc(using s: Stream, p: []byte) -> (n: int, err: Error)
Write_At_Proc    :: proc(using s: Stream, p: []byte, off: i64) -> (n: int, err: Error)
Write_To_Proc    :: proc(using s: Stream, w: Writer) -> (n: i64, err: Error)
Write_Byte_Proc  :: proc(using s: Stream, c: byte) -> Error
Write_Rune_Proc  :: proc(using s: Stream, r: rune) -> (size: int, err: Error)
Destroy_Proc     :: proc(using s: Stream) -> Error


Stream :: struct {
	using stream_vtable: ^Stream_VTable,
	stream_data:         rawptr,
}
Stream_VTable :: struct {
	impl_close: Close_Proc,
	impl_flush: Flush_Proc,

	impl_seek:  Seek_Proc,
	impl_size:  Size_Proc,

	impl_read:      Read_Proc,
	impl_read_at:   Read_At_Proc,
	impl_read_byte: Read_Byte_Proc,
	impl_read_rune: Read_Rune_Proc,
	impl_write_to:  Write_To_Proc,

	impl_write:      Write_Proc,
	impl_write_at:   Write_At_Proc,
	impl_write_byte: Write_Byte_Proc,
	impl_write_rune: Write_Rune_Proc,
	impl_read_from:  Read_From_Proc,

	impl_unread_byte: Unread_Byte_Proc,
	impl_unread_rune: Unread_Rune_Proc,

	impl_destroy: Destroy_Proc,
}


Reader             :: struct {using stream: Stream}
Writer             :: struct {using stream: Stream}
Closer             :: struct {using stream: Stream}
Flusher            :: struct {using stream: Stream}
Seeker             :: struct {using stream: Stream}

Read_Writer        :: struct {using stream: Stream}
Read_Closer        :: struct {using stream: Stream}
Read_Write_Closer  :: struct {using stream: Stream}
Read_Write_Seeker  :: struct {using stream: Stream}

Write_Closer       :: struct {using stream: Stream}
Write_Seeker       :: struct {using stream: Stream}
Write_Flusher      :: struct {using stream: Stream}
Write_Flush_Closer :: struct {using stream: Stream}

Reader_At          :: struct {using stream: Stream}
Writer_At          :: struct {using stream: Stream}
Reader_From        :: struct {using stream: Stream}
Writer_To          :: struct {using stream: Stream}


destroy :: proc(s: Stream) -> Error {
	close_err := close({s})
	if s.stream_vtable != nil && s.impl_destroy != nil {
		return s->impl_destroy()
	}
	if close_err != .None {
		return close_err
	}
	return .Empty
}

// read reads up to len(p) bytes into s. It returns the number of bytes read and any error if occurred.
//
// When read encounters an .EOF or error after successfully reading n > 0 bytes, it returns the number of
// bytes read along with the error.
read :: proc(s: Reader, p: []byte, n_read: ^int = nil) -> (n: int, err: Error) {
	if s.stream_vtable != nil {
		if s.impl_read != nil {
			n, err = s->impl_read(p)
			if n_read != nil {
				n_read^ += n
			}
			return
		} else if s.impl_read_byte != nil {
			bytes_read := 0
			defer if n_read != nil {
				n_read^ += bytes_read
			}
			for _, i in p {
				p[i] = s->impl_read_byte() or_return
				bytes_read += 1
			}
			return
		}
	}
	return 0, .Empty
}

// write writes up to len(p) bytes into s. It returns the number of bytes written and any error if occurred.
write :: proc(s: Writer, p: []byte, n_written: ^int = nil) -> (n: int, err: Error) {
	if s.stream_vtable != nil {
		if s.impl_write != nil {
			n, err = s->impl_write(p)
			if n_written != nil {
				n_written^ += n
			}
			return
		} else if s.impl_write_byte != nil {
			bytes_written := 0
			defer if n_written != nil {
				n_written^ += bytes_written
			}
			for c in p {
				s->impl_write_byte(c) or_return
				bytes_written += 1
			}
			return
		}
	}
	return 0, .Empty
}

// seek sets the offset of the next read or write to offset.
//
// .Start means seek relative to the origin of the file.
// .Current means seek relative to the current offset.
// .End means seek relative to the end.
//
// seek returns the new offset to the start of the file/stream, and any error if occurred.
seek :: proc(s: Seeker, offset: i64, whence: Seek_From) -> (n: i64, err: Error) {
	if s.stream_vtable != nil && s.impl_seek != nil {
		return s->impl_seek(offset, whence)
	}
	return 0, .Empty
}

// The behaviour of close after the first call is stream implementation defined.
// Different streams may document their own behaviour.
close :: proc(s: Closer) -> Error {
	if s.stream_vtable != nil && s.impl_close != nil {
		return s->impl_close()
	}
	// Instead of .Empty, .None is fine in this case
	return .None
}

flush :: proc(s: Flusher) -> Error {
	if s.stream_vtable != nil && s.impl_flush != nil {
		return s->impl_flush()
	}
	// Instead of .Empty, .None is fine in this case
	return .None
}

// size returns the size of the stream. If the stream does not support querying its size, 0 will be returned.
size :: proc(s: Stream) -> i64 {
	if s.stream_vtable == nil {
		return 0
	}
	if s.impl_size != nil {
		return s->impl_size()
	}
	if s.impl_seek == nil {
		return 0
	}

	curr, end: i64
	err: Error
	if curr, err = s->impl_seek(0, .Current); err != nil {
		return 0
	}

	if end, err = s->impl_seek(0, .End); err != nil {
		return 0
	}

	if _, err = s->impl_seek(curr, .Start); err != nil {
		return 0
	}

	return end
}



// read_at reads len(p) bytes into p starting with the provided offset in the underlying Reader_At stream r.
// It returns the number of bytes read and any error if occurred.
//
// When read_at returns n < len(p), it returns a non-nil Error explaining why.
//
// If n == len(p), err may be either nil or .EOF
read_at :: proc(r: Reader_At, p: []byte, offset: i64, n_read: ^int = nil) -> (n: int, err: Error) {
	defer if n_read != nil {
		n_read^ += n
	}
	
	if r.stream_vtable == nil {
		return 0, .Empty
	}
	if r.impl_read_at != nil {
		return r->impl_read_at(p, offset)
	}
	if r.impl_seek == nil || r.impl_read == nil {
		return 0, .Empty
	}

	curr_offset := r->impl_seek(offset, .Current) or_return

	n, err = r->impl_read(p)
	_, err1 := r->impl_seek(curr_offset, .Start)
	if err1 != nil && err == nil {
		err = err1
	}
	return

}

// write_at writes len(p) bytes into p starting with the provided offset in the underlying Writer_At stream w.
// It returns the number of bytes written and any error if occurred.
//
// If write_at is writing to a Writer_At which has a seek offset, then write_at should not affect the underlying
// seek offset.
write_at :: proc(w: Writer_At, p: []byte, offset: i64, n_written: ^int = nil) -> (n: int, err: Error) {
	defer if n_written != nil {
		n_written^ += n
	}
	
	if w.stream_vtable == nil {
		return 0, .Empty
	}
	if w.impl_write_at != nil {
		return w->impl_write_at(p, offset)
	}
	if w.impl_seek == nil || w.impl_write == nil {
		return 0, .Empty
	}

	curr_offset: i64
	curr_offset, err = w->impl_seek(offset, .Current)
	if err != nil {
		return 0, err
	}

	n, err = w->impl_write(p)
	_, err1 := w->impl_seek(curr_offset, .Start)
	if err1 != nil && err == nil {
		err = err1
	}
	return
}

write_to :: proc(r: Writer_To, w: Writer) -> (n: i64, err: Error) {
	if r.stream_vtable == nil || w.stream_vtable == nil {
		return 0, .Empty
	}
	if r.impl_write_to != nil {
		return r->impl_write_to(w)
	}
	return 0, .Empty
}
read_from :: proc(w: Reader_From, r: Reader) -> (n: i64, err: Error) {
	if r.stream_vtable == nil || w.stream_vtable == nil {
		return 0, .Empty
	}
	if r.impl_read_from != nil {
		return w->impl_read_from(r)
	}
	return 0, .Empty
}


// read_byte reads and returns the next byte from r.
read_byte :: proc(r: Reader, n_read: ^int = nil) -> (b: byte, err: Error) {
	defer if err == nil && n_read != nil {
		n_read^ += 1
	}
	
	if r.stream_vtable == nil {
		return 0, .Empty
	}
	if r.impl_read_byte != nil {
		return r->impl_read_byte()
	}
	if r.impl_read == nil {
		return 0, .Empty
	}

	buf: [1]byte
	_, err = r->impl_read(buf[:])
	return buf[0], err
}

write_byte :: proc(w: Writer, c: byte, n_written: ^int = nil) -> Error {
	return _write_byte(auto_cast w, c, n_written)
}

@(private)
_write_byte :: proc(w: Writer, c: byte, n_written: ^int = nil) -> (err: Error) {
	defer if err == nil && n_written != nil {
		n_written^ += 1
	}
	if w.stream_vtable == nil {
		return .Empty
	}
	if w.impl_write_byte != nil {
		return w->impl_write_byte(c)
	}
	if w.impl_write == nil {
		return .Empty
	}

	b := [1]byte{c}
	_, err = w->impl_write(b[:])
	return err
}

// read_rune reads a single UTF-8 encoded Unicode codepoint and returns the rune and its size in bytes.
read_rune :: proc(br: Reader, n_read: ^int = nil) -> (ch: rune, size: int, err: Error) {
	defer if err == nil && n_read != nil {
		n_read^ += size
	}
	if br.stream_vtable == nil {
		return 0, 0, .Empty
	}
	if br.impl_read_rune != nil {
		return br->impl_read_rune()
	}
	if br.impl_read == nil {
		return 0, 0, .Empty
	}

	b: [utf8.UTF_MAX]byte
	_, err = br->impl_read(b[:1])
	

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
	size, err = br->impl_read(b[1:sz])
	if err != nil || size+1 < sz {
		ch = utf8.RUNE_ERROR
		return
	}

	ch, size = utf8.decode_rune(b[:sz])
	return
}

unread_byte :: proc(s: Stream) -> Error {
	if s.stream_vtable == nil {
		return .Empty
	}
	if s.impl_unread_byte != nil {
		return s->impl_unread_byte()
	}
	if s.impl_seek != nil {
		_, err := s->impl_seek(-1, .Current)
		return err
	}

	return .Empty
}
unread_rune :: proc(s: Writer) -> Error {
	if s.stream_vtable != nil && s.impl_unread_rune != nil {
		return s->impl_unread_rune()
	}
	return .Empty
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
	
	if s.stream_vtable == nil {
		return 0, .Empty
	}
	if s.impl_write_rune != nil {
		return s->impl_write_rune(r)
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
	if dst.stream_vtable == nil || src.stream_vtable == nil {
		return 0, .Empty
	}
	if src.impl_write_to != nil {
		return src->impl_write_to(dst)
	}
	if src.impl_read_from != nil {
		return dst->impl_read_from(src)
	}
	buf := buf
	if buf == nil {
		DEFAULT_SIZE :: 4 * 1024
		size := DEFAULT_SIZE
		if src.stream_vtable == _limited_reader_vtable {
			l := (^Limited_Reader)(src.stream_data)
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
