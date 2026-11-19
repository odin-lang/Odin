// Encoding and decoding of hex-encoded binary, e.g. `0x23` -> `#`.
package encoding_hex

import "base:runtime"
import "core:io"
import "core:strings"

/*
	Copyright 2023 Laytan Laats.
	Copyright 2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Laytan Laats:    Initial implementation.
		Jeroen van Rijn: `encode_upper`, `encode_upper_into_writer`, documentation.
		mo:              `decode_into_buffer`.
		bplu4t2f:        Error handling.
*/

/*
Encodes a byte slice into a lowercase hex sequence

*Allocates Using Provided Allocator*

Inputs:
- src: The `[]byte` to be hex-encoded
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: #caller_location)

Returns:
- res: The hex-encoded result
- err: An optional allocator error if one occurred, `.None` otherwise
*/
encode :: proc(src: []byte, allocator := context.allocator, loc := #caller_location) -> (res: []byte, err: runtime.Allocator_Error) #optional_allocator_error {
	if len(src) > max(int) / 2 {
		return nil, .Out_Of_Memory
	}
	res = make([]byte, len(src) * 2, allocator, loc) or_return
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
- err: An `io.Error` if one occurred, `.None` otherwise
*/
encode_into_writer :: proc(dst: io.Writer, src: []byte) -> (err: io.Error) {
	return encode_into_writer_table(dst, src, LOWER)
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
- err: An optional allocator error if one occurred, `.None` otherwise
*/
encode_upper :: proc(src: []byte, allocator := context.allocator, loc := #caller_location) -> (res: []byte, err: runtime.Allocator_Error) #optional_allocator_error {
	if len(src) > max(int) / 2 {
		return nil, .Out_Of_Memory
	}
	res = make([]byte, len(src) * 2, allocator, loc) or_return
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
- err: An `io.Error` if one occurred, `.None` otherwise
*/
encode_upper_into_writer :: proc(dst: io.Writer, src: []byte) -> (err: io.Error) {
	return encode_into_writer_table(dst, src, UPPER)
}

/*
Decodes a hex sequence into a byte slice

*Allocates Using Provided Allocator*

Inputs:
- src: The `[]byte` to be hex-decoded
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: #caller_location)

Returns:
- dst: The hex sequence decoded into bytes, `nil` on failure
- err: `.Invalid_Length` if `len(src)` is odd, else an allocator error if one occurred, else
  `.Invalid_Character` if `src` holds a byte that isn't a hex digit, `nil` otherwise
*/
decode :: proc(src: []byte, allocator := context.allocator, loc := #caller_location) -> (dst: []byte, err: Error) {
	if len(src) % 2 == 1 {
		return nil, .Invalid_Length
	}

	dst = make([]byte, len(src) / 2, allocator, loc) or_return

	#no_bounds_check for i, j := 0, 1; j < len(src); j += 2 {
		p := src[j-1]
		q := src[j]

		a, a_ok := hex_digit(p)
		b, b_ok := hex_digit(q)
		if !a_ok || !b_ok {
			delete(dst, allocator, loc)
			return nil, .Invalid_Character
		}

		dst[i] = (a << 4) | b
		i += 1
	}

	return dst, nil
}

/*
Decodes a hex sequence into a byte slice

Inputs:
- src: The `[]byte` to be hex-decoded
- buf: A buffer large enough to hold the decoded sequence, or `src` itself to decode in place

Returns:
- dst: `buf[:len(src) / 2]` holding the decoded bytes, `nil` on failure
- ok:  `false` if `len(src)` is odd, if `buf` is shorter than `len(src) / 2`, or if `src`
  holds a byte that isn't a hex digit, `true` otherwise. In the last case `buf` already
  holds the bytes decoded from the pairs before the bad one.
*/
decode_into_buffer :: proc(src: []byte, buf: []byte) -> (dst: []byte, ok: bool) #optional_ok {
	if len(src) % 2 == 1 {
		return
	}
	dst_len := len(src) / 2
	if len(buf) < dst_len {
		return
	}

	#no_bounds_check for i, j := 0, 1; j < len(src); j += 2 {
		p := src[j-1]
		q := src[j]

		a := hex_digit(p) or_return
		b := hex_digit(q) or_return

		buf[i] = (a << 4) | b
		i += 1
	}

	return buf[:dst_len], true
}

/*
Decodes two hex digits, optionally prefixed with `0x` or `0X`, to a byte

Inputs:
- str: A hex-encoded `string`, e.g. `"0x23"`

Returns:
- res: The decoded byte, e.g. `'#'`
- ok:  `false` if `str` isn't two hex digits after the optional prefix, `true` otherwise
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
encode_into_writer_table :: proc(dst: io.Writer, src: []byte, table: [16]byte) -> (err: io.Error) {
	buf: [256]byte
	n := 0
	for v in src {
		buf[n]   = table[v>>4]
		buf[n+1] = table[v&0x0f]
		n += 2
		if n == len(buf) {
			io.write_full(dst, buf[:]) or_return
			n = 0
		}
	}
	if n > 0 {
		io.write_full(dst, buf[:n]) or_return
	}
	return
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
