package test_core_hex

import "core:encoding/hex"
import "core:testing"
import "core:fmt"
import "core:os"

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect  :: testing.expect
	log     :: testing.log
} else {
	expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.printf("[%v] %v\n", loc, message)
			return
		}
	}
	log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

main :: proc() {
	t := testing.T{}

	hex_encode(&t)
	hex_decode(&t)
	hex_decode_sequence(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

CASES :: [][2]string{
	{"11", "3131"},
	{"g", "67"},
	{"Hello", "48656c6c6f"},
}

@(test)
hex_encode :: proc(t: ^testing.T) {
	for test in CASES {
		encoded := string(hex.encode(transmute([]byte)test[0]))
		expect(
			t,
			encoded == test[1],
			fmt.tprintf("encode: %q -> %q (should be: %q)", test[0], encoded, test[1]),
		)
	}
}

@(test)
hex_decode :: proc(t: ^testing.T) {
	for test in CASES {
		decoded, ok := hex.decode(transmute([]byte)test[1])
		expect(t, ok, fmt.tprintf("decode: %q not ok", test[1]))
		expect(
			t,
			string(decoded) == test[0],
			fmt.tprintf("decode: %q -> %q (should be: %q)", test[1], string(decoded), test[0]),
		)
	}
}

@(test)
hex_decode_sequence :: proc(t: ^testing.T) {
	b, ok := hex.decode_sequence("0x23")
	expect(t, ok, "decode_sequence: 0x23 not ok")
	expect(t, b == '#', fmt.tprintf("decode_sequence: 0x23 -> %c (should be: %c)", b, '#'))

	b, ok = hex.decode_sequence("0X3F")
	expect(t, ok, "decode_sequence: 0X3F not ok")
	expect(t, b == '?', fmt.tprintf("decode_sequence: 0X3F -> %c (should be: %c)", b, '?'))

	b, ok = hex.decode_sequence("2a")
	expect(t, ok, "decode_sequence: 2a not ok")
	expect(t, b == '*', fmt.tprintf("decode_sequence: 2a -> %c (should be: %c)", b, '*'))

	_, ok = hex.decode_sequence("1")
	expect(t, !ok, "decode_sequence: 1 should be too short")

	_, ok = hex.decode_sequence("123")
	expect(t, !ok, "decode_sequence: 123 should be too long")
}
