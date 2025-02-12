#+feature dynamic-literals
package test_core_runtime

import "base:intrinsics"
import "core:mem"
import "base:runtime"
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
