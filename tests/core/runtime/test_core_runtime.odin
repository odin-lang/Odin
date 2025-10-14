#+feature dynamic-literals
package test_core_runtime

import "base:intrinsics"
import "core:mem"
import "base:runtime"
import "core:slice"
import "core:testing"

// Tests that having space for the allocation, but not for the allocation and alignment
// is handled correctly.
@(test)
test_temp_allocator_alignment_boundary :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)
	defer runtime.arena_destroy(&arena)

	_, _ = mem.alloc(int(runtime.DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE)-120)
	_, err := mem.alloc(112, 32)
	testing.expect(t, err == nil)
}

// Tests that big allocations with big alignments are handled correctly.
@(test)
test_temp_allocator_big_alloc_and_alignment :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)
	defer runtime.arena_destroy(&arena)

	mappy: map[[8]int]int
	err := reserve(&mappy, 50000)
	testing.expect(t, err == nil)
}

@(test)
test_align_bumping_block_limit :: proc(t: ^testing.T) {
	a: runtime.Arena
	a.minimum_block_size = 8*mem.Megabyte
	defer runtime.arena_destroy(&a)

	data, err := runtime.arena_alloc(&a, 4193371, 1)
	testing.expect_value(t, err, nil)
	testing.expect(t, len(data) == 4193371)

	data, err = runtime.arena_alloc(&a, 896, 64)
	testing.expect_value(t, err, nil)
	testing.expect(t, len(data) == 896)
}

@(test)
test_temp_allocator_returns_correct_size :: proc(t: ^testing.T) {
	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)
	defer runtime.arena_destroy(&arena)

	bytes, err := mem.alloc_bytes(10, 16)
	testing.expect(t, err == nil)
	testing.expect(t, len(bytes) == 10)
}

@(test)
test_init_cap_map_dynarray :: proc(t: ^testing.T) {
	m1 := make(map[int]string)
	defer delete(m1)
	testing.expect(t, cap(m1) == 0)
	testing.expect(t, m1.allocator.procedure == context.allocator.procedure)

	ally := context.temp_allocator
	m2 := make(map[int]string, ally)
	defer delete(m2)
	testing.expect(t, cap(m2) == 0)
	testing.expect(t, m2.allocator.procedure == ally.procedure)

	d1 := make([dynamic]string)
	defer delete(d1)
	testing.expect(t, cap(d1) == 0)
	testing.expect(t, d1.allocator.procedure == context.allocator.procedure)

	d2 := make([dynamic]string, ally)
	defer delete(d2)
	testing.expect(t, cap(d2) == 0)
	testing.expect(t, d2.allocator.procedure == ally.procedure)
}

@(test)
test_map_get :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, m: map[$K]$V, loc := #caller_location) {
		for k, v in m {
			got_key, got_val, ok := runtime.map_get(m, k)
			testing.expect_value(t, got_key, k, loc = loc)
			testing.expect_value(t, got_val, v, loc = loc)
			testing.expect(t, ok, loc = loc)
		}
	}

	// small keys & values
	{
		m := map[int]int{
			1 = 10,
			2 = 20,
			3 = 30,
		}
		defer delete(m)
		check(t, m)
	}

	// small keys; 2 values per cell
	{
		m := map[int][3]int{
			1 = [3]int{10, 100, 1000},
			2 = [3]int{20, 200, 2000},
			3 = [3]int{30, 300, 3000},
		}
		defer delete(m)
		check(t, m)
	}

	// 2 keys per cell; small values
	{
		m := map[[3]int]int{
			[3]int{10, 100, 1000} = 1,
			[3]int{20, 200, 2000} = 2,
			[3]int{30, 300, 3000} = 3,
		}
		defer delete(m)
		check(t, m)
	}


	// small keys; 3 values per cell
	{
		val :: struct #packed {
			a, b: int,
			c:    i32,
		}
		m := map[int]val{
			1 = val{10, 100, 1000},
			2 = val{20, 200, 2000},
			3 = val{30, 300, 3000},
		}
		defer delete(m)
		check(t, m)
	}

	// 3 keys per cell; small values
	{
		key :: struct #packed {
			a, b: int,
			c:    i32,
		}
		m := map[key]int{
			key{10, 100, 1000} = 1,
			key{20, 200, 2000} = 2,
			key{30, 300, 3000} = 3,
		}
		defer delete(m)
		check(t, m)
	}

	// small keys; value bigger than a chacheline
	{
		m := map[int][9]int{
			1 = [9]int{10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000},
			2 = [9]int{20, 200, 2000, 20000, 200000, 2000000, 20000000, 200000000, 2000000000},
			3 = [9]int{30, 300, 3000, 30000, 300000, 3000000, 30000000, 300000000, 3000000000},
		}
		defer delete(m)
		check(t, m)
	}
	// keys bigger than a chacheline; small values
	{
		m := map[[9]int]int{
			[9]int{10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000} = 1,
			[9]int{20, 200, 2000, 20000, 200000, 2000000, 20000000, 200000000, 2000000000} = 2,
			[9]int{30, 300, 3000, 30000, 300000, 3000000, 30000000, 300000000, 3000000000} = 3,
		}
		defer delete(m)
		check(t, m)
	}
}

@(test)
test_soa_array_resize :: proc(t: ^testing.T) {

	V :: struct {x: int, y: u8}

	array := make(#soa[dynamic]V, 0, 2)
	defer delete(array)

	append(&array, V{1, 2}, V{3, 4})

	testing.expect_value(t, len(array), 2)
	testing.expect_value(t, array[0], V{1, 2})
	testing.expect_value(t, array[1], V{3, 4})

	resize(&array, 1)

	testing.expect_value(t, len(array), 1)
	testing.expect_value(t, array[0], V{1, 2})

	resize(&array, 2)

	testing.expect_value(t, len(array), 2)
	testing.expect_value(t, array[0], V{1, 2})
	testing.expect_value(t, array[1], V{0, 0})

	resize(&array, 0)
	resize(&array, 3)

	testing.expect_value(t, len(array), 3)
	testing.expect_value(t, array[0], V{0, 0})
	testing.expect_value(t, array[1], V{0, 0})
	testing.expect_value(t, array[2], V{0, 0})
}

@(test)
test_soa_make_len :: proc(t: ^testing.T) {

	array, err := make(#soa[dynamic][2]int, 2)
	defer delete(array)
	array[0] = [2]int{1, 2}
	array[1] = [2]int{3, 4}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(array), 2)
	testing.expect_value(t, cap(array), 2)

	testing.expect_value(t, array[0], [2]int{1, 2})
	testing.expect_value(t, array[1], [2]int{3, 4})
}

@(test)
test_soa_array_allocator_resize :: proc(t: ^testing.T) {

	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)
	defer runtime.arena_destroy(&arena)

	// |1 3 _ 2 4 _|
	// |1 3 _ _ 2 4 _ _|

	array, err := make(#soa[dynamic][2]int, 2, 3)
	defer delete(array)
	array[0] = [2]int{1, 2}
	array[1] = [2]int{3, 4}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(array), 2)
	testing.expect_value(t, cap(array), 3)

	err = resize(&array, 4)

	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(array), 4)
	testing.expect_value(t, cap(array), 4)

	testing.expect_value(t, array[0], [2]int{1, 2})
	testing.expect_value(t, array[1], [2]int{3, 4})
	testing.expect_value(t, array[2], [2]int{0, 0})
	testing.expect_value(t, array[3], [2]int{0, 0})
}


@(test)
test_soa_array_allocator_resize_overlapping :: proc(t: ^testing.T) {

	arena: runtime.Arena
	context.allocator = runtime.arena_allocator(&arena)
	defer runtime.arena_destroy(&arena)

	// |1 4 2 5 3 6|
	// |1 4 _ _ 2 5 _ _ 3 6 _ _|

	array, err := make(#soa[dynamic][3]int, 2, 2)
	defer delete(array)
	array[0] = [3]int{1, 2, 3}
	array[1] = [3]int{4, 5, 6}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(array), 2)
	testing.expect_value(t, cap(array), 2)

	err = resize(&array, 4)

	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(array), 4)
	testing.expect_value(t, cap(array), 4)

	testing.expect_value(t, array[0], [3]int{1, 2, 3})
	testing.expect_value(t, array[1], [3]int{4, 5, 6})
	testing.expect_value(t, array[2], [3]int{0, 0, 0})
	testing.expect_value(t, array[3], [3]int{0, 0, 0})
}

@(test)
test_memory_equal :: proc(t: ^testing.T) {
	data: [256]u8
	cmp: [256]u8

	slice.fill(data[:], 0xAA)
	slice.fill(cmp[:], 0xAA)

	for offset in 0..<len(data) {
		subdata := data[offset:]
		subcmp := cmp[offset:]
		for idx in 0..<len(subdata) {
			if !testing.expect_value(t, runtime.memory_equal(&subdata[0], &subcmp[0], len(subdata)), true) {
				return
			}

			subcmp[idx] = 0x55
			if !testing.expect_value(t, runtime.memory_equal(&subdata[0], &subcmp[0], len(subdata)), false) {
				return
			}
			subcmp[idx] = 0xAA
		}
	}
}

@(test)
test_memory_compare :: proc(t: ^testing.T) {
	data: [256]u8
	cmp: [256]u8

	for offset in 0..<len(data) {
		subdata := data[offset:]
		subcmp := cmp[offset:]
		for idx in 0..<len(subdata) {
			if !testing.expect_value(t, runtime.memory_compare(&subdata[0], &subcmp[0], len(subdata)), 0) {
				return
			}

			subdata[idx] = 0x7F
			subcmp[idx] = 0xFF
			if !testing.expect_value(t, runtime.memory_compare(&subdata[0], &subcmp[0], len(subdata)), -1) {
				return
			}

			subdata[idx] = 0xFF
			subcmp[idx] = 0x7F
			if !testing.expect_value(t, runtime.memory_compare(&subdata[0], &subcmp[0], len(subdata)), 1) {
				return
			}

			subdata[idx] = 0
			subcmp[idx] = 0
		}
	}
}

@(test)
test_memory_compare_zero :: proc(t: ^testing.T) {
	data: [256]u8

	for offset in 0..<len(data) {
		subdata := data[offset:]
		for idx in 0..<len(subdata) {
			if !testing.expect_value(t, runtime.memory_compare_zero(&subdata[0], len(subdata)), 0) {
				return
			}
			subdata[idx] = 0xFF
			if !testing.expect_value(t, runtime.memory_compare_zero(&subdata[0], len(subdata)), 1) {
				return
			}
			subdata[idx] = 0
		}
	}
}
