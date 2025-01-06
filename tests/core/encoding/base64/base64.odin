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
		v := string(base64.decode(test.base64))
		defer delete(v)
		testing.expect_value(t, v, test.vector)
	}
}
