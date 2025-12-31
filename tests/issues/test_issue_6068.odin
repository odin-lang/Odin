// Tests issue #6068 https://github.com/odin-lang/Odin/issues/6068
package test_issues

import "core:testing"

@test
test_issue_6068 :: proc(t: ^testing.T) {
	{
		check_be : i128be = -1
		check_le : i128le = -1
		value := -1
		reverse := i128be(value)

		// test variable
		testing.expect(t, i128be(value) == check_be)
		testing.expect(t, i128be(-1) == check_be)
		testing.expect(t, cast(i128be)value == check_be)
		testing.expect(t, cast(i128be)-1 == check_be)
		testing.expect(t, i128be(int(-1)) == check_be)
		testing.expect(t, cast(i128be)int(-1) == check_be)
		testing.expect(t, i128le(value) == check_le)
		testing.expect(t, i128le(-1) == check_le)
		testing.expect(t, cast(i128le)value == check_le)
		testing.expect(t, cast(i128le)-1 == check_le)
		testing.expect(t, i128le(int(-1)) == check_le)
		testing.expect(t, cast(i128le)int(-1) == check_le)
		testing.expect(t, i128le(reverse) == check_le)
		testing.expect(t, cast(i128le)reverse == check_le)

		// test literal
		testing.expect(t, i128be(value) == -1)
		testing.expect(t, i128be(-1) == -1)
		testing.expect(t, cast(i128be)value == -1)
		testing.expect(t, cast(i128be)-1 == -1)
		testing.expect(t, i128be(int(-1)) == -1)
		testing.expect(t, cast(i128be)int(-1) == -1)
		testing.expect(t, i128le(value) == -1)
		testing.expect(t, i128le(-1) == -1)
		testing.expect(t, cast(i128le)value == -1)
		testing.expect(t, cast(i128le)-1 == -1)
		testing.expect(t, i128le(int(-1)) == -1)
		testing.expect(t, cast(i128le)int(-1) == -1)
		testing.expect(t, i128le(reverse) == -1)
		testing.expect(t, cast(i128le)reverse == -1)
	}

	// NOTE(ske): [llvm_backend_const.cpp:lb_big_int_to_llvm]
	// floats behaved wonky when I tested because I forgot to sign extend whole
	// rop so I added more tests here to be safe
	{
		check_be : f64be = -1.234
		check_le : f64le = -1.234
		value : f64 = -1.234
		reverse := f64be(value)

		// test variable
		testing.expect(t, f64be(value) == check_be)
		testing.expect(t, f64be(-1.234) == check_be)
		testing.expect(t, cast(f64be)value == check_be)
		testing.expect(t, cast(f64be)-1.234 == check_be)
		testing.expect(t, f64be(int(-1.234)) == check_be)
		testing.expect(t, cast(f64be)int(-1.234) == check_be)
		testing.expect(t, f64le(value) == check_le)
		testing.expect(t, f64le(-1.234) == check_le)
		testing.expect(t, cast(f64le)value == check_le)
		testing.expect(t, cast(f64le)-1.234 == check_le)
		testing.expect(t, f64le(int(-1.234)) == check_le)
		testing.expect(t, cast(f64le)int(-1.234) == check_le)
		testing.expect(t, f64le(reverse) == check_le)
		testing.expect(t, cast(f64le)reverse == check_le)

		// test literal
		testing.expect(t, f64be(value) == -1.234)
		testing.expect(t, f64be(-1.234) == -1.234)
		testing.expect(t, cast(f64be)value == -1.234)
		testing.expect(t, cast(f64be)-1.234 == -1.234)
		testing.expect(t, f64be(int(-1.234)) == -1.234)
		testing.expect(t, cast(f64be)int(-1.234) == -1.234)
		testing.expect(t, f64le(value) == -1.234)
		testing.expect(t, f64le(-1.234) == -1.234)
		testing.expect(t, cast(f64le)value == -1.234)
		testing.expect(t, cast(f64le)-1.234 == -1.234)
		testing.expect(t, f64le(int(-1.234)) == -1.234)
		testing.expect(t, cast(f64le)int(-1.234) == -1.234)
		testing.expect(t, f64le(reverse) == -1.234)
		testing.expect(t, cast(f64le)reverse == -1.234)
	}

	testing.expect(t, i64be(-1) + i64be(1) == 0)
	testing.expect(t, i64le(-1) + i64le(i64be(1)) == 0)
	testing.expect(t, i64be(-7) * i64be(7) == -49)
}
