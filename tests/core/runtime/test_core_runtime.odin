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
test_soa_array_inject_at_elem :: proc(t: ^testing.T) {

	V :: struct {a: u8, b: f32}

	array := make(#soa[dynamic]V, 0, 2)
	defer delete(array)

	append(&array, V{1, 1.5}, V{2, 2.5}, V{3, 3.5})

	expect_inject(t, &array, 0, {0, 0.5}, {{0, 0.5}, {1, 1.5}, {2, 2.5}, {3, 3.5}})
	expect_inject(t, &array, 2, {5, 5.5}, {{0, 0.5}, {1, 1.5}, {5, 5.5}, {2, 2.5}, {3, 3.5}})
	expect_inject(t, &array, 5, {9, 9.5}, {{0, 0.5}, {1, 1.5}, {5, 5.5}, {2, 2.5}, {3, 3.5}, {9, 9.5}})

	expect_inject :: proc(t: ^testing.T, arr: ^#soa[dynamic]V, index: int, arg: V, expected_slice: []V) {
		ok, err := inject_at_soa(arr, index, arg)
		testing.expectf(t, ok == true, "Injection of %v at index %d failed", arg, index)
		testing.expectf(t, err == nil, "Injection allocation of %v at index %d failed: %v", arg, index, err)
		equals := len(arr) == len(expected_slice)
		for e, i in expected_slice {
			if arr[i] != e {
				equals = false
				break
			}
		}
		testing.expectf(t, equals, "After injection of %v at index %d, expected array to be\n&%v, got\n%v", arg, index, expected_slice, arr)
	}
}

@(test)
test_soa_array_inject_at_elems :: proc(t: ^testing.T) {

	V :: struct {a: u8, b: f32}

	array := make(#soa[dynamic]V, 0, 2)
	defer delete(array)

	append(&array, V{1, 1.5}, V{2, 2.5}, V{3, 3.5})

	expect_inject(t, &array, 0, {{0, 0.5}}, {{0, 0.5}, {1, 1.5}, {2, 2.5}, {3, 3.5}})
	expect_inject(t, &array, 2, {{5, 5.5}, {6, 6.5}}, {{0, 0.5}, {1, 1.5}, {5, 5.5}, {6, 6.5}, {2, 2.5}, {3, 3.5}})
	expect_inject(t, &array, 6, {{9, 9.5}, {10, 10.5}}, {{0, 0.5}, {1, 1.5}, {5, 5.5}, {6, 6.5}, {2, 2.5}, {3, 3.5}, {9, 9.5}, {10, 10.5}})
	expect_inject(t, &array, 6, {}, {{0, 0.5}, {1, 1.5}, {5, 5.5}, {6, 6.5}, {2, 2.5}, {3, 3.5}, {9, 9.5}, {10, 10.5}})

	expect_inject :: proc(t: ^testing.T, arr: ^#soa[dynamic]V, index: int, args: []V, expected_slice: []V) {
		ok, err := inject_at_soa(arr, index, ..args)
		testing.expectf(t, ok == true, "Injection of %v at index %d failed", args, index)
		testing.expectf(t, err == nil, "Injection allocation of %v at index %d failed: %v", args, index, err)
		equals := len(arr) == len(expected_slice)
		for e, i in expected_slice {
			if arr[i] != e {
				equals = false
				break
			}
		}
		testing.expectf(t, equals, "After injection of %v at index %d, expected array to be\n&%v, got\n%v", args, index, expected_slice, arr)
	}
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

// Runs identical append/inject/remove sequences for a #soa[dynamic] array
// and an AoS [dynamic] reference, comparing all elements after each
// stage. Covers appends, injections (interior, at the end, and past the
// end where the gap must read as zero elements), unordered and ordered
// removes.
@(test)
test_soa_array_append_inject_remove :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, $E: typeid, mk: proc(i: int) -> E) {
		expect_same :: proc(t: ^testing.T, soa: #soa[dynamic]$T, model: [dynamic]T) {
			testing.expect_value(t, len(soa), len(model))
			for i in 0..<min(len(soa), len(model)) {
				testing.expect_value(t, soa[i], model[i])
			}
		}

		soa: #soa[dynamic]E
		defer delete(soa)
		ref: [dynamic]E
		defer delete(ref)

		// single appends
		for i in 0..<10 {
			n, err := append(&soa, mk(i))
			testing.expect_value(t, n, 1)
			testing.expect_value(t, err, nil)
			append(&ref, mk(i))
		}
		expect_same(t, soa, ref)

		// batch appends
		buf: [32]E
		for i in 0..<32 { buf[i] = mk(123 + i) }
		BATCH_LEN :: 5
		n, err := append(&soa, ..buf[:BATCH_LEN])
		testing.expect_value(t, n, BATCH_LEN)
		testing.expect_value(t, err, nil)
		append(&ref, ..buf[:BATCH_LEN])
		expect_same(t, soa, ref)

		n, err = append(&soa, ..buf[:])
		testing.expect_value(t, n, 32)
		testing.expect_value(t, err, nil)
		append(&ref, ..buf[:])
		expect_same(t, soa, ref)

		// single injections
		ok: bool
		ok, err = inject_at_soa(&soa, 0, mk(300))
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, 0, mk(300))
		expect_same(t, soa, ref)

		ok, err = inject_at_soa(&soa, len(soa)/2, mk(301))
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, len(ref)/2, mk(301))
		expect_same(t, soa, ref)

		// inject at the end
		ok, err = inject_at_soa(&soa, len(soa), mk(302))
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, len(ref), mk(302))
		expect_same(t, soa, ref)

		// batch injections
		ok, err = inject_at_soa(&soa, 3, ..buf[:BATCH_LEN])
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, 3, ..buf[:BATCH_LEN])
		expect_same(t, soa, ref)

		ok, err = inject_at_soa(&soa, len(soa), ..buf[:])
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, len(ref), ..buf[:])
		expect_same(t, soa, ref)

		// injecting nothing is a no-op
		ok, err = inject_at_soa(&soa, 4, ..buf[:0])
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, 4, ..buf[:0])
		expect_same(t, soa, ref)

		// single injection past the end: the gap [len, index) reads as zero
		// elements. Poison the spare capacity first (fresh heap pages are
		// already zero, which would hide a missing gap zero), then shrink back.
		for i in 0..<8 {
			n, err = append(&soa, mk(900 + i))
			testing.expect_value(t, n, 1)
			testing.expect_value(t, err, nil)
		}
		testing.expect_value(t, resize_soa(&soa, len(soa) - 8), nil)
		ok, err = inject_at_soa(&soa, len(soa) + 3, mk(500))
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, len(ref) + 3, mk(500))
		expect_same(t, soa, ref)

		// batch injection past the end (its gap slots reuse the poison above)
		ok, err = inject_at_soa(&soa, len(soa) + 2, ..buf[:BATCH_LEN])
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, len(ref) + 2, ..buf[:BATCH_LEN])
		expect_same(t, soa, ref)

		// unordered removes
		unordered_remove_soa(&soa, 20)
		unordered_remove(&ref, 20)
		unordered_remove_soa(&soa, 0)
		unordered_remove(&ref, 0)
		unordered_remove_soa(&soa, len(soa)-1)
		unordered_remove(&ref, len(ref)-1)
		expect_same(t, soa, ref)

		// ordered removes
		ordered_remove_soa(&soa, 17)
		ordered_remove(&ref, 17)
		ordered_remove_soa(&soa, 0)
		ordered_remove(&ref, 0)
		ordered_remove_soa(&soa, len(soa)-1)
		ordered_remove(&ref, len(ref)-1)
		expect_same(t, soa, ref)

		// interleaved removes, appends and injections
		for i in 0..<8 {
			unordered_remove_soa(&soa, i)
			unordered_remove(&ref, i)
			n, err = append(&soa, mk(200 + i))
			testing.expect_value(t, n, 1)
			testing.expect_value(t, err, nil)
			append(&ref, mk(200 + i))
			ok, err = inject_at_soa(&soa, i, mk(400 + i))
			testing.expect(t, ok)
			testing.expect_value(t, err, nil)
			inject_at(&ref, i, mk(400 + i))
		}
		expect_same(t, soa, ref)

		// remove till empty, then reuse
		for len(soa) > 0 {
			unordered_remove_soa(&soa, 0)
			unordered_remove(&ref, 0)
		}
		testing.expect_value(t, len(soa), 0)

		// inject into an empty array
		ok, err = inject_at_soa(&soa, 0, mk(998))
		testing.expect(t, ok)
		testing.expect_value(t, err, nil)
		inject_at(&ref, 0, mk(998))
		expect_same(t, soa, ref)

		// non-zero append
		n, err = non_zero_append(&soa, mk(42))
		testing.expect_value(t, n, 1)
		testing.expect_value(t, err, nil)
		non_zero_append(&ref, mk(42))
		expect_same(t, soa, ref)
	}

	// mixed field widths + padding
	Padded :: struct { a: u8, b: u64, c: u16 }
	check(t, Padded, proc(i: int) -> Padded { return {u8(i*3), u64(i)*257 + 7, u16(i*5 + 1)} })
	// array element type
	check(t, [4]u16, proc(i: int) -> [4]u16 { return {u16(i), u16(i + 1), u16(i*3), u16(i*7)} })
	// eight fields at varying widths, no two neighbouring fields share a stride
	Eight :: struct { a: u8, b: u16, c: u32, d: u64, e: i8, f: i16, g: f32, h: f64 }
	check(t, Eight, proc(i: int) -> Eight {
		return {
			u8(i), u16(i*3 + 1), u32(i)*5 + 2, u64(i)*7 + 3,
			i8(i >> 1), i16(i*11 + 4), f32(i)*1.5, f64(i)*2.25,
		}
	})
	// #packed struct with > 16 fields, field offsets diverging from default
	// layout (u8/u64 alternate, align_of == 1), and the field count takes
	// the type-erased batch appends compile time branch.
	Packed17 :: struct #packed {
		f0: u8, f1: u64, f2: u8, f3: u64, f4: u8, f5: u64, f6: u8, f7: u64,
		f8: u8, f9: u64, f10: u8, f11: u64, f12: u8, f13: u64, f14: u8, f15: u64,
		f16: u8,
	}
	check(t, Packed17, proc(i: int) -> Packed17 {
		return {
			u8(i), u64(i)*3 + 1, u8(i >> 1), u64(i)*5 + 2, u8(i >> 2), u64(i)*7 + 3, u8(i >> 3), u64(i)*11 + 4,
			u8(i >> 4), u64(i)*13 + 5, u8(i >> 5), u64(i)*17 + 6, u8(i >> 6), u64(i)*19 + 7, u8(i >> 7), u64(i)*23 + 8,
			u8(i*3),
		}
	})
}
