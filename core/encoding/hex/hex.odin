// Encoding and decoding of hex-encoded binary, e.g. `0x23` -> `#`.
package encoding_hex

import "base:runtime"
import "core:io"
import "core:strings"

/*
Encodes a byte slice into a lowercase hex sequence

*Allocates Using Provided Allocator*

Inputs:
- src: The `[]byte` to be hex-encoded
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: #caller_location)

Returns:
- res: The hex-encoded result
- err: An optional allocator error if one occured, `.None` otherwise
*/
encode :: proc(src: []byte, allocator := context.allocator, loc := #caller_location) -> (res: []byte, err: runtime.Allocator_Error) #optional_allocator_error {
	res, err = make([]byte, len(src) * 2, allocator, loc)
	#no_bounds_check for i, j := 0, 0; i < len(src); i += 1 {
		v := src[i]
		res[j]   = LOWER[v>>4]
		res[j+1] = LOWER[v&0x0f]
		j += 2
	}
	return
}

/*
Encodes a byte slice as a lowercase hex sequence into an `io.Writer`

Inputs:
- dst: The `io.Writer` to encode into
- src: The `[]byte` to be hex-encoded

Returns:
- err: An `io.Error` if one occured, `.None` otherwise
*/
encode_into_writer :: proc(dst: io.Writer, src: []byte) -> (err: io.Error) {
	for v in src {
		io.write(dst, {LOWER[v>>4], LOWER[v&0x0f]}) or_return
	}
	return
}

/*
Encodes a byte slice into an uppercase hex sequence

*Allocates Using Provided Allocator*

Inputs:
- src: The `[]byte` to be hex-encoded
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: #caller_location)

Returns:
- res: The hex-encoded result
- err: An optional allocator error if one occured, `.None` otherwise
*/
encode_upper :: proc(src: []byte, allocator := context.allocator, loc := #caller_location) -> (res: []byte, err: runtime.Allocator_Error) #optional_allocator_error {
	res, err = make([]byte, len(src) * 2, allocator, loc)
	#no_bounds_check for i, j := 0, 0; i < len(src); i += 1 {
		v := src[i]
		res[j]   = UPPER[v>>4]
		res[j+1] = UPPER[v&0x0f]
		j += 2
	}
	return
}

/*
Encodes a byte slice as an uppercase hex sequence into an `io.Writer`

Inputs:
- dst: The `io.Writer` to encode into
- src: The `[]byte` to be hex-encoded

Returns:
- err: An `io.Error` if one occured, `.None` otherwise
*/
encode_upper_into_writer :: proc(dst: io.Writer, src: []byte) -> (err: io.Error) {
	for v in src {
		io.write(dst, {UPPER[v>>4], UPPER[v&0x0f]}) or_return
	}
	return
}

/*
Decodes a hex sequence into a byte slice

*Allocates Using Provided Allocator*

Inputs:
- dst: The hex sequence decoded into bytes
- src: The `[]byte` to be hex-decoded
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: #caller_location)

Returns:
- ok:  A bool, `true` if decoding succeeded, `false` otherwise
*/
decode :: proc(src: []byte, allocator := context.allocator, loc := #caller_location) -> (dst: []byte, ok: bool) {
	if len(src) % 2 == 1 {
		return
	}

	dst = make([]byte, len(src) / 2, allocator, loc)
	#no_bounds_check for i, j := 0, 1; j < len(src); j += 2 {
		p := src[j-1]
		q := src[j]

		a := hex_digit(p) or_return
		b := hex_digit(q) or_return

		dst[i] = (a << 4) | b
		i += 1
	}

	return dst, true
}

/*
Decodes the first byte in a hex sequence to a byte

Inputs:
- str: A hex-encoded `string`, e.g. `"0x23"`

Returns:
- res: The decoded byte, e.g. `'#'`
- ok:  A bool, `true` if decoding succeeded, `false` otherwise
*/
decode_sequence :: proc(str: string) -> (res: byte, ok: bool) {
	str := str
	if strings.has_prefix(str, "0x") || strings.has_prefix(str, "0X") {
		str = str[2:]
	}

	if len(str) != 2 {
		return 0, false
	}

	upper := hex_digit(str[0]) or_return
	lower := hex_digit(str[1]) or_return

	return upper << 4 | lower, true
}

@(private)
LOWER := [16]byte {
	'0', '1', '2', '3',
	'4', '5', '6', '7',
	'8', '9', 'a', 'b',
	'c', 'd', 'e', 'f',
}

@(private)
UPPER := [16]byte {
	'0', '1', '2', '3',
	'4', '5', '6', '7',
	'8', '9', 'A', 'B',
	'C', 'D', 'E', 'F',
}

@(private)
hex_digit :: proc(char: byte) -> (u8, bool) {
	switch char {
	case '0' ..= '9': return char - '0', true
	case 'a' ..= 'f': return char - 'a' + 10, true
	case 'A' ..= 'F': return char - 'A' + 10, true
	case:             return 0, false
	}
}