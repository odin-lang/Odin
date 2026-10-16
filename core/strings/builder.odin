package strings

import "base:runtime"
import "core:unicode/utf8"
import "core:strconv"
import "core:io"

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
@(require_results)
builder_make_none :: proc(allocator := context.allocator, loc := #caller_location) -> (res: Builder, err: runtime.Allocator_Error) #optional_allocator_error {
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
@(require_results)
builder_make_len :: proc(len: int, allocator := context.allocator, loc := #caller_location) -> (res: Builder, err: runtime.Allocator_Error) #optional_allocator_error {
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
@(require_results)
builder_make_len_cap :: proc(len, cap: int, allocator := context.allocator, loc := #caller_location) -> (res: Builder, err: runtime.Allocator_Error) #optional_allocator_error {
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
builder_init_none :: proc(b: ^Builder, allocator := context.allocator, loc := #caller_location) -> (res: ^Builder, err: runtime.Allocator_Error) #optional_allocator_error {
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
builder_init_len :: proc(b: ^Builder, len: int, allocator := context.allocator, loc := #caller_location) -> (res: ^Builder, err: runtime.Allocator_Error) #optional_allocator_error {
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
builder_init_len_cap :: proc(b: ^Builder, len, cap: int, allocator := context.allocator, loc := #caller_location) -> (res: ^Builder, err: runtime.Allocator_Error) #optional_allocator_error {
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
	return 0, .Unsupported
}

/*
Returns an io.Stream from a Builder

Inputs:
- b: A pointer to the Builder

Returns:
- res: the io.Stream
*/
@(require_results)
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
@(require_results)
to_writer :: proc(b: ^Builder) -> (res: io.Writer) {
	return io.to_writer(to_stream(b))
}
/*
Deletes the Builder byte buffer content

NOTE: If the Builder is re-used after this operation, be aware that its stored allocator
      has been cleared as well.
      Consider calling `builder_init` to reinstate a specific allocator, if needed.

Inputs:
- b: A pointer to the Builder
*/
builder_destroy :: proc(b: ^Builder, loc := #caller_location) {
	// NOTE: Delete might not be supported (e.g. arena allocator).
	//       In this case, we set the buffer to nil anyway, which effectively
	//       behaves as if it got freed.
	//       If a real error occurred while freeing the memory, this will
	//       cause a memory leak.
	delete(b.buf, loc=loc)
	b.buf = nil
}
/*
Reserves the Builder byte buffer to a specific capacity, when it's higher than before

Inputs:
- b: A pointer to the Builder
- cap: The desired capacity for the Builder's buffer
*/
builder_grow :: proc(b: ^Builder, cap: int, loc := #caller_location) -> (err: runtime.Allocator_Error) {
	return reserve(&b.buf, cap, loc=loc)
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
@(require_results)
builder_from_bytes :: proc(backing: []byte) -> (res: Builder) {
	return Builder{
		buf = transmute([dynamic]byte)runtime.Raw_Dynamic_Array{
			data      = raw_data(backing),
			len       = 0,
			cap       = len(backing),
			allocator = runtime.Allocator{
				procedure = runtime.nil_allocator_proc,
				data = nil,
			},
		},
	}
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
@(require_results)
to_string :: proc(b: Builder) -> (res: string) {
	return string(b.buf[:])
}
/*
Appends a trailing null byte after the end of the current Builder byte buffer and then casts it to a cstring

NOTE: This procedure will not check if the backing buffer has enough space to include the extra null byte.

Inputs:
- b: A pointer to builder

Returns:
- res: A cstring of the Builder's buffer
- err: An allocator error if one occured, `nil` otherwise.
*/
@(require_results)
unsafe_to_cstring :: proc(b: ^Builder, loc := #caller_location) -> (res: cstring, err: runtime.Allocator_Error) #optional_allocator_error {
	append(&b.buf, 0, loc) or_return
	pop(&b.buf)
	return cstring(raw_data(b.buf)), nil
}
/*
Appends a trailing null byte after the end of the current Builder byte buffer and then casts it to a cstring

Inputs:
- b: A pointer to builder

Returns:
- res: A cstring of the Builder's buffer upon success
- err: An optional allocator error if one occured, `nil` otherwise
*/
@(require_results)
to_cstring :: proc(b: ^Builder, loc := #caller_location) -> (res: cstring, err: runtime.Allocator_Error) #optional_allocator_error {
	n := append(&b.buf, 0, loc) or_return
	if n != 1 {
		return nil, .Out_Of_Memory
	}
	pop(&b.buf)
	#no_bounds_check {
		assert(b.buf[len(b.buf)] == 0)
	}
	return cstring(raw_data(b.buf)), nil
}
/*
Returns the length of the Builder's buffer, in bytes

Inputs:
- b: A Builder

Returns:
- res: The length of the Builder's buffer
*/
@(require_results)
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
@(require_results)
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
@(require_results)
builder_space :: proc(b: Builder) -> (res: int) {
	return cap(b.buf) - len(b.buf)
}


/*
Appends a single byte `x` to the Builder `b`, and returns the number of bytes appended.

**Inputs:**
- `b`: A pointer to the Builder.
- `x`: The byte to be appended.

**Returns:**
- `n`: The number of bytes appended.
- `err`:  An allocator error if one occured, `nil` otherwise.

**Remarks:**

The backing dynamic array may be fixed in capacity or fail to resize; `n` states the number actually written.

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
write_byte :: proc(b: ^Builder, x: byte, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	n0 := len(b.buf)
	append(&b.buf, x, loc) or_return
	n1 := len(b.buf)
	return n1-n0, nil
}


/*
Appends a slice of bytes to the Builder `b`, and returns the number of bytes appended.

**Inputs:**
- `b`: A pointer to the Builder.
- `x`: The slice of bytes to be appended.

**Returns:**
- `n`: The number of bytes appended.
- `err`:  An allocator error if one occured, `nil` otherwise.

**Remarks:**

The backing dynamic array may be fixed in capacity or fail to resize; `n` states the number actually written.

Example:

	import "core:fmt"
	import "core:strings"

	write_bytes_example :: proc() {
		builder := strings.builder_make()
		bytes := [?]byte { 'a', 'b', 'c' }
		strings.write_bytes(&builder, bytes[:]) // 3
		fmt.println(strings.to_string(builder)) // -> abc
	}

*/
write_bytes :: proc(b: ^Builder, x: []byte, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	n0 := len(b.buf)
	append(&b.buf, ..x, loc=loc) or_return
	n1 := len(b.buf)
	return n1-n0, nil
}


/*
Appends a single rune `r` as its UTF-8 encoded byte sequence to the Builder `b`, and returns the number of bytes written.

**Inputs:**
- `b`:    A pointer to the Builder.
- `r`:    The rune to be appended.

**Returns:**
- `n`:    The number of bytes written.
- `err`:  An allocator error if one occured, `nil` otherwise.

**Remarks:**

The backing dynamic array may be fixed in capacity or fail to resize, `n` states the number actually written.

The rune is encoded as-is. It is not escaped or quoted.

If the rune cannot be encoded as a valid Unicode codepoint, this will append a Replacement Character (`\ufffd`) instead.

Example:

	import "core:fmt"
	import "core:strings"

	write_rune_example :: proc() {
		builder := strings.builder_make()
		strings.write_rune(&builder, 'ä')       // 2
		strings.write_rune(&builder, 'b')       // 1
		fmt.println(strings.to_string(builder)) // -> äb
	}

Output:

	äb

*/
write_rune :: proc(b: ^Builder, r: rune, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	n0 := len(b.buf)
	if r < utf8.RUNE_SELF {
		append(&b.buf, cast(byte)r, loc) or_return
	} else {
		buf, w := utf8.encode_rune(r)
		append(&b.buf, ..buf[:w], loc=loc) or_return
	}
	n1 := len(b.buf)
	return n1-n0, nil
}


/*
Appends a single quoted rune `r` as its UTF-8 encoded byte sequence to the Builder `b`, and returns the number of bytes written.

**Inputs:**
- `b`:        A pointer to the Builder.
- `r`:        The rune to be appended.
- `options`:  Controls how characters in the string are escaped.

**Returns:**
- `n`:        The number of bytes written.
- `err`:      An allocator error if one occured, `nil` otherwise.

**Remarks:**

The rune is quoted such that it would parse back as a valid rune literal in Odin syntax.

This implies that single quotes (`'`) are used.

The backing dynamic array may be fixed in capacity or fail to resize; `n` states the number actually written.

Example:

	import "core:fmt"
	import "core:strings"

	write_quoted_rune_example :: proc() {
		builder := strings.builder_make()
		strings.write_string(&builder, "abc")      // 3
		strings.write_quoted_rune(&builder, 'ä')   // 4
		strings.write_string(&builder, "abc")      // 3
		fmt.println(strings.to_string(builder))    // -> abc'ä'abc
	}

Output:

	abc'ä'abc

*/
write_quoted_rune :: proc(b: ^Builder, r: rune, options: strconv.Rune_Escaping_Options = nil, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	buf: [strconv.QUOTED_RUNE_MAX_NEEDED_BYTES]byte
	s := strconv.quote_rune(buf[:], r, options = options)
	return write_string(b, s, loc=loc)
}


/*
Appends string `s` to the Builder `b`, and returns the number of bytes written.

**Inputs:**
- `b`:    A pointer to the Builder.
- `s`:    The string to be appended.

**Returns:**
- `n`:    The number of bytes written.
- `err`:  An allocator error if one occured, `nil` otherwise.

**Remarks:**

The backing dynamic array may be fixed in capacity or fail to resize; `n` states the number actually written.

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
write_string :: proc(b: ^Builder, s: string, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	return append(&b.buf, s, loc=loc)
}


/*
Appends UTF-16 encoded string `str` to the Builder `b`, and returns the number of bytes written.

**Inputs:**
- `b`:    A pointer to the Builder.
- `s`:    The string to be appended.

**Returns:**
- `n`:    The number of bytes written.
- `err`:  An allocator error if one occured, `nil` otherwise.

**Remarks:**

The UTF-16 input string is encoded as UTF-8 in the output.

Unpaired UTF-16 surrogates are encoded as the Unicode replacement character. The UTF-16 decoder does not
distinguish malformed sequences from literal replacement characters, so both are written identically.

The backing dynamic array may be fixed in capacity or fail to resize; `n` states the number actually written.
*/
write_string16 :: proc(b: ^Builder, str: string16, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	result := strconv.write_string16_dynamic_array(&b.buf, str, loc=loc) or_return
	return len(result), nil
}


/*
Removes the last byte in the Builder `b`, and returns its value.

If the Builder is empty, returns `0`.

**Inputs:**
- `b`: A pointer to the Builder

**Returns:**
- `r`: The last byte in the Builder, or `0` if empty.
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
Decodes the last UTF-8 rune in the Builder `b`, and returns its value and width (in bytes).

If the Builder is empty, returns `(0, 0)`.

**Inputs:**
- `b`:      A pointer to the Builder

**Returns:**
- `r`:      The popped rune
- `width`:  The rune width or 0 if the builder was empty
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


/*
Appends string `str` to the Builder `b`, and returns the number of bytes written.

Runes in the string are escaped when appropriate, and surrounded with the specified `quote`.

**Inputs:**
- `b`:        A pointer to the Builder.
- `str`:      The string to be quoted and appended.
- `quote`:    The quote character. Default is double quotes (`"`).
- `options`:  Controls how characters in the string are escaped.

**Returns:**
- `n`:        The number of bytes written
- `err`:      An allocator error if one occured, `nil` otherwise

**Remarks:**

Runes are escaped according to Odin string syntax rules. If double-quotes (`"`) are used, then the string is quoted and escaped such that
it would parse back as the same string in an Odin string literal.

The backing dynamic array may be fixed in capacity or fail to resize; `n` states the number actually written.

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
write_quoted_string :: proc(b: ^Builder, str: string, quote: byte = '"', options: strconv.Rune_Escaping_Options = nil, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	result := strconv.quote_string_dynamic_array(&b.buf, str, quote, options = options, loc = loc) or_return
	return len(result), nil
}


/*
Appends UTF-16 encoded string `str` to the Builder `b`, and returns the number of bytes written.

Runes in the string are escaped when appropriate, and surrounded with the specified `quote`.

**Inputs:**
- `b`:        A pointer to the Builder.
- `str`:      The string to be quoted and appended.
- `quote`:    The quote character. Default is double quotes (`"`).
- `options`:  Controls how characters in the string are escaped.

**Returns:**
- `n`:        The number of bytes written
- `err`:      An allocator error if one occured, `nil` otherwise

**Remarks:**

The UTF-16 input string is encoded as UTF-8 in the output.

Runes are escaped according to Odin string syntax rules. If double-quotes (`"`) are used, then the string is quoted and escaped such that
it would parse back as the same string in an Odin string literal.

Unpaired UTF-16 surrogates are encoded as the Unicode replacement character. The UTF-16 decoder does not
distinguish malformed sequences from literal replacement characters, so both are written identically.

The backing dynamic array may be fixed in capacity or fail to resize; `n` states the number actually written.
*/
write_quoted_string16 :: proc(b: ^Builder, str: string16, quote: byte = '"', options: strconv.Rune_Escaping_Options = nil, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	result := strconv.quote_string16_dynamic_array(&b.buf, str, quote, options = options, loc = loc) or_return
	return len(result), nil
}


/*
Appends a single rune `r`, in UTF-8 encoded, possibly escaped, and optionally quoted form,
to the Builder `b`, and returns the number of bytes written.

**Inputs:**
- `b`:            A pointer to the Builder.
- `r`:            The rune to be appended.
- `write_quote`:  Optional boolean flag to wrap in single-quotes (`'`) (default is true).
- `options`:      Controls how the rune is escaped.

**Returns:**
- `n`:            The number of bytes written.
- `err`:          An allocator error if one occured, `nil` otherwise.

**Remarks:**

When `write_quote` is `true`, a single quote (`'`) will be escaped.

When `write_quote` is `false`, neither single quotes (`'`) nor double quotes (`"`) will be escaped.
For better control over this, please migrate to `write_encoded_and_escaped_rune`.

The backing dynamic array may be fixed in capacity or fail to resize; `n` states the number actually written.

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
write_encoded_rune :: proc(b: ^Builder, r: rune, write_quote := true, options: strconv.Rune_Escaping_Options = nil, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	if write_quote {
		return write_quoted_rune(b, r, options, loc=loc)
	} else {
		// COMPAT: Originally, this procedure would never escape the quote character.
		//         It does now when `write_quote` is true (that was arguably a bug),
		//         but for compatibility, we still don't escape the quote in this branch.
		return write_encoded_and_escaped_rune(b, r, 0, options, loc=loc)
	}
}


/*
Appends an escaped rune `r`, in UTF-8 encoded and possibly escaped, to the Builder `b`, and returns the number of bytes written.

**Inputs:**
- `b`:          A pointer to the Builder.
- `r`:          The rune to be appended.
- `quote`:      An additional character that is considered the enclosing quote character. This character will be escaped.
                This feature can be disabled by passing `quote = 0`.
- `html_safe`:  Optional boolean flag to escape `<`, `>`, `&` in the format `\x##` (default is false).

**Returns:**
- `n`:          The number of bytes written
- `err`:        An allocator error if one occured, `nil` otherwise.

**Remarks:**

The rune `'\a'` will be written as such.

The backing dynamic array may be fixed in capacity or fail to resize; `n` states the number actually written.
*/
write_escaped_rune :: proc(b: ^Builder, r: rune, quote: byte, html_safe := false, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) {
	options: strconv.Rune_Escaping_Options
	if html_safe {
		options |= { .html_safe }
	}
	return write_encoded_and_escaped_rune(b, r, quote, options, loc=loc)
}


/*
Appends a single rune `r`, encoded as UTF-8 and possibly escaped, to the Builder `b`, and returns the number of bytes written.

**Inputs:**
- `b`:        A pointer to the Builder.
- `r`:        The rune to be appended.
- `quote`:    An additional character that is considered the enclosing quote character. This character will be escaped.
              This feature can be disabled by passing `quote = 0`.
- `options`:  Controls how the rune is escaped.

**Returns:**
- `n`:        The number of bytes written.
- `err`:      An allocator error if one occured, `nil` otherwise.

**Remarks:**

The backing dynamic array may be fixed in capacity or fail to resize; `n` states the number actually written.

To write out a properly quoted single rune, such that it would parse back as a valid Odin rune literal, consider using `write_quoted_rune`.

To write out a properly quoted string, such that it would parse back as a valid Odin string literal, consider using `write_quoted_string`.

Example:

	import "core:fmt"
	import "core:strings"

	write_encoded_and_escaped_rune_example :: proc() {
		builder := strings.builder_make()
		strings.write_encoded_and_escaped_rune(&builder, 'a', '\'') // 1
		strings.write_encoded_and_escaped_rune(&builder, '\"', '\'') // 1
		strings.write_encoded_and_escaped_rune(&builder, '\'', '\'') // 2
		strings.write_encoded_and_escaped_rune(&builder, 'z', '\'') // 1
		strings.write_encoded_and_escaped_rune(&builder, 0, '\'') // 4
		strings.write_encoded_and_escaped_rune(&builder, '\n', '\'') // 2
		fmt.println(strings.to_string(builder))
	}

Output:

	a"\'z\x00\n

*/
write_encoded_and_escaped_rune :: proc(b: ^Builder, r: rune, quote: byte, options: strconv.Rune_Escaping_Options = nil, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) {
	// CONSIDER: Ensure capacity `ESCAPED_RUNE_MAX_NEEDED_BYTES`, and write directly to the buffer.
	buf: [strconv.ESCAPED_RUNE_MAX_NEEDED_BYTES]byte
	encoded, encode_and_escape_rune_ok := strconv.encode_and_escape_rune(buf[:], r, quote, options = options)
	assert(encode_and_escape_rune_ok == true)
	return write_string(b, encoded, loc=loc)
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
- err: An allocator error if one occured, `nil` otherwise.
*/
write_float :: proc(b: ^Builder, f: f64, fmt: byte, prec, bit_size: int, always_signed := false, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	buf: [384]byte
	s := strconv.write_float(buf[:], f, fmt, prec, bit_size)
	// If the result starts with a `+` then unless we always want signed results,
	// we skip it unless it's followed by an `I` (because of +Inf).
	if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
		// xxxx this functionality is also needed by fmt and maybe io - I think strconv should be able to do this because it's super awkward to stay on top of this.
		s = s[1:]
	}
	return write_string(b, s, loc=loc)
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
- err: An allocator error if one occured, `nil` otherwise.
*/
write_f16 :: proc(b: ^Builder, f: f16, fmt: byte, always_signed := false, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	buf: [384]byte
	s := strconv.write_float(buf[:], f64(f), fmt, 2*size_of(f), 8*size_of(f))
	if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
		// xxxx this functionality is also needed by fmt and maybe io - I think strconv should be able to do this because it's super awkward to stay on top of this.
		s = s[1:]
	}
	return write_string(b, s, loc=loc)
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
- err: An allocator error if one occured, `nil` otherwise.

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
write_f32 :: proc(b: ^Builder, f: f32, fmt: byte, always_signed := false, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	buf: [384]byte
	s := strconv.write_float(buf[:], f64(f), fmt, 2*size_of(f), 8*size_of(f))
	if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
		// xxxx this functionality is also needed by fmt and maybe io - I think strconv should be able to do this because it's super awkward to stay on top of this.
		s = s[1:]
	}
	return write_string(b, s, loc=loc)
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
- err: An allocator error if one occured, `nil` otherwise.
*/
write_f64 :: proc(b: ^Builder, f: f64, fmt: byte, always_signed := false, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	buf: [384]byte
	s := strconv.write_float(buf[:], f64(f), fmt, 2*size_of(f), 8*size_of(f))
	if !always_signed && (buf[0] == '+' && buf[1] != 'I') {
		// xxxx this functionality is also needed by fmt and maybe io - I think strconv should be able to do this because it's super awkward to stay on top of this.
		s = s[1:]
	}
	return write_string(b, s, loc=loc)
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
- err: An allocator error if one occured, `nil` otherwise.
*/
write_u64 :: proc(b: ^Builder, i: u64, base: int = 10, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	buf: [32]byte
	s := strconv.write_bits(buf[:], i, base, false, 64, strconv.digits, nil)
	return write_string(b, s, loc=loc)
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
- err: An allocator error if one occured, `nil` otherwise.
*/
write_i64 :: proc(b: ^Builder, i: i64, base: int = 10, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	buf: [32]byte
	s := strconv.write_bits(buf[:], u64(i), base, true, 64, strconv.digits, nil)
	return write_string(b, s, loc=loc)
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
- err: An allocator error if one occured, `nil` otherwise.
*/
write_uint :: proc(b: ^Builder, i: uint, base: int = 10, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	return write_u64(b, u64(i), base, loc=loc)
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
- err: An allocator error if one occured, `nil` otherwise.
*/
write_int :: proc(b: ^Builder, i: int, base: int = 10, loc := #caller_location) -> (n: int, err: runtime.Allocator_Error) #optional_allocator_error {
	return write_i64(b, i64(i), base, loc=loc)
}


/*
Replaces all instances of `old` in the string in a Builder `b` with the `new` string

*Allocates Using The Allocator On The Builder*

Inputs:
- b: The input `Builder`
- old: The substring to be replaced
- new: The replacement string

Returns:
- replaced: The number of replacements
- err: if any allocation errors occurred
*/
builder_replace_all :: proc(b: ^Builder, old, new: string, loc := #caller_location) -> (replaced: int, err: runtime.Allocator_Error) {
	return builder_replace(b, old, new, -1, loc=loc)
}

/*
Replaces up to `n` instances of `old` in the string in a Builder `b` with the `new` string

*Allocates Using The Allocator On The Builder*

Inputs:
- b: The input `Builder`
- old: The substring to be replaced
- new: The replacement string
- n: The maximum number of instances to replace (if `n < 0`, no limit on the number of replacements)

Returns:
- replaced: The number of replacements
- err: if any allocation errors occurred
*/
builder_replace :: proc(b: ^Builder, old, new: string, n: int, loc := #caller_location) -> (replaced: int, err: runtime.Allocator_Error) {
	if old == new || n == 0 {
		return
	}

	// TODO(bplu4t2f): This whole procedure can be made more efficient.
	if m := count(to_string(b^), old); m == 0 {
		return
	}

	if len(old) == 0 {
		// NOTE(bill): reserve the necessary memory
		found := 0
		for i := 0; i <= len(b.buf); i += len(new)+1 {
			if n > 0 && found == n {
				break
			}
			found += 1
		}
		if found == 0 {
			return
		}
		reserve(&b.buf, len(b.buf) + len(new)*found) or_return


		for i := 0; i <= len(b.buf); i += len(new)+1 {
			if n > 0 && replaced == n {
				break
			}

			resize(&b.buf, len(b.buf)+len(new), loc) or_return
			copy(b.buf[i+len(new):], b.buf[i:])
			copy(b.buf[i:], new)
			replaced += 1
		}
	} else {
		if len(new) > len(old) {
			// NOTE(bill): reserve the necessary memory
			found := 0
			for i := 0; i < len(b.buf); /**/ {
				if n > 0 && found == n {
					break
				}

				j := index(string(b.buf[i:]), old)
				if j < 0 {
					break
				}
				i += j+len(old)
				found += 1
			}
			if found == 0 {
				return
			}
			reserve(&b.buf, len(b.buf) + (len(new)-len(old))*found) or_return
		}

		for i := 0; i < len(b.buf); /**/ {
			if n > 0 && replaced == n {
				break
			}

			j := index(string(b.buf[i:]), old)
			if j < 0 {
				break
			}

			if len(new) > len(old) {
				resize(&b.buf, len(b.buf) + len(new)-len(old)) or_return
			}

			cur := b.buf[i+j:]
			src := cur[len(old):]
			dst := cur[len(new):]
			copy(dst, src)
			copy(cur, new)

			i += j+len(new)

			replaced += 1

			if len(new) < len(old) {
				resize(&b.buf, len(b.buf) + len(new)-len(old)) or_return
			}
		}
	}
	return
}
