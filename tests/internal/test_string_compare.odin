package test_internal_string_compare

import "core:fmt"
import "core:os"
import "core:testing"

Op :: enum { Eq, Lt, Gt }

Test :: struct {
	a:   cstring,
	b:   cstring,
	res: [Op]bool,
}

CASES := []Test{
	{"hellope",  "hellope", {.Eq=true,  .Lt=false, .Gt=false}},
	{"Hellope",  "hellope", {.Eq=false, .Lt=true,  .Gt=false}}, // H < h
	{"Hell",     "Hellope", {.Eq=false, .Lt=true,  .Gt=false}},
	{"Hellope!", "Hellope", {.Eq=false, .Lt=false, .Gt=true }},
	{"Hellopf",  "Hellope", {.Eq=false, .Lt=false, .Gt=true }},
}

@test
string_compare :: proc(t: ^testing.T) {
	for v in CASES {
		s_a := string(v.a)
		s_b := string(v.b)

		for res, op in v.res {
			switch op {
			case .Eq:
				expect(t, (v.a == v.b) == res,  fmt.tprintf("Expected cstring(\"%v\") == cstring(\"%v\") to be %v", v.a, v.b, res))
				expect(t, (s_a == s_b) == res,  fmt.tprintf("Expected string(\"%v\") == string(\"%v\") to be %v", v.a, v.b, res))

				// If a == b then a != b
				expect(t, (v.a != v.b) == !res, fmt.tprintf("Expected cstring(\"%v\") != cstring(\"%v\") to be %v", v.a, v.b, !res))
				expect(t, (s_a != s_b) == !res, fmt.tprintf("Expected string(\"%v\") != string(\"%v\") to be %v", v.a, v.b, !res))

			case .Lt:
				expect(t, (v.a < v.b) == res,  fmt.tprintf("Expected cstring(\"%v\") < cstring(\"%v\") to be %v", v.a, v.b, res))
				expect(t, (s_a < s_b) == res,  fmt.tprintf("Expected string(\"%v\") < string(\"%v\") to be %v", v.a, v.b, res))

				// .Lt | .Eq == .LtEq
				lteq := v.res[.Eq] | res
				expect(t, (v.a <= v.b) == lteq, fmt.tprintf("Expected cstring(\"%v\") <= cstring(\"%v\") to be %v", v.a, v.b, lteq))
				expect(t, (s_a <= s_b) == lteq, fmt.tprintf("Expected string(\"%v\") <= string(\"%v\") to be %v", v.a, v.b, lteq))

			case .Gt:
				expect(t, (v.a > v.b) == res,  fmt.tprintf("Expected cstring(\"%v\") > cstring(\"%v\") to be %v", v.a, v.b, res))
				expect(t, (s_a > s_b) == res,  fmt.tprintf("Expected string(\"%v\") > string(\"%v\") to be %v", v.a, v.b, res))

				// .Gt | .Eq == .GtEq
				gteq := v.res[.Eq] | res
				expect(t, (v.a >= v.b) == gteq, fmt.tprintf("Expected cstring(\"%v\") >= cstring(\"%v\") to be %v", v.a, v.b, gteq))
				expect(t, (s_a >= s_b) == gteq, fmt.tprintf("Expected string(\"%v\") >= string(\"%v\") to be %v", v.a, v.b, gteq))
			}
		}
	}
}

// -------- -------- -------- -------- -------- -------- -------- -------- -------- --------

main :: proc() {
	t := testing.T{}

	string_compare(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

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