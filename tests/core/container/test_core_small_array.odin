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

@(test)
test_small_array_push_back_elems :: proc(t: ^testing.T) {
	array: small_array.Small_Array(2, int)
	testing.expect(t, slice_equal(small_array.slice(&array), []int { }))
	testing.expect(t, small_array.append(&array, 0), "Expected to be able to append to empty small array")
	testing.expect(t, slice_equal(small_array.slice(&array), []int { 0 }))
	testing.expect(t, small_array.append(&array, 1, 2) == false, "Expected to fail appending multiple elements beyond capacity of small array")
	testing.expect(t, small_array.append(&array, 1), "Expected to be able to append to small array")
	testing.expect(t, slice_equal(small_array.slice(&array), []int { 0, 1 }))
	testing.expect(t, small_array.append(&array, 1) == false, "Expected to fail appending to full small array")
	testing.expect(t, small_array.append(&array, 1, 2) == false, "Expected to fail appending multiple elements to full small array")
	small_array.clear(&array)
	testing.expect(t, slice_equal(small_array.slice(&array), []int { }))
	testing.expect(t, small_array.append(&array, 1, 2, 3) == false, "Expected to fail appending multiple elements to empty small array")
	testing.expect(t, slice_equal(small_array.slice(&array), []int { }))
	testing.expect(t, small_array.append(&array, 1, 2), "Expected to be able to append multiple elements to empty small array")
	testing.expect(t, slice_equal(small_array.slice(&array), []int { 1, 2 }))
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
