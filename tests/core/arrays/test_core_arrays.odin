package test_core_arrays

import "core:testing"
import "core:fmt"
import "core:arrays"

@(test)
test_array_sum :: proc(t: ^testing.T) {
	data := []u32{1, 2, 3, 4, 5}

	if result := arrays.array_sum([]u32, data); result != 15 {
		testing.expect_value(t, result, 15)
	}
}

@(test)
test_array_map :: proc(t: ^testing.T) {
	data := []u32{2, 4, 5}

	result := arrays.array_map([]u32, data, proc(x: u32) -> u32 {
			return x * 2
		})

	testing.expect_value(t, result[0], 4)
	testing.expect_value(t, result[1], 8)
	testing.expect_value(t, result[2], 10)

}

@(test)
test_array_filter :: proc(t: ^testing.T) {
	data := [dynamic]u32{2, 4, 5}

	result := arrays.array_filter([dynamic]u32, data, proc(x: u32) -> bool {
			return x % 2 == 0
		})

	testing.expect_value(t, len(result), 2)
}

@(test)
test_array_is_empty :: proc(t: ^testing.T) {
	data := []u32{1, 2, 3, 4, 5}
	data2 := []u32{}

	testing.expect_value(t, arrays.array_is_empty([]u32, data), false)
	testing.expect_value(t, arrays.array_is_empty([]u32, data2), true)
}

@(test)
test_array_merge :: proc(t: ^testing.T) {
	data := [dynamic]u32{1, 2}
	data2 := [dynamic]u32{3, 4}

	result := arrays.array_merge([dynamic]u32, data, data2)

	testing.expect_value(t, result[0], 1)
	testing.expect_value(t, result[1], 2)
	testing.expect_value(t, result[2], 3)
	testing.expect_value(t, result[3], 4)

}
