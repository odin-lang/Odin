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
		testing.expect(t, output == c.expected)
	}
}

@(test)
test_base32_decode_invalid :: proc(t: ^testing.T) {
	// Section 3.2 - Alphabet check
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

	// Section 4 - Padding requirements
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

	// Section 6 - Block size requirements
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
		decoded, err := decode(encoded)
		if decoded != nil {
			defer delete(decoded)
		}
		testing.expect_value(t, err, Error.None)
		testing.expect(t, bytes.equal(decoded, transmute([]byte)input))
	}
}
