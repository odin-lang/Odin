package test_encoding_base64

import "base:intrinsics"

import "core:encoding/base64"
import "core:fmt"
import "core:os"
import "core:reflect"
import "core:testing"

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect_value :: testing.expect_value

} else {
	expect_value :: proc(t: ^testing.T, value, expected: $T, loc := #caller_location) -> bool where intrinsics.type_is_comparable(T) {
		TEST_count += 1
		ok := value == expected || reflect.is_nil(value) && reflect.is_nil(expected)
		if !ok {
			TEST_fail += 1
			fmt.printf("[%v] expected %v, got %v\n", loc, expected, value)
		}
		return ok
	}
}

main :: proc() {
	t := testing.T{}

	test_encoding(&t)
	test_decoding(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

@(test)
test_encoding :: proc(t: ^testing.T) {
	expect_value(t, base64.encode(transmute([]byte)string("")), "")
	expect_value(t, base64.encode(transmute([]byte)string("f")), "Zg==")
	expect_value(t, base64.encode(transmute([]byte)string("fo")), "Zm8=")
	expect_value(t, base64.encode(transmute([]byte)string("foo")), "Zm9v")
	expect_value(t, base64.encode(transmute([]byte)string("foob")), "Zm9vYg==")
	expect_value(t, base64.encode(transmute([]byte)string("fooba")), "Zm9vYmE=")
	expect_value(t, base64.encode(transmute([]byte)string("foobar")), "Zm9vYmFy")
}

@(test)
test_decoding :: proc(t: ^testing.T) {
	expect_value(t, string(base64.decode("")), "")
	expect_value(t, string(base64.decode("Zg==")), "f")
	expect_value(t, string(base64.decode("Zm8=")), "fo")
	expect_value(t, string(base64.decode("Zm9v")), "foo")
	expect_value(t, string(base64.decode("Zm9vYg==")), "foob")
	expect_value(t, string(base64.decode("Zm9vYmE=")), "fooba")
	expect_value(t, string(base64.decode("Zm9vYmFy")), "foobar")
}
