package test_internal

import "core:testing"

@(private="file")
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


@(test)
test_fixed_capacity_dynamic_array_removes :: proc(t: ^testing.T) {
	array: [dynamic; 10]int
	append(&array, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)

	ordered_remove(&array, 0)
	testing.expect(t, slice_equal(array[:], []int { 1, 2, 3, 4, 5, 6, 7, 8, 9 }))
	ordered_remove(&array, 5)
	testing.expect(t, slice_equal(array[:], []int { 1, 2, 3, 4, 5, 7, 8, 9 }))
	ordered_remove(&array, 6)
	testing.expect(t, slice_equal(array[:], []int { 1, 2, 3, 4, 5, 7, 9 }))
	unordered_remove(&array, 0)
	testing.expect(t, slice_equal(array[:], []int { 9, 2, 3, 4, 5, 7 }))
	unordered_remove(&array, 2)
	testing.expect(t, slice_equal(array[:], []int { 9, 2, 7, 4, 5 }))
	unordered_remove(&array, 4)
	testing.expect(t, slice_equal(array[:], []int { 9, 2, 7, 4 }))
}

@(test)
test_fixed_capacity_dynamic_array_inject_at :: proc(t: ^testing.T) {
	array: [dynamic; 13]int
	append(&array, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)

	testing.expect(t, inject_at(&array, 0, 0), "Expected to be able to inject into fixed capacity dynamic array")
	testing.expect(t, slice_equal(array[:], []int { 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }))
	testing.expect(t, inject_at(&array, 0, 5), "Expected to be able to inject into fixed capacity dynamic array")
	testing.expect(t, slice_equal(array[:], []int { 5, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }))
	testing.expect(t, inject_at(&array, len(array), 0), "Expected to be able to inject into fixed capacity dynamic array")
	testing.expect(t, slice_equal(array[:], []int { 5, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0 }))
}

@(test)
test_fixed_capacity_dynamic_array_push_back_elems :: proc(t: ^testing.T) {
	array: [dynamic; 2]int
	testing.expect(t, slice_equal(array[:], []int { }))
	testing.expect(t, append(&array, 0) == 1, "Expected to be able to append to empty fixed capacity dynamic array")
	testing.expect(t, slice_equal(array[:], []int { 0 }))
	testing.expect(t, append(&array, 1) == 1, "Expected to be able to append to fixed capacity dynamic array")
	testing.expect(t, slice_equal(array[:], []int { 0, 1 }))
	testing.expect(t, append(&array, 1, 2) == 0, "Expected to fail appending multiple elements beyond capacity of fixed capacity dynamic array")
	clear(&array)
	testing.expect(t, append(&array, 1) == 1, "Expected to be able to append to fixed capacity dynamic array")
	testing.expect(t, append(&array, 2) == 1, "Expected to be able to append to fixed capacity dynamic array")
	testing.expect(t, append(&array, 1) != 1, "Expected to fail appending to full fixed capacity dynamic array")
	testing.expect(t, append(&array, 1, 2) != 2, "Expected to fail appending multiple elements to full fixed capacity dynamic array")
	clear(&array)
	testing.expect(t, slice_equal(array[:], []int { }))
	testing.expect(t, append(&array, 1, 2, 3) != 3, "Expected to fail appending multiple elements to empty fixed capacity dynamic array")
	testing.expect(t, slice_equal(array[:], []int { 1, 2 }))
	clear(&array)
	testing.expect(t, append(&array, 1, 2) == 2, "Expected to be able to append multiple elements to empty fixed capacity dynamic array")
	testing.expect(t, slice_equal(array[:], []int { 1, 2 }))
}

@(test)
test_fixed_capacity_dynamic_array_resize :: proc(t: ^testing.T) {
	array: [dynamic; 4]int

	for i in 0..<4 {
		append(&array, i+1)
	}
	testing.expect(t, slice_equal(array[:], []int{1, 2, 3, 4}), "Expected to initialize the array with 1, 2, 3, 4")

	clear(&array)
	testing.expect(t, slice_equal(array[:], []int{}), "Expected to clear the array")

	non_zero_resize(&array, 4)
	testing.expect(t, slice_equal(array[:], []int{1, 2, 3, 4}), "Expected non_zero_resize to set length 4 with previous values")

	clear(&array)
	resize(&array, 4)
	testing.expect(t, slice_equal(array[:], []int{0, 0, 0, 0}), "Expected resize to set length 4 with zeroed values")
}

// Constant slice indices are checked against the length, not the capacity.
@(test)
test_fixed_capacity_dynamic_array_constant_slice :: proc(t: ^testing.T) {
	array: [dynamic; 4]int
	append(&array, 1, 2, 3)
	testing.expect(t, slice_equal(array[0:3], []int{1, 2, 3}))
	testing.expect(t, slice_equal(array[1:2], []int{2}))
}

// AddressSanitizer on Windows ends the process on the bounds check trap before the test runner can catch it.
when !(ODIN_OS == .Windows && .Address in ODIN_SANITIZER_FLAGS) {
	@(test)
	test_fixed_capacity_dynamic_array_constant_slice_out_of_range :: proc(t: ^testing.T) {
		array: [dynamic; 4]int
		append(&array, 1, 2, 3)
		pop(&array)
		testing.expect_assert(t, "0:3 is out of range 0..<2")
		s := array[0:3]
		testing.expectf(t, false, "slicing past the length gave %v", s)
	}
}
