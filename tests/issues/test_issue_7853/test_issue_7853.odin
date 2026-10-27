package test_issue_7853

import "core:testing"

// The bounds of a `switch` range case were not converted to the type of the switch tag, unlike a single case
// value, so untyped bounds took their own default type. Against a `cstring` tag they became `string`, and
// converting a constant `string` to `cstring` in the backend crashed the compiler. A `cstring16` or `string16`
// tag failed with an invalid conversion from `string`, and a constant `cstring` or `cstring16` tag missed the
// runtime comparison procedures it needs.

classify :: proc(text: cstring) -> int {
	switch text {
	case "0"..="9":
		return 1
	case "a"..<"n":
		return 2
	case:
		return 0
	}
}

@(test)
test_cstring_range :: proc(t: ^testing.T) {
	testing.expect_value(t, classify("0"), 1)
	testing.expect_value(t, classify("3"), 1)
	testing.expect_value(t, classify("9"), 1)
	testing.expect_value(t, classify("10"), 1) // compared as strings, "0" <= "10" <= "9"
	testing.expect_value(t, classify("a"), 2)
	testing.expect_value(t, classify("m"), 2)
	testing.expect_value(t, classify("n"), 0)
	testing.expect_value(t, classify(""), 0)
	testing.expect_value(t, classify("~"), 0)
}

@(test)
test_cstring_range_bounds :: proc(t: ^testing.T) {
	// one bound typed, the other untyped
	one_typed :: proc(text: cstring) -> bool {
		switch text {
		case cstring("0")..="9":
			return true
		}
		return false
	}
	testing.expect(t, one_typed("5"))
	testing.expect(t, !one_typed("a"))

	// an empty bound
	from_empty :: proc(text: cstring) -> bool {
		switch text {
		case ""..="9":
			return true
		}
		return false
	}
	testing.expect(t, from_empty(""))
	testing.expect(t, from_empty("9"))
	testing.expect(t, !from_empty("a"))
}

@(test)
test_distinct_cstring_range :: proc(t: ^testing.T) {
	Distinct :: distinct cstring
	in_range :: proc(text: Distinct) -> bool {
		switch text {
		case "0"..="9":
			return true
		}
		return false
	}
	testing.expect(t, in_range("3"))
	testing.expect(t, !in_range("a"))
}

@(test)
test_utf16_ranges :: proc(t: ^testing.T) {
	c16 :: proc(text: cstring16) -> bool {
		switch text {
		case "0"..="9":
			return true
		}
		return false
	}
	testing.expect(t, c16("3"))
	testing.expect(t, !c16("a"))

	s16 :: proc(text: string16) -> bool {
		switch text {
		case "0"..<"9":
			return true
		}
		return false
	}
	testing.expect(t, s16("3"))
	testing.expect(t, !s16("9"))
}

@(test)
test_constant_tags :: proc(t: ^testing.T) {
	result := 0

	C :: cstring("3")
	switch C {
	case "0"..="9": result += 1
	}
	switch C {
	case cstring("0")..=cstring("9"): result += 1
	}

	C16 :: cstring16("3")
	switch C16 {
	case "0"..="9": result += 1
	}
	switch C16 {
	case cstring16("0")..<cstring16("9"): result += 1
	}

	S16 :: string16("3")
	switch S16 {
	case "0"..="9": result += 1
	}

	testing.expect_value(t, result, 5)
}

@(test)
test_integer_ranges :: proc(t: ^testing.T) {
	// rune bounds on a `u8` tag now take the type `u8`
	letter :: proc(c: u8) -> bool {
		switch c {
		case 'a'..='z', 'A'..='Z':
			return true
		}
		return false
	}
	testing.expect(t, letter('q'))
	testing.expect(t, letter('Q'))
	testing.expect(t, !letter('0'))
	testing.expect(t, !letter(255))

	high :: proc(c: u8) -> bool {
		switch c {
		case 128..=255:
			return true
		}
		return false
	}
	testing.expect(t, high(200))
	testing.expect(t, high(255))
	testing.expect(t, !high(127))
}
