/*
`Base64` encoding and decoding.

A secondary param can be used to supply a custom alphabet to `encode` and a matching decoding table to `decode`.

If none is supplied it just uses the standard Base64 alphabet.
In case your specific version does not use padding, you may
truncate it from the encoded output.
*/
package encoding_base64

import "base:intrinsics"
import "base:runtime"
import "core:io"

@(rodata)
ENC_TABLE := [64]byte {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
    'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
    'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
    'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3',
    '4', '5', '6', '7', '8', '9', '+', '/',
}

// Encoding table for Base64url variant
@(rodata)
ENC_URL_TABLE := [64]byte {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
    'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
    'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
    'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3',
    '4', '5', '6', '7', '8', '9', '-', '_',
}

PADDING :: '='

@(rodata)
DEC_TABLE := [256]i8 {
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, 62, -1, -1, -1, 63,
    52, 53, 54, 55, 56, 57, 58, 59,
    60, 61, -1, -1, -1, -1, -1, -1,
    -1,  0,  1,  2,  3,  4,  5,  6,
     7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22,
    23, 24, 25, -1, -1, -1, -1, -1,
    -1, 26, 27, 28, 29, 30, 31, 32,
    33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48,
    49, 50, 51, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
}

// Decoding table for Base64url variant
@(rodata)
DEC_URL_TABLE := [256]i8 {
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, 62, -1, -1,
    52, 53, 54, 55, 56, 57, 58, 59,
    60, 61, -1, -1, -1, -1, -1, -1,
    -1,  0,  1,  2,  3,  4,  5,  6,
     7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22,
    23, 24, 25, -1, -1, -1, -1, 63,
    -1, 26, 27, 28, 29, 30, 31, 32,
    33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48,
    49, 50, 51, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
}

Error :: union #shared_nil {
	runtime.Allocator_Error,
	io.Error,
	Decode_Error,
}

Decode_Error :: enum {
	None,
	Invalid_Character,
}

encode :: proc(data: []byte, ENC_TBL := ENC_TABLE, allocator := context.allocator) -> (encoded: string, err: runtime.Allocator_Error) #optional_allocator_error {
	out_length := encoded_len(data)
	if out_length == 0 {
		return
	}

	out := make([]byte, out_length, allocator) or_return
	_, ioerr := encode_impl(out, data, ENC_TBL)
	assert(ioerr == nil, "encode should not IO error")
	assert(len(out) == out_length, "buffer resized, `encoded_len` was wrong")

	encoded = transmute(string)(out)

	return
}

encode_into_buf :: proc(dst, data: []byte, ENC_TBL := ENC_TABLE) -> (encoded: []byte, err: Error) {
	out_length := encoded_len(data)
	if out_length == 0 {
		return
	}

	return encode_impl(dst, data, ENC_TBL)
}

encode_into :: proc(w: io.Writer, data: []byte, ENC_TBL := ENC_TABLE) -> io.Error {
	_, err := encode_impl(w, data, ENC_TBL)
	return err
}

@(private)
encode_impl :: proc(dst: $T, data: []byte, ENC_TBL := ENC_TABLE) -> ([]byte, io.Error) where T == io.Writer || T == []byte {
	length := len(data)
	when T == []byte {
		out_length := encoded_len(data)
		if len(dst) < out_length {
			return nil, io.Error.Short_Buffer
		}
		buf := dst
	} else {
		if length == 0 {
			return nil, nil
		}
		buf: [4]byte
	}

	c0, c1, c2, block: int
	for i := 0; i < length; i += 3 {
		#no_bounds_check {
			c0, c1, c2 = int(data[i]), -1, -1

			if i + 1 < length { c1 = int(data[i + 1]) }
			if i + 2 < length { c2 = int(data[i + 2]) }

			block = (c0 << 16) | (max(c1, 0) << 8) | max(c2, 0)

			buf[0] = ENC_TBL[block >> 18 & 63]
			buf[1] = ENC_TBL[block >> 12 & 63]
			buf[2] = c1 == -1 ? PADDING : ENC_TBL[block >> 6 & 63]
			buf[3] = c2 == -1 ? PADDING : ENC_TBL[block & 63]
			when T == []byte {
				buf = buf[4:]
			}
		}
		when T == io.Writer {
			if _, err := io.write_full(dst, buf[:]); err != nil {
				return nil, err
			}
		}
	}

	when T == io.Writer {
		return nil, nil
	} else {
		return dst[:out_length], nil
	}
}

encoded_len :: proc(data: []byte) -> int {
	length := len(data)
	if length == 0 {
		return 0
	}

	return ((4 * length / 3) + 3) &~ 3
}

decode :: proc(data: string, DEC_TBL := DEC_TABLE, dst: []byte = nil, allocator := context.allocator) -> (decoded: []byte, err: Error) {
	out_length := decoded_len(data)
	if out_length == 0 {
		return nil, nil
	}

	buf: []byte
	if buf, err = make([]byte, out_length, allocator); err != nil {
		return
	}

	decoded, err = decode_impl(buf, data, DEC_TBL)
	if err != nil {
		delete(buf, allocator)
	}
	assert(err != nil || len(decoded) == out_length, "buffer unexpectedly resized, `decoded_len` was wrong")

	return
}

decode_into_buf :: proc(dst: []byte, data: string, DEC_TBL := DEC_TABLE) -> (decoded: []byte, err: Error) {
	out_length := decoded_len(data)
	if out_length == 0 {
		return
	}

	return decode_impl(dst, data, DEC_TBL)
}

decode_into :: proc(w: io.Writer, data: string, DEC_TBL := DEC_TABLE) -> Error {
	_, err := decode_impl(w, data, DEC_TBL)
	return err
}

@(private)
decode_impl :: proc(dst: $T, data: string, DEC_TBL := DEC_TABLE) -> ([]byte, Error) where T == io.Writer || T == []byte {
	length := decoded_len(data)
	when T == []byte {
		if len(dst) < length {
			return nil, io.Error.Short_Buffer
		}
		off: int
	} else {
		if length == 0 {
			return nil, nil
		}
		buf: [3]byte
	}

	c0, c1, c2, c3: int
	d0, d1, d2, d3: i8
	b0, b1, b2: int
	i, j: int
	for ; j + 3 <= length; i, j = i + 4, j + 3 {
		#no_bounds_check {
			d0 = DEC_TBL[data[i]]
			d1 = DEC_TBL[data[i + 1]]
			d2 = DEC_TBL[data[i + 2]]
			d3 = DEC_TBL[data[i + 3]]

			if intrinsics.unlikely((d0 | d1 | d2 | d3) & ~i8(0x3f) != 0) {
				return nil, Decode_Error.Invalid_Character
			}

			c0, c1, c2, c3 = int(d0), int(d1), int(d2), int(d3)

			b0 = (c0 << 2) | (c1 >> 4)
			b1 = (c1 << 4) | (c2 >> 2)
			b2 = (c2 << 6) | c3

			when T == []byte {
				dst[off+0] = byte(b0)
				dst[off+1] = byte(b1)
				dst[off+2] = byte(b2)
				off += 3
			} else {
				buf[0] = byte(b0)
				buf[1] = byte(b1)
				buf[2] = byte(b2)
			}
		}

		when T == io.Writer {
			if _, err := io.write_full(dst, buf[:]); err != .None {
				return nil, err
			}
		}
	}

	rest := length - j
	if rest > 0 {
		#no_bounds_check {
			// Note: decoded_len handles removing padding.
			d0 = DEC_TBL[data[i]]
			d1 = DEC_TBL[data[i + 1]]
			if d2 = 0; rest == 2 {
				d2 = DEC_TBL[data[i + 2]]
			}

			if intrinsics.unlikely((d0 | d1 | d2) & ~i8(0x3f) != 0) {
				return nil, Decode_Error.Invalid_Character
			}

			c0, c1, c2 = int(d0), int(d1), int(d2)

			b0 = (c0 << 2) | (c1 >> 4)
			b1 = (c1 << 4) | (c2 >> 2)

			when T == []byte {
				switch rest {
				case 2:
					dst[off+1] = byte(b1)
					fallthrough
				case 1:
					dst[off] = byte(b0)
				}
			} else {
				buf[0] = byte(b0)
				buf[1] = byte(b1)
			}
		}

		when T == io.Writer {
			if _, err := io.write_full(dst, buf[:rest]); err != .None {
				return nil, err
			}
		}
	}

	when T == io.Writer {
		return nil, nil
	} else {
		return dst[:length], nil
	}
}

decoded_len :: proc(data: string) -> int {
	length := len(data)
	if length == 0 {
		return 0
	}

	padding: int
	if data[length - 1] == PADDING {
		if length > 1 && data[length - 2] == PADDING {
			padding = 2
		} else {
			padding = 1
		}
	}

	return ((length * 6) >> 3) - padding
}
