package test_internal_string_compare

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
				testing.expectf(t, (v.a == v.b) == res,  "Expected cstring(\"%v\") == cstring(\"%v\") to be %v", v.a, v.b, res)
				testing.expectf(t, (s_a == s_b) == res,  "Expected string(\"%v\") == string(\"%v\") to be %v", v.a, v.b, res)

				// If a == b then a != b
				testing.expectf(t, (v.a != v.b) == !res, "Expected cstring(\"%v\") != cstring(\"%v\") to be %v", v.a, v.b, !res)
				testing.expectf(t, (s_a != s_b) == !res, "Expected string(\"%v\") != string(\"%v\") to be %v", v.a, v.b, !res)

			case .Lt:
				testing.expectf(t, (v.a < v.b) == res,   "Expected cstring(\"%v\") < cstring(\"%v\") to be %v", v.a, v.b, res)
				testing.expectf(t, (s_a < s_b) == res,   "Expected string(\"%v\") < string(\"%v\") to be %v", v.a, v.b, res)

				// .Lt | .Eq == .LtEq
				lteq := v.res[.Eq] | res
				testing.expectf(t, (v.a <= v.b) == lteq, "Expected cstring(\"%v\") <= cstring(\"%v\") to be %v", v.a, v.b, lteq)
				testing.expectf(t, (s_a <= s_b) == lteq, "Expected string(\"%v\") <= string(\"%v\") to be %v", v.a, v.b, lteq)

			case .Gt:
				testing.expectf(t, (v.a > v.b) == res,   "Expected cstring(\"%v\") > cstring(\"%v\") to be %v", v.a, v.b, res)
				testing.expectf(t, (s_a > s_b) == res,   "Expected string(\"%v\") > string(\"%v\") to be %v", v.a, v.b, res)

				// .Gt | .Eq == .GtEq
				gteq := v.res[.Eq] | res
				testing.expectf(t, (v.a >= v.b) == gteq, "Expected cstring(\"%v\") >= cstring(\"%v\") to be %v", v.a, v.b, gteq)
				testing.expectf(t, (s_a >= s_b) == gteq, "Expected string(\"%v\") >= string(\"%v\") to be %v", v.a, v.b, gteq)
			}
		}
	}
}