package test_core_container

import "core:testing"
import "core:container/small_array"

import tc "tests:common"

@(test)
test_small_array :: proc(t: ^testing.T) {
	tc.log(t, "Testing small_array")

    test_small_array_removes(t)
    test_small_array_inject_at(t)
}

@(test)
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

@(test)
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
