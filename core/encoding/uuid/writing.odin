package uuid

import "base:runtime"
import "core:io"
import "core:strconv"
import "core:strings"

/*
Write a UUID in the 8-4-4-4-12 format.

Inputs:
- w: A writable stream.
- id: The identifier to convert.
*/
write :: proc(w: io.Writer, id: Identifier) #no_bounds_check {
	write_octet :: proc (w: io.Writer, octet: u8) {
		high_nibble := octet >> 4
		low_nibble := octet & 0xF

		io.write_byte(w, strconv.digits[high_nibble])
		io.write_byte(w, strconv.digits[low_nibble])
	}

	for index in  0 ..<  4 { write_octet(w, id[index]) }
	io.write_byte(w, '-')
	for index in  4 ..<  6 { write_octet(w, id[index]) }
	io.write_byte(w, '-')
	for index in  6 ..<  8 { write_octet(w, id[index]) }
	io.write_byte(w, '-')
	for index in  8 ..< 10 { write_octet(w, id[index]) }
	io.write_byte(w, '-')
	for index in 10 ..< 16 { write_octet(w, id[index]) }
}

/*
Convert a UUID to a string in the 8-4-4-4-12 format.

*Allocates Using Provided Allocator*

Inputs:
- id: The identifier to convert.
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: #caller_location)

Returns:
- str: The allocated and converted string.
- error: An optional allocator error if one occured, `nil` otherwise.
*/
to_string_allocated :: proc(
	id: Identifier,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	str: string,
	error: runtime.Allocator_Error,
) #optional_allocator_error {
	buf := make([]byte, EXPECTED_LENGTH, allocator, loc) or_return
	builder := strings.builder_from_bytes(buf[:])
	write(strings.to_writer(&builder), id)
	return strings.to_string(builder), nil
}

/*
Convert a UUID to a string in the 8-4-4-4-12 format.

Inputs:
- id: The identifier to convert.
- buffer: A byte buffer to store the result. Must be at least 32 bytes large.
- loc: The caller location for debugging purposes (default: #caller_location)

Returns:
- str: The converted string which will be stored in `buffer`.
*/
to_string_buffer :: proc(
	id: Identifier,
	buffer: []byte,
	loc := #caller_location,
) -> (
	str: string,
) {
	assert(len(buffer) >= EXPECTED_LENGTH, "The buffer provided is not at least 32 bytes large.", loc)
	builder := strings.builder_from_bytes(buffer)
	write(strings.to_writer(&builder), id)
	return strings.to_string(builder)
}

to_string :: proc {
	to_string_allocated,
	to_string_buffer,
}
