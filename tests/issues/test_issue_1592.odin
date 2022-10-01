// Tests issue #1592 https://github.com/odin-lang/Odin/issues/1592
package test_issues

import "core:fmt"
import "core:testing"

/* Original issue #1592 example */

// I get a LLVM code gen error when this constant is false, but it works when it is true
CONSTANT_BOOL :: false

bool_result :: proc() -> bool {
	return false
}

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
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if (CONSTANT_FALSE) {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !CONSTANT_FALSE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if (!CONSTANT_FALSE) {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !(CONSTANT_FALSE) {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !!CONSTANT_FALSE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if CONSTANT_FALSE == true {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if CONSTANT_FALSE == false {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !(CONSTANT_FALSE == true) {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !(CONSTANT_FALSE == false) {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
}

@test
test_simple_const_true :: proc(t: ^testing.T) {
	if CONSTANT_TRUE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if (CONSTANT_TRUE) {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !CONSTANT_TRUE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if (!CONSTANT_TRUE) {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if (!CONSTANT_TRUE) {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(CONSTANT_TRUE) {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !!CONSTANT_TRUE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_TRUE == true {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_TRUE == false {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(CONSTANT_TRUE == true) {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(CONSTANT_TRUE == false) {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_simple_proc_false :: proc(t: ^testing.T) {
	if false_result() {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !false_result() {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_simple_proc_true :: proc(t: ^testing.T) {
	if true_result() {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !true_result() {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
}

@test
test_const_false_const_false :: proc(t: ^testing.T) {
	if CONSTANT_FALSE || CONSTANT_FALSE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if CONSTANT_FALSE && CONSTANT_FALSE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !CONSTANT_FALSE || CONSTANT_FALSE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !CONSTANT_FALSE && CONSTANT_FALSE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if CONSTANT_FALSE || !CONSTANT_FALSE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_FALSE && !CONSTANT_FALSE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !(CONSTANT_FALSE || CONSTANT_FALSE) {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !(CONSTANT_FALSE && CONSTANT_FALSE) {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_const_false_const_true :: proc(t: ^testing.T) {
	if CONSTANT_FALSE || CONSTANT_TRUE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_FALSE && CONSTANT_TRUE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !CONSTANT_FALSE || CONSTANT_TRUE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !CONSTANT_FALSE && CONSTANT_TRUE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}

	if CONSTANT_FALSE || !CONSTANT_TRUE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if CONSTANT_FALSE && !CONSTANT_TRUE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !(CONSTANT_FALSE || CONSTANT_TRUE) {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(CONSTANT_FALSE && CONSTANT_TRUE) {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_const_true_const_false :: proc(t: ^testing.T) {
	if CONSTANT_TRUE || CONSTANT_FALSE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_TRUE && CONSTANT_FALSE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !CONSTANT_TRUE || CONSTANT_FALSE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !CONSTANT_TRUE && CONSTANT_FALSE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if CONSTANT_TRUE || !CONSTANT_FALSE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_TRUE && !CONSTANT_FALSE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}

	if !(CONSTANT_TRUE || CONSTANT_FALSE) {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(CONSTANT_TRUE && CONSTANT_FALSE) {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_const_true_const_true :: proc(t: ^testing.T) {
	if CONSTANT_TRUE || CONSTANT_TRUE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_TRUE && CONSTANT_TRUE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}

	if !CONSTANT_TRUE || CONSTANT_TRUE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !CONSTANT_TRUE && CONSTANT_TRUE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if CONSTANT_TRUE || !CONSTANT_TRUE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if CONSTANT_TRUE && !CONSTANT_TRUE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !(CONSTANT_TRUE || CONSTANT_TRUE) {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(CONSTANT_TRUE && CONSTANT_TRUE) {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
}

@test
test_proc_false_const_false :: proc(t: ^testing.T) {
	if false_result() || CONSTANT_FALSE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if false_result() && CONSTANT_FALSE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !(false_result() || CONSTANT_FALSE) {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if !(false_result() && CONSTANT_FALSE) {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_proc_false_const_true :: proc(t: ^testing.T) {
	if false_result() || CONSTANT_TRUE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if false_result() && CONSTANT_TRUE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !(false_result() || CONSTANT_TRUE) {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(false_result() && CONSTANT_TRUE) {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_proc_true_const_false :: proc(t: ^testing.T) {
	if true_result() || CONSTANT_FALSE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if true_result() && CONSTANT_FALSE {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}

	if !(true_result() || CONSTANT_FALSE) {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(true_result() && CONSTANT_FALSE) {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
}

@test
test_proc_true_const_true :: proc(t: ^testing.T) {
	if true_result() || CONSTANT_TRUE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}
	if true_result() && CONSTANT_TRUE {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	} else {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	}

	if !(true_result() || CONSTANT_TRUE) {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
	if !(true_result() && CONSTANT_TRUE) {
		testing.expect(t, false, fmt.tprintf("%s: !false\n", #procedure))
	} else {
		testing.expect(t, true, fmt.tprintf("%s: !true\n", #procedure))
	}
}
