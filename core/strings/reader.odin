package strings

import "core:io"
import "core:unicode/utf8"

/*
io stream data for a string reader that can read based on bytes or runes
implements the vtable when using the `io.Reader` variants
"read" calls advance the current reading offset `i`
*/
Reader :: struct {
	s:         string, // read-only buffer
	i:         i64,    // current reading index
	prev_rune: int,    // previous reading index of rune or < 0
}
/*
Initializes a string Reader with the provided string

Inputs:
- r: A pointer to a Reader struct
- s: The input string to be read
*/
reader_init :: proc(r: ^Reader, s: string) {
	r.s = s
	r.i = 0
	r.prev_rune = -1
}
/*
Converts a Reader into an `io.Stream`

Inputs:
- r: A pointer to a Reader struct

Returns:
- s: An io.Stream for the given Reader
*/
reader_to_stream :: proc(r: ^Reader) -> (s: io.Stream) {
	s.data = r
	s.procedure = _reader_proc
	return
}
/*
Initializes a string Reader and returns an `io.Reader` for the given string

Inputs:
- r: A pointer to a Reader struct
- s: The input string to be read

Returns:
- res: An io.Reader for the given string
*/
to_reader :: proc(r: ^Reader, s: string) -> (res: io.Reader) {
	reader_init(r, s)
	rr, _ := io.to_reader(reader_to_stream(r))
	return rr
}
/*
Initializes a string Reader and returns an `io.Reader_At` for the given string

Inputs:
- r: A pointer to a Reader struct
- s: The input string to be read

Returns:
- res: An `io.Reader_At` for the given string
*/
to_reader_at :: proc(r: ^Reader, s: string) -> (res: io.Reader_At) {
	reader_init(r, s)
	rr, _ := io.to_reader_at(reader_to_stream(r))
	return rr
}
/*
Returns the remaining length of the Reader

Inputs:
- r: A pointer to a Reader struct

Returns:
- res: The remaining length of the Reader
*/
reader_length :: proc(r: ^Reader) -> (res: int) {
	if r.i >= i64(len(r.s)) {
		return 0
	}
	return int(i64(len(r.s)) - r.i)
}
/*
Returns the length of the string stored in the Reader

Inputs:
- r: A pointer to a Reader struct

Returns:
- res: The length of the string stored in the Reader
*/
reader_size :: proc(r: ^Reader) -> (res: i64) {
	return i64(len(r.s))
}
/*
Reads len(p) bytes from the Reader's string and copies into the provided slice.

Inputs:
- r: A pointer to a Reader struct
- p: A byte slice to copy data into

Returns:
- n: The number of bytes read
- err: An `io.Error` if an error occurs while reading, including `.EOF`, otherwise `nil` denotes success.
*/
reader_read :: proc(r: ^Reader, p: []byte) -> (n: int, err: io.Error) {
	if r.i >= i64(len(r.s)) {
		return 0, .EOF
	}
	r.prev_rune = -1
	n = copy(p, r.s[r.i:])
	r.i += i64(n)
	return
}
/*
Reads len(p) bytes from the Reader's string and copies into the provided slice, at the specified offset from the current index.

Inputs:
- r: A pointer to a Reader struct
- p: A byte slice to copy data into
- off: The offset from which to read

Returns:
- n: The number of bytes read
- err: An `io.Error` if an error occurs while reading, including `.EOF`, otherwise `nil` denotes success.
*/
reader_read_at :: proc(r: ^Reader, p: []byte, off: i64) -> (n: int, err: io.Error) {
	if off < 0 {
		return 0, .Invalid_Offset
	}
	if off >= i64(len(r.s)) {
		return 0, .EOF
	}
	n = copy(p, r.s[off:])
	if n < len(p) {
		err = .EOF
	}
	return
}
/*
Reads and returns a single byte from the Reader's string

Inputs:
- r: A pointer to a Reader struct

Returns:
- The byte read from the Reader
- err: An `io.Error` if an error occurs while reading, including `.EOF`, otherwise `nil` denotes success.
*/
reader_read_byte :: proc(r: ^Reader) -> (res: byte, err: io.Error) {
	r.prev_rune = -1
	if r.i >= i64(len(r.s)) {
		return 0, .EOF
	}
	b := r.s[r.i]
	r.i += 1
	return b, nil
}
/*
Decrements the Reader's index (i) by 1

Inputs:
- r: A pointer to a Reader struct

Returns:
- err: An `io.Error` if `r.i <= 0` (`.Invalid_Unread`), otherwise `nil` denotes success.
*/
reader_unread_byte :: proc(r: ^Reader) -> (err: io.Error) {
	if r.i <= 0 {
		return .Invalid_Unread
	}
	r.prev_rune = -1
	r.i -= 1
	return nil
}
/*
Reads and returns a single rune and its `size` from the Reader's string

Inputs:
- r: A pointer to a Reader struct

Returns:
- rr: The rune read from the Reader
- size: The size of the rune in bytes
- err: An `io.Error` if an error occurs while reading
*/
reader_read_rune :: proc(r: ^Reader) -> (rr: rune, size: int, err: io.Error) {
	if r.i >= i64(len(r.s)) {
		r.prev_rune = -1
		return 0, 0, .EOF
	}
	r.prev_rune = int(r.i)
	if c := r.s[r.i]; c < utf8.RUNE_SELF {
		r.i += 1
		return rune(c), 1, nil
	}
	rr, size = utf8.decode_rune_in_string(r.s[r.i:])
	r.i += i64(size)
	return
}
/*
Decrements the Reader's index (i) by the size of the last read rune

Inputs:
- r: A pointer to a Reader struct

WARNING: May only be used once and after a valid `read_rune` call

Returns:
- err: An `io.Error` if an error occurs while unreading (`.Invalid_Unread`), else `nil` denotes success.
*/
reader_unread_rune :: proc(r: ^Reader) -> (err: io.Error) {
	if r.i <= 0 {
		return .Invalid_Unread
	}
	if r.prev_rune < 0 {
		return .Invalid_Unread
	}
	r.i = i64(r.prev_rune)
	r.prev_rune = -1
	return nil
}
/*
Seeks the Reader's index to a new position

Inputs:
- r: A pointer to a Reader struct
- offset: The new offset position
- whence: The reference point for the new position (`.Start`, `.Current`, or `.End`)

Returns:
- The absolute offset after seeking
- err: An `io.Error` if an error occurs while seeking (`.Invalid_Whence`, `.Invalid_Offset`)
*/
reader_seek :: proc(r: ^Reader, offset: i64, whence: io.Seek_From) -> (res: i64, err: io.Error) {
	r.prev_rune = -1
	abs: i64
	switch whence {
	case .Start:
		abs = offset
	case .Current:
		abs = r.i + offset
	case .End:
		abs = i64(len(r.s)) + offset
	case:
		return 0, .Invalid_Whence
	}

	if abs < 0 {
		return 0, .Invalid_Offset
	}
	r.i = abs
	return abs, nil
}
/*
Writes the remaining content of the Reader's string into the provided `io.Writer`

Inputs:
- r: A pointer to a Reader struct
- w: The io.Writer to write the remaining content into

WARNING: Panics if writer writes more bytes than remainig length of string.

Returns:
- n: The number of bytes written
- err: An io.Error if an error occurs while writing (`.Short_Write`)
*/
reader_write_to :: proc(r: ^Reader, w: io.Writer) -> (n: i64, err: io.Error) {
	r.prev_rune = -1
	if r.i >= i64(len(r.s)) {
		return 0, nil
	}
	s := r.s[r.i:]
	m: int
	m, err = io.write_string(w, s)
	if m > len(s) {
		panic("bytes.Reader.write_to: invalid io.write_string count")
	}
	r.i += i64(m)
	n = i64(m)
	if m != len(s) && err == nil {
		err = .Short_Write
	}
	return
}
/*
VTable containing implementations for various `io.Stream` methods

This VTable is used by the Reader struct to provide its functionality
as an `io.Stream`.
*/
@(private)
_reader_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Reader)(stream_data)
	#partial switch mode {
	case .Size:
		n = reader_size(r)
		return
	case .Read:
		return io._i64_err(reader_read(r, p))
	case .Read_At:
		return io._i64_err(reader_read_at(r, p, offset))
	case .Seek:
		n, err = reader_seek(r, offset, whence)
		return
	case .Query:
		return io.query_utility({.Size, .Read, .Read_At, .Seek, .Query})
	}
	return 0, .Empty
}
