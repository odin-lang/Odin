package test_core_container

import "core:fmt"
import "core:testing"

import tc "tests:common"

expect_equal :: proc(t: ^testing.T, the_slice, expected: []int, loc := #caller_location) {
    _eq :: proc(a, b: []int) -> bool {
        if len(a) != len(b) do return false
        for a, i in a {
            if b[i] != a do return false
        }
        return true
    }
    tc.expect(t, _eq(the_slice, expected), fmt.tprintf("Expected %v, got %v\n", the_slice, expected), loc)
}

main :: proc() {
	t := testing.T{}

	test_avl(&t)
	test_rbtree(&t)
	test_small_array(&t)
	tc.report(&t)
}
