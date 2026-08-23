package test_core_slice

import "core:math/rand"
import "core:slice"
import "core:testing"

@(test)
test_slice_sort :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	id :: distinct i32
	arr := make([]id, 1_000)
	defer delete(arr)

	for &a in arr {
		a = cast(id)rand.int_max(1_000)
	}

	slice.sort(arr)

	testing.expect(t, slice.is_sorted(arr), "expected slice_sort to sort")
}

@(test)
test_slice_sort_by :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	arr := make([][5]i32, 1_000)
	defer delete(arr)
	
	for &a in arr {
		a[0] = cast(i32)rand.int_max(1_000)
	}

	slice.sort_by(arr, proc(l, r: [5]i32) -> bool {
		return l[0] > r[0]
	})

	testing.expect(t, slice.is_sorted_by(arr, proc(l, r: [5]i32) -> bool {
		return l[0] > r[0]
	}), "expected slice_sort_by to sort")
}

@(test)
test_slice_sort_with_indices :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	arr := make([]i32, 1_000)
	defer delete(arr)

	for &a in arr {
		a = cast(i32)rand.int_max(1_000)
	}

	indices := slice.sort_with_indices(arr)
	defer delete(indices)

	testing.expect(t, slice.is_sorted(arr), "expected slice_sort_with_indices to sort")
}

@(test)
test_slice_sort_by_with_indices :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	arr := make([]i32, 1_000)
	defer delete(arr)

	for &a in arr {
		a = cast(i32)rand.int_max(1_000)
	}

	indices := slice.sort_by_with_indices(
		arr,
		proc(l, r: i32) -> bool {
			return l > r
		},
	)
	defer delete(indices)

	testing.expect(t, slice.is_sorted_by(arr, proc(l, r: i32) -> bool {
		return l > r
	}), "expected slice_sort_by_with_indices to sort")
}

@(test)
test_slice_sort_by_with_data :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	arr := make([]i32, 1_000)
	defer delete(arr)

	for &a in arr {
		a = cast(i32)rand.int_max(1_000)
	}

	modulus := []i32{1,2,5,0,4,3,9,8,7,6}

	slice.sort_by_with_data(
		arr,
		proc(l, r: i32, user_data: rawptr) -> bool {
			modulus := (^[]i32)(user_data)
			return modulus[l %% 10] < modulus[r %% 10]
		},
		&modulus,
	)

	sorted := true
	for i in 1..<len(arr) {
		if modulus[arr[i - 1] %% 10] > modulus[arr[i] %% 10] {
			sorted = false
		}
	}
	testing.expect(t, sorted, "expected slice_sort_by_with_data to sort")
}

@(test)
test_slice_sort_by_with_indices_with_data :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	arr := make([]i32, 1_000)
	defer delete(arr)

	for &a in arr {
		a = cast(i32)rand.int_max(1_000)
	}

	modulus := []i32{1,2,5,0,4,3,9,8,7,6}

	indecies := slice.sort_by_with_indices_with_data(
		arr,
		proc(l, r: i32, user_data: rawptr) -> bool {
			modulus := (^[]i32)(user_data)
			return modulus[l %% 10] < modulus[r %% 10]
		},
		&modulus,
	)
	defer delete(indecies)

	sorted := true
	for i in 1..<len(arr) {
		if modulus[arr[i - 1] %% 10] > modulus[arr[i] %% 10] {
			sorted = false
		}
	}
	testing.expect(t, sorted, "expected slice_sort_by_with_indices_with_data to sort")
}

@(test)
test_slice_sort_by_cmp :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	arr := make([]f32, 1_000)
	defer delete(arr)

	for &a in arr {
		a = rand.float32()
	}

	slice.sort_by_cmp(
		arr,
		proc(l, r: f32) -> slice.Ordering {
			if l < r do return .Less
			if l > r do return .Greater
			return .Equal
		},
	)

	testing.expect(t, slice.is_sorted_by(arr, proc(l, r: f32) -> bool {
		return l < r
	}), "expected slice_sort_by_cmp to sort")
}

@(test)
test_slice_sort_by_cmp_with_data :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	arr := make([]int, 1_000)
	defer delete(arr)

	for &a in arr {
		a = rand.int_max(1_000)
	}

	modulus := []int{1,2,5,0,4,3,9,8,7,6}

	slice.sort_by_cmp_with_data(
		arr,
		proc(l, r: int, user_data: rawptr) -> slice.Ordering {
			modulus := (^[]int)(user_data)
			if modulus[l %% 10] < modulus[r %% 10] {
				return .Less
			}
			if modulus[l %% 10] > modulus[r %% 10] {
				return .Greater
			}
			return .Equal
		},
		&modulus,
	)

	sorted := true
	for i in 1..<len(arr) {
		if modulus[arr[i - 1] %% 10] > modulus[arr[i] %% 10] {
			sorted = false
		}
	}
	testing.expect(t, sorted, "expected slice_sort_by_cmp_with_data to sort")
}
