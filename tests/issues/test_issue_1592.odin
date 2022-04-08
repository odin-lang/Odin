// Tests issue #1592 https://github.com/odin-lang/Odin/issues/1592
package test_issues

import "core:fmt"
import "core:testing"
import tc "tests:common"

main :: proc() {
	t := testing.T{}

	/* This won't short-circuit */
	test_orig()

	/* These will short-circuit */
	test_simple_const_false(&t)
	test_simple_const_true(&t)

	/* These won't short-circuit */
	test_simple_proc_false(&t)
	test_simple_proc_true(&t)

	/* These won't short-circuit */
	test_const_false_const_false(&t)
	test_const_false_const_true(&t)
	test_const_true_const_false(&t)
	test_const_true_const_true(&t)

	/* These won't short-circuit */
	test_proc_false_const_false(&t)
	test_proc_false_const_true(&t)
	test_proc_true_const_false(&t)
	test_proc_true_const_true(&t)

	tc.report(&t)
}

/* Original issue #1592 example */

// I get a LLVM code gen error when this constant is false, but it works when it is true
CONSTANT_BOOL :: false

bool_result :: proc() -> bool {
	return false
}

@test
test_orig :: proc() {
	if bool_result() || CONSTANT_BOOL {
	}
}

CONSTANT_FALSE :: false
CONSTANT_TRUE :: true

false_result :: proc() -> bool {
	return false
}
true_result :: proc() -> bool {
	return true
}

@test
test_simple_const_false :: proc(t: ^testing.T) {
	if CONSTANT_FALSE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if (CONSTANT_FALSE) {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !CONSTANT_FALSE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if (!CONSTANT_FALSE) {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !(CONSTANT_FALSE) {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !!CONSTANT_FALSE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if CONSTANT_FALSE == true {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if CONSTANT_FALSE == false {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !(CONSTANT_FALSE == true) {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !(CONSTANT_FALSE == false) {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
}

@test
test_simple_const_true :: proc(t: ^testing.T) {
	if CONSTANT_TRUE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if (CONSTANT_TRUE) {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !CONSTANT_TRUE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if (!CONSTANT_TRUE) {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if (!CONSTANT_TRUE) {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(CONSTANT_TRUE) {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !!CONSTANT_TRUE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_TRUE == true {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_TRUE == false {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(CONSTANT_TRUE == true) {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(CONSTANT_TRUE == false) {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_simple_proc_false :: proc(t: ^testing.T) {
	if false_result() {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !false_result() {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_simple_proc_true :: proc(t: ^testing.T) {
	if true_result() {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !true_result() {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
}

@test
test_const_false_const_false :: proc(t: ^testing.T) {
	if CONSTANT_FALSE || CONSTANT_FALSE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if CONSTANT_FALSE && CONSTANT_FALSE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !CONSTANT_FALSE || CONSTANT_FALSE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !CONSTANT_FALSE && CONSTANT_FALSE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if CONSTANT_FALSE || !CONSTANT_FALSE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_FALSE && !CONSTANT_FALSE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !(CONSTANT_FALSE || CONSTANT_FALSE) {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !(CONSTANT_FALSE && CONSTANT_FALSE) {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_const_false_const_true :: proc(t: ^testing.T) {
	if CONSTANT_FALSE || CONSTANT_TRUE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_FALSE && CONSTANT_TRUE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !CONSTANT_FALSE || CONSTANT_TRUE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !CONSTANT_FALSE && CONSTANT_TRUE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}

	if CONSTANT_FALSE || !CONSTANT_TRUE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if CONSTANT_FALSE && !CONSTANT_TRUE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !(CONSTANT_FALSE || CONSTANT_TRUE) {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(CONSTANT_FALSE && CONSTANT_TRUE) {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_const_true_const_false :: proc(t: ^testing.T) {
	if CONSTANT_TRUE || CONSTANT_FALSE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_TRUE && CONSTANT_FALSE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !CONSTANT_TRUE || CONSTANT_FALSE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !CONSTANT_TRUE && CONSTANT_FALSE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if CONSTANT_TRUE || !CONSTANT_FALSE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_TRUE && !CONSTANT_FALSE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}

	if !(CONSTANT_TRUE || CONSTANT_FALSE) {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(CONSTANT_TRUE && CONSTANT_FALSE) {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_const_true_const_true :: proc(t: ^testing.T) {
	if CONSTANT_TRUE || CONSTANT_TRUE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_TRUE && CONSTANT_TRUE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}

	if !CONSTANT_TRUE || CONSTANT_TRUE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !CONSTANT_TRUE && CONSTANT_TRUE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if CONSTANT_TRUE || !CONSTANT_TRUE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_TRUE && !CONSTANT_TRUE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !(CONSTANT_TRUE || CONSTANT_TRUE) {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(CONSTANT_TRUE && CONSTANT_TRUE) {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
}

@test
test_proc_false_const_false :: proc(t: ^testing.T) {
	if false_result() || CONSTANT_FALSE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if false_result() && CONSTANT_FALSE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !(false_result() || CONSTANT_FALSE) {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !(false_result() && CONSTANT_FALSE) {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_proc_false_const_true :: proc(t: ^testing.T) {
	if false_result() || CONSTANT_TRUE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if false_result() && CONSTANT_TRUE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !(false_result() || CONSTANT_TRUE) {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(false_result() && CONSTANT_TRUE) {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_proc_true_const_false :: proc(t: ^testing.T) {
	if true_result() || CONSTANT_FALSE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if true_result() && CONSTANT_FALSE {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !(true_result() || CONSTANT_FALSE) {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(true_result() && CONSTANT_FALSE) {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_proc_true_const_true :: proc(t: ^testing.T) {
	if true_result() || CONSTANT_TRUE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if true_result() && CONSTANT_TRUE {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}

	if !(true_result() || CONSTANT_TRUE) {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(true_result() && CONSTANT_TRUE) {
		tc.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		tc.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
}
