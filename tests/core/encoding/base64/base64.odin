package test_encoding_base64

import "base:intrinsics"
import "core:encoding/base64"
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
