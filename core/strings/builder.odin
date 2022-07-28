package strings

import "core:runtime"
import "core:unicode/utf8"
import "core:strconv"
import "core:io"

Builder_Flush_Proc :: #type proc(b: ^Builder) -> (do_reset: bool)

/*
	dynamic byte buffer / string builder with helper procedures
	the dynamic array is wrapped inside the struct to be more opaque
	you can use `fmt.sbprint*` procedures with a `^strings.Builder` directly
*/
Builder :: struct {
	buf: [dynamic]byte,
}

// return a builder, default length 0 / cap 16 are done through make
builder_make_none :: proc(allocator := context.allocator) -> Builder {
	return Builder{buf=make([dynamic]byte, allocator)}
}

// return a builder, with a set length `len` and cap 16 byte buffer
builder_make_len :: proc(len: int, allocator := context.allocator) -> Builder {
	return Builder{buf=make([dynamic]byte, len, allocator)}
}

// return a builder, with a set length `len` byte buffer and a custom `cap`
builder_make_len_cap :: proc(len, cap: int, allocator := context.allocator) -> Builder {
	return Builder{buf=make([dynamic]byte, len, cap, allocator)}
}

// overload simple `builder_make_*` with or without len / cap parameters
builder_make :: proc{
	builder_make_none,
	builder_make_len,
	builder_make_len_cap,
}

// initialize a builder, default length 0 / cap 16 are done through make
// replaces the existing `buf`
builder_init_none :: proc(b: ^Builder, allocator := context.allocator) -> ^Builder {
	b.buf = make([dynamic]byte, allocator)
	return b
}

// initialize a builder, with a set length `len` and cap 16 byte buffer
// replaces the existing `buf`
builder_init_len :: proc(b: ^Builder, len: int, allocator := context.allocator) -> ^Builder {
	b.buf = make([dynamic]byte, len, allocator)
	return b
}

// initialize a builder, with a set length `len` byte buffer and a custom `cap`
// replaces the existing `buf`
builder_init_len_cap :: proc(b: ^Builder, len, cap: int, allocator := context.allocator) -> ^Builder {
	b.buf = make([dynamic]byte, len, cap, allocator)
	return b
}

// overload simple `builder_init_*` with or without len / ap parameters
builder_init :: proc{
	builder_init_none,
	builder_init_len,
	builder_init_len_cap,
}

@(private)
_builder_stream_vtable := &io.Stream_VTable{
	impl_write = proc(s: io.Stream, p: []byte) -> (n: int, err: io.Error) {
		b := (^Builder)(s.stream_data)
		n = write_bytes(b, p)
		if n < len(p) {
			err = .EOF
		}
		return
	},
	impl_write_byte = proc(s: io.Stream, c: byte) -> (err: io.Error) {
		b := (^Builder)(s.stream_data)
		n := write_byte(b, c)
		if n == 0 {
			err = .EOF
		}
		return
	},
	impl_size = proc(s: io.Stream) -> i64 {
		b := (^Builder)(s.stream_data)
		return i64(len(b.buf))
	},
	impl_destroy = proc(s: io.Stream) -> io.Error {
		b := (^Builder)(s.stream_data)
		delete(b.buf)
		return .None
	},
}

// return an `io.Stream` from a builder
to_stream :: proc(b: ^Builder) -> io.Stream {
	return io.Stream{stream_vtable=_builder_stream_vtable, stream_data=b}
}

// return an `io.Writer` from a builder
to_writer :: proc(b: ^Builder) -> io.Writer {
	return io.to_writer(to_stream(b))
}

// delete and clear the builder byte buffer content
builder_destroy :: proc(b: ^Builder) {
	delete(b.buf)
	clear(&b.buf)
}

// reserve the builfer byte buffer to a specific cap, when it's higher than before
builder_grow :: proc(b: ^Builder, cap: int) {
	reserve(&b.buf, cap)
}

// clear the builder byte buffer content
builder_reset :: proc(b: ^Builder) {
	clear(&b.buf)
}

/*
	create an empty builder with the same slice length as its cap
	uses the `mem.nil_allocator` to avoid allocation and keep a fixed length
	used in `fmt.bprint*`
	
	bytes: [8]byte // <-- gets filled
	builder := strings.builder_from_bytes(bytes[:])
	strings.write_byte(&builder, 'a') -> "a"
	strings.write_byte(&builder, 'b') -> "ab"
*/
builder_from_bytes :: proc(backing: []byte) -> Builder {
	s := transmute(runtime.Raw_Slice)backing
	d := runtime.Raw_Dynamic_Array{
		data = s.data,
		len  = 0,
		cap  = s.len,
		allocator = runtime.nil_allocator(),
	}
	return Builder{
		buf = transmute([dynamic]byte)d,
	}
}
builder_from_slice :: builder_from_bytes

// cast the builder byte buffer to a string and return it
to_string :: proc(b: Builder) -> string {
	return string(b.buf[:])
}

// return the length of the builder byte buffer
builder_len :: proc(b: Builder) -> int {
	return len(b.buf)
}

// return the cap of the builder byte buffer
builder_cap :: proc(b: Builder) -> int {
	return cap(b.buf)
}

// returns the space left in the builder byte buffer to use up
builder_space :: proc(b: Builder) -> int {
	return cap(b.buf) - len(b.buf)
}

/*
	appends a byte to the builder, returns the append diff

	builder := strings.builder_make()
	strings.write_byte(&builder, 'a') // 1
	strings.write_byte(&builder, 'b') // 1
	strings.write_byte(&builder, 'c') // 1
	fmt.println(strings.to_string(builder)) // -> abc
*/
write_byte :: proc(b: ^Builder, x: byte) -> (n: int) {
	n0 := len(b.buf)
	append(&b.buf, x)
	n1 := len(b.buf)
	return n1-n0
}

/*
	appends a slice of bytes to the builder, returns the append diff

	builder := strings.builder_make()
	bytes := [?]byte { 'a', 'b', 'c' }
	strings.write_bytes(&builder, bytes[:]) // 3
	fmt.println(strings.to_string(builder)) // -> abc
*/
write_bytes :: proc(b: ^Builder, x: []byte) -> (n: int) {
	n0 := len(b.buf)
	append(&b.buf, ..x)
	n1 := len(b.buf)
	return n1-n0
}

/*
	appends a single rune into the builder, returns written rune size and an `io.Error`

	builder := strings.builder_make()
	strings.write_rune(&builder, 'ä') // 2 None
	strings.write_rune(&builder, 'b') // 1 None
	strings.write_rune(&builder, 'c') // 1 None
	fmt.println(strings.to_string(builder)) // -> äbc
*/
write_rune :: proc(b: ^Builder, r: rune) -> (int, io.Error) {
	return io.write_rune(to_writer(b), r)
}

/*
	appends a quoted rune into the builder, returns written size

	builder := strings.builder_make()
	strings.write_string(&builder, "abc") // 3
	strings.write_quoted_rune(&builder, 'ä') // 4
	strings.write_string(&builder, "abc") // 3
	fmt.println(strings.to_string(builder)) // -> abc'ä'abc
*/
write_quoted_rune :: proc(b: ^Builder, r: rune) -> (n: int) {
	return io.write_quoted_rune(to_writer(b), r)
}


/*
	appends a string to the builder, return the written byte size
	
	builder := strings.builder_make()
	strings.write_string(&builder, "a") // 1
	strings.write_string(&builder, "bc") // 2	
	strings.write_string(&builder, "xyz") // 3
	fmt.println(strings.to_string(builder)) // -> abcxyz
*/
write_string :: proc(b: ^Builder, s: string) -> (n: int) {
	n0 := len(b.buf)
	append(&b.buf, s)
	n1 := len(b.buf)
	return n1-n0
}


// pops and returns the last byte in the builder
// returns 0 when the builder is empty
pop_byte :: proc(b: ^Builder) -> (r: byte) {
	if len(b.buf) == 0 {
		return 0
	}

	r = b.buf[len(b.buf)-1]
	d := cast(^runtime.Raw_Dynamic_Array)&b.buf
	d.len = max(d.len-1, 0)
	return
}

// pops the last rune in the builder and returns the popped rune and its rune width
// returns 0, 0 when the builder is empty
pop_rune :: proc(b: ^Builder) -> (r: rune, width: int) {
	if len(b.buf) == 0 {
		return 0, 0
	}

	r, width = utf8.decode_last_rune(b.buf[:])
	d := cast(^runtime.Raw_Dynamic_Array)&b.buf
	d.len = max(d.len-width, 0)
	return
}

@(private)
DIGITS_LOWER := "0123456789abcdefx"

/*
	append a quoted string into the builder, return the written byte size

	builder := strings.builder_make()
	strings.write_quoted_string(&builder, "a") // 3
	strings.write_quoted_string(&builder, "bc", '\'') // 4	
	strings.write_quoted_string(&builder, "xyz") // 5
	fmt.println(strings.to_string(builder)) // -> "a"'bc'xyz"
*/
write_quoted_string :: proc(b: ^Builder, str: string, quote: byte = '"') -> (n: int) {
	n, _ = io.write_quoted_string(to_writer(b), str, quote)
	return
}


// appends a rune to the builder, optional `write_quote` boolean tag, returns the written rune size
write_encoded_rune :: proc(b: ^Builder, r: rune, write_quote := true) -> (n: int) {
	n, _ = io.write_encoded_rune(to_writer(b), r, write_quote)
	return

}

// appends a rune to the builder, fully written out in case of escaped runes e.g. '\a' will be written as such
// when `r` and `quote` match and `quote` is `\\` - they will be written as two slashes
// `html_safe` flag in case the runes '<', '>', '&' should be encoded as digits e.g. `\u0026`
write_escaped_rune :: proc(b: ^Builder, r: rune, quote: byte, html_safe := false) -> (n: int) {
	n, _ = io.write_escaped_rune(to_writer(b), r, quote, html_safe)
	return
}

// writes a u64 value `i` in `base` = 10 into the builder, returns the written amount of characters
write_u64 :: proc(b: ^Builder, i: u64, base: int = 10) -> (n: int) {
	buf: [32]byte
	s := strconv.append_bits(buf[:], i, base, false, 64, strconv.digits, nil)
	return write_string(b, s)
}

// writes a i64 value `i` in `base` = 10 into the builder, returns the written amount of characters
write_i64 :: proc(b: ^Builder, i: i64, base: int = 10) -> (n: int) {
	buf: [32]byte
	s := strconv.append_bits(buf[:], u64(i), base, true, 64, strconv.digits, nil)
	return write_string(b, s)
}

// writes a uint value `i` in `base` = 10 into the builder, returns the written amount of characters
write_uint :: proc(b: ^Builder, i: uint, base: int = 10) -> (n: int) {
	return write_u64(b, u64(i), base)
}

// writes a int value `i` in `base` = 10 into the builder, returns the written amount of characters
write_int :: proc(b: ^Builder, i: int, base: int = 10) -> (n: int) {
	return write_i64(b, i64(i), base)
}

