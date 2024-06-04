package test_core_hex

import "core:encoding/hex"
import "core:testing"

CASES :: [][2]string{
	{"11", "3131"},
	{"g", "67"},
	{"Hello", "48656c6c6f"},
}

@(test)
hex_encode :: proc(t: ^testing.T) {
	for test in CASES {
		encoded := string(hex.encode(transmute([]byte)test[0]))
		defer delete(encoded)
		testing.expectf(
			t,
			encoded == test[1],
			"encode: %q -> %q (should be: %q)",
			test[0],
			encoded,
			test[1],
		)
	}
}

@(test)
hex_decode :: proc(t: ^testing.T) {
	for test in CASES {
		decoded, ok := hex.decode(transmute([]byte)test[1])
		defer delete(decoded)
		testing.expectf(
			t,
			ok,
			"decode: %q not ok",
			test[1],
		)
		testing.expectf(
			t,
			string(decoded) == test[0],
			"decode: %q -> %q (should be: %q)",
			test[1],
			string(decoded),
			test[0],
		)
	}
}

@(test)
hex_decode_sequence :: proc(t: ^testing.T) {
	b, ok := hex.decode_sequence("0x23")
	testing.expect(t, ok, "decode_sequence: 0x23 not ok")
	testing.expectf(
		t,
		b == '#',
		"decode_sequence: 0x23 -> %c (should be: %c)",
		b,
		'#',
	)

	b, ok = hex.decode_sequence("0X3F")
	testing.expect(t, ok, "decode_sequence: 0X3F not ok")
	testing.expectf(
		t,
		b == '?',
		"decode_sequence: 0X3F -> %c (should be: %c)",
		b,
		'?',
	)

	b, ok = hex.decode_sequence("2a")
	testing.expect(t, ok, "decode_sequence: 2a not ok")
	testing.expectf(t,
		b == '*',
		"decode_sequence: 2a -> %c (should be: %c)",
		b,
		'*',
	)

	_, ok = hex.decode_sequence("1")
	testing.expect(t, !ok, "decode_sequence: 1 should be too short")

	_, ok = hex.decode_sequence("123")
	testing.expect(t, !ok, "decode_sequence: 123 should be too long")
}