package test_encoding_base32

import "core:testing"
import "core:bytes"
import "core:encoding/base32"

Decode_Error :: base32.Decode_Error

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
		output, err := base32.decode(c.input)
		defer delete(output)
		testing.expect_value(t, err, nil)
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
		output := base32.encode(transmute([]byte)c.input)
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
		output, err := base32.decode(input)
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Decode_Error.Invalid_Character)
	}
	{
		// Lowercase not allowed
		input := "mzxq===="
		output, err := base32.decode(input)
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Decode_Error.Invalid_Character)
	}

	// Section 3.2 - Padding requirements
	{
		// Padding in middle without trailing padding
		input := "MZ===YTBMZXW6YTB" // '===' in middle, no trailing padding
		output, err := base32.decode(input)
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Decode_Error.Invalid_Padding)
	}
	{
		// Padding must only be at end (with trailing padding)
		input := "MZ=Q===="
		output, err := base32.decode(input)
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Decode_Error.Invalid_Padding)
	}
	{
		// Missing padding
		input := "MZXQ" // Should be MZXQ====
		output, err := base32.decode(input, options = {.Strict})
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Decode_Error.Invalid_Padding)
	}
	{
		// Incorrect padding length
		input := "MZXQ=" // Needs 4 padding chars
		output, err := base32.decode(input, options = {.Strict})
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Decode_Error.Invalid_Padding)
	}
	{
		// Too much padding
		input := "MY=========" // Extra padding chars
		output, err := base32.decode(input, options = {.Strict})
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Decode_Error.Invalid_Padding)
	}

	// Section 6 - Base32 block size requirements
	{
		// Single character (invalid block)
		input := "M"
		output, err := base32.decode(input)
		if output != nil {
			defer delete(output)
		}
		testing.expect_value(t, err, Decode_Error.Malformed_Quantum)
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
		encoded := base32.encode(transmute([]byte)input)
		defer delete(encoded)
		decoded, err := base32.decode(encoded)
		defer delete(decoded)
		testing.expect_value(t, err, nil)
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

	custom_dec_table: [256]i8
	for &v in custom_dec_table {
		v = -1
	}
	for i := 0; i < len(custom_enc_table); i += 1 {
		custom_dec_table[custom_enc_table[i]] = i8(i)
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
		encoded := base32.encode(transmute([]byte)c.input, custom_enc_table)
		defer delete(encoded)
		testing.expect(t, encoded == c.enc_expected)

		// Test decoding
		decoded, err := base32.decode(encoded, custom_dec_table)
		defer if decoded != nil {
			delete(decoded)
		}

		testing.expect_value(t, err, nil)
		testing.expect(t, bytes.equal(decoded, transmute([]byte)c.input))
	}

	// Test invalid character detection
	{
		input := "WXYZ====" // Contains chars not in our alphabet
		output, err := base32.decode(input, custom_dec_table)
		if output != nil {
			delete(output)
		}
		testing.expect_value(t, err, Decode_Error.Invalid_Character)
	}
}
