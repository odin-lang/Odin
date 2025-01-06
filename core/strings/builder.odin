package strings

import "base:runtime"
import "core:unicode/utf8"
import "core:strconv"
import "core:mem"
import "core:io"
/*
Type definition for a procedure that flushes a Builder

Inputs:
- b: A pointer to the Builder

Returns:
A boolean indicating whether the Builder should be reset
*/
Builder_Flush_Proc :: #type proc(b: ^Builder) -> (do_reset: bool)
/*
A dynamic byte buffer / string builder with helper procedures
The dynamic array is wrapped inside the struct to be more opaque
You can use `fmt.sbprint*` procedures with a `^strings.Builder` directly
*/
Builder :: struct {
	buf: [dynamic]byte,
}
/*
Produces an empty Builder

*Allocates Using Provided Allocator*

Inputs:
- allocator: (default is context.allocator)

Returns:
- res: The new Builder
- err: An optional allocator error if one occured, `nil` otherwise
*/
builder_make_none :: proc(allocator := context.allocator, loc := #caller_location) -> (res: Builder, err: mem.Allocator_Error) #optional_allocator_error {
	return Builder{buf=make([dynamic]byte, allocator, loc) or_return }, nil
}
/*
Produces a Builder with specified length and capacity `len`.

*Allocates Using Provided Allocator*

Inputs:
- len: The desired length of the Builder's buffer
- allocator: (default is context.allocator)

Returns:
- res: The new Builder
- err: An optional allocator error if one occured, `nil` otherwise
*/
builder_make_len :: proc(len: int, allocator := context.allocator, loc := #caller_location) -> (res: Builder, err: mem.Allocator_Error) #optional_allocator_error {
	return Builder{buf=make([dynamic]byte, len, allocator, loc) or_return }, nil
}
/*
Produces a Builder with specified length `len` and capacity `cap`.

*Allocates Using Provided Allocator*

Inputs:
- len: The desired length of the Builder's buffer
- cap: The desired capacity of the Builder's buffer, cap is max(cap, len)
- allocator: (default is context.allocator)

Returns:
- res: The new Builder
- err: An optional allocator error if one occured, `nil` otherwise
*/
builder_make_len_cap :: proc(len, cap: int, allocator := context.allocator, loc := #caller_location) -> (res: Builder, err: mem.Allocator_Error) #optional_allocator_error {
	return Builder{buf=make([dynamic]byte, len, cap, allocator, loc) or_return }, nil
}
/*
Produces a String Builder

*Allocates Using Provided Allocator*

Example:

	import "core:fmt"
	import "core:strings"
	builder_make_example :: proc() {
		sb := strings.builder_make()
		strings.write_byte(&sb, 'a')
		strings.write_string(&sb, " slice of ")
		strings.write_f64(&sb, 3.14,'g',true) // See `fmt.fmt_float` byte codes
		strings.write_string(&sb, " is ")
		strings.write_int(&sb, 180)
		strings.write_rune(&sb,'°')
		the_string :=strings.to_string(sb)
		fmt.println(the_string)
	}

Output:

	a slice of +3.14 is 180°

*/
builder_make :: proc{
	builder_make_none,
	builder_make_len,
	builder_make_len_cap,
}
/*
Initializes an empty Builder
It replaces the existing `buf`

*Allocates Using Provided Allocator*

Inputs:
- b: A pointer to the Builder
- allocator: (default is context.allocator)

Returns:
- res: A pointer to the initialized Builder
- err: An optional allocator error if one occured, `nil` otherwise
*/
builder_init_none :: proc(b: ^Builder, allocator := context.allocator, loc := #caller_location) -> (res: ^Builder, err: mem.Allocator_Error) #optional_allocator_error {
	b.buf = make([dynamic]byte, allocator, loc) or_return
	return b, nil
}
/*
Initializes a Builder with specified length and capacity `len`.
It replaces the existing `buf`

*Allocates Using Provided Allocator*

Inputs:
- b: A pointer to the Builder
- len: The desired length of the Builder's buffer
- allocator: (default is context.allocator)

Returns:
- res: A pointer to the initialized Builder
- err: An optional allocator error if one occured, `nil` otherwise
*/
builder_init_len :: proc(b: ^Builder, len: int, allocator := context.allocator, loc := #caller_location) -> (res: ^Builder, err: mem.Allocator_Error) #optional_allocator_error {
	b.buf = make([dynamic]byte, len, allocator, loc) or_return
	return b, nil
}
/*
Initializes a Builder with specified length `len` and capacity `cap`.
It replaces the existing `buf`

Inputs:
- b: A pointer to the Builder
- len: The desired length of the Builder's buffer
- cap: The desired capacity of the Builder's buffer, actual max(len,cap)
- allocator: (default is context.allocator)

Returns:
- res: A pointer to the initialized Builder
- err: An optional allocator error if one occured, `nil` otherwise
*/
builder_init_len_cap :: proc(b: ^Builder, len, cap: int, allocator := context.allocator, loc := #caller_location) -> (res: ^Builder, err: mem.Allocator_Error) #optional_allocator_error {
	b.buf = make([dynamic]byte, len, cap, allocator, loc) or_return
	return b, nil
}
// Overload simple `builder_init_*` with or without len / ap parameters
builder_init :: proc{
	builder_init_none,
	builder_init_len,
	builder_init_len_cap,
}
@(private)
_builder_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	b := (^Builder)(stream_data)
	#partial switch mode {
	case .Write:
		n = i64(write_bytes(b, p))
		if n < i64(len(p)) {
			err = .EOF
		}
		return
	case .Size:
		n = i64(len(b.buf))
		return
	case .Destroy:
		builder_destroy(b)
		return
	case .Query:
		return io.query_utility({.Write, .Size, .Destroy, .Query})
	}
	return 0, .Empty
}

/*
Returns an io.Stream from a Builder

Inputs:
- b: A pointer to the Builder

Returns:
- res: the io.Stream
*/
to_stream :: proc(b: ^Builder) -> (res: io.Stream) {
	return io.Stream{procedure=_builder_stream_proc, data=b}
}
/*
Returns an io.Writer from a Builder

Inputs:
- b: A pointer to the Builder

Returns:
- res: The io.Writer
*/
to_writer :: proc(b: ^Builder) -> (res: io.Writer) {
	return io.to_writer(to_stream(b))
}
/*
Deletes the Builder byte buffer content

Inputs:
- b: A pointer to the Builder
*/
builder_destroy :: proc(b: ^Builder) {
	delete(b.buf)
	b.buf = nil
}
/*
Reserves the Builder byte buffer to a specific capacity, when it's higher than before

Inputs:
- b: A pointer to the Builder
- cap: The desired capacity for the Builder's buffer
*/
builder_grow :: proc(b: ^Builder, cap: int) {
	reserve(&b.buf, cap)
}
/*
Clears the Builder byte buffer content (sets len to zero)

Inputs:
- b: A pointer to the Builder
*/
builder_reset :: proc(b: ^Builder) {
	clear(&b.buf)
}
/*
Creates a Builder from a slice of bytes with the same slice length as its capacity. Used in fmt.bprint*

*Uses Nil Allocator - Does NOT allocate*

Inputs:
- backing: A slice of bytes to be used as the backing buffer

Returns:
- res: The new Builder

Example:

	import "core:fmt"
	import "core:strings"
	builder_from_bytes_example :: proc() {
		bytes: [8]byte // <-- gets filled
		builder := strings.builder_from_bytes(bytes[:])
		strings.write_byte(&builder, 'a')
		fmt.println(strings.to_string(builder)) // -> "a"
		strings.write_byte(&builder, 'b')
		fmt.println(strings.to_string(builder)) // -> "ab"
	}

Output:

	a
	ab

*/
builder_from_bytes :: proc(backing: []byte) -> (res: Builder) {
	return Builder{ buf = mem.buffer_from_slice(backing) }
}
// Alias to `builder_from_bytes`
builder_from_slice :: builder_from_bytes
/*
Casts the Builder byte buffer to a string and returns it

Inputs:
- b: A Builder

Returns:
- res: The contents of the Builder's buffer, as a string
*/
to_string :: proc(b: Builder) -> (res: string) {
	return string(b.buf[:])
}
/*
Appends a trailing null byte after the end of the current Builder byte buffer and then casts it to a cstring

Inputs:
- b: A pointer to builder

Returns:
- res: A cstring of the Builder's buffer
*/
to_cstring :: proc(b: ^Builder) -> (res: cstring) {
	append(&b.buf, 0)
	pop(&b.buf)
	return cstring(raw_data(b.buf))
}
/*
Returns the length of the Builder's buffer, in bytes

Inputs:
- b: A Builder

Returns:
- res: The length of the Builder's buffer
*/
builder_len :: proc(b: Builder) -> (res: int) {
	return len(b.buf)
}
/*
Returns the capacity of the Builder's buffer, in bytes

Inputs:
- b: A Builder

Returns:
- res: The capacity of the Builder's buffer
*/
builder_cap :: proc(b: Builder) -> (res: int) {
	return cap(b.buf)
}
/*
The free space left in the Builder's buffer, in bytes

Inputs:
- b: A Builder

Returns:
- res: The available space left in the Builder's buffer
*/
builder_space :: proc(b: Builder) -> (res: int) {
	return cap(b.buf) - len(b.buf)
}
/*
Appends a byte to the Builder and returns the number of bytes appended

Inputs:
- b: A pointer to the Builder
- x: The byte to be appended

Returns:
- n: The number of bytes appended

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Example:

	import "core:fmt"
	import "core:strings"

	write_byte_example :: proc() {
		builder := strings.builder_make()
		strings.write_byte(&builder, 'a')        // 1
		strings.write_byte(&builder, 'b')        // 1
		fmt.println(strings.to_string(builder))  // -> ab
	}

Output:

	ab

*/
write_byte :: proc(b: ^Builder, x: byte, loc := #caller_location) -> (n: int) {
	n0 := len(b.buf)
	append(&b.buf, x, loc)
	n1 := len(b.buf)
	return n1-n0
}
/*
Appends a slice of bytes to the Builder and returns the number of bytes appended

Inputs:
- b: A pointer to the Builder
- x: The slice of bytes to be appended

Example:

	import "core:fmt"
	import "core:strings"

	write_bytes_example :: proc() {
		builder := strings.builder_make()
		bytes := [?]byte { 'a', 'b', 'c' }
		strings.write_bytes(&builder, bytes[:]) // 3
		fmt.println(strings.to_string(builder)) // -> abc
	}

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Returns:
- n: The number of bytes appended
*/
write_bytes :: proc(b: ^Builder, x: []byte, loc := #caller_location) -> (n: int) {
	n0 := len(b.buf)
	append(&b.buf, ..x, loc=loc)
	n1 := len(b.buf)
	return n1-n0
}
/*
Appends a single rune to the Builder and returns the number of bytes written and an `io.Error`

Inputs:
- b: A pointer to the Builder
- r: The rune to be appended

Returns:
- res: The number of bytes written
- err: An io.Error if one occured, `nil` otherwise

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Example:

	import "core:fmt"
	import "core:strings"

	write_rune_example :: proc() {
		builder := strings.builder_make()
		strings.write_rune(&builder, 'ä')     // 2 None
		strings.write_rune(&builder, 'b')       // 1 None
		fmt.println(strings.to_string(builder)) // -> äb
	}

Output:

	äb

*/
write_rune :: proc(b: ^Builder, r: rune) -> (res: int, err: io.Error) {
	return io.write_rune(to_writer(b), r)
}
/*
Appends a quoted rune to the Builder and returns the number of bytes written

Inputs:
- b: A pointer to the Builder
- r: The rune to be appended

Returns:
- n: The number of bytes written

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Example:

	import "core:fmt"
	import "core:strings"

	write_quoted_rune_example :: proc() {
		builder := strings.builder_make()
		strings.write_string(&builder, "abc")      // 3
		strings.write_quoted_rune(&builder, 'ä') // 4
		strings.write_string(&builder, "abc")      // 3
		fmt.println(strings.to_string(builder))    // -> abc'ä'abc
	}

Output:

	abc'ä'abc

*/
write_quoted_rune :: proc(b: ^Builder, r: rune) -> (n: int) {
	return io.write_quoted_rune(to_writer(b), r)
}
/*
Appends a string to the Builder and returns the number of bytes written

Inputs:
- b: A pointer to the Builder
- s: The string to be appended

Returns:
- n: The number of bytes written

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Example:

	import "core:fmt"
	import "core:strings"

	write_string_example :: proc() {
		builder := strings.builder_make()
		strings.write_string(&builder, "a")     // 1
		strings.write_string(&builder, "bc")    // 2
		fmt.println(strings.to_string(builder)) // -> abc
	}

Output:

	abc

*/
write_string :: proc(b: ^Builder, s: string) -> (n: int) {
	n0 := len(b.buf)
	append(&b.buf, s)
	n1 := len(b.buf)
	return n1-n0
}
/*
Pops and returns the last byte in the Builder or 0 when the Builder is empty

Inputs:
- b: A pointer to the Builder

Returns:
- r: The last byte in the Builder or 0 if empty
*/
pop_byte :: proc(b: ^Builder) -> (r: byte) {
	if len(b.buf) == 0 {
		return 0
	}

	r = b.buf[len(b.buf)-1]
	d := (^runtime.Raw_Dynamic_Array)(&b.buf)
	d.len = max(d.len-1, 0)
	return
}
/*
Pops the last rune in the Builder and returns the popped rune and its rune width or (0, 0) if empty

Inputs:
- b: A pointer to the Builder

Returns:
- r: The popped rune
- width: The rune width or 0 if the builder was empty
*/
pop_rune :: proc(b: ^Builder) -> (r: rune, width: int) {
	if len(b.buf) == 0 {
		return 0, 0
	}

	r, width = utf8.decode_last_rune(b.buf[:])
	d := (^runtime.Raw_Dynamic_Array)(&b.buf)
	d.len = max(d.len-width, 0)
	return
}
@(private)
DIGITS_LOWER := "0123456789abcdefx"
/*
Inputs:
- b: A pointer to the Builder
- str: The string to be quoted and appended
- quote: The optional quote character (default is double quotes)

Returns:
- n: The number of bytes written

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Example:

	import "core:fmt"
	import "core:strings"

	write_quoted_string_example :: proc() {
		builder := strings.builder_make()
		strings.write_quoted_string(&builder, "a")        // 3
		strings.write_quoted_string(&builder, "bc", '\'') // 4
		strings.write_quoted_string(&builder, "xyz")      // 5
		fmt.println(strings.to_string(builder))
	}

Output:

	"a"'bc'"xyz"

*/
write_quoted_string :: proc(b: ^Builder, str: string, quote: byte = '"') -> (n: int) {
	n, _ = io.write_quoted_string(to_writer(b), str, quote)
	return
}
/*
Appends a rune to the Builder and returns the number of bytes written

Inputs:
- b: A pointer to the Builder
- r: The rune to be appended
- write_quote: Optional boolean flag to wrap in single-quotes (') (default is true)

Returns:
- n: The number of bytes written

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Example:

	import "core:fmt"
	import "core:strings"

	write_encoded_rune_example :: proc() {
		builder := strings.builder_make()
		strings.write_encoded_rune(&builder, 'a', false) // 1
		strings.write_encoded_rune(&builder, '\"', true) // 3
		strings.write_encoded_rune(&builder, 'x', false) // 1
		fmt.println(strings.to_string(builder))
	}

Output:

	a'"'x

*/
write_encoded_rune :: proc(b: ^Builder, r: rune, write_quote := true) -> (n: int) {
	n, _ = io.write_encoded_rune(to_writer(b), r, write_quote)
	return

}
/*
Appends an escaped rune to the Builder and returns the number of bytes written

Inputs:
- b: A pointer to the Builder
- r: The rune to be appended
- quote: The quote character
- html_safe: Optional boolean flag to encode '<', '>', '&' as digits (default is false)

**Usage**
- '\a' will be written as such
- `r` and `quote` match and `quote` is `\\` - they will be written as two slashes
- `html_safe` flag in case the runes '<', '>', '&' should be encoded as digits e.g. `\u0026`

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Returns:
- n: The number of bytes written
*/
write_escaped_rune :: proc(b: ^Builder, r: rune, quote: byte, html_safe := false) -> (n: int) {
	n, _ = io.write_escaped_rune(to_writer(b), r, quote, html_safe)
	return
}
/*
Writes a f64 value to the Builder and returns the number of characters written

Inputs:
- b: A pointer to the Builder
- f: The f64 value to be appended
- fmt: The format byte
- prec: The precision
- bit_size: The bit size
- always_signed: Optional boolean flag to always include the sign (default is false)

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Returns:
- n: The number of characters written
*/
write_float :: proc(b: ^Builder, f: f64, fmt: byte, prec, bit_size: int, always_signed := false) -> (n: int) {
	buf: [384]byte
	s := strconv.append_float(buf[:], f, fmt, prec, bit_size)
	// If the result starts with a `+` then unless we always want signed results,
	// we skip it unless it's followed by an `I` (because of +Inf).
	if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
		s = s[1:]
	}
	return write_string(b, s)
}
/*
Writes a f16 value to the Builder and returns the number of characters written

Inputs:
- b: A pointer to the Builder
- f: The f16 value to be appended
- fmt: The format byte
- always_signed: Optional boolean flag to always include the sign

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Returns:
- n: The number of characters written
*/
write_f16 :: proc(b: ^Builder, f: f16, fmt: byte, always_signed := false) -> (n: int) {
	buf: [384]byte
	s := strconv.append_float(buf[:], f64(f), fmt, 2*size_of(f), 8*size_of(f))
	if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
		s = s[1:]
	}
	return write_string(b, s)
}
/*
Writes a f32 value to the Builder and returns the number of characters written

Inputs:
- b: A pointer to the Builder
- f: The f32 value to be appended
- fmt: The format byte
- always_signed: Optional boolean flag to always include the sign

Returns:
- n: The number of characters written

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Example:

	import "core:fmt"
	import "core:strings"

	write_f32_example :: proc() {
		builder := strings.builder_make()
		strings.write_f32(&builder, 3.14159, 'f') // 6
		strings.write_string(&builder, " - ")     // 3
		strings.write_f32(&builder, -0.123, 'e')  // 8
		fmt.println(strings.to_string(builder))   // -> 3.14159012 - -1.23000003e-01
	}

Output:

	3.14159012 - -1.23000003e-01

*/
write_f32 :: proc(b: ^Builder, f: f32, fmt: byte, always_signed := false) -> (n: int) {
	buf: [384]byte
	s := strconv.append_float(buf[:], f64(f), fmt, 2*size_of(f), 8*size_of(f))
	if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
		s = s[1:]
	}
	return write_string(b, s)
}
/*
Writes a f64 value to the Builder and returns the number of characters written

Inputs:
- b: A pointer to the Builder
- f: The f64 value to be appended
- fmt: The format byte
- always_signed: Optional boolean flag to always include the sign

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Returns:
- n: The number of characters written
*/
write_f64 :: proc(b: ^Builder, f: f64, fmt: byte, always_signed := false) -> (n: int) {
	buf: [384]byte
	s := strconv.append_float(buf[:], f64(f), fmt, 2*size_of(f), 8*size_of(f))
	if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
		s = s[1:]
	}
	return write_string(b, s)
}
/*
Writes a u64 value to the Builder and returns the number of characters written

Inputs:
- b: A pointer to the Builder
- i: The u64 value to be appended
- base: The optional base for the numeric representation

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Returns:
- n: The number of characters written
*/
write_u64 :: proc(b: ^Builder, i: u64, base: int = 10) -> (n: int) {
	buf: [32]byte
	s := strconv.append_bits(buf[:], i, base, false, 64, strconv.digits, nil)
	return write_string(b, s)
}
/*
Writes a i64 value to the Builder and returns the number of characters written

Inputs:
- b: A pointer to the Builder
- i: The i64 value to be appended
- base: The optional base for the numeric representation

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Returns:
- n: The number of characters written
*/
write_i64 :: proc(b: ^Builder, i: i64, base: int = 10) -> (n: int) {
	buf: [32]byte
	s := strconv.append_bits(buf[:], u64(i), base, true, 64, strconv.digits, nil)
	return write_string(b, s)
}
/*
Writes a uint value to the Builder and returns the number of characters written

Inputs:
- b: A pointer to the Builder
- i: The uint value to be appended
- base: The optional base for the numeric representation

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Returns:
- n: The number of characters written
*/
write_uint :: proc(b: ^Builder, i: uint, base: int = 10) -> (n: int) {
	return write_u64(b, u64(i), base)
}
/*
Writes a int value to the Builder and returns the number of characters written

Inputs:
- b: A pointer to the Builder
- i: The int value to be appended
- base: The optional base for the numeric representation

NOTE: The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

Returns:
- n: The number of characters written
*/
write_int :: proc(b: ^Builder, i: int, base: int = 10) -> (n: int) {
	return write_i64(b, i64(i), base)
}
