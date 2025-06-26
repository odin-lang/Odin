package test_core_testing

import "core:c/libc"
import "core:math/rand"
import "core:testing"

@test
test_expected_assert :: proc(t: ^testing.T) {
	target := #location(); target.line += 2; target.column = 2
	testing.expect_assert_from(t, target)
	assert(false)
}

@test
test_expected_two_assert :: proc(t: ^testing.T) {
	target1 := #location(); target1.line += 5; target1.column = 3
	target2 := #location(); target2.line += 6; target2.column = 3
	testing.expect_assert_from(t, target1)
	testing.expect_assert_from(t, target2)
	if rand.uint32() & 1 == 0 {
		assert(false)
	} else {
		assert(false)
	}
}

some_proc :: proc() {
	assert(false)
}

@test
test_expected_assert_in_proc :: proc(t: ^testing.T) {
	target := #location(some_proc)
	target.line += 1
	target.column = 2
	assert(target.procedure == "", "The bug's been fixed; this line and the next can be deleted.")
	target.procedure = "some_proc" // TODO: Is this supposed to be blank on #location(...)?
	testing.expect_assert(t, target)
	some_proc()
}

@test
test_expected_assert_message :: proc(t: ^testing.T) {
	testing.expect_assert(t, "failure")
	assert(false, "failure")
}

@test
test_expected_signal :: proc(t: ^testing.T) {
	testing.expect_signal(t, libc.SIGILL)
	libc.raise(libc.SIGILL)
}
