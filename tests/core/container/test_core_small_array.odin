package test_core_compress

import "core:fmt"
import "core:testing"
import "core:container/small_array"
import tc "tests:common"

main :: proc() {
    t := testing.T{}
    test_small_array_removes(&t)
    test_small_array_inject_at(&t)
	tc.report(&t)
}

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

@test
test_small_array_removes :: proc(t: ^testing.T) {
    array: small_array.Small_Array(10, int)
    small_array.append(&array, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)

    small_array.ordered_remove(&array, 0)
    expect_equal(t, small_array.slice(&array), []int { 1, 2, 3, 4, 5, 6, 7, 8, 9 })
    small_array.ordered_remove(&array, 5)
    expect_equal(t, small_array.slice(&array), []int { 1, 2, 3, 4, 5, 7, 8, 9 })
    small_array.ordered_remove(&array, 6)
    expect_equal(t, small_array.slice(&array), []int { 1, 2, 3, 4, 5, 7, 9 })
    small_array.unordered_remove(&array, 0)
    expect_equal(t, small_array.slice(&array), []int { 9, 2, 3, 4, 5, 7 })
    small_array.unordered_remove(&array, 2)
    expect_equal(t, small_array.slice(&array), []int { 9, 2, 7, 4, 5 })
    small_array.unordered_remove(&array, 4)
    expect_equal(t, small_array.slice(&array), []int { 9, 2, 7, 4 })
}

@test
test_small_array_inject_at :: proc(t: ^testing.T) {
    array: small_array.Small_Array(13, int)
    small_array.append(&array, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)

    tc.expect(t, small_array.inject_at(&array, 0, 0), "Expected to be able to inject into small array")
    expect_equal(t, small_array.slice(&array), []int { 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 })
    tc.expect(t, small_array.inject_at(&array, 0, 5), "Expected to be able to inject into small array")
    expect_equal(t, small_array.slice(&array), []int { 0, 0, 1, 2, 3, 0, 4, 5, 6, 7, 8, 9 })
    tc.expect(t, small_array.inject_at(&array, 0, small_array.len(array)), "Expected to be able to inject into small array")
    expect_equal(t, small_array.slice(&array), []int { 0, 0, 1, 2, 3, 0, 4, 5, 6, 7, 8, 9, 0 })
}
