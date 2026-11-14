/*
`Base32` encoding and decoding, as specified in [[ RFC 4648; https://www.rfc-editor.org/rfc/rfc4648.html ]].

A secondary param can be used to supply a custom alphabet to `encode` and a matching decoding
table to `decode`. If none is supplied it uses the standard Base32 alphabet. `ENC_HEX_TABLE` and
`DEC_HEX_TABLE` hold the "Extended Hex" alphabet of RFC 4648 section 7.

By default `encode` emits padding. With `{.No_Padding}` it omits it, and `encoded_len` reports
the shorter length.

By default `decode` is lenient, accepting padded and unpadded input and not checking the
trailing padding bits. `{.Strict}` requires canonical input (RFC 4648 section 3.5): exact
padding and zero trailing bits. `{.Strict, .No_Padding}` accepts only canonical unpadded input.
*/
package encoding_base32

import "base:runtime"
import "core:io"

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

Decode_Option :: enum {
	Strict,
	No_Padding,
}

Decode_Options :: bit_set[Decode_Option; u8]

Encode_Option :: enum {
	No_Padding,
}

Encode_Options :: bit_set[Encode_Option; u8]

@(rodata)
ENC_TABLE := [32]byte {
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
	'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
	'Y', 'Z', '2', '3', '4', '5', '6', '7',
}

@(rodata)
ENC_HEX_TABLE := [32]byte {
	'0', '1', '2', '3', '4', '5', '6', '7',
	'8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
	'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
	'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V',
}

PADDING :: '='

@(rodata)
DEC_TABLE := [256]i8 {
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, 26, 27, 28, 29, 30, 31, -1, -1, -1, -1, -1, -1, -1, -1,
	-1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
}

@(rodata)
DEC_HEX_TABLE := [256]i8 {
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, -1, -1, -1, -1, -1, -1,
	-1, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
	25, 26, 27, 28, 29, 30, 31, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
}

encode :: proc(data: []byte, ENC_TBL := ENC_TABLE, allocator := context.allocator, options := Encode_Options{}) -> (encoded: string, err: runtime.Allocator_Error) #optional_allocator_error {
	out_length := encoded_len(data, options)
	if out_length == 0 {
		return
	}

	out := make([]byte, out_length, allocator) or_return
	_, io_err := encode_impl(out, data, ENC_TBL, options)
	assert(io_err == nil)

	encoded = string(out)
	return
}

encode_into_buf :: proc(dst, data: []byte, ENC_TBL := ENC_TABLE, options := Encode_Options{}) -> (encoded: []byte, err: Error) {
	if encoded_len(data, options) == 0 {
		return
	}
	return encode_impl(dst, data, ENC_TBL, options)
}

encode_into :: proc(w: io.Writer, data: []byte, ENC_TBL := ENC_TABLE, options := Encode_Options{}) -> io.Error {
	_, err := encode_impl(w, data, ENC_TBL, options)
	return err
}

encoded_len :: proc(data: []byte, options := Encode_Options{}) -> int {
	length := len(data)
	if length > max(int) / 8 * 5 {
		return max(int)
	}

	quanta := length / 5
	rem := length % 5
	if rem == 0 {
		return quanta * 8
	}
	if .No_Padding in options {
		return quanta * 8 + (rem * 8 + 4) / 5
	}
	return quanta * 8 + 8
}

decode :: proc(data: string, DEC_TBL := DEC_TABLE, allocator := context.allocator, options := Decode_Options{}) -> (decoded: []byte, err: Error) {
	info := decode_analyze(data, DEC_TBL, options) or_return
	if info.out_length == 0 {
		return
	}

	buf := make([]byte, info.out_length, allocator) or_return
	decoded, err = decode_impl(buf, info, DEC_TBL)
	if err != nil {
		delete(buf, allocator)
		decoded = nil
	}
	return
}

decode_into_buf :: proc(dst: []byte, data: string, DEC_TBL := DEC_TABLE, options := Decode_Options{}) -> (decoded: []byte, err: Error) {
	info := decode_analyze(data, DEC_TBL, options) or_return
	if info.out_length == 0 {
		return
	}
	return decode_impl(dst, info, DEC_TBL)
}

decode_into :: proc(w: io.Writer, data: string, DEC_TBL := DEC_TABLE, options := Decode_Options{}) -> Error {
	info := decode_analyze(data, DEC_TBL, options) or_return
	_, err := decode_impl(w, info, DEC_TBL)
	return err
}

decoded_len :: proc(data: string, DEC_TBL := DEC_TABLE, options := Decode_Options{}) -> (n: int, err: Decode_Error) {
	info := decode_analyze(data, DEC_TBL, options) or_return
	return info.out_length, .None
}

@(private)
encode_impl :: proc(dst: $T, data: []byte, ENC_TBL := ENC_TABLE, options := Encode_Options{}) -> ([]byte, io.Error) where T == io.Writer || T == []byte {
	length := len(data)
	when T == []byte {
		out_length := encoded_len(data, options)
		if len(dst) < out_length {
			return nil, .Short_Buffer
		}
		buf := dst
	} else {
		buf: [8]byte
	}

	for i := 0; i < length; i += 5 {
		n := min(length - i, 5)
		block: u64
		for j in 0..<n {
			block |= u64(data[i + j]) << uint(32 - 8 * j)
		}

		emit := (n * 8 + 4) / 5
		write := 8
		if .No_Padding in options {
			write = emit
		}
		for j in 0..<write {
			if j < emit {
				buf[j] = ENC_TBL[block >> uint(35 - 5 * j) & 31]
			} else {
				buf[j] = PADDING
			}
		}

		when T == []byte {
			buf = buf[write:]
		} else {
			if _, err := io.write_full(dst, buf[:write]); err != nil {
				return nil, err
			}
		}
	}

	when T == []byte {
		return dst[:out_length], nil
	} else {
		return nil, nil
	}
}

@(private)
Decode_Info :: struct {
	out_length: int,
	trimmed_in: string,
}

@(private)
decode_analyze :: proc(data: string, DEC_TBL := DEC_TABLE, options: Decode_Options) -> (info: Decode_Info, err: Decode_Error) {
	err = validate_strict_decode(data, DEC_TBL, options)
	if err != .None {
		return
	}

	length_in := len(data)
	for length_in > 0 && data[length_in - 1] == PADDING {
		length_in -= 1
	}

	rem_in := length_in % 8
	switch rem_in {
	case 1, 3, 6:
		err = .Malformed_Quantum
		return
	}

	info = {
		out_length = length_in / 8 * 5 + rem_in * 5 / 8,
		trimmed_in = data[:length_in],
	}
	return
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
	pad := 0
	if .No_Padding in options {
		for i in 0..<n {
			if data[i] == PADDING {
				return .Invalid_Padding
			}
		}
	} else {
		for si > 0 && data[si - 1] == PADDING {
			si -= 1
			pad += 1
		}
		for i in 0..<si {
			if data[i] == PADDING {
				return .Invalid_Padding
			}
		}
	}

	rem := si % 8
	switch rem {
	case 1, 3, 6:
		return .Malformed_Quantum
	}

	if .Strict not_in options {
		return .None
	}

	if .No_Padding not_in options {
		if n % 8 != 0 {
			return .Invalid_Padding
		}
		if rem == 0 && pad != 0 || rem != 0 && pad != 8 - rem {
			return .Invalid_Padding
		}
	}

	if rem != 0 {
		c := dec_tbl[data[si - 1]]
		if c < 0 {
			return .Invalid_Character
		}
		if c & (i8(1) << uint(rem * 5 % 8) - 1) != 0 {
			return .Non_Canonical
		}
	}
	return .None
}

@(private)
decode_impl :: proc(dst: $T, info: Decode_Info, DEC_TBL := DEC_TABLE) -> ([]byte, Error) where T == io.Writer || T == []byte {
	when T == []byte {
		if len(dst) < info.out_length {
			return nil, io.Error.Short_Buffer
		}
		buf := dst
	} else {
		buf: [5]byte
	}

	data := info.trimmed_in
	for i := 0; i < len(data); i += 8 {
		n := min(len(data) - i, 8)
		block: u64
		for j in 0..<n {
			d := DEC_TBL[data[i + j]]
			if d & ~i8(0x1f) != 0 {
				return nil, decode_group_error(data[i:][:n], DEC_TBL)
			}
			block |= u64(d) << uint(35 - 5 * j)
		}

		m := n * 5 / 8
		for j in 0..<m {
			buf[j] = byte(block >> uint(32 - 8 * j))
		}

		when T == []byte {
			buf = buf[m:]
		} else {
			if _, err := io.write_full(dst, buf[:m]); err != nil {
				return nil, err
			}
		}
	}

	when T == []byte {
		return dst[:info.out_length], nil
	} else {
		return nil, nil
	}
}

@(private)
decode_group_error :: proc(group: string, DEC_TBL: [256]i8) -> Decode_Error {
	for i in 0..<len(group) {
		if group[i] != PADDING && DEC_TBL[group[i]] & ~i8(0x1f) != 0 {
			return .Invalid_Character
		}
	}
	return .Invalid_Padding
}
