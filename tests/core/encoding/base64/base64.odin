package test_encoding_base64

import "base:intrinsics"
import "core:encoding/base64"
import "core:io"
import "core:strings"
import "core:testing"

Test :: struct {
	vector: string,
	base64: string,
}

tests :: []Test{
	{"",       ""},
	{"f",      "Zg=="},
	{"fo",     "Zm8="},
	{"foo",    "Zm9v"},
	{"foob",   "Zm9vYg=="},
	{"fooba",  "Zm9vYmE="},
	{"foobar", "Zm9vYmFy"},
}

@(test)
test_encoding :: proc(t: ^testing.T) {
	for test in tests {
		v := base64.encode(transmute([]byte)test.vector)
		defer delete(v)
		testing.expect_value(t, v, test.base64)
	}
}

@(test)
test_decoding :: proc(t: ^testing.T) {
	for test in tests {
		v, err := base64.decode(test.base64)
		if !testing.expect_value(t, err, nil) {
			continue
		}
		defer delete(v)
		testing.expect_value(t, string(v), test.vector)
	}
}

@(test)
test_decoding_failure :: proc(t: ^testing.T) {
	v, err := base64.decode("!#$%")
	testing.expect(t, v == nil)
	testing.expect(t, err == base64.Decode_Error.Invalid_Character)
}

@(test)
test_roundtrip :: proc(t: ^testing.T) {
	values: [1024]u8
	for &v, i in values[:] {
		v = u8(i)
	}

	encoded := base64.encode(values[:])
	defer delete(encoded)

	decoded, err := base64.decode(encoded)
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer delete(decoded)

	for v, i in decoded {
		testing.expect_value(t, v, values[i])
	}
}

@(test)
test_base64url :: proc(t: ^testing.T) {
	plain := ">>>"
	url := "Pj4-"

	encoded := base64.encode(transmute([]byte)plain, base64.ENC_URL_TABLE)
	defer delete(encoded)
	testing.expect_value(t, encoded, url)

	decoded, err := base64.decode(url, base64.DEC_URL_TABLE)
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer delete(decoded)
	testing.expect_value(t, string(decoded), plain)
}

@(test)
test_strict_known :: proc(t: ^testing.T) {
	cases := []struct {
		src:     string,
		options: base64.Decode_Options,
		exp:     string,
	} {
		{"", {.Strict}, ""},
		{"", {.Strict, .No_Padding}, ""},
		{"Zg==", {.Strict}, "f"},
		{"Zm8=", {.Strict}, "fo"},
		{"Zm9v", {.Strict}, "foo"},
		{"Zm9vYg==", {.Strict}, "foob"},
		{"Zm9vYmE=", {.Strict}, "fooba"},
		{"Zm9vYmFy", {.Strict}, "foobar"},
		{"Zg", {.Strict, .No_Padding}, "f"},
		{"Zm8", {.Strict, .No_Padding}, "fo"},
		{"Zm9v", {.Strict, .No_Padding}, "foo"},
		{"Zm9vYg", {.Strict, .No_Padding}, "foob"},
		{"Zm9vYmE", {.Strict, .No_Padding}, "fooba"},
		{"Zm9vYmFy", {.Strict, .No_Padding}, "foobar"},
	}
	for c in cases {
		decoded, err := base64.decode(c.src, options = c.options)
		if !testing.expectf(t, err == nil, "decode(%q, %v): %v", c.src, c.options, err) {
			continue
		}
		testing.expectf(t, string(decoded) == c.exp, "decode(%q): got %q, want %q", c.src, decoded, c.exp)
		delete(decoded)
	}
}

@(test)
test_strict_reject :: proc(t: ^testing.T) {
	cases := []struct {
		src:     string,
		options: base64.Decode_Options,
		err:     base64.Decode_Error,
	} {
		{"A", {.Strict}, .Invalid_Padding},
		{"AA", {.Strict}, .Invalid_Padding},
		{"Zg", {.Strict}, .Invalid_Padding},
		{"Zm8", {.Strict}, .Invalid_Padding},
		{"Zg=", {.Strict}, .Invalid_Padding},
		{"Zg===", {.Strict}, .Invalid_Padding},
		{"=Zg=", {.Strict}, .Invalid_Padding},
		{"Zm=8", {.Strict}, .Invalid_Padding},
		{"AAAAAA=", {.Strict}, .Invalid_Padding},
		{"Zh==", {.Strict}, .Non_Canonical},
		{"QR==", {.Strict}, .Non_Canonical},
		{"WvLTlMrX9NpYDQlEIFlnDB==", {.Strict}, .Non_Canonical},
		{"Zg==", {.Strict, .No_Padding}, .Invalid_Padding},
		{"Zm8=", {.Strict, .No_Padding}, .Invalid_Padding},
		{"Z", {.Strict, .No_Padding}, .Invalid_Padding},
		{"QR", {.Strict, .No_Padding}, .Non_Canonical},
		{"!!!!", {.Strict}, .Invalid_Character},
		{"Zm9!", {.Strict}, .Invalid_Character},
	}
	for c in cases {
		decoded, err := base64.decode(c.src, options = c.options)
		testing.expectf(t, err == c.err, "decode(%q, %v): got %v, want %v", c.src, c.options, err, c.err)
		delete(decoded)
	}
}

@(test)
test_strict_trailing_bits :: proc(t: ^testing.T) {
	// The pair from Go's TestDecoderIssue15656.
	decoded, err := base64.decode("WvLTlMrX9NpYDQlEIFlnDA==", options = {.Strict})
	if testing.expect_value(t, err, nil) {
		delete(decoded)
	}

	decoded, err = base64.decode("WvLTlMrX9NpYDQlEIFlnDB==", options = {.Strict})
	testing.expect(t, err == base64.Decode_Error.Non_Canonical)
	testing.expect(t, decoded == nil)
}

@(test)
test_strict_base64url :: proc(t: ^testing.T) {
	// '>>>' encodes to 'Pj4-' (raw) in the URL alphabet.
	decoded, err := base64.decode("Pj4-", base64.DEC_URL_TABLE, options = {.Strict, .No_Padding})
	if testing.expect_value(t, err, nil) {
		testing.expect_value(t, string(decoded), ">>>")
		delete(decoded)
	}

	// URL alphabet characters are invalid in the standard alphabet.
	_, err = base64.decode("Pj4-", options = {.Strict, .No_Padding})
	testing.expect(t, err == base64.Decode_Error.Invalid_Character)

	// Padded URL alphabet: {0xFB, 0xEF} encodes to '--8='.
	decoded, err = base64.decode("--8=", base64.DEC_URL_TABLE, options = {.Strict})
	if testing.expect_value(t, err, nil) {
		testing.expect_value(t, string(decoded), "\xFB\xEF")
		delete(decoded)
	}
}

@(test)
test_strict_roundtrip :: proc(t: ^testing.T) {
	values: [1024]u8
	for &v, i in values[:] {
		v = u8(i)
	}

	for n in 0 ..= len(values) {
		data := values[:n]

		padded := base64.encode(data)
		defer delete(padded)

		decoded, err := base64.decode(padded, options = {.Strict})
		if testing.expectf(t, err == nil, "strict padded decode n=%d: %v", n, err) {
			testing.expectf(t, string(decoded) == string(data), "strict padded roundtrip mismatch n=%d", n)
			delete(decoded)
		}

		raw := strings.trim_right(padded, "=")
		decoded, err = base64.decode(raw, options = {.Strict, .No_Padding})
		if testing.expectf(t, err == nil, "strict raw decode n=%d: %v", n, err) {
			testing.expectf(t, string(decoded) == string(data), "strict raw roundtrip mismatch n=%d", n)
			delete(decoded)
		}
	}
}

@(test)
test_strict_decode_into :: proc(t: ^testing.T) {
	builder: strings.Builder
	strings.builder_init(&builder)
	defer strings.builder_destroy(&builder)

	err := base64.decode_into(strings.to_writer(&builder), "Zm9v", options = {.Strict})
	testing.expect_value(t, err, nil)
	testing.expect_value(t, strings.to_string(builder), "foo")

	err = base64.decode_into(strings.to_writer(&builder), "Zh==", options = {.Strict})
	testing.expect(t, err == base64.Decode_Error.Non_Canonical)

	buf: [8]byte
	decoded, derr := base64.decode_into_buf(buf[:], "Zm8", options = {.Strict, .No_Padding})
	testing.expect_value(t, derr, nil)
	testing.expect_value(t, string(decoded), "fo")

	_, derr = base64.decode_into_buf(buf[:], "Zm8=", options = {.Strict, .No_Padding})
	testing.expect(t, derr == base64.Decode_Error.Invalid_Padding)
}

@(test)
test_strict_is_optional :: proc(t: ^testing.T) {
	// Without options, the historical lenient behavior is preserved.
	lenient := []string{"Zg", "Zh=="}
	for src in lenient {
		decoded, err := base64.decode(src)
		testing.expectf(t, err == nil, "lenient decode(%q): %v", src, err)
		delete(decoded)
	}
}

@(test)
test_encoding_no_padding :: proc(t: ^testing.T) {
	cases := []Test{
		{"",       ""},
		{"f",      "Zg"},
		{"fo",     "Zm8"},
		{"foo",    "Zm9v"},
		{"foob",   "Zm9vYg"},
		{"fooba",  "Zm9vYmE"},
		{"foobar", "Zm9vYmFy"},
	}
	for c in cases {
		v := base64.encode(transmute([]byte)c.vector, options = {.No_Padding})
		defer delete(v)
		testing.expectf(t, v == c.base64, "encode(%q, raw): got %q, want %q", c.vector, v, c.base64)
	}

	url_cases := []Test{
		{">>>",     "Pj4-"},
		{"\xFB\xEF", "--8"},
	}
	for c in url_cases {
		v := base64.encode(transmute([]byte)c.vector, base64.ENC_URL_TABLE, options = {.No_Padding})
		defer delete(v)
		testing.expectf(t, v == c.base64, "encode url(%q, raw): got %q, want %q", c.vector, v, c.base64)
	}
}

@(test)
test_encoding_no_padding_roundtrip :: proc(t: ^testing.T) {
	values: [1024]u8
	for &v, i in values[:] {
		v = u8(i)
	}

	tables := []struct {
		enc: [64]byte,
		dec: [256]i8,
	} {
		{base64.ENC_TABLE, base64.DEC_TABLE},
		{base64.ENC_URL_TABLE, base64.DEC_URL_TABLE},
	}

	for table, ti in tables {
		for n in 0 ..= len(values) {
			data := values[:n]

			padded := base64.encode(data, table.enc)
			raw := base64.encode(data, table.enc, options = {.No_Padding})

			if !testing.expectf(t, raw == strings.trim_right(padded, "="), "table %d n=%d: raw %q, padded %q", ti, n, raw, padded) {
				delete(padded)
				delete(raw)
				continue
			}
			testing.expectf(t, base64.encoded_len(data, {.No_Padding}) == len(raw), "table %d n=%d: encoded_len %d, raw len %d", ti, n, base64.encoded_len(data, {.No_Padding}), len(raw))
			testing.expectf(t, strings.index_byte(raw, '=') < 0, "table %d n=%d: raw output contains padding: %q", ti, n, raw)

			decoded, err := base64.decode(raw, table.dec, options = {.Strict, .No_Padding})
			if testing.expectf(t, err == nil, "table %d n=%d: strict raw decode: %v", ti, n, err) {
				testing.expectf(t, string(decoded) == string(data), "table %d n=%d: raw roundtrip mismatch", ti, n)
				delete(decoded)
			}

			delete(padded)
			delete(raw)
		}
	}
}

@(test)
test_encoding_no_padding_into_buf :: proc(t: ^testing.T) {
	data := []byte{0xFB, 0xEF, 0xFF, 0x01, 0x7A, 0x00}

	for n in 0 ..= len(data) {
		raw_len := base64.encoded_len(data[:n], {.No_Padding})

		// The tail is a canary: raw output must not write pad bytes past
		// the advertised length, even with a buffer that covers them.
		canary: [64]byte
		for &b in canary {
			b = 0xA5
		}

		encoded, err := base64.encode_into_buf(canary[:raw_len], data[:n], options = {.No_Padding})
		if !testing.expectf(t, err == nil, "n=%d: encode_into_buf: %v", n, err) {
			continue
		}
		testing.expectf(t, len(encoded) == raw_len, "n=%d: returned %d bytes, want %d", n, len(encoded), raw_len)

		for b, i in canary[raw_len:] {
			testing.expectf(t, b == 0xA5, "n=%d: byte %d past raw output overwritten: %x", n, raw_len + i, b)
		}

		decoded, derr := base64.decode(string(encoded), options = {.Strict, .No_Padding})
		if testing.expectf(t, derr == nil, "n=%d: decode: %v", n, derr) {
			testing.expectf(t, string(decoded) == string(data[:n]), "n=%d: roundtrip mismatch", n)
			delete(decoded)
		}

		if raw_len > 0 {
			_, serr := base64.encode_into_buf(canary[:raw_len - 1], data[:n], options = {.No_Padding})
			testing.expectf(t, serr == io.Error.Short_Buffer, "n=%d: short buffer: %v", n, serr)
		}
	}
}

@(test)
test_encoding_no_padding_into :: proc(t: ^testing.T) {
	builder: strings.Builder
	strings.builder_init(&builder)
	defer strings.builder_destroy(&builder)

	foob := "foob"
	err := base64.encode_into(strings.to_writer(&builder), transmute([]byte)foob, options = {.No_Padding})
	testing.expect_value(t, err, nil)
	testing.expect_value(t, strings.to_string(builder), "Zm9vYg")

	// A full block followed by a two-character tail.
	builder2: strings.Builder
	strings.builder_init(&builder2)
	defer strings.builder_destroy(&builder2)

	fooba := "fooba"
	err = base64.encode_into(strings.to_writer(&builder2), transmute([]byte)fooba, base64.ENC_URL_TABLE, options = {.No_Padding})
	testing.expect_value(t, err, nil)
	testing.expect_value(t, strings.to_string(builder2), "Zm9vYmE")

	// Empty input writes nothing.
	builder3: strings.Builder
	strings.builder_init(&builder3)
	defer strings.builder_destroy(&builder3)

	err = base64.encode_into(strings.to_writer(&builder3), nil, options = {.No_Padding})
	testing.expect_value(t, err, nil)
	testing.expect_value(t, strings.to_string(builder3), "")
}

// Transforms a canonical padded standard-alphabet vector into the URL-safe
// alphabet (RFC 4648 section 5, Table 2) and/or the unpadded form (section
// 3.2), mirroring the reference-string converters of Go's encoding/base64
// tests. The result lives in the temp allocator.
_transform_reference :: proc(encoded: string, url, raw: bool) -> string {
	s := encoded
	if url {
		s, _ = strings.replace_all(s, "+", "-", allocator = context.temp_allocator)
		s, _ = strings.replace_all(s, "/", "_", allocator = context.temp_allocator)
	}
	if raw {
		s = strings.trim_right(s, "=")
	}
	return s
}

@(test)
test_rfc4648_and_go_vectors :: proc(t: ^testing.T) {
	vectors := []Test{
		// RFC 4648 section 9 illustrations (also the RFC 3548 examples in
		// Go's encoding/base64 tests). These cover all three padding cases
		// and exercise index 62 '+', which separates the URL alphabet.
		{"\x14\xFB\x9C\x03\xD9\x7E", "FPucA9l+"},
		{"\x14\xFB\x9C\x03\xD9",     "FPucA9k="},
		{"\x14\xFB\x9C\x03",         "FPucAw=="},

		// RFC 4648 section 10 test vectors.
		{"",       ""},
		{"f",      "Zg=="},
		{"fo",     "Zm8="},
		{"foo",    "Zm9v"},
		{"foob",   "Zm9vYg=="},
		{"fooba",  "Zm9vYmE="},
		{"foobar", "Zm9vYmFy"},

		// "Wikipedia examples", via Go's encoding/base64 tests.
		{"sure.",    "c3VyZS4="},
		{"sure",     "c3VyZQ=="},
		{"sur",      "c3Vy"},
		{"su",       "c3U="},
		{"leasure.", "bGVhc3VyZS4="},
		{"easure.",  "ZWFzdXJlLg=="},
		{"asure.",   "YXN1cmUu"},

		// Go's bigtest.
		{"Twas brillig, and the slithy toves", "VHdhcyBicmlsbGlnLCBhbmQgdGhlIHNsaXRoeSB0b3Zlcw=="},
	}

	variants := []struct {
		name:     string,
		enc:      [64]byte,
		dec:      [256]i8,
		options:  base64.Encode_Options,
		doptions: base64.Decode_Options,
		url:      bool,
		raw:      bool,
	} {
		{"std",     base64.ENC_TABLE,     base64.DEC_TABLE,     {},            {.Strict},              false, false},
		{"url",     base64.ENC_URL_TABLE, base64.DEC_URL_TABLE, {},            {.Strict},              true,  false},
		{"raw",     base64.ENC_TABLE,     base64.DEC_TABLE,     {.No_Padding}, {.Strict, .No_Padding}, false, true},
		{"raw url", base64.ENC_URL_TABLE, base64.DEC_URL_TABLE, {.No_Padding}, {.Strict, .No_Padding}, true,  true},
	}

	for v in vectors {
		for variant in variants {
			expected := _transform_reference(v.base64, variant.url, variant.raw)

			encoded := base64.encode(transmute([]byte)v.vector, variant.enc, options = variant.options)
			testing.expectf(t, encoded == expected, "%s encode(%q): got %q, want %q", variant.name, v.vector, encoded, expected)
			testing.expectf(t, base64.encoded_len(transmute([]byte)v.vector, variant.options) == len(expected), "%s encoded_len(%q): got %d, want %d", variant.name, v.vector, base64.encoded_len(transmute([]byte)v.vector, variant.options), len(expected))
			delete(encoded)

			decoded, err := base64.decode(expected, variant.dec, options = variant.doptions)
			if testing.expectf(t, err == nil, "%s decode(%q): %v", variant.name, expected, err) {
				testing.expectf(t, string(decoded) == v.vector, "%s decode(%q): got %q, want %q", variant.name, expected, decoded, v.vector)
			}
			delete(decoded)
		}
	}
}

@(test)
test_newline_rejected :: proc(t: ^testing.T) {
	// Inputs from Go's TestNewLineCharacters. Go's decoder deliberately ignores
	// "\r" and "\n" (MIME legacy); RFC 4648 section 3.3 says implementations
	// MUST reject characters outside the alphabet, so Odin must not accept them.
	// The strict validator checks structure before the alphabet, so only the
	// fact of rejection is asserted here.
	strict_cases := []string{
		"c3VyZQ==\r",
		"c3VyZQ==\n",
		"c3VyZQ==\r\n",
		"c3VyZ\r\nQ==",
		"c3V\ryZ\nQ==",
		"c3V\nyZ\rQ==",
		"c3VyZ\nQ==",
		"c3VyZQ\n==",
		"c3VyZQ=\n=",
		"c3VyZQ=\r\n\r\n=",
	}
	for c in strict_cases {
		decoded, err := base64.decode(c, options = {.Strict})
		testing.expectf(t, err != nil, "strict decode(%q): expected rejection, got %q", c, decoded)
		delete(decoded)
	}

	// Lenient mode only scans the input span `decoded_len` implies, so bytes
	// past the decoded tail are not always inspected (e.g. "c3VyZQ\n=="
	// currently decodes to "sure"); interior ones are always seen.
	lenient_cases := []string{
		"c3VyZQ==\n",
		"c3VyZQ=\n=",
		"c3V\ryZ\rQ==",
	}
	for c in lenient_cases {
		decoded, err := base64.decode(c)
		testing.expectf(t, err == base64.Decode_Error.Invalid_Character, "lenient decode(%q): got %v, want Invalid_Character", c, err)
		testing.expect(t, decoded == nil)
	}
}
