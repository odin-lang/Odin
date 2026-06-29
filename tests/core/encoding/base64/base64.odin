package test_encoding_base64

import "base:intrinsics"
import "core:encoding/base64"
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
