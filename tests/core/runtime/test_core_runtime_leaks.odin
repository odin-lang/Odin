package test_core_runtime

import "base:runtime"
import "core:mem"
import "core:testing"

@(private="file")
Leak_Soa_Elem :: struct {
	a: u8,
	b: u64,
	c: u16,
}

@(private="file")
Leak_Failing_Allocator :: struct {
	backing: runtime.Allocator,
	count:   int,
	fail_at: int,
}

@(private="file")
leak_failing_allocator_proc :: proc(data: rawptr, mode: runtime.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, runtime.Allocator_Error) {
	fa := (^Leak_Failing_Allocator)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		if fa.count == fa.fail_at {
			fa.count += 1
			return nil, .Out_Of_Memory
		}
		fa.count += 1
	}
	return fa.backing.procedure(fa.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

@(test)
test_leak_make_soa_len_cap_oom :: proc(t: ^testing.T) {
	Case :: struct {
		length, capacity: int,
	}
	cases := []Case{{10, 4}, {4, 10}, {0, 8}, {8, 0}, {3, 3}}
	for c in cases {
		for k in 0..<8 {
			track: mem.Tracking_Allocator
			mem.tracking_allocator_init(&track, context.allocator)
			track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
			fa := Leak_Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
			alloc := runtime.Allocator{procedure = leak_failing_allocator_proc, data = &fa}

			array, err := make_soa(#soa[dynamic]Leak_Soa_Elem, c.length, c.capacity, alloc)
			if err == nil {
				testing.expectf(t, len(array) == c.length, "%v, fail at %v: len %v", c, k, len(array))
				testing.expectf(t, cap(array) >= max(c.length, c.capacity), "%v, fail at %v: cap %v", c, k, cap(array))
				for i in 0..<len(array) {
					testing.expectf(t, array[i] == Leak_Soa_Elem{}, "%v, fail at %v: element %v not zeroed", c, k, i)
				}
				delete_soa(array)
			} else {
				testing.expectf(t, err == .Out_Of_Memory, "%v, fail at %v: %v", c, k, err)
				testing.expectf(t, len(array) == 0 && cap(array) == 0, "%v, fail at %v: array not empty on error", c, k)
			}
			leaked    := len(track.allocation_map)
			bad_frees := len(track.bad_free_array)
			injected  := fa.count > k
			mem.tracking_allocator_destroy(&track)
			testing.expectf(t, leaked == 0, "%v, fail at %v: %v block(s) leaked", c, k, leaked)
			testing.expectf(t, bad_frees == 0, "%v, fail at %v: %v bad free(s)", c, k, bad_frees)
			if !injected {
				testing.expectf(t, err == nil, "%v, no failure injected: %v", c, err)
				break
			}
		}
	}
}

@(test)
test_leak_make_soa_len_cap_keeps_allocator :: proc(t: ^testing.T) {
	arg_track, ctx_track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&arg_track, context.allocator)
	defer mem.tracking_allocator_destroy(&arg_track)
	mem.tracking_allocator_init(&ctx_track, context.allocator)
	defer mem.tracking_allocator_destroy(&ctx_track)

	array := make_soa(#soa[dynamic]Leak_Soa_Elem, 0, 0, mem.tracking_allocator(&arg_track))
	{
		context.allocator = mem.tracking_allocator(&ctx_track)
		append_soa(&array, Leak_Soa_Elem{a = 1, b = 2, c = 3})
	}
	testing.expect_value(t, len(array), 1)
	testing.expect_value(t, array[0], Leak_Soa_Elem{a = 1, b = 2, c = 3})
	testing.expect_value(t, ctx_track.total_allocation_count, 0)
	testing.expect_value(t, arg_track.total_allocation_count, 1)
	delete_soa(array)
	testing.expect_value(t, len(arg_track.allocation_map), 0)
}

@(private="file")
LEAK_WRAPPING_COUNT :: (1 << uint(8*size_of(int) - 3)) + 1

@(test)
test_leak_make_size_overflow :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)

	s, s_err := make([]u64, LEAK_WRAPPING_COUNT)
	testing.expect_value(t, s_err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(s), 0)

	d0, d0_err := make([dynamic]u64, LEAK_WRAPPING_COUNT)
	testing.expect_value(t, d0_err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(d0), 0)

	d1, d1_err := make([dynamic]u64, 0, LEAK_WRAPPING_COUNT)
	testing.expect_value(t, d1_err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, cap(d1), 0)

	mp, mp_err := make([^]u64, LEAK_WRAPPING_COUNT)
	testing.expect_value(t, mp_err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect(t, mp == nil)

	d: [dynamic]u64
	append(&d, 1, 2, 3)
	testing.expect_value(t, reserve(&d, LEAK_WRAPPING_COUNT), runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, non_zero_reserve(&d, LEAK_WRAPPING_COUNT), runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, resize(&d, LEAK_WRAPPING_COUNT), runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, non_zero_resize(&d, LEAK_WRAPPING_COUNT), runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(d), 3)
	testing.expect_value(t, d[2], 3)
	delete(d)

	soa_s, soa_s_err := make_soa(#soa[]Leak_Soa_Elem, LEAK_WRAPPING_COUNT)
	testing.expect_value(t, soa_s_err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(soa_s), 0)

	soa_d, soa_d_err := make_soa(#soa[dynamic]Leak_Soa_Elem, 0, LEAK_WRAPPING_COUNT)
	testing.expect_value(t, soa_d_err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, cap(soa_d), 0)

	soa: #soa[dynamic]Leak_Soa_Elem
	append_soa(&soa, Leak_Soa_Elem{a = 1, b = 2, c = 3})
	testing.expect_value(t, reserve_soa(&soa, LEAK_WRAPPING_COUNT), runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(soa), 1)
	testing.expect_value(t, soa[0], Leak_Soa_Elem{a = 1, b = 2, c = 3})
	delete_soa(soa)

	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(test)
test_leak_map_reserve_size_overflow :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)

	capacities := []int{1 << uint(8*size_of(int) - 4), max(int)/2, max(int)}
	for capacity in capacities {
		m: map[int]int
		m[7] = 70
		before := track.total_allocation_count
		err := reserve(&m, capacity)
		testing.expectf(t, err == .Out_Of_Memory, "capacity %v: %v", capacity, err)
		testing.expectf(t, track.total_allocation_count == before, "capacity %v: %v allocation(s)", capacity, track.total_allocation_count - before)
		testing.expectf(t, cap(m) < 1 << 20, "capacity %v: cap %v", capacity, cap(m))
		for i in 0..<100 {
			m[i] = i*10
		}
		testing.expect_value(t, len(m), 100)
		testing.expect_value(t, m[7], 70)
		testing.expect_value(t, m[99], 990)
		delete(m)
	}

	big: map[[64]u8][64]u8
	testing.expect_value(t, reserve(&big, max(int)/64), runtime.Allocator_Error.Out_Of_Memory)
	delete(big)

	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(test)
test_leak_inject_assign_index_overflow :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)

	d: [dynamic]int
	append(&d, 1, 2, 3)

	ok, err := inject_at(&d, max(int), 9)
	testing.expect(t, !ok)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	ok, err = inject_at(&d, max(int) - 1, 9, 9)
	testing.expect(t, !ok)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	ok, err = inject_at(&d, LEAK_WRAPPING_COUNT, 9)
	testing.expect(t, !ok)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)

	ok, err = assign_at(&d, max(int), 9)
	testing.expect(t, !ok)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	ok, err = assign_at(&d, max(int) - 1, 9, 9)
	testing.expect(t, !ok)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	ok, err = assign_at(&d, -1, 9)
	testing.expect(t, !ok)
	testing.expect_value(t, err, nil)
	ok, err = assign_at(&d, -2, 9, 9)
	testing.expect(t, !ok)
	testing.expect_value(t, err, nil)

	testing.expect_value(t, len(d), 3)
	testing.expect_value(t, d[0], 1)
	testing.expect_value(t, d[2], 3)

	ok, err = assign_at(&d, 5, 6)
	testing.expect(t, ok)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(d), 6)
	testing.expect_value(t, d[5], 6)
	ok, err = inject_at(&d, 1, 7, 8)
	testing.expect(t, ok)
	testing.expect_value(t, len(d), 8)
	testing.expect_value(t, d[1], 7)
	testing.expect_value(t, d[3], 2)
	delete(d)

	b: [dynamic]u8
	append(&b, "abc")
	ok, err = inject_at(&b, max(int), "xy")
	testing.expect(t, !ok)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	ok, err = assign_at(&b, max(int) - 1, "xy")
	testing.expect(t, !ok)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	ok, err = assign_at(&b, -1, "xy")
	testing.expect(t, !ok)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, string(b[:]), "abc")
	delete(b)

	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(private="file")
Leak_Fixed_Guarded :: struct {
	array:  [dynamic; 4]int,
	canary: [4]int,
}

@(private="file")
Leak_Fixed_Guarded_Bytes :: struct {
	array:  [dynamic; 4]u8,
	canary: [4]int,
}

@(test)
test_leak_fixed_capacity_out_of_bounds :: proc(t: ^testing.T) {
	CANARY :: [4]int{-1, -2, -3, -4}

	g := Leak_Fixed_Guarded{canary = CANARY}
	append(&g.array, 1, 2)

	testing.expect(t, !assign_at(&g.array, 4, 9))
	testing.expect(t, !assign_at(&g.array, 100, 9))
	testing.expect(t, !assign_at(&g.array, -1, 9))
	testing.expect(t, !assign_at(&g.array, 5, 9, 9))
	testing.expect(t, !assign_at(&g.array, -1, 9, 9))
	testing.expect(t, !inject_at(&g.array, 4, 9))
	testing.expect(t, !inject_at(&g.array, 100, 9))
	testing.expect(t, !inject_at(&g.array, 5, 9, 9))
	testing.expect_value(t, len(g.array), 2)
	testing.expect_value(t, g.canary, CANARY)

	testing.expect(t, assign_at(&g.array, 3, 7))
	testing.expect_value(t, len(g.array), 4)
	testing.expect_value(t, g.array[3], 7)
	testing.expect(t, assign_at(&g.array, 0, 5, 6))
	testing.expect_value(t, g.array[0], 5)
	testing.expect_value(t, g.array[1], 6)
	testing.expect(t, !inject_at(&g.array, 4, 8))
	testing.expect_value(t, len(g.array), 4)
	testing.expect_value(t, g.canary, CANARY)

	gb := Leak_Fixed_Guarded_Bytes{canary = CANARY}
	append(&gb.array, 'a')
	testing.expect(t, !inject_at(&gb.array, 5, "xy"))
	testing.expect(t, !assign_at(&gb.array, 5, "xy"))
	testing.expect(t, !assign_at(&gb.array, -1, "xy"))
	testing.expect_value(t, len(gb.array), 1)
	testing.expect(t, inject_at(&gb.array, 0, "xyz"))
	testing.expect_value(t, string(gb.array[:]), "xyza")
	testing.expect(t, assign_at(&gb.array, 4, "q"))
	testing.expect_value(t, len(gb.array), 4)
	testing.expect_value(t, gb.canary, CANARY)
}

@(test)
test_leak_heap_and_temp_arena_huge_request :: proc(t: ^testing.T) {
	for size in ([?]int{max(int), max(int) - 1, max(int) - 3}) {
		for alignment in ([?]int{1, 16, 64}) {
			data, err := runtime.mem_alloc(size, alignment, runtime.heap_allocator())
			testing.expectf(t, err == .Out_Of_Memory, "heap size %v, alignment %v: %v", size, alignment, err)
			testing.expectf(t, data == nil, "heap size %v, alignment %v: %v bytes", size, alignment, len(data))
		}
	}

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)

	arena: runtime.Arena
	testing.expect_value(t, runtime.arena_init(&arena, 4096, mem.tracking_allocator(&track)), nil)
	capacity := arena.total_capacity
	blocks := track.total_allocation_count

	for size in ([?]uint{max(uint), max(uint) - 15, uint(max(int)), uint(max(int)) + 1}) {
		data, err := runtime.arena_alloc(&arena, size, 16)
		testing.expectf(t, err == .Out_Of_Memory, "arena size %v: %v", size, err)
		testing.expectf(t, data == nil, "arena size %v: %v bytes", size, len(data))
		testing.expectf(t, arena.total_capacity == capacity, "arena size %v: capacity %v", size, arena.total_capacity)
	}
	testing.expect_value(t, track.total_allocation_count, blocks)

	data, err := runtime.arena_alloc(&arena, 100, 16)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(data), 100)

	runtime.arena_destroy(&arena)
	testing.expect_value(t, len(track.allocation_map), 0)
}
