package encoding_base64

import "core:io"
import "core:mem"
import "core:strings"

// @note(zh): Encoding utility for Base64
// A secondary param can be used to supply a custom alphabet to
// @link(encode) and a matching decoding table to @link(decode).
// If none is supplied it just uses the standard Base64 alphabet.
// Incase your specific version does not use padding, you may
// truncate it from the encoded output.

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

PADDING :: '='

DEC_TABLE := [128]int {
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
}

encode :: proc(data: []byte, ENC_TBL := ENC_TABLE, allocator := context.allocator) -> (encoded: string, err: mem.Allocator_Error) #optional_allocator_error {
	out_length := encoded_len(data)
	if out_length == 0 {
		return
	}

	out   := strings.builder_make(0, out_length, allocator) or_return
	ioerr := encode_into(strings.to_stream(&out), data, ENC_TBL)

	assert(ioerr == nil,                           "string builder should not IO error")
	assert(strings.builder_cap(out) == out_length, "buffer resized, `encoded_len` was wrong")

	return strings.to_string(out), nil
}

encode_into :: proc(w: io.Writer, data: []byte, ENC_TBL := ENC_TABLE) -> io.Error {
	length := len(data)
	if length == 0 {
		return nil
	}

	c0, c1, c2, block: int
	out: [4]byte
	for i := 0; i < length; i += 3 {
		#no_bounds_check {
			c0, c1, c2 = int(data[i]), -1, -1

			if i + 1 < length { c1 = int(data[i + 1]) }
			if i + 2 < length { c2 = int(data[i + 2]) }

			block = (c0 << 16) | (max(c1, 0) << 8) | max(c2, 0)
			
			out[0] = ENC_TBL[block >> 18 & 63]
			out[1] = ENC_TBL[block >> 12 & 63]
			out[2] = c1 == -1 ? PADDING : ENC_TBL[block >> 6 & 63]
			out[3] = c2 == -1 ? PADDING : ENC_TBL[block & 63]
		}
		io.write_full(w, out[:]) or_return
	}
	return nil
}

encoded_len :: proc(data: []byte) -> int {
	length := len(data)
	if length == 0 {
		return 0
	}

	return ((4 * length / 3) + 3) &~ 3
}

decode :: proc(data: string, DEC_TBL := DEC_TABLE, allocator := context.allocator) -> (decoded: []byte, err: mem.Allocator_Error) #optional_allocator_error {
	out_length := decoded_len(data)

	out   := strings.builder_make(0, out_length, allocator) or_return
	ioerr := decode_into(strings.to_stream(&out), data, DEC_TBL)

	assert(ioerr == nil,                           "string builder should not IO error")
	assert(strings.builder_cap(out) == out_length, "buffer resized, `decoded_len` was wrong")

	return out.buf[:], nil
}

decode_into :: proc(w: io.Writer, data: string, DEC_TBL := DEC_TABLE) -> io.Error {
	length := decoded_len(data)
	if length == 0 {
		return nil
	}

	c0, c1, c2, c3: int
	b0, b1, b2: int
	buf: [3]byte
	i, j: int
	for ; j + 3 <= length; i, j = i + 4, j + 3 {
		#no_bounds_check {
			c0 = DEC_TBL[data[i]]
			c1 = DEC_TBL[data[i + 1]]
			c2 = DEC_TBL[data[i + 2]]
			c3 = DEC_TBL[data[i + 3]]

			b0 = (c0 << 2) | (c1 >> 4)
			b1 = (c1 << 4) | (c2 >> 2)
			b2 = (c2 << 6) | c3

			buf[0] = byte(b0)
			buf[1] = byte(b1)
			buf[2] = byte(b2)
		}

		io.write_full(w, buf[:]) or_return
	}

	rest := length - j
	if rest > 0 {
		#no_bounds_check {
			c0 = DEC_TBL[data[i]]
			c1 = DEC_TBL[data[i + 1]]
			c2 = DEC_TBL[data[i + 2]]

			b0 = (c0 << 2) | (c1 >> 4)
			b1 = (c1 << 4) | (c2 >> 2)
		}

		switch rest {
		case 1: io.write_byte(w, byte(b0))             or_return
		case 2: io.write_full(w, {byte(b0), byte(b1)}) or_return
		}
	}

	return nil
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
