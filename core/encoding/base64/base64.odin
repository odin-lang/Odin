/*
`Base64` encoding and decoding.

A secondary param can be used to supply a custom alphabet to `encode` and a matching decoding table to `decode`.

If none is supplied it just uses the standard Base64 alphabet.

By default `encode` emits padding. Encode options can omit it: with
`{.No_Padding}` the output is the canonical unpadded ("raw") form of
RFC 4648 section 3.2, and `encoded_len` reports the shorter length.

By default `decode` is lenient, accepting padded and unpadded input and not
checking the trailing padding bits. Decode options can enable strict
(RFC 4648 section 3.5) canonical decoding: `{.Strict}` requires correct
padding and zero trailing bits, while `{.Strict, .No_Padding}` accepts only
canonical unpadded input.
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
	Invalid_Padding,
	Non_Canonical,
	Malformed_Quantum,
}

// Decode_Option selects optional validation performed by the decode routines.
Decode_Option :: enum {
	// Strict requires canonical input as described in RFC 4648 section 3.5:
	// trailing padding bits must be zero, padding must be exact, and padding
	// characters may only appear at the end.
	Strict,
	// No_Padding rejects the padding character, requiring unpadded input.
	No_Padding,
}

// Decode_Options is a set of Decode_Option values.
Decode_Options :: bit_set[Decode_Option; u8]

// Encode_Option selects optional behavior of the encode routines.
Encode_Option :: enum {
	// No_Padding omits the padding character from the output (RFC 4648
	// section 3.2), producing the canonical unpadded ("raw") form.
	// Combine with ENC_URL_TABLE for unpadded base64url, as used by JOSE.
	No_Padding,
}

// Encode_Options is a set of Encode_Option values.
Encode_Options :: bit_set[Encode_Option; u8]

encode :: proc(data: []byte, ENC_TBL := ENC_TABLE, allocator := context.allocator, options := Encode_Options{}) -> (encoded: string, err: runtime.Allocator_Error) #optional_allocator_error {
	out_length := encoded_len(data, options)
	if out_length == 0 {
		return
	}

	out := make([]byte, out_length, allocator) or_return
	_, ioerr := encode_impl(out, data, ENC_TBL, options)
	assert(ioerr == nil, "encode should not IO error")
	assert(len(out) == out_length, "buffer resized, `encoded_len` was wrong")

	encoded = transmute(string)(out)

	return
}

encode_into_buf :: proc(dst, data: []byte, ENC_TBL := ENC_TABLE, options := Encode_Options{}) -> (encoded: []byte, err: Error) {
	out_length := encoded_len(data, options)
	if out_length == 0 {
		return
	}

	return encode_impl(dst, data, ENC_TBL, options)
}

encode_into :: proc(w: io.Writer, data: []byte, ENC_TBL := ENC_TABLE, options := Encode_Options{}) -> io.Error {
	_, err := encode_impl(w, data, ENC_TBL, options)
	return err
}

@(private)
encode_impl :: proc(dst: $T, data: []byte, ENC_TBL := ENC_TABLE, options := Encode_Options{}) -> ([]byte, io.Error) where T == io.Writer || T == []byte {
	length := len(data)
	when T == []byte {
		out_length := encoded_len(data, options)
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

	// c0, c1, c2 are the group's input bytes; -1 marks a missing byte, which
	// is how a partial (final) group is identified.
	c0, c1, c2, block, write: int
	for i := 0; i < length; i += 3 {
		#no_bounds_check {
			c0, c1, c2 = int(data[i]), -1, -1

			if i + 1 < length { c1 = int(data[i + 1]) }
			if i + 2 < length { c2 = int(data[i + 2]) }

			// Pack the group into a 24-bit value, most significant input
			// byte first; missing bytes contribute zero bits, as RFC 4648
			// section 4 requires.
			block = (c0 << 16) | (max(c1, 0) << 8) | max(c2, 0)

			// Characters the final block carries once padding is dropped:
			// four for a full group, two (one input byte) or three (two
			// input bytes) for a partial one.
			emit := 4
			if c1 == -1 {
				emit = 2
			} else if c2 == -1 {
				emit = 3
			}

			// Padded output still writes a full four-character block, with
			// PADDING where the group ran out of input bytes.
			write = emit
			if .No_Padding not_in options {
				write = 4
			}

			// The output characters, most significant six bits first;
			// PADDING replaces the characters a partial group lacks.
			buf[0] = ENC_TBL[block >> 18 & 63]
			buf[1] = ENC_TBL[block >> 12 & 63]
			if write > 2 {
				buf[2] = c1 == -1 ? PADDING : ENC_TBL[block >> 6 & 63]
				if write > 3 {
					buf[3] = c2 == -1 ? PADDING : ENC_TBL[block & 63]
				}
			}
			when T == []byte {
				buf = buf[write:]
			}
		}
		when T == io.Writer {
			if _, err := io.write_full(dst, buf[:write]); err != nil {
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

encoded_len :: proc(data: []byte, options := Encode_Options{}) -> int {
	length := len(data)
	if length == 0 {
		return 0
	}

	padded := ((4 * length / 3) + 3) &~ 3
	if .No_Padding not_in options {
		return padded
	}

	switch length % 3 {
	case 1:
		return padded - 2
	case 2:
		return padded - 1
	}
	return padded
}

@(private)
validate_strict_decode :: proc(data: string, dec_tbl: [256]i8, options: Decode_Options) -> Decode_Error {
	if options == {} {
		return .None
	}

	n := len(data)
	if n == 0 {
		return .None
	}

	si := n
	pad: int
	if .No_Padding in options {
		for i in 0 ..< n {
			if data[i] == PADDING {
				return .Invalid_Padding
			}
		}
	} else {
		for si > 0 && data[si - 1] == PADDING {
			si -= 1
			pad += 1
		}
		for j in 0 ..< si {
			if data[j] == PADDING {
				// Interior padding, e.g. QQ=Q
				return .Invalid_Padding
			}
		}
	}

	// `si` is the amount of meaningful data, excluding trailing padding.

	// Number of non-padding characters in the last quantum (e.g. 2 for "QQ==", 3 for "QUI=").
	rem := si % 4
	if rem == 1 {
		// "QUJDQ"  ||  "QUJDQ==="
		//  -> unsalvageable (this is not just missing padding or non-canonical).
		return .Malformed_Quantum
	}

	if .Strict in options {
		if .No_Padding not_in options {
			if n % 4 != 0 {
				// "QQ"  ||  "QUI"
				//  -> MUST be "QQ=="  ||  "QUI="
				return .Invalid_Padding
			}

			switch rem {
			case 0:
				if pad != 0 {
					// "QUJD="  ||  "QUJD=="
					//  -> MUST be "QUJD"
					return .Invalid_Padding
				}
			case 2:
				if pad != 2 {
					// "QQ"  ||  "QQ="
					//  -> MUST be "QQ=="
					return .Invalid_Padding
				}
			case 3:
				if pad != 1 {
					// "QUI"  ||  "QUI=="
					//  -> MUST be "QUI="
					return .Invalid_Padding
				}
			case:
				unreachable()
			}
		}

		switch rem {
		case 2:
			c := dec_tbl[data[si - 1]]
			if c < 0 {
				return .Invalid_Character
			}
			if (c & 0x0f) != 0 {
				// In the last quantum, the second encoded character would decode into
				// non-zero bits in the second decoded byte, which is beyond the decoded range.
				return .Non_Canonical
			}
		case 3:
			c := dec_tbl[data[si - 1]]
			if c < 0 {
				return .Invalid_Character
			}
			if (c & 0x03) != 0 {
				// In the last quantum, the third encoded character would decode into
				// non-zero bits in the third decoded byte, which is beyond the decoded range.
				return .Non_Canonical
			}
		}
	}

	return .None
}

@(private)
Decode_Info :: struct {
	out_length: int,
	trimmed_in: string,
}

@(private)
decode_analyze :: proc(data: string, DEC_TBL := DEC_TABLE, options: Decode_Options) -> (info: Decode_Info, err: Decode_Error) {
	err = validate_strict_decode(data, DEC_TBL, options)
	if err != nil {
		return
	}

	// Calculate trimmed input length based on stripped trailing padding.
	length_in := len(data)
	for length_in > 0 && data[length_in - 1] == PADDING {
		length_in -= 1
	}

	quanta := length_in >> 2
	rem_in := length_in & 3
	rem_out: int
	switch rem_in {
	case 0:
	case 1:
		err = .Malformed_Quantum
		return
	case 2: rem_out = 1
	case 3: rem_out = 2
	case:   unreachable()
	}

	info = {
		out_length = quanta * 3 + rem_out,
		trimmed_in = data[:length_in],
	}
	return
}

decode :: proc(data: string, DEC_TBL := DEC_TABLE, dst: []byte = nil, allocator := context.allocator, options := Decode_Options{}) -> (decoded: []byte, err: Error) {
	decode_info := decode_analyze(data, DEC_TBL, options) or_return

	if decode_info.out_length == 0 {
		return nil, nil
	}

	buf: []byte
	if buf, err = make([]byte, decode_info.out_length, allocator); err != nil {
		return
	}

	decoded, err = decode_impl(buf, decode_info, DEC_TBL)
	if err != nil {
		delete(buf, allocator)
	}
	assert(err != nil || len(decoded) == decode_info.out_length, "buffer unexpectedly resized, `analyze_decode` was wrong")

	return
}

decode_into_buf :: proc(dst: []byte, data: string, DEC_TBL := DEC_TABLE, options := Decode_Options{}) -> (decoded: []byte, err: Error) {
	decode_info := decode_analyze(data, DEC_TBL, options) or_return

	if decode_info.out_length == 0 {
		return
	}

	return decode_impl(dst, decode_info, DEC_TBL)
}

decode_into :: proc(w: io.Writer, data: string, DEC_TBL := DEC_TABLE, options := Decode_Options{}) -> Error {
	decode_info := decode_analyze(data, DEC_TBL, options) or_return

	_, err := decode_impl(w, decode_info, DEC_TBL)
	return err
}

@(private)
decode_impl :: proc(dst: $T, info: Decode_Info, DEC_TBL := DEC_TABLE) -> ([]byte, Error) where T == io.Writer || T == []byte {
	dst_cursor: int
	when T == []byte {
		if len(dst) < info.out_length {
			return nil, io.Error.Short_Buffer
		}
	} else {
		if info.out_length == 0 {
			return nil, nil
		}
		buf: [3]byte
	}

	// Note: decode_analyze handles removing padding.
	data := info.trimmed_in

	c0, c1, c2, c3: int
	d0, d1, d2, d3: i8
	b0, b1, b2: int
	i: int
	for ; i + 4 <= len(data); i += 4 {
		#no_bounds_check {
			d0 = DEC_TBL[data[i]]
			d1 = DEC_TBL[data[i + 1]]
			d2 = DEC_TBL[data[i + 2]]
			d3 = DEC_TBL[data[i + 3]]

			if intrinsics.unlikely((d0 | d1 | d2 | d3) & ~i8(0x3f) != 0) {
				// To be consistent with validate_strict_decode, this will return
				// Invalid_Padding if the input string contains invalid padding
				// characters, but would otherwise be valid.
				if (data[i + 0] == PADDING || d0 & ~i8(0x3f) == 0) &&
				   (data[i + 1] == PADDING || d1 & ~i8(0x3f) == 0) &&
				   (data[i + 2] == PADDING || d2 & ~i8(0x3f) == 0) &&
				   (data[i + 3] == PADDING || d3 & ~i8(0x3f) == 0) {
					return nil, .Invalid_Padding
				} else {
					return nil, .Invalid_Character
				}
			}

			c0, c1, c2, c3 = int(d0), int(d1), int(d2), int(d3)

			b0 = (c0 << 2) | (c1 >> 4)
			b1 = (c1 << 4) | (c2 >> 2)
			b2 = (c2 << 6) | c3

			when T == []byte {
				dst[dst_cursor+0] = byte(b0)
				dst[dst_cursor+1] = byte(b1)
				dst[dst_cursor+2] = byte(b2)
				dst_cursor += 3
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
			dst_cursor += 3
		}
	}

	rest_in := len(data) - i
	if rest_in > 0 {
		when T == io.Writer {
			rest_out: int
		}

		#no_bounds_check {
			d0 = DEC_TBL[data[i + 0]]
			d1 = DEC_TBL[data[i + 1]] if rest_in >= 2 else 0
			d2 = DEC_TBL[data[i + 2]] if rest_in >= 3 else 0

			if intrinsics.unlikely((d0 | d1 | d2) & ~i8(0x3f) != 0) {
				// To be consistent with validate_strict_decode, this will return
				// Invalid_Padding if the input string contains invalid padding
				// characters, but would otherwise be valid.
				if (               (data[i + 0] == PADDING || d0 & ~i8(0x3f) == 0)) &&
				   (rest_in < 2 || (data[i + 1] == PADDING || d1 & ~i8(0x3f) == 0)) &&
				   (rest_in < 3 || (data[i + 2] == PADDING || d2 & ~i8(0x3f) == 0)) {
					return nil, .Invalid_Padding
				} else {
					return nil, .Invalid_Character
				}
			}

			c0, c1, c2 = int(d0), int(d1), int(d2)

			b0 = (c0 << 2) | (c1 >> 4)
			b1 = (c1 << 4) | (c2 >> 2)

			when T == []byte {
				switch rest_in {
				case 1:
					// Last quantum is malformed:  "Q==="
					return nil, .Malformed_Quantum
				case 2:
					dst[dst_cursor + 0] = byte(b0)
					dst_cursor += 1
				case 3:
					dst[dst_cursor + 0] = byte(b0)
					dst[dst_cursor + 1] = byte(b1)
					dst_cursor += 2
				}
			} else {
				switch rest_in {
				case 1:
					// Last quantum is malformed:  "Q==="
					return nil, .Malformed_Quantum
				case 2:
					buf[0] = byte(b0)
					rest_out = 1
				case 3:
					buf[0] = byte(b0)
					buf[1] = byte(b1)
					rest_out = 2
				}
			}
		}

		when T == io.Writer {
			if _, err := io.write_full(dst, buf[:rest_out]); err != .None {
				return nil, err
			}
			dst_cursor += rest_out
		}
	}

	assert(dst_cursor == info.out_length)

	when T == io.Writer {
		return nil, nil
	} else {
		return dst[:dst_cursor], nil
	}
}

decoded_len :: proc(data: string, DEC_TBL := DEC_TABLE, options: Decode_Options = {}) -> (n: int, err: Decode_Error) {
	// NOTE(bplu4t2f):
	//     It's not clear whether this is intended to be a public API.
	//     There are no regression tests for it.
	info := decode_analyze(data, DEC_TBL, options) or_return
	n = info.out_length
	return
}
