package encoding_base32

import "core:testing"
import "core:bytes"

@(test)
test_base32_decode_valid :: proc(t: ^testing.T) {
	// RFC 4648 Section 10 - Test vectors
	cases := [?]struct {
		input, expected: string,
	}{
		{"", ""},
		{"MY======", "f"},
		{"MZXQ====", "fo"},
		{"MZXW6===", "foo"},
		{"MZXW6YQ=", "foob"},
		{"MZXW6YTB", "fooba"},
		{"MZXW6YTBOI======", "foobar"},
	}

	for c in cases {
		output, err := decode(c.input)
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Error.None)
		expected := transmute([]u8)c.expected
		if output != nil {
			testing.expect(t, bytes.equal(output, expected))
		} else {
			testing.expect(t, len(c.expected) == 0)
		}
	}
}

@(test)
test_base32_encode :: proc(t: ^testing.T) {
	// RFC 4648 Section 10 - Test vectors
	cases := [?]struct {
		input, expected: string,
	}{
		{"", ""},
		{"f", "MY======"},
		{"fo", "MZXQ===="},
		{"foo", "MZXW6==="},
		{"foob", "MZXW6YQ="},
		{"fooba", "MZXW6YTB"},
		{"foobar", "MZXW6YTBOI======"},
	}

	for c in cases {
		output := encode(transmute([]byte)c.input)
		defer delete(output)
		testing.expect(t, output == c.expected)
	}
}

@(test)
test_base32_decode_invalid :: proc(t: ^testing.T) {
	// Section 3.3 - Non-alphabet characters
	{
		// Characters outside alphabet
		input := "MZ1W6YTB" // '1' not in alphabet (A-Z, 2-7)
		output, err := decode(input)
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Error.Invalid_Character)
	}
	{
		// Lowercase not allowed
		input := "mzxq===="
		output, err := decode(input)
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Error.Invalid_Character)
	}

	// Section 3.2 - Padding requirements
	{
		// Padding must only be at end
		input := "MZ=Q===="
		output, err := decode(input)
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Error.Malformed_Input)
	}
	{
		// Missing padding
		input := "MZXQ" // Should be MZXQ====
		output, err := decode(input)
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Error.Malformed_Input)
	}
	{
		// Incorrect padding length
		input := "MZXQ=" // Needs 4 padding chars
		output, err := decode(input)
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Error.Malformed_Input)
	}
	{
		// Too much padding
		input := "MY=========" // Extra padding chars
		output, err := decode(input)
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Error.Malformed_Input)
	}

	// Section 6 - Base32 block size requirements
	{
		// Single character (invalid block)
		input := "M"
		output, err := decode(input)
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Error.Invalid_Length)
	}
}

@(test)
test_base32_roundtrip :: proc(t: ^testing.T) {
	cases := [?]string{
		"",
		"f",
		"fo",
		"foo",
		"foob",
		"fooba",
		"foobar",
	}

	for input in cases {
		encoded := encode(transmute([]byte)input)
		defer delete(encoded)
		decoded, err := decode(encoded)
		if decoded != nil {
			defer delete(decoded)
		}
		testing.expect_value(t, err, Error.None)
		testing.expect(t, bytes.equal(decoded, transmute([]byte)input))
	}
}

@(test)
test_base32_custom_alphabet :: proc(t: ^testing.T) {
	custom_enc_table := [32]byte{
		'0', '1', '2', '3', '4', '5', '6', '7',
		'8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
		'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
		'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V',
	}

	custom_dec_table: [256]u8
	for i := 0; i < len(custom_enc_table); i += 1 {
		custom_dec_table[custom_enc_table[i]] = u8(i)
	}

	/*
	custom_dec_table := [256]u8{
		0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0x00-0x0f
		0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0x10-0x1f
		0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0x20-0x2f
		0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  0,  0,  0,  0,  0,  0, // 0x30-0x3f ('0'-'9')
		0, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, // 0x40-0x4f ('A'-'O')
	 25, 26, 27, 28, 29, 30, 31,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0x50-0x5f ('P'-'V')
		0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0x60-0x6f
		0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0x70-0x7f
		0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0x80-0x8f
		0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0x90-0x9f
		0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0xa0-0xaf
		0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0xb0-0xbf
		0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0xc0-0xcf
		0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0xd0-0xdf
		0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0xe0-0xef
		0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, // 0xf0-0xff
	}
	*/

	custom_validate :: proc(c: byte) -> bool {
		return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'V') || c == byte(PADDING)
	}

	cases := [?]struct {
		input: string,
		enc_expected: string,
	}{
		{"f", "CO======"},
		{"fo", "CPNG===="},
		{"foo", "CPNMU==="},
	}

	for c in cases {
		// Test encoding
		encoded := encode(transmute([]byte)c.input, custom_enc_table)
		defer delete(encoded)
		testing.expect(t, encoded == c.enc_expected)

		// Test decoding
		decoded, err := decode(encoded, custom_dec_table, custom_validate)
		defer if decoded != nil {
			delete(decoded)
		}

		testing.expect_value(t, err, Error.None)
		testing.expect(t, bytes.equal(decoded, transmute([]byte)c.input))
	}

	// Test invalid character detection
	{
		input := "WXY=====" // Contains chars not in our alphabet
		output, err := decode(input, custom_dec_table, custom_validate)
		if output != nil {
			delete(output)
		}
		testing.expect_value(t, err, Error.Invalid_Character)
	}
}
