// Base32 encoding/decoding implementation as specified in RFC 4648.
// [[ More; https://www.rfc-editor.org/rfc/rfc4648.html ]]
package encoding_base32

// @note(zh): Encoding utility for Base32
// A secondary param can be used to supply a custom alphabet to
// @link(encode) and a matching decoding table to @link(decode).
// If none is supplied it just uses the standard Base32 alphabet.
// In case your specific version does not use padding, you may
// truncate it from the encoded output.

// Error represents errors that can occur during base32 decoding operations.
// As per RFC 4648:
// - Section 3.3: Invalid character handling
// - Section 3.2: Padding requirements
// - Section 6: Base32 encoding specifics (including block size requirements)
Error :: enum {
	None,
	Invalid_Character, // Input contains characters outside the specified alphabet
	Invalid_Length,    // Input length is not valid for base32 (must be a multiple of 8 with proper padding)
	Malformed_Input,   // Input has improper structure (wrong padding position or incomplete groups)
}

Validate_Proc :: #type proc(c: byte) -> bool

@private
_validate_default :: proc(c: byte) -> bool {
	return (c >= 'A' && c <= 'Z') || (c >= '2' && c <= '7')
}

@(rodata)
ENC_TABLE := [32]byte {
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
	'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
	'Y', 'Z', '2', '3', '4', '5', '6', '7',
}

PADDING :: '='

@(rodata)
DEC_TABLE := [256]u8 {
	 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	 0,  0, 26, 27, 28, 29, 30, 31,  0,  0,  0,  0,  0,  0,  0,  0,
	 0,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,  0,  0,  0,  0,  0,
	 0,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,  0,  0,  0,  0,  0,
	 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
}

encode :: proc(data: []byte, ENC_TBL := ENC_TABLE, allocator := context.allocator) -> string {
	out_length := (len(data) + 4) / 5 * 8
	out := make([]byte, out_length, allocator)
	_encode(out, data, ENC_TBL)
	return string(out[:])
}

@private
_encode :: proc(out, data: []byte, ENC_TBL := ENC_TABLE, allocator := context.allocator) {
	out := out
	data := data

	for len(data) > 0 {
		carry: byte
		switch len(data) {
		case:
			out[7] = ENC_TBL[data[4] & 0x1f]
			carry = data[4] >> 5
			fallthrough
		case 4:
			out[6] = ENC_TBL[carry | (data[3] << 3) & 0x1f]
			out[5] = ENC_TBL[(data[3] >> 2) & 0x1f]
			carry = data[3] >> 7
			fallthrough
		case 3:
			out[4] = ENC_TBL[carry | (data[2] << 1) & 0x1f]
			carry = (data[2] >> 4) & 0x1f
			fallthrough
		case 2:
			out[3] = ENC_TBL[carry | (data[1] << 4) & 0x1f]
			out[2] = ENC_TBL[(data[1] >> 1) & 0x1f]
			carry = (data[1] >> 6) & 0x1f
			fallthrough
		case 1:
			out[1] = ENC_TBL[carry | (data[0] << 2) & 0x1f]
			out[0] = ENC_TBL[data[0] >> 3]
		}

		if len(data) < 5 {
			out[7] = byte(PADDING)
			if len(data) < 4 {
				out[6] = byte(PADDING)
				out[5] = byte(PADDING)
				if len(data) < 3 {
					out[4] = byte(PADDING)
					if len(data) < 2 {
						out[3] = byte(PADDING)
						out[2] = byte(PADDING)
					}
				}
			}
			break
		}
		data = data[5:]
		out = out[8:]
	}
}

@(optimization_mode="favor_size")
decode :: proc(
	data: string,
	DEC_TBL := DEC_TABLE,
	validate: Validate_Proc = _validate_default,
	allocator := context.allocator) -> (out: []byte, err: Error) {
	if len(data) == 0 {
		return nil, .None
	}

	// Check minimum length requirement first
	if len(data) < 2 {
		return nil, .Invalid_Length
	}

	// Validate characters using provided validation function
	for i := 0; i < len(data); i += 1 {
		c := data[i]
		if c == byte(PADDING) {
			break
		}
		if !validate(c) {
			return nil, .Invalid_Character
		}
	}

	// Validate padding and length
	data_len := len(data)
	padding_count := 0
	for i := data_len - 1; i >= 0; i -= 1 {
		if data[i] != byte(PADDING) {
			break
		}
		padding_count += 1
	}

	// Check for proper padding and length combinations
	if padding_count > 0 {
		// Verify no padding in the middle
		for i := 0; i < data_len - padding_count; i += 1 {
			if data[i] == byte(PADDING) {
				return nil, .Malformed_Input
			}
		}

		content_len := data_len - padding_count
		mod8 := content_len % 8
		required_padding: int
		switch mod8 {
		case 2: required_padding = 6 // 2 chars need 6 padding chars
		case 4: required_padding = 4 // 4 chars need 4 padding chars
		case 5: required_padding = 3 // 5 chars need 3 padding chars
		case 7: required_padding = 1 // 7 chars need 1 padding char
		case: required_padding = 0
		}

		if required_padding > 0 {
			if padding_count != required_padding {
				return nil, .Malformed_Input
			}
		} else if mod8 != 0 {
			return nil, .Malformed_Input
		}
	} else {
		// No padding - must be multiple of 8
		if data_len % 8 != 0 {
			return nil, .Malformed_Input
		}
	}

	// Calculate decoded length: 5 bytes for every 8 input chars
	input_chars := data_len - padding_count
	out_len := input_chars * 5 / 8
	out = make([]byte, out_len, allocator)
	defer if err != .None {
		delete(out)
	}

	// Process input in 8-byte blocks
	outi := 0
	for i := 0; i < input_chars; i += 8 {
		buf: [8]byte
		block_size := min(8, input_chars - i)

		// Decode block
		for j := 0; j < block_size; j += 1 {
			buf[j] = DEC_TBL[data[i + j]]
		}

		// Convert to output bytes based on block size
		bytes_to_write := block_size * 5 / 8
		switch block_size {
		case 8:
			out[outi + 4] = (buf[6] << 5) | buf[7]
			fallthrough
		case 7:
			out[outi + 3] = (buf[4] << 7) | (buf[5] << 2) | (buf[6] >> 3)
			fallthrough
		case 5:
			out[outi + 2] = (buf[3] << 4) | (buf[4] >> 1)
			fallthrough
		case 4:
			out[outi + 1] = (buf[1] << 6) | (buf[2] << 1) | (buf[3] >> 4)
			fallthrough
		case 2:
			out[outi] = (buf[0] << 3) | (buf[1] >> 2)
		}
		outi += bytes_to_write
	}

	return
}
