package test_core_container

import "core:testing"
import "core:container/small_array"

@(test)
test_small_array_removes :: proc(t: ^testing.T) {
	array: small_array.Small_Array(10, int)
	small_array.append(&array, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)

	small_array.ordered_remove(&array, 0)
	testing.expect(t, slice_equal(small_array.slice(&array), []int { 1, 2, 3, 4, 5, 6, 7, 8, 9 }))
	small_array.ordered_remove(&array, 5)
	testing.expect(t, slice_equal(small_array.slice(&array), []int { 1, 2, 3, 4, 5, 7, 8, 9 }))
	small_array.ordered_remove(&array, 6)
	testing.expect(t, slice_equal(small_array.slice(&array), []int { 1, 2, 3, 4, 5, 7, 9 }))
	small_array.unordered_remove(&array, 0)
	testing.expect(t, slice_equal(small_array.slice(&array), []int { 9, 2, 3, 4, 5, 7 }))
	small_array.unordered_remove(&array, 2)
	testing.expect(t, slice_equal(small_array.slice(&array), []int { 9, 2, 7, 4, 5 }))
	small_array.unordered_remove(&array, 4)
	testing.expect(t, slice_equal(small_array.slice(&array), []int { 9, 2, 7, 4 }))
}

@(test)
test_small_array_inject_at :: proc(t: ^testing.T) {
	array: small_array.Small_Array(13, int)
	small_array.append(&array, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)

	testing.expect(t, small_array.inject_at(&array, 0, 0), "Expected to be able to inject into small array")
	testing.expect(t, slice_equal(small_array.slice(&array), []int { 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }))
	testing.expect(t, small_array.inject_at(&array, 0, 5), "Expected to be able to inject into small array")
	testing.expect(t, slice_equal(small_array.slice(&array), []int { 0, 0, 1, 2, 3, 0, 4, 5, 6, 7, 8, 9 }))
	testing.expect(t, small_array.inject_at(&array, 0, small_array.len(array)), "Expected to be able to inject into small array")
	testing.expect(t, slice_equal(small_array.slice(&array), []int { 0, 0, 1, 2, 3, 0, 4, 5, 6, 7, 8, 9, 0 }))
}

slice_equal :: proc(a, b: []int) -> bool {
	if len(a) != len(b) {
		return false
	}

	for a, i in a {
		if b[i] != a {
			return false
		}
	}
	return true
}
